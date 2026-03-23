import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lexii/core/subscription/subscription_providers.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/practice/data/models/speaking_question_model.dart';
import 'package:lexii/features/practice/data/models/sw_writing_question_model.dart';
import 'package:lexii/features/practice/data/repositories/speaking_writing_repository.dart';
import 'package:lexii/features/practice/presentation/providers/practice_providers.dart';
import 'package:record/record.dart';

class SpeakingPracticePage extends ConsumerStatefulWidget {
  const SpeakingPracticePage({super.key});

  @override
  ConsumerState<SpeakingPracticePage> createState() =>
      _SpeakingPracticePageState();
}

class _SpeakingPracticePageState extends ConsumerState<SpeakingPracticePage> {
  @override
  Widget build(BuildContext context) {
    final isPremiumAsync = ref.watch(isPremiumProvider);
    final isPremium = isPremiumAsync.valueOrNull ?? false;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          _SwHeader(
            title: 'Speaking',
            subtitle: 'Luyện tập từng phần',
            icon: Icons.mic,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AiBadgeCard(
                    title: 'Chế độ AI tự động',
                    subtitle:
                        'Mỗi bài nói sẽ được chấm bằng AI theo tiêu chí TOEIC. Bạn chỉ cần chọn dạng bài và bắt đầu luyện.',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Danh sách Part',
                    style: GoogleFonts.lexend(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSlate800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._speakingTypes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isLocked = !isPremium && index > 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SwPartCard(
                        title: item.title,
                        subtitle: item.subtitle,
                        icon: item.icon,
                        bgColor: _speakingBgColor(item.type),
                        fgColor: _speakingFgColor(item.type),
                        isLocked: isLocked,
                        onTap: () => _showSpeakingModal(
                          context,
                          item.type,
                          item.title,
                          item.subtitle,
                        ),
                        onLockedTap: () =>
                            Navigator.of(context).pushNamed('/upgrade'),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSpeakingModal(
    BuildContext context,
    String taskType,
    String title,
    String subtitle,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SwStartModal(
        partLabel: 'Speaking',
        title: title,
        subtitle: subtitle,
        color: const Color(0xFFF97316),
        onStart: () {
          Navigator.pop(ctx);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SpeakingAttemptPage(
                taskType: taskType,
                taskTitle: title,
                mode: GradingMode.ai,
              ),
            ),
          );
        },
      ),
    );
  }
}

class WritingPracticePage extends ConsumerStatefulWidget {
  const WritingPracticePage({super.key});

  @override
  ConsumerState<WritingPracticePage> createState() =>
      _WritingPracticePageState();
}

class _WritingPracticePageState extends ConsumerState<WritingPracticePage> {
  @override
  Widget build(BuildContext context) {
    final isPremiumAsync = ref.watch(isPremiumProvider);
    final isPremium = isPremiumAsync.valueOrNull ?? false;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          _SwHeader(
            title: 'Writing',
            subtitle: 'Luyện tập từng phần',
            icon: Icons.edit_note,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI badge
                  _AiBadgeCard(
                    title: 'Chế độ AI tự động',
                    subtitle:
                        'Bài viết sẽ được AI chấm chi tiết ngay sau khi nộp, bao gồm góp ý và hướng cải thiện theo chuẩn TOEIC.',
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Danh sách Part',
                    style: GoogleFonts.lexend(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSlate800,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ..._writingTypes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isLocked = !isPremium && index > 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SwPartCard(
                        title: item.title,
                        subtitle: item.subtitle,
                        icon: item.icon,
                        bgColor: _writingBgColor(item.type),
                        fgColor: _writingFgColor(item.type),
                        isLocked: isLocked,
                        onTap: () => _showWritingModal(
                          context,
                          item.type,
                          item.title,
                          item.subtitle,
                        ),
                        onLockedTap: () =>
                            Navigator.of(context).pushNamed('/upgrade'),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWritingModal(
    BuildContext context,
    String taskType,
    String title,
    String subtitle,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SwStartModal(
        partLabel: 'Writing',
        title: title,
        subtitle: subtitle,
        color: const Color(0xFF9333EA),
        onStart: () {
          Navigator.pop(ctx);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WritingAttemptPage(
                taskType: taskType,
                taskTitle: title,
                mode: GradingMode.ai,
              ),
            ),
          );
        },
      ),
    );
  }
}

class SpeakingAttemptPage extends ConsumerStatefulWidget {
  final String taskType;
  final String taskTitle;
  final GradingMode mode;

  const SpeakingAttemptPage({
    super.key,
    required this.taskType,
    required this.taskTitle,
    required this.mode,
  });

  @override
  ConsumerState<SpeakingAttemptPage> createState() =>
      _SpeakingAttemptPageState();
}

class _SpeakingAttemptPageState extends ConsumerState<SpeakingAttemptPage> {
  final TextEditingController _transcriptController = TextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _loading = true;
  bool _recording = false;
  bool _playingAudio = false;
  bool _submitting = false;
  int _prepCountdown = 3;
  int _recordSeconds = 0;
  Timer? _prepTimer;
  Timer? _recordTimer;
  String? _recordedAudioPath;
  SpeakingQuestionModel? _question;

  @override
  void initState() {
    super.initState();
    _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() => _playingAudio = state.playing);
    });
    _loadQuestion();
  }

  @override
  void dispose() {
    _prepTimer?.cancel();
    _recordTimer?.cancel();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    _transcriptController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestion() async {
    final repo = ref.read(speakingWritingRepositoryProvider);
    final items = await repo.getSpeakingQuestionsByType(widget.taskType);
    if (!mounted) return;
    setState(() {
      _question = items.isNotEmpty ? items.first : null;
      _loading = false;
    });
  }

  void _startPrep() {
    if (_recording || _prepTimer != null) return;
    setState(() => _prepCountdown = 3);
    _prepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_prepCountdown <= 1) {
        timer.cancel();
        _prepTimer = null;
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
      _recordedAudioPath = null;
    });

    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _recordSeconds += 1);
    });
  }

  Future<void> _stopRecording() async {
    String? path;
    try {
      path = await _audioRecorder.stop();
    } catch (_) {
      path = null;
    }

    _recordTimer?.cancel();
    _recordTimer = null;
    if (!mounted) return;
    setState(() {
      _recording = false;
      _recordedAudioPath = path;
    });

    if (path == null || path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tạo được file thu âm. Thử lại một lần nữa.'),
        ),
      );
    }
  }

  Future<void> _playRecordedAudio() async {
    final path = _recordedAudioPath;
    if (path == null || path.isEmpty) return;

    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
      return;
    }

    await _audioPlayer.setFilePath(path);
    await _audioPlayer.play();
  }

  Future<void> _submit() async {
    final question = _question;
    if (question == null || _submitting) return;

    if (_recording) {
      await _stopRecording();
    }

    setState(() => _submitting = true);
    final repo = ref.read(speakingWritingRepositoryProvider);

    String finalTranscript = _transcriptController.text.trim();
    AiScoreBundle? ai;
    String? answerId;

    try {
      if (finalTranscript.isEmpty &&
          (_recordedAudioPath?.isNotEmpty ?? false)) {
        try {
          finalTranscript = await repo
              .transcribeSpeakingAudioWithGemini(audioPath: _recordedAudioPath!)
              .timeout(const Duration(seconds: 20));
        } catch (_) {
          finalTranscript = '';
        }

        if (finalTranscript.isNotEmpty) {
          _transcriptController.text = finalTranscript;
        }
      }

      if (finalTranscript.isEmpty) {
        finalTranscript = 'No transcript captured from audio.';
      }

      try {
        answerId = await repo
            .submitSpeakingAnswer(
              questionId: question.id,
              transcript: finalTranscript,
              durationSeconds: _recordSeconds,
              audioUrl: _recordedAudioPath,
            )
            .timeout(const Duration(seconds: 15));
      } catch (_) {
        answerId = null;
      }

      if (widget.mode == GradingMode.ai) {
        try {
          ai = await repo
              .evaluateSpeakingByGemini(
                taskType: widget.taskType,
                prompt: question.content,
                transcript: finalTranscript,
                durationSeconds: _recordSeconds,
              )
              .timeout(const Duration(seconds: 25));
        } catch (_) {
          ai = repo.evaluateSpeakingByAi(
            taskType: widget.taskType,
            prompt: question.content,
            transcript: finalTranscript,
            durationSeconds: _recordSeconds,
          );
        }

        if (answerId != null) {
          try {
            await repo
                .saveAiSpeakingEvaluation(answerId: answerId, ai: ai)
                .timeout(const Duration(seconds: 10));
          } catch (_) {
            // Keep UX smooth if evaluation persistence is delayed.
          }
        }
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SwResultPage(
            isSpeaking: true,
            mode: widget.mode,
            taskTitle: widget.taskTitle,
            ai: ai,
            userAnswer: finalTranscript,
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
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final question = _question;
    if (question == null) {
      return _EmptyScaffold(title: 'Chưa có câu hỏi cho dạng này.');
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          _AttemptHeader(title: widget.taskTitle),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ModeChip(mode: widget.mode),
                  const SizedBox(height: 12),
                  _PromptCard(
                    content: question.content,
                    imageUrl: question.imageUrl,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderSlate200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _recording ? Icons.mic : Icons.timer,
                          color: _recording
                              ? AppColors.red600
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _recording
                                ? 'Đang ghi âm: ${_recordSeconds}s'
                                : _prepTimer != null
                                ? 'Chuẩn bị ghi âm: $_prepCountdown'
                                : 'Nhấn Bắt đầu để ghi âm câu trả lời',
                            style: GoogleFonts.lexend(
                              fontSize: 13,
                              color: AppColors.textSlate600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: (_recording || _prepTimer != null)
                              ? null
                              : _startPrep,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Bắt đầu'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _recording
                              ? () {
                                  _stopRecording();
                                }
                              : null,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _recording
                                ? AppColors.red600
                                : null,
                            foregroundColor: _recording ? Colors.white : null,
                            side: BorderSide(
                              color: _recording
                                  ? AppColors.red600
                                  : AppColors.borderSlate200,
                            ),
                          ),
                          icon: const Icon(Icons.stop),
                          label: const Text('Dừng'),
                        ),
                      ),
                    ],
                  ),
                  if (_recordedAudioPath != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Đã lưu bảng ghi âm. Bạn có thể nghe lại trước khi nộp.',
                            style: GoogleFonts.lexend(
                              fontSize: 12,
                              color: AppColors.green600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _playRecordedAudio,
                          icon: Icon(
                            _playingAudio
                                ? Icons.pause_circle
                                : Icons.play_circle,
                          ),
                          label: Text(_playingAudio ? 'Tạm dừng' : 'Nghe lại'),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                              'Nộp bài',
                              style: GoogleFonts.lexend(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WritingAttemptPage extends ConsumerStatefulWidget {
  final String taskType;
  final String taskTitle;
  final GradingMode mode;

  const WritingAttemptPage({
    super.key,
    required this.taskType,
    required this.taskTitle,
    required this.mode,
  });

  @override
  ConsumerState<WritingAttemptPage> createState() => _WritingAttemptPageState();
}

class _WritingAttemptPageState extends ConsumerState<WritingAttemptPage> {
  final TextEditingController _answerController = TextEditingController();
  bool _loading = true;
  bool _submitting = false;
  SwWritingQuestionModel? _question;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestion() async {
    final repo = ref.read(speakingWritingRepositoryProvider);
    final items = await repo.getWritingQuestionsByType(widget.taskType);
    if (!mounted) return;
    setState(() {
      _question = items.isNotEmpty ? items.first : null;
      _loading = false;
    });
  }

  Future<void> _submit() async {
    final question = _question;
    if (question == null || _submitting) return;

    setState(() => _submitting = true);
    final repo = ref.read(speakingWritingRepositoryProvider);

    final userAnswer = _answerController.text.trim();
    String? answerId;
    AiScoreBundle? ai;

    try {
      try {
        answerId = await repo
            .submitWritingAnswer(
              questionId: question.id,
              answerText: userAnswer,
            )
            .timeout(const Duration(seconds: 15));
      } catch (_) {
        answerId = null;
      }

      if (widget.mode == GradingMode.ai) {
        try {
          ai = await repo
              .evaluateWritingByGemini(
                taskType: widget.taskType,
                prompt: question.content,
                answer: userAnswer,
              )
              .timeout(const Duration(seconds: 25));
        } catch (_) {
          ai = repo.evaluateWritingByAi(
            taskType: widget.taskType,
            prompt: question.content,
            answer: userAnswer,
          );
        }

        if (answerId != null) {
          try {
            await repo
                .saveAiWritingEvaluation(answerId: answerId, ai: ai)
                .timeout(const Duration(seconds: 10));
          } catch (_) {
            // Ignore persistence delays and continue to result page.
          }
        }
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SwResultPage(
            isSpeaking: false,
            mode: widget.mode,
            taskTitle: widget.taskTitle,
            ai: ai,
            userAnswer: userAnswer,
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
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final question = _question;
    if (question == null) {
      return _EmptyScaffold(title: 'Chưa có câu hỏi cho dạng này.');
    }

    final wordCount = _answerController.text.trim().isEmpty
        ? 0
        : _answerController.text.trim().split(RegExp(r'\s+')).length;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          _AttemptHeader(title: widget.taskTitle),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ModeChip(mode: widget.mode),
                  const SizedBox(height: 12),
                  _PromptCard(
                    content: question.content,
                    imageUrl: question.imageUrl,
                    keywords: question.keywords,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _answerController,
                    minLines: 8,
                    maxLines: 14,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      color: AppColors.textSlate800,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Nhập câu trả lời của bạn...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Số từ: $wordCount',
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: AppColors.textSlate500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                              'Nộp bài',
                              style: GoogleFonts.lexend(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SwResultPage extends StatelessWidget {
  final bool isSpeaking;
  final GradingMode mode;
  final String taskTitle;
  final AiScoreBundle? ai;
  final String userAnswer;

  const SwResultPage({
    super.key,
    required this.isSpeaking,
    required this.mode,
    required this.taskTitle,
    required this.ai,
    required this.userAnswer,
  });

  String _taskLabel(String key) {
    final normalized = key.trim().toLowerCase();
    switch (normalized) {
      case 'pronunciation':
        return 'Phát âm';
      case 'fluency':
        return 'Trôi chảy';
      case 'grammar':
        return 'Ngữ pháp';
      case 'vocabulary':
        return 'Từ vựng';
      case 'coherence':
      case 'content':
        return 'Nội dung';
      default:
        return key;
    }
  }

  Color _scoreColor(int score) {
    if (score >= 80) return AppColors.green600;
    if (score >= 60) return AppColors.yellow500;
    return AppColors.red500;
  }

  @override
  Widget build(BuildContext context) {
    final isAi = mode == GradingMode.ai;
    final overall = ai?.overall ?? 0;
    final answeredCount = userAnswer.trim().isEmpty ? 0 : 1;

    final scoreEntries = ai != null
        ? (ai!.taskScores.isNotEmpty
              ? ai!.taskScores.entries
                    .map((e) => MapEntry(_taskLabel(e.key), e.value))
                    .toList()
              : isSpeaking
              ? <MapEntry<String, int>>[
                  MapEntry('Phát âm', ai!.pronunciation),
                  MapEntry('Trôi chảy', ai!.fluency),
                  MapEntry('Ngữ pháp', ai!.grammar),
                  MapEntry('Từ vựng', ai!.vocabulary),
                  MapEntry('Nội dung', ai!.coherence),
                ]
              : <MapEntry<String, int>>[
                  MapEntry('Nội dung', ai!.coherence),
                  MapEntry('Ngữ pháp', ai!.grammar),
                  MapEntry('Từ vựng', ai!.vocabulary),
                ])
        : const <MapEntry<String, int>>[];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF14B8A6)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            taskTitle,
                            style: GoogleFonts.lexend(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            isAi
                                ? 'AI Chấm · $answeredCount/1 bài đã nộp'
                                : 'Chế độ thường · Bài làm đã được lưu',
                            style: GoogleFonts.lexend(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.88),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isAi && overall > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$overall',
                              style: GoogleFonts.lexend(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '/100',
                              style: GoogleFonts.lexend(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.9),
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
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSlate100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kết quả chấm AI',
                                style: GoogleFonts.lexend(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSlate800,
                                ),
                              ),
                              Text(
                                isAi
                                    ? '1 bài đã nộp · đã chấm chi tiết'
                                    : 'Bài làm đã được lưu thành công',
                                style: GoogleFonts.lexend(
                                  fontSize: 12,
                                  color: AppColors.textSlate500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (isAi && overall > 0) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'Điểm tổng',
                            style: GoogleFonts.lexend(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$overall/100',
                            style: GoogleFonts.lexend(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: overall / 100,
                          minHeight: 8,
                          backgroundColor: AppColors.slate100,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _scoreColor(overall),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (isAi && ai != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderSlate100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Điểm chi tiết',
                        style: GoogleFonts.lexend(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSlate800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...scoreEntries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 96,
                                child: Text(
                                  entry.key,
                                  style: GoogleFonts.lexend(
                                    fontSize: 12,
                                    color: AppColors.textSlate500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: entry.value / 100,
                                    minHeight: 6,
                                    backgroundColor: AppColors.slate100,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _scoreColor(entry.value),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 28,
                                child: Text(
                                  '${entry.value}',
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.lexend(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.slate700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (ai!.errors.isNotEmpty)
                  _ResultPanel(
                    title: 'Lỗi cần sửa',
                    content: ai!.errors.map((e) => '- $e').join('\n'),
                    bg: const Color(0xFFFEF2F2),
                    border: const Color(0xFFFECACA),
                  ),
                if (ai!.errors.isNotEmpty) const SizedBox(height: 10),
                _ResultPanel(
                  title: 'Phân tích & góp ý',
                  content: ai!.feedback,
                  bg: Colors.white,
                  border: AppColors.borderSlate200,
                ),
                if (isSpeaking && ai!.missingDetails.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _ResultPanel(
                    title: 'Ý còn thiếu',
                    content: ai!.missingDetails.map((e) => '- $e').join('\n'),
                    bg: const Color(0xFFFFFBEB),
                    border: const Color(0xFFFDE68A),
                  ),
                ],
                if (isSpeaking && ai!.wrongInformation.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _ResultPanel(
                    title: 'Thông tin chưa chính xác',
                    content: ai!.wrongInformation.map((e) => '- $e').join('\n'),
                    bg: const Color(0xFFFFF7ED),
                    border: const Color(0xFFFED7AA),
                  ),
                ],
                if (ai!.vocabularyHighlights.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _ResultPanel(
                    title: 'Từ vựng nên dùng',
                    content: ai!.vocabularyHighlights
                        .map((e) => '- $e')
                        .join('\n'),
                    bg: const Color(0xFFEFF6FF),
                    border: const Color(0xFFBFDBFE),
                  ),
                ],
                if (ai!.aiSuggestedAnswer.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _ResultPanel(
                    title: 'Gợi ý của AI',
                    content: ai!.aiSuggestedAnswer,
                    bg: const Color(0xFFFFFBEB),
                    border: const Color(0xFFFDE68A),
                  ),
                ],
              ],

              if (userAnswer.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                _ResultPanel(
                  title: isSpeaking ? 'Văn bản nhận diện' : 'Bài làm của bạn',
                  content: userAnswer,
                  bg: const Color(0xFFF8FAFC),
                  border: AppColors.borderSlate200,
                ),
              ],

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    isSpeaking ? 'Về trang luyện nói' : 'Về trang luyện tập',
                    style: GoogleFonts.lexend(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  final String title;
  final String content;
  final Color bg;
  final Color border;

  const _ResultPanel({
    required this.title,
    required this.content,
    required this.bg,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.lexend(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textSlate800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.lexend(
              fontSize: 13,
              height: 1.45,
              color: AppColors.slate700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SwHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 4),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.lexend(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttemptHeader extends StatelessWidget {
  final String title;

  const _AttemptHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.lexend(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final GradingMode mode;

  const _ModeChip({required this.mode});

  @override
  Widget build(BuildContext context) {
    final isAi = mode == GradingMode.ai;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isAi ? AppColors.indigo100 : AppColors.teal100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isAi ? 'Chế độ AI' : 'Chế độ thường',
        style: GoogleFonts.lexend(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isAi ? AppColors.indigo600 : AppColors.primaryDark,
        ),
      ),
    );
  }
}

class _AiBadgeCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _AiBadgeCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Color(0xFFF97316),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSlate800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    color: AppColors.textSlate500,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SwPartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color bgColor;
  final Color fgColor;
  final bool isLocked;
  final VoidCallback onTap;
  final VoidCallback? onLockedTap;

  const _SwPartCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.bgColor,
    required this.fgColor,
    required this.isLocked,
    required this.onTap,
    this.onLockedTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isLocked ? (onLockedTap ?? onTap) : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isLocked
                  ? const Color(0xFFFDE68A)
                  : AppColors.borderSlate100,
            ),
            color: isLocked ? const Color(0xFFFFFBEB) : Colors.white,
            boxShadow: isLocked
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isLocked ? const Color(0xFFFEF3C7) : bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isLocked ? const Color(0xFFD97706) : fgColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isLocked
                            ? const Color(0xFF92400E)
                            : AppColors.textSlate800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: AppColors.textSlate500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (isLocked)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock,
                        size: 12,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Premium',
                        style: GoogleFonts.lexend(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.textSlate400,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwStartModal extends StatelessWidget {
  final String partLabel;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onStart;

  const _SwStartModal({
    required this.partLabel,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 20 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        partLabel,
                        style: GoogleFonts.lexend(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.help_outline,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sẵn sàng luyện tập',
                        style: GoogleFonts.lexend(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSlate800,
                        ),
                      ),
                      Text(
                        'Bạn sẽ luyện tập $title với chế độ AI chấm.',
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          color: AppColors.textSlate500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.borderSlate200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Hủy bỏ',
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSlate600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Bắt đầu ngay',
                        style: GoogleFonts.lexend(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Color helpers for Speaking / Writing parts ─────────────
Color _speakingBgColor(String type) {
  switch (type) {
    case 'read_aloud':
      return const Color(0xFFDBEAFE);
    case 'describe_image':
      return const Color(0xFFFAF5FF);
    case 'respond_questions':
      return const Color(0xFFDCFCE7);
    case 'express_opinion':
      return const Color(0xFFFEF3C7);
    case 'propose_solution':
      return const Color(0xFFFCE7F3);
    default:
      return const Color(0xFFF0FDFA);
  }
}

Color _speakingFgColor(String type) {
  switch (type) {
    case 'read_aloud':
      return const Color(0xFF2563EB);
    case 'describe_image':
      return const Color(0xFF9333EA);
    case 'respond_questions':
      return const Color(0xFF16A34A);
    case 'express_opinion':
      return const Color(0xFFD97706);
    case 'propose_solution':
      return const Color(0xFFDB2777);
    default:
      return AppColors.primary;
  }
}

Color _writingBgColor(String type) {
  switch (type) {
    case 'sentence':
      return const Color(0xFFDBEAFE);
    case 'email':
      return const Color(0xFFFAF5FF);
    case 'essay':
      return const Color(0xFFFEF3C7);
    default:
      return const Color(0xFFF0FDFA);
  }
}

Color _writingFgColor(String type) {
  switch (type) {
    case 'sentence':
      return const Color(0xFF2563EB);
    case 'email':
      return const Color(0xFF9333EA);
    case 'essay':
      return const Color(0xFFD97706);
    default:
      return AppColors.primary;
  }
}

class _PromptCard extends StatelessWidget {
  final String content;
  final String? imageUrl;
  final List<String> keywords;

  const _PromptCard({
    required this.content,
    this.imageUrl,
    this.keywords = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSlate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            content,
            style: GoogleFonts.lexend(
              fontSize: 14,
              color: AppColors.textSlate600,
              height: 1.5,
            ),
          ),
          if (keywords.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: keywords
                  .map(
                    (k) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.teal50,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        k,
                        style: GoogleFonts.lexend(
                          fontSize: 11,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyScaffold extends StatelessWidget {
  final String title;

  const _EmptyScaffold({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          title,
          style: GoogleFonts.lexend(color: AppColors.textSlate500),
        ),
      ),
    );
  }
}

class _PracticeType {
  final String type;
  final String title;
  final String subtitle;
  final IconData icon;

  const _PracticeType({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

const List<_PracticeType> _speakingTypes = [
  _PracticeType(
    type: 'read_aloud',
    title: 'Đọc đoạn văn',
    subtitle: 'Read Aloud',
    icon: Icons.record_voice_over,
  ),
  _PracticeType(
    type: 'describe_picture',
    title: 'Mô tả hình ảnh',
    subtitle: 'Describe a Picture',
    icon: Icons.image,
  ),
  _PracticeType(
    type: 'respond_questions',
    title: 'Trả lời câu hỏi',
    subtitle: 'Respond to Questions',
    icon: Icons.question_answer,
  ),
  _PracticeType(
    type: 'respond_information',
    title: 'Trả lời dựa trên thông tin',
    subtitle: 'Respond to Information',
    icon: Icons.table_chart,
  ),
  _PracticeType(
    type: 'express_opinion',
    title: 'Trình bày quan điểm',
    subtitle: 'Express an Opinion',
    icon: Icons.campaign,
  ),
];

const List<_PracticeType> _writingTypes = [
  _PracticeType(
    type: 'write_sentence_picture',
    title: 'Viết câu dựa trên hình ảnh',
    subtitle: 'Write a Sentence Based on a Picture',
    icon: Icons.image,
  ),
  _PracticeType(
    type: 'reply_email',
    title: 'Trả lời email',
    subtitle: 'Respond to an Email',
    icon: Icons.email,
  ),
  _PracticeType(
    type: 'opinion_essay',
    title: 'Viết bài luận nêu quan điểm',
    subtitle: 'Opinion Essay',
    icon: Icons.edit_note,
  ),
];
