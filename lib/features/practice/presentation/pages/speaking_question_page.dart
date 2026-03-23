import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/practice/data/models/speaking_question_model.dart';
import 'package:lexii/features/practice/data/repositories/speaking_writing_repository.dart';
import 'package:lexii/features/practice/presentation/pages/sw_practice_page.dart'
    show SwResultPage;
import 'package:lexii/features/practice/presentation/providers/practice_providers.dart';

class SpeakingQuestionPage extends ConsumerStatefulWidget {
  final int partNumber;
  final String partTitle;
  final int? questionLimit;

  const SpeakingQuestionPage({
    super.key,
    required this.partNumber,
    required this.partTitle,
    this.questionLimit,
  });

  @override
  ConsumerState<SpeakingQuestionPage> createState() =>
      _SpeakingQuestionPageState();
}

class _SpeakingQuestionPageState extends ConsumerState<SpeakingQuestionPage> {
  int _currentIndex = 0;
  final Map<String, _SpeakingAnswerData> _answers = {};

  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _recording = false;
  bool _submitting = false;
  bool _showCountdown = false;
  int _prepCountdown = 10;
  int _recordSeconds = 0;
  Timer? _prepTimer;
  Timer? _recordTimer;
  String? _playingQuestionId;

  List<SpeakingQuestionModel>? _loadedQuestions;

  static const Map<int, _SpeakingMeta> _partMeta = {
    1: _SpeakingMeta(
      label: 'Read Aloud',
      taskLabel: 'Đọc đoạn văn to rõ ràng',
      bg: Color(0xFFEFF6FF),
      fg: Color(0xFF2563EB),
    ),
    2: _SpeakingMeta(
      label: 'Describe a Picture',
      taskLabel: 'Mô tả hình ảnh chi tiết',
      bg: Color(0xFFFAF5FF),
      fg: Color(0xFF9333EA),
    ),
    3: _SpeakingMeta(
      label: 'Respond to Questions',
      taskLabel: 'Trả lời câu hỏi ngắn',
      bg: Color(0xFFF0FDF4),
      fg: Color(0xFF16A34A),
    ),
    4: _SpeakingMeta(
      label: 'Respond to Information',
      taskLabel: 'Phản hồi theo thông tin cho sẵn',
      bg: Color(0xFFFFF7ED),
      fg: Color(0xFFEA580C),
    ),
    5: _SpeakingMeta(
      label: 'Express an Opinion',
      taskLabel: 'Trình bày quan điểm cá nhân',
      bg: Color(0xFFFEF2F2),
      fg: Color(0xFFDC2626),
    ),
  };

  @override
  void initState() {
    super.initState();
    _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      if (!state.playing) {
        setState(() => _playingQuestionId = null);
      }
    });
  }

  @override
  void dispose() {
    _prepTimer?.cancel();
    _recordTimer?.cancel();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _togglePlay(SpeakingQuestionModel q) async {
    final answer = _answers[q.id];
    if (answer == null || answer.audioPath.isEmpty) return;

    try {
      if (_playingQuestionId == q.id && _audioPlayer.playing) {
        await _audioPlayer.pause();
        if (mounted) setState(() => _playingQuestionId = null);
        return;
      }

      await _audioPlayer.stop();
      await _audioPlayer.setFilePath(answer.audioPath);
      await _audioPlayer.play();
      if (mounted) setState(() => _playingQuestionId = q.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể phát lại audio: $e')));
    }
  }

  Future<void> _stopPlayback() async {
    if (_audioPlayer.playing || _playingQuestionId != null) {
      await _audioPlayer.stop();
      if (mounted) setState(() => _playingQuestionId = null);
    }
  }

  String _titleOf(SpeakingQuestionModel q) {
    final v = q.extraData['title']?.toString().trim();
    if (v != null && v.isNotEmpty) return v;
    return 'Câu ${_currentIndex + 1}';
  }

  String _promptOf(SpeakingQuestionModel q) {
    final v = q.extraData['prompt']?.toString().trim();
    if (v != null && v.isNotEmpty) return v;
    return q.content;
  }

  String? _passageOf(SpeakingQuestionModel q) {
    final v = q.extraData['passage']?.toString().trim();
    if (v != null && v.isNotEmpty) return v;
    return null;
  }

  int _prepSecondsOf(SpeakingQuestionModel q) {
    final raw = q.extraData['prep_seconds'];
    if (raw is num && raw > 0) return raw.toInt();
    return 10;
  }

  void _startPrep(SpeakingQuestionModel q) {
    if (_recording || _prepTimer != null) return;
    _stopPlayback();

    final prepSeconds = _prepSecondsOf(q);
    if (prepSeconds <= 0) {
      _startRecording();
      return;
    }

    setState(() {
      _prepCountdown = prepSeconds;
      _showCountdown = true;
    });

    _prepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_prepCountdown <= 1) {
        timer.cancel();
        _prepTimer = null;
        if (!mounted) return;
        setState(() {
          _showCountdown = false;
          _prepCountdown = 0;
        });
        _startRecording();
        return;
      }
      if (!mounted) return;
      setState(() => _prepCountdown -= 1);
    });
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission || !mounted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Không có quyền micro. Vui lòng cấp quyền để thu âm.',
              ),
            ),
          );
        }
        return;
      }

      final filePath =
          '${Directory.systemTemp.path}/lexii-speaking-${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể bắt đầu thu âm: $e')));
      return;
    }

    setState(() {
      _recording = true;
      _recordSeconds = 0;
    });

    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _recordSeconds += 1);
    });
  }

  Future<void> _stopRecording(String questionId) async {
    String? path;
    try {
      path = await _audioRecorder.stop();
    } catch (_) {
      path = null;
    }

    _recordTimer?.cancel();
    _recordTimer = null;
    await _stopPlayback();
    if (!mounted) return;

    setState(() {
      _recording = false;
      if (path != null && path.isNotEmpty) {
        _answers[questionId] = _SpeakingAnswerData(
          audioPath: path,
          duration: _recordSeconds,
        );
      }
    });

    if (path == null || path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tạo được file thu âm. Thử lại một lần nữa.'),
        ),
      );
    }
  }

  Future<void> _submitAll(List<SpeakingQuestionModel> questions) async {
    if (_submitting) return;

    if (_recording) {
      final currentQ = questions[_currentIndex];
      await _stopRecording(currentQ.id);
    }

    setState(() => _submitting = true);
    final repo = ref.read(speakingWritingRepositoryProvider);

    try {
      String? lastAnswerId;
      AiScoreBundle? lastAi;
      String? lastTranscript;

      for (var i = 0; i < questions.length; i++) {
        final q = questions[i];
        final ans = _answers[q.id];
        if (ans == null || ans.audioPath.isEmpty) continue;

        var transcript = '';
        try {
          transcript = await repo
              .transcribeSpeakingAudioWithGemini(audioPath: ans.audioPath)
              .timeout(const Duration(seconds: 20));
        } catch (_) {}

        if (transcript.isEmpty) {
          transcript = 'No transcript captured from audio.';
        }

        String? answerId;
        try {
          answerId = await repo
              .submitSpeakingAnswer(
                questionId: q.id,
                transcript: transcript,
                durationSeconds: ans.duration,
                audioUrl: ans.audioPath,
              )
              .timeout(const Duration(seconds: 15));
        } catch (_) {}

        if (i == questions.length - 1 || _answers.values.last == ans) {
          lastAnswerId = answerId;
          lastTranscript = transcript;

          try {
            lastAi = await repo
                .evaluateSpeakingByGemini(
                  taskType: q.type,
                  prompt: _promptOf(q),
                  transcript: transcript,
                  durationSeconds: ans.duration,
                )
                .timeout(const Duration(seconds: 25));
          } catch (_) {
            lastAi = repo.evaluateSpeakingByAi(
              taskType: q.type,
              prompt: _promptOf(q),
              transcript: transcript,
              durationSeconds: ans.duration,
            );
          }

          if (lastAnswerId != null) {
            try {
              await repo
                  .saveAiSpeakingEvaluation(answerId: lastAnswerId, ai: lastAi)
                  .timeout(const Duration(seconds: 10));
            } catch (_) {}
          }
        }
      }

      ref.invalidate(speakingPartsProvider);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SwResultPage(
            isSpeaking: true,
            mode: GradingMode.ai,
            taskTitle: widget.partTitle,
            ai: lastAi,
            userAnswer: lastTranscript ?? '',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final speakingRepo = ref.watch(speakingWritingRepositoryProvider);
    final meta = _partMeta[widget.partNumber] ?? _partMeta[1]!;

    return FutureBuilder<List<SpeakingQuestionModel>>(
      future: _loadedQuestions == null
          ? speakingRepo
                .getSpeakingPromptsByPartNumber(
                  widget.partNumber,
                  limit: widget.questionLimit,
                )
                .then((p) {
                  if (widget.questionLimit != null &&
                      widget.questionLimit! > 0 &&
                      p.length > widget.questionLimit!) {
                    p = p.sublist(0, widget.questionLimit);
                  }
                  _loadedQuestions = p;
                  return p;
                })
          : Future.value(_loadedQuestions),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _loadedQuestions == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'Lỗi: ${snapshot.error}',
                style: GoogleFonts.lexend(color: AppColors.textSlate500),
              ),
            ),
          );
        }

        final questions = snapshot.data ?? _loadedQuestions ?? [];
        if (questions.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.partTitle)),
            body: const Center(child: Text('Chưa có câu hỏi cho phần này.')),
          );
        }

        final q = questions[_currentIndex];
        final isLast = _currentIndex == questions.length - 1;
        final hasRecorded = _answers.containsKey(q.id);
        final isPlayingCurrent =
            _playingQuestionId == q.id && _audioPlayer.playing;
        final currentPassage = _passageOf(q);
        final currentPrompt = _promptOf(q);
        final currentTitle = _titleOf(q);
        final recordedCount = _answers.length;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              _showExitDialog();
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.backgroundLight,
            body: Column(
              children: [
                _buildHeader(meta, questions),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.borderSlate100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(18),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: meta.bg,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.menu_book,
                                        color: meta.fg,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            meta.taskLabel,
                                            style: GoogleFonts.lexend(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textSlate500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            currentTitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.lexend(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textSlate800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (q.imageUrl != null && q.imageUrl!.isNotEmpty)
                                Container(
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: AppColors.borderSlate100,
                                      ),
                                      bottom: BorderSide(
                                        color: AppColors.borderSlate100,
                                      ),
                                    ),
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: q.imageUrl!,
                                    width: double.infinity,
                                    height: 220,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, _, __) => Container(
                                      height: 220,
                                      color: AppColors.slate100,
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        color: AppColors.textSlate400,
                                      ),
                                    ),
                                  ),
                                ),
                              if (currentPassage != null)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.fromLTRB(
                                    14,
                                    14,
                                    14,
                                    0,
                                  ),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Doan van can doc',
                                        style: GoogleFonts.lexend(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF2563EB),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        currentPassage,
                                        style: GoogleFonts.lexend(
                                          fontSize: 14,
                                          height: 1.55,
                                          color: AppColors.textSlate600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentPassage != null
                                          ? 'Yêu cầu'
                                          : 'Câu hỏi',
                                      style: GoogleFonts.lexend(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textSlate500,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      currentPrompt,
                                      style: GoogleFonts.lexend(
                                        fontSize: 14,
                                        height: 1.55,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.slate700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.borderSlate200),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  14,
                                  14,
                                  10,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: _recording
                                            ? const Color(0xFFFEE2E2)
                                            : AppColors.slate100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        _recording ? Icons.mic : Icons.timer,
                                        size: 18,
                                        color: _recording
                                            ? AppColors.red600
                                            : AppColors.textSlate500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _recording
                                            ? 'Đang ghi âm ${_formatTime(_recordSeconds)}'
                                            : _showCountdown
                                            ? 'Chuẩn bị thu âm: $_prepCountdown'
                                            : hasRecorded
                                            ? 'Đã ghi âm câu này'
                                            : 'Nhấn nút để bắt đầu thu âm',
                                        style: GoogleFonts.lexend(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: _recording
                                              ? AppColors.red600
                                              : AppColors.textSlate600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(
                                height: 1,
                                thickness: 1,
                                color: AppColors.borderSlate100,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 18,
                                ),
                                child: Column(
                                  children: [
                                    if (_showCountdown)
                                      Container(
                                        width: 72,
                                        height: 72,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.borderSlate200,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '$_prepCountdown',
                                          style: GoogleFonts.lexend(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.slate700,
                                          ),
                                        ),
                                      )
                                    else
                                      GestureDetector(
                                        onTap: _submitting
                                            ? null
                                            : () {
                                                if (_recording) {
                                                  _stopRecording(q.id);
                                                } else {
                                                  if (hasRecorded) {
                                                    _answers.remove(q.id);
                                                  }
                                                  _startPrep(q);
                                                }
                                              },
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 180,
                                          ),
                                          width: 84,
                                          height: 84,
                                          decoration: BoxDecoration(
                                            color: _recording
                                                ? AppColors.red600
                                                : AppColors.primary,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    (_recording
                                                            ? AppColors.red600
                                                            : AppColors.primary)
                                                        .withValues(alpha: 0.3),
                                                blurRadius: 16,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            _recording ? Icons.stop : Icons.mic,
                                            color: Colors.white,
                                            size: 34,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _recording
                                          ? 'Nhấn để dừng ghi âm'
                                          : hasRecorded
                                          ? 'Nhấn để thu âm lại'
                                          : 'Nhấn để bắt đầu',
                                      style: GoogleFonts.lexend(
                                        fontSize: 12,
                                        color: AppColors.textSlate500,
                                      ),
                                    ),
                                    if (hasRecorded) ...[
                                      const SizedBox(height: 10),
                                      OutlinedButton.icon(
                                        onPressed: _recording
                                            ? null
                                            : () {
                                                _togglePlay(q);
                                              },
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: AppColors.borderSlate200,
                                          ),
                                          minimumSize: const Size.fromHeight(
                                            40,
                                          ),
                                        ),
                                        icon: Icon(
                                          isPlayingCurrent
                                              ? Icons.pause_circle_outline
                                              : Icons.play_circle_outline,
                                          size: 18,
                                        ),
                                        label: Text(
                                          isPlayingCurrent
                                              ? 'Tam dung nghe lai'
                                              : 'Nghe lai ban ghi',
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 10,
                    bottom: 14 + MediaQuery.of(context).padding.bottom,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: (_currentIndex > 0 && !_recording)
                              ? () async {
                                  await _stopPlayback();
                                  setState(() => _currentIndex--);
                                }
                              : null,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.borderSlate200,
                            ),
                            minimumSize: const Size.fromHeight(44),
                          ),
                          icon: const Icon(Icons.chevron_left, size: 18),
                          label: const Text('Câu trước'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed:
                              (_recording || _showCountdown || _submitting)
                              ? null
                              : () async {
                                  if (isLast) {
                                    _submitAll(questions);
                                  } else {
                                    await _stopPlayback();
                                    setState(() => _currentIndex++);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.textSlate300,
                            minimumSize: const Size.fromHeight(44),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  isLast
                                      ? 'Nộp bài'
                                      : 'Câu tiếp (${recordedCount}/${questions.length})',
                                  style: GoogleFonts.lexend(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    _SpeakingMeta meta,
    List<SpeakingQuestionModel> questions,
  ) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          child: Column(
            children: [
              Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showExitDialog,
                      borderRadius: BorderRadius.circular(999),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.arrow_back,
                          size: 24,
                          color: AppColors.slate700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.partTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lexend(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSlate800,
                          ),
                        ),
                        Text(
                          '${meta.label} · ${_currentIndex + 1}/${questions.length}',
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            color: AppColors.textSlate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF3D7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'AI Chấm',
                      style: GoogleFonts.lexend(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(questions.length, (index) {
                  final item = questions[index];
                  final active = index == _currentIndex;
                  final answered = _answers.containsKey(item.id);
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index == questions.length - 1 ? 0 : 6,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          if (_recording || _showCountdown) return;
                          _stopPlayback();
                          setState(() => _currentIndex = index);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          height: 6,
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary
                                : answered
                                ? const Color(0xFF2DD4BF)
                                : AppColors.slate200,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.borderSlate100,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Thoát luyện tập?',
          style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Tiến trình của bạn sẽ không được lưu.',
          style: GoogleFonts.lexend(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Tiếp tục làm',
              style: GoogleFonts.lexend(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: Text(
              'Thoát',
              style: GoogleFonts.lexend(color: AppColors.red600),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _SpeakingAnswerData {
  final String audioPath;
  final int duration;

  _SpeakingAnswerData({required this.audioPath, required this.duration});
}

class _SpeakingMeta {
  final String label;
  final String taskLabel;
  final Color bg;
  final Color fg;

  const _SpeakingMeta({
    required this.label,
    required this.taskLabel,
    required this.bg,
    required this.fg,
  });
}
