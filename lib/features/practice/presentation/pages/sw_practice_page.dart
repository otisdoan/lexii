import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/practice/data/models/speaking_question_model.dart';
import 'package:lexii/features/practice/data/models/sw_writing_question_model.dart';
import 'package:lexii/features/practice/data/repositories/speaking_writing_repository.dart';
import 'package:lexii/features/practice/presentation/pages/sw_history_page.dart';
import 'package:lexii/features/practice/presentation/providers/practice_providers.dart';
import 'package:record/record.dart';

class SpeakingPracticePage extends ConsumerStatefulWidget {
  const SpeakingPracticePage({super.key});

  @override
  ConsumerState<SpeakingPracticePage> createState() => _SpeakingPracticePageState();
}

class _SpeakingPracticePageState extends ConsumerState<SpeakingPracticePage> {
  GradingMode _mode = GradingMode.normal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          _SwHeader(
            title: 'Luyện nói',
            subtitle: 'Speaking Practice',
            icon: Icons.mic,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GradingModeSelector(
                    mode: _mode,
                    onChanged: (value) => setState(() => _mode = value),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SwHistoryPage(isSpeaking: true),
                          ),
                        );
                      },
                      icon: const Icon(Icons.history, size: 18),
                      label: const Text('Lịch sử luyện tập'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Các dạng luyện tập',
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSlate800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._speakingTypes.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PracticeTypeCard(
                        title: item.title,
                        subtitle: item.subtitle,
                        icon: item.icon,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SpeakingAttemptPage(
                                taskType: item.type,
                                taskTitle: item.title,
                                mode: _mode,
                              ),
                            ),
                          );
                        },
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

class WritingPracticePage extends ConsumerStatefulWidget {
  const WritingPracticePage({super.key});

  @override
  ConsumerState<WritingPracticePage> createState() => _WritingPracticePageState();
}

class _WritingPracticePageState extends ConsumerState<WritingPracticePage> {
  GradingMode _mode = GradingMode.normal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          _SwHeader(
            title: 'Luyện viết',
            subtitle: 'Writing Practice',
            icon: Icons.edit_note,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GradingModeSelector(
                    mode: _mode,
                    onChanged: (value) => setState(() => _mode = value),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SwHistoryPage(isSpeaking: false),
                          ),
                        );
                      },
                      icon: const Icon(Icons.history, size: 18),
                      label: const Text('Lịch sử luyện tập'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Các dạng luyện tập',
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSlate800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._writingTypes.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PracticeTypeCard(
                        title: item.title,
                        subtitle: item.subtitle,
                        icon: item.icon,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => WritingAttemptPage(
                                taskType: item.type,
                                taskTitle: item.title,
                                mode: _mode,
                              ),
                            ),
                          );
                        },
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
  ConsumerState<SpeakingAttemptPage> createState() => _SpeakingAttemptPageState();
}

class _SpeakingAttemptPageState extends ConsumerState<SpeakingAttemptPage> {
  final TextEditingController _transcriptController = TextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _loading = true;
  bool _recording = false;
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
    _loadQuestion();
  }

  @override
  void dispose() {
    _prepTimer?.cancel();
    _recordTimer?.cancel();
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
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission || !mounted) return;

    final filePath = '${Directory.systemTemp.path}/lexii-speaking-${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: filePath,
    );

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
    final path = await _audioRecorder.stop();
    _recordTimer?.cancel();
    _recordTimer = null;
    if (!mounted) return;
    setState(() {
      _recording = false;
      _recordedAudioPath = path;
    });
  }

  Future<void> _submit() async {
    final question = _question;
    if (question == null || _submitting) return;

    if (_recording) {
      await _stopRecording();
    }

    setState(() => _submitting = true);
    final repo = ref.read(speakingWritingRepositoryProvider);

    final answerId = await repo.submitSpeakingAnswer(
      questionId: question.id,
      transcript: _transcriptController.text.trim(),
      durationSeconds: _recordSeconds,
      audioUrl: _recordedAudioPath,
    );

    AiScoreBundle? ai;
    if (widget.mode == GradingMode.ai) {
      ai = repo.evaluateSpeakingByAi(
        prompt: question.content,
        transcript: _transcriptController.text.trim(),
        durationSeconds: _recordSeconds,
      );

      if (answerId != null) {
        await repo.saveAiSpeakingEvaluation(answerId: answerId, ai: ai);
      }
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SwResultPage(
          isSpeaking: true,
          mode: widget.mode,
          taskTitle: widget.taskTitle,
          ai: ai,
          userAnswer: _transcriptController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
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
                          color: _recording ? AppColors.red600 : AppColors.primary,
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
                          onPressed: (_recording || _prepTimer != null) ? null : _startPrep,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Bắt đầu'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _recording
                              ? () {
                                  _stopRecording();
                                }
                              : null,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.red600),
                          icon: const Icon(Icons.stop),
                          label: const Text('Dừng ghi âm'),
                        ),
                      ),
                    ],
                  ),
                  if (_recordedAudioPath != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Da luu ban ghi am.',
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: AppColors.green600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextField(
                    controller: _transcriptController,
                    minLines: 4,
                    maxLines: 7,
                    style: GoogleFonts.lexend(fontSize: 14, color: AppColors.textSlate800),
                    decoration: InputDecoration(
                      hintText: 'Transcript (tùy chọn): dán hoặc nhập phần bạn đã nói để AI phân tích chi tiết hơn.',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
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
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'Nộp bài',
                              style: GoogleFonts.lexend(fontWeight: FontWeight.w700, color: Colors.white),
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

    final answerId = await repo.submitWritingAnswer(
      questionId: question.id,
      answerText: _answerController.text.trim(),
    );

    AiScoreBundle? ai;
    if (widget.mode == GradingMode.ai) {
      ai = repo.evaluateWritingByAi(
        prompt: question.content,
        answer: _answerController.text.trim(),
      );

      if (answerId != null) {
        await repo.saveAiWritingEvaluation(answerId: answerId, ai: ai);
      }
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SwResultPage(
          isSpeaking: false,
          mode: widget.mode,
          taskTitle: widget.taskTitle,
          ai: ai,
          userAnswer: _answerController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
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
                    style: GoogleFonts.lexend(fontSize: 14, color: AppColors.textSlate800),
                    decoration: InputDecoration(
                      hintText: 'Nhập câu trả lời của bạn...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Số từ: $wordCount',
                      style: GoogleFonts.lexend(fontSize: 12, color: AppColors.textSlate500),
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
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'Nộp bài',
                              style: GoogleFonts.lexend(fontWeight: FontWeight.w700, color: Colors.white),
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

  @override
  Widget build(BuildContext context) {
    final isAi = mode == GradingMode.ai;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          _AttemptHeader(title: 'Kết quả: $taskTitle'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isAi ? AppColors.indigo100 : AppColors.teal100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      isAi
                          ? 'Bài làm đã được chấm bằng AI. Bạn có thể xem chi tiết điểm và gợi ý bên dưới.'
                          : 'Bài làm đã được lưu thành công (chế độ chấm thường). Bạn có thể xem lại trong lịch sử luyện tập.',
                      style: GoogleFonts.lexend(fontSize: 13, color: AppColors.textSlate600),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (isAi && ai != null) ...[
                    _ScoreCard(title: 'Overall', score: ai!.overall),
                    const SizedBox(height: 10),
                    if (isSpeaking) ...[
                      _ScoreRow(label: 'Pronunciation', value: ai!.pronunciation),
                      _ScoreRow(label: 'Fluency', value: ai!.fluency),
                    ] else ...[
                      _ScoreRow(label: 'Coherence', value: ai!.coherence),
                    ],
                    _ScoreRow(label: 'Grammar', value: ai!.grammar),
                    _ScoreRow(label: 'Vocabulary', value: ai!.vocabulary),
                    const SizedBox(height: 12),
                    _Block(
                      title: 'Phân tích lỗi & góp ý',
                      content: ai!.feedback,
                    ),
                    const SizedBox(height: 10),
                    _Block(
                      title: 'Phiên bản đề xuất',
                      content: ai!.correctedVersion,
                    ),
                    const SizedBox(height: 10),
                  ],
                  _Block(
                    title: isSpeaking ? 'Transcript đã lưu' : 'Bài viết đã lưu',
                    content: userAnswer.trim().isEmpty
                        ? 'Không có nội dung.'
                        : userAnswer,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Về trang luyện tập',
                        style: GoogleFonts.lexend(color: Colors.white, fontWeight: FontWeight.w700),
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

class _GradingModeSelector extends StatelessWidget {
  final GradingMode mode;
  final ValueChanged<GradingMode> onChanged;

  const _GradingModeSelector({
    required this.mode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSlate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chế độ chấm bài',
            style: GoogleFonts.lexend(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textSlate800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Chấm thường'),
                selected: mode == GradingMode.normal,
                onSelected: (_) => onChanged(GradingMode.normal),
              ),
              ChoiceChip(
                label: const Text('Chấm bằng AI'),
                selected: mode == GradingMode.ai,
                onSelected: (_) => onChanged(GradingMode.ai),
              ),
            ],
          ),
        ],
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

class _PracticeTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _PracticeTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.teal50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.lexend(
                        fontSize: 15,
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
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSlate400),
            ],
          ),
        ),
      ),
    );
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.teal50,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        k,
                        style: GoogleFonts.lexend(fontSize: 11, color: AppColors.primaryDark),
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

class _ScoreCard extends StatelessWidget {
  final String title;
  final int score;

  const _ScoreCard({required this.title, required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.lexend(fontWeight: FontWeight.w700, color: AppColors.textSlate600),
          ),
          const Spacer(),
          Text(
            '$score/100',
            style: GoogleFonts.lexend(fontWeight: FontWeight.w800, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final int value;

  const _ScoreRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.lexend(fontSize: 13, color: AppColors.textSlate600),
            ),
          ),
          Text(
            '$value',
            style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSlate800),
          ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final String title;
  final String content;

  const _Block({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSlate800),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.lexend(fontSize: 13, color: AppColors.textSlate600, height: 1.5),
          ),
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
