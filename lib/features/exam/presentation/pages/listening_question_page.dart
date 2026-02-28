import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/exam/data/models/question_model.dart';
import 'package:lexii/features/exam/presentation/providers/test_providers.dart';

class ListeningQuestionPage extends ConsumerStatefulWidget {
  final String testId;
  final String testTitle;

  const ListeningQuestionPage({
    super.key,
    required this.testId,
    required this.testTitle,
  });

  @override
  ConsumerState<ListeningQuestionPage> createState() =>
      _ListeningQuestionPageState();
}

class _ListeningQuestionPageState
    extends ConsumerState<ListeningQuestionPage>
    with SingleTickerProviderStateMixin {
  // Question state
  int _currentIndex = 0;
  final Map<int, int> _answers = {}; // questionIndex → optionIndex

  // Timer
  int _hours = 1;
  int _minutes = 59;
  int _seconds = 59;
  Timer? _timer;

  // Audio
  late final AudioPlayer _audioPlayer;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  bool _isAudioLoading = false;

  // Animation
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _startTimer();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Listen to audio streams
    _audioPlayer.durationStream.listen((d) {
      if (d != null && mounted) setState(() => _audioDuration = d);
    });
    _audioPlayer.positionStream.listen((p) {
      if (mounted) setState(() => _audioPosition = p);
    });
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {});
        if (state.playing) {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
          _pulseController.value = 0;
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_seconds > 0) {
          _seconds--;
        } else if (_minutes > 0) {
          _minutes--;
          _seconds = 59;
        } else if (_hours > 0) {
          _hours--;
          _minutes = 59;
          _seconds = 59;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _loadAudio(String url) async {
    if (_isAudioLoading) return;
    setState(() => _isAudioLoading = true);
    try {
      await _audioPlayer.setUrl(url);
    } catch (_) {
      // Handle error silently
    } finally {
      if (mounted) setState(() => _isAudioLoading = false);
    }
  }

  void _togglePlay() {
    if (_audioPlayer.playing) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  void _seekRelative(Duration offset) {
    final newPos = _audioPosition + offset;
    _audioPlayer.seek(
      Duration(
        milliseconds: newPos.inMilliseconds
            .clamp(0, _audioDuration.inMilliseconds),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}';
  }

  void _goToQuestion(int index, List<QuestionModel> questions) {
    if (index < 0 || index >= questions.length) return;
    _audioPlayer.stop();
    setState(() {
      _currentIndex = index;
    });
    // Load new audio
    final q = questions[index];
    if (q.audioUrl != null) {
      _loadAudio(q.audioUrl!);
    }
  }

  void _submitTest(List<QuestionModel> questions) {
    // Pause audio while dialog is showing
    _audioPlayer.pause();

    final answered = _answers.length;
    final total = questions.length;
    final unanswered = total - answered;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'submit_confirm',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (ctx, anim, secondAnim, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutBack,
          ),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (ctx, anim, secondAnim) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(ctx).size.width * 0.85,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top gradient accent
                  Container(
                    height: 6,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, Color(0xFF2DD4BF)],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Warning icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.15),
                          const Color(0xFF2DD4BF).withValues(alpha: 0.08),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.assignment_turned_in_outlined,
                        color: AppColors.primary,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Text(
                    'Xác nhận nộp bài?',
                    style: GoogleFonts.lexend(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSlate900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Bạn có chắc chắn muốn nộp bài?\nSau khi nộp sẽ không thể sửa đáp án.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        color: AppColors.textSlate500,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Stats row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: AppColors.borderSlate100),
                      ),
                      child: Row(
                        children: [
                          // Answered
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '$answered',
                                  style: GoogleFonts.lexend(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Đã trả lời',
                                  style: GoogleFonts.lexend(
                                    fontSize: 11,
                                    color: AppColors.textSlate400,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 36,
                            color: AppColors.borderSlate200,
                          ),
                          // Unanswered
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '$unanswered',
                                  style: GoogleFonts.lexend(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: unanswered > 0
                                        ? AppColors.orange500
                                        : AppColors.green600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Chưa trả lời',
                                  style: GoogleFonts.lexend(
                                    fontSize: 11,
                                    color: AppColors.textSlate400,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 36,
                            color: AppColors.borderSlate200,
                          ),
                          // Total
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '$total',
                                  style: GoogleFonts.lexend(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textSlate800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tổng câu',
                                  style: GoogleFonts.lexend(
                                    fontSize: 11,
                                    color: AppColors.textSlate400,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Row(
                      children: [
                        // Cancel
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSlate600,
                              side: const BorderSide(
                                  color: AppColors.borderSlate200),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Hủy bỏ',
                              style: GoogleFonts.lexend(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Confirm
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _doSubmit(questions);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Xác nhận nộp',
                              style: GoogleFonts.lexend(
                                fontSize: 14,
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
          ),
        );
      },
    );
  }

  void _doSubmit(List<QuestionModel> questions) {
    _audioPlayer.stop();
    _timer?.cancel();

    // Group questions by partId to determine listening vs reading
    final partOrder = <String>[];
    for (final q in questions) {
      if (!partOrder.contains(q.partId)) {
        partOrder.add(q.partId);
      }
    }

    final listeningPartIds = partOrder.take(4).toSet();
    final readingPartIds = partOrder.skip(4).toSet();

    int listeningCorrect = 0;
    int listeningTotal = 0;
    int readingCorrect = 0;
    int readingTotal = 0;

    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final selectedIdx = _answers[i];
      final isCorrect = selectedIdx != null &&
          selectedIdx < q.options.length &&
          q.options[selectedIdx].isCorrect;

      if (listeningPartIds.contains(q.partId)) {
        listeningTotal++;
        if (isCorrect) listeningCorrect++;
      } else if (readingPartIds.contains(q.partId)) {
        readingTotal++;
        if (isCorrect) readingCorrect++;
      }
    }

    int toToeicScore(int correct, int total) {
      if (total == 0) return 5;
      final raw = 5.0 + (correct.toDouble() / total.toDouble() * 490.0);
      return raw.round().clamp(5, 495).toInt();
    }

    final listeningScore = toToeicScore(listeningCorrect, listeningTotal);
    final readingScore = toToeicScore(readingCorrect, readingTotal);
    final totalCorrect = listeningCorrect + readingCorrect;

    context.push('/exam/score', extra: {
      'testId': widget.testId,
      'testTitle': widget.testTitle,
      'listeningScore': listeningScore,
      'readingScore': readingScore,
      'totalCorrect': totalCorrect,
      'totalQuestions': questions.length,
      'userAnswers': Map<int, int>.from(_answers),
    });
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(questionsByTestIdProvider(widget.testId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: questionsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Lỗi tải câu hỏi',
                  style: GoogleFonts.lexend(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lexend(fontSize: 12, color: AppColors.textSlate500),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Quay lại'),
                ),
              ],
            ),
          ),
        ),
        data: (questions) {
          if (questions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.quiz_outlined, size: 64, color: AppColors.textSlate400),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có câu hỏi nào',
                    style: GoogleFonts.lexend(fontSize: 16, color: AppColors.textSlate500),
                  ),
                ],
              ),
            );
          }

          // Auto-load audio for first question on initial
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_audioDuration == Duration.zero &&
                !_isAudioLoading &&
                questions[_currentIndex].audioUrl != null) {
              _loadAudio(questions[_currentIndex].audioUrl!);
            }
          });

          final question = questions[_currentIndex];
          final totalQ = questions.length;

          return Column(
            children: [
              _buildHeader(totalQ, questions),
              // Question area — scrollable, fills remaining space
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question number badge
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Câu ${_currentIndex + 1}',
                                  style: GoogleFonts.lexend(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Part 1 · Photographs',
                                style: GoogleFonts.lexend(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSlate500,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${_currentIndex + 1}/$totalQ',
                                style: GoogleFonts.lexend(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSlate400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Question card
                        _buildQuestionCard(question),
                        const SizedBox(height: 20),
                        // Answer options
                        ...question.options.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final opt = entry.value;
                          final letter = String.fromCharCode(65 + idx);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildAnswerOption(
                              idx,
                              letter,
                              opt.content,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
              // Audio bar — fixed at bottom, NO overlap
              _buildAudioBar(question, totalQ, questions),
            ],
          );
        },
      ),
    );
  }

  /// Compact header: Row 1 has back + timer + tools + nộp bài
  /// Row 2 has tool icons
  Widget _buildHeader(int totalQ, List<QuestionModel> questions) {
    final timerStr =
        '${_hours.toString().padLeft(2, '0')}:${_minutes.toString().padLeft(2, '0')}:${_seconds.toString().padLeft(2, '0')}';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSlate100),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
          child: Column(
            children: [
              // Row 1: Back + Timer + Nộp bài
              Row(
                children: [
                  // Back button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.pop(),
                      borderRadius: BorderRadius.circular(9999),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.arrow_back,
                            color: AppColors.textSlate800, size: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Compact timer
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderSlate100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: _hours == 0 && _minutes < 5
                              ? Colors.red
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timerStr,
                          style: GoogleFonts.lexend(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _hours == 0 && _minutes < 5
                                ? Colors.red
                                : AppColors.textSlate800,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Tool buttons inline
                  _buildMiniTool(Icons.flag_outlined, 'Báo lỗi'),
                  _buildMiniTool(Icons.favorite_border, 'Yêu thích'),
                  _buildMiniTool(Icons.visibility_outlined, 'Đáp án'),
                  _buildMiniTool(Icons.pause_circle_outline, 'Dừng'),
                  const SizedBox(width: 4),
                  // Nộp bài button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _submitTest(questions),
                      borderRadius: BorderRadius.circular(9999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          'Nộp bài',
                          style: GoogleFonts.lexend(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniTool(IconData icon, String tooltip) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(9999),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 20, color: AppColors.textSlate400),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(QuestionModel question) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF9C3).withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFFEAB308).withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  question.imageUrl != null ? Icons.image : Icons.headphones,
                  color: const Color(0xFFCA8A04),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'SELECT THE ANSWER',
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFCA8A04),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Image or question text
          if (question.imageUrl != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: CachedNetworkImage(
                    imageUrl: question.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.slate100,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.slate100,
                      child: const Center(
                        child: Icon(Icons.broken_image,
                            size: 48, color: AppColors.textSlate300),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else if (question.questionText != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                question.questionText!,
                style: GoogleFonts.lexend(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSlate800,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnswerOption(int index, String letter, String text) {
    final isSelected = _answers[_currentIndex] == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _answers[_currentIndex] = index),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.05)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Letter
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primary : AppColors.slate100,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color:
                                AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: GoogleFonts.lexend(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSlate600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.lexend(
                    fontSize: 15,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.textSlate900
                        : AppColors.textSlate800,
                  ),
                ),
              ),
              // Radio
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.borderSlate200,
                    width: isSelected ? 6 : 2,
                  ),
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioBar(
      QuestionModel question, int totalQ, List<QuestionModel> questions) {
    final isPlaying = _audioPlayer.playing;
    final hasAudio = question.audioUrl != null;
    final progress = _audioDuration.inMilliseconds > 0
        ? _audioPosition.inMilliseconds / _audioDuration.inMilliseconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title row + slider
            Row(
              children: [
                // Animated icon
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(
                                alpha: 0.8 + _pulseController.value * 0.2),
                            AppColors.primary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(
                                alpha: 0.3 + _pulseController.value * 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isPlaying ? Icons.graphic_eq : Icons.headphones,
                        color: Colors.white,
                        size: 18,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Câu ${_currentIndex + 1} · Audio',
                        style: GoogleFonts.lexend(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'TOEIC Listening Part 1',
                        style: GoogleFonts.lexend(
                          fontSize: 10,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!hasAudio)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'No audio',
                      style: GoogleFonts.lexend(
                        fontSize: 10,
                        color: Colors.red[300],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Slider with time labels
            Row(
              children: [
                Text(
                  _formatDuration(_audioPosition),
                  style: GoogleFonts.lexend(
                    fontSize: 10,
                    color: const Color(0xFF94A3B8),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: const Color(0xFFF97316),
                      inactiveTrackColor:
                          Colors.white.withValues(alpha: 0.08),
                      thumbColor: const Color(0xFFF97316),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 5,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                      trackHeight: 2.5,
                      overlayColor:
                          const Color(0xFFF97316).withValues(alpha: 0.15),
                    ),
                    child: Slider(
                      value: progress.clamp(0.0, 1.0),
                      onChanged: hasAudio
                          ? (v) {
                              _audioPlayer.seek(Duration(
                                milliseconds:
                                    (v * _audioDuration.inMilliseconds)
                                        .round(),
                              ));
                            }
                          : null,
                    ),
                  ),
                ),
                Text(
                  _formatDuration(_audioDuration),
                  style: GoogleFonts.lexend(
                    fontSize: 10,
                    color: const Color(0xFF94A3B8),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(
                  icon: Icons.skip_previous_rounded,
                  onTap: _currentIndex > 0
                      ? () => _goToQuestion(_currentIndex - 1, questions)
                      : null,
                  size: 22,
                ),
                const SizedBox(width: 16),
                _buildControlButton(
                  icon: Icons.replay_5,
                  onTap: hasAudio
                      ? () => _seekRelative(const Duration(seconds: -5))
                      : null,
                  size: 24,
                ),
                const SizedBox(width: 16),
                // Play button
                GestureDetector(
                  onTap: hasAudio ? _togglePlay : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: hasAudio
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF14B8A6),
                                AppColors.primary,
                              ],
                            )
                          : null,
                      color: hasAudio ? null : const Color(0xFF374151),
                      shape: BoxShape.circle,
                      boxShadow: hasAudio
                          ? [
                              BoxShadow(
                                color: AppColors.primary
                                    .withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: _isAudioLoading
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                _buildControlButton(
                  icon: Icons.forward_5,
                  onTap: hasAudio
                      ? () => _seekRelative(const Duration(seconds: 5))
                      : null,
                  size: 24,
                ),
                const SizedBox(width: 16),
                _buildControlButton(
                  icon: Icons.skip_next_rounded,
                  onTap: _currentIndex < totalQ - 1
                      ? () => _goToQuestion(_currentIndex + 1, questions)
                      : null,
                  size: 22,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    VoidCallback? onTap,
    double size = 28,
  }) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9999),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: enabled
                ? const Color(0xFFCBD5E1)
                : const Color(0xFF475569),
            size: size,
          ),
        ),
      ),
    );
  }
}
