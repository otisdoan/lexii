import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/exam/data/models/question_model.dart';
import 'package:lexii/features/exam/data/models/test_part_model.dart';
import 'package:lexii/features/exam/presentation/providers/test_providers.dart';
import 'package:lexii/features/practice/presentation/providers/practice_providers.dart';

class ListeningQuestionPage extends ConsumerStatefulWidget {
  final String testId;
  final String testTitle;
  /// When set, only questions for this part are loaded (practice mode).
  final String? partId;
  /// When set in practice mode, loads questions by listening part number across full tests.
  final int? partNumber;
  /// In practice mode, no countdown timer is shown.
  final bool isPracticeMode;
  /// When set, only the first N questions are shown (practice mode).
  final int? questionLimit;
  /// When set, load explicit question IDs instead of test/part queries.
  final List<String>? questionIds;
  /// Randomize question order before applying [questionLimit].
  final bool randomizeQuestions;

  const ListeningQuestionPage({
    super.key,
    required this.testId,
    required this.testTitle,
    this.partId,
    this.partNumber,
    this.isPracticeMode = false,
    this.questionLimit,
    this.questionIds,
    this.randomizeQuestions = false,
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

  // Part-transition state
  int? _pendingPartIntroForPart;
  int? _pendingPartIntroNextIndex;
  bool _isShowingPartIntro = false;
  List<QuestionModel>? _cachedQuestions;
  List<TestPartModel> _cachedParts = [];
  bool _audioInitialized = false; // prevent re-init on every rebuild

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    if (!widget.isPracticeMode) _startTimer();
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

  // ─── GROUP HELPERS ───────────────────────────────────────────
  /// Returns the indices of all questions in the same group as [index].
  /// Group = consecutive questions sharing the exact same non-null audioUrl.
  /// For questions without audio (Part 5-7) each question is its own group.
  List<int> _groupFor(int index, List<QuestionModel> questions) {
    final partId = questions[index].partId;

    // Primary grouping key: passageId — MUST stay within the same part
    final passageId = questions[index].passageId;
    if (passageId != null) {
      final indices = <int>[];
      for (int i = 0; i < questions.length; i++) {
        if (questions[i].passageId == passageId &&
            questions[i].partId == partId) {
          indices.add(i);
        }
      }
      if (indices.length > 1) return indices;
    }

    // Secondary fallback for Part 6: group every 4 consecutive questions
    // within the same part (Text Completion — 4 questions per passage)
    final partNumber = _cachedParts
        .where((p) => p.id == partId)
        .firstOrNull
        ?.partNumber;
    if (partNumber == 6) {
      // Find the first index of this part
      final firstOfPart = questions.indexWhere((q) => q.partId == partId);
      final posInPart = index - firstOfPart;
      final groupStartInPart = (posInPart ~/ 4) * 4;
      final groupStart = firstOfPart + groupStartInPart;
      final groupEnd = (groupStart + 3).clamp(0, questions.length - 1);
      // Make sure we don't cross into another part
      final indices = <int>[];
      for (int i = groupStart; i <= groupEnd; i++) {
        if (questions[i].partId == partId) indices.add(i);
      }
      if (indices.length > 1) return indices;
    }

    // Fallback: consecutive questions sharing the same audioUrl, same part only
    final audio = questions[index].audioUrl;
    if (audio == null) return [index];

    int start = index;
    while (start > 0 &&
        questions[start - 1].audioUrl == audio &&
        questions[start - 1].partId == partId) {
      start--;
    }
    int end = index;
    while (end < questions.length - 1 &&
        questions[end + 1].audioUrl == audio &&
        questions[end + 1].partId == partId) {
      end++;
    }
    if (end == start) return [index];
    return List<int>.generate(end - start + 1, (i) => start + i);
  }

  /// Returns the index of the first question of the group containing [index].
  int _groupStart(int index, List<QuestionModel> questions) {
    return _groupFor(index, questions).first;
  }

  int _displayQuestionNumber(int index, List<QuestionModel> questions) {
    final raw = questions[index].orderIndex;
    if (widget.isPracticeMode) {
      return index + 1;
    }
    return raw > 0 ? raw : index + 1;
  }

  void _goToQuestion(int index, List<QuestionModel> questions) {
    if (index < 0 || index >= questions.length) return;

    // Always navigate to the first question of the target group
    final targetStart = _groupStart(index, questions);

    // Resolve audio: first question in the group that has an audioUrl
    String? audioUrlFor(int groupStart) {
      final grp = _groupFor(groupStart, questions);
      for (final i in grp) {
        final url = questions[i].audioUrl;
        if (url != null) return url;
      }
      return null;
    }

    final currentAudioUrl = audioUrlFor(_currentIndex);
    final nextAudioUrl = audioUrlFor(targetStart);
    final isSameAudio = currentAudioUrl != null &&
        nextAudioUrl != null &&
        currentAudioUrl == nextAudioUrl;

    setState(() {
      _currentIndex = targetStart;
    });

    if (!isSameAudio) {
      _audioPlayer.stop();
      if (nextAudioUrl != null) {
        _loadAudio(nextAudioUrl);
      }
    }
    // Same audio URL → keep playing without interruption
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

  void _doSubmit(List<QuestionModel> questions) async {
    _audioPlayer.stop();
    _timer?.cancel();

    // Count correct answers
    int totalCorrect = 0;
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final selectedIdx = _answers[i];
      if (selectedIdx != null &&
          selectedIdx < q.options.length &&
          q.options[selectedIdx].isCorrect) {
        totalCorrect++;
      }
    }

    // Save attempt + answers to Supabase
    try {
      final repo = ref.read(questionRepositoryProvider);
      int score;
      if (widget.isPracticeMode) {
        score = totalCorrect;
      } else {
        // Group questions by partId to determine listening vs reading
        final partOrder = <String>[];
        for (final q in questions) {
          if (!partOrder.contains(q.partId)) partOrder.add(q.partId);
        }
        final listeningPartIds = partOrder.take(4).toSet();
        final readingPartIds = partOrder.skip(4).toSet();
        int listeningCorrect = 0, listeningTotal = 0;
        int readingCorrect = 0, readingTotal = 0;
        for (int i = 0; i < questions.length; i++) {
          final q = questions[i];
          final isCorrect = _answers[i] != null &&
              _answers[i]! < q.options.length &&
              q.options[_answers[i]!].isCorrect;
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
        score = toToeicScore(listeningCorrect, listeningTotal) +
            toToeicScore(readingCorrect, readingTotal);
      }

      await repo.submitAttempt(
        testId: widget.testId,
        score: score,
        questions: questions,
        userAnswers: _answers,
      );
      if (widget.isPracticeMode) {
        await repo.saveListeningPracticeTracking(
          questions: questions,
          userAnswers: _answers,
        );
        // Force immediate stats refresh when user returns to practice pages.
        ref.invalidate(listeningPracticePartsProvider);
        ref.invalidate(wrongListeningQuestionIdsProvider);
      }
    } catch (e) {
      debugPrint('Failed to save attempt: $e');
    }

    if (!mounted) return;

    if (widget.isPracticeMode) {
      if (!mounted) return;
      context.pushReplacement('/practice/part-result', extra: {
        'testId': widget.testId,
        'partId': widget.partId ?? '',
        'partTitle': widget.testTitle,
        'correct': totalCorrect,
        'total': questions.length,
        'userAnswers': Map<int, int>.from(_answers),
        'questions': questions,
      });
      return;
    }

    // Full-test mode: navigate to score certificate
    final partOrder = <String>[];
    for (final q in questions) {
      if (!partOrder.contains(q.partId)) partOrder.add(q.partId);
    }
    final listeningPartIds = partOrder.take(4).toSet();
    final readingPartIds = partOrder.skip(4).toSet();
    int listeningCorrect = 0, listeningTotal = 0;
    int readingCorrect = 0, readingTotal = 0;
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final isCorrect = _answers[i] != null &&
          _answers[i]! < q.options.length &&
          q.options[_answers[i]!].isCorrect;
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
    context.push('/exam/score', extra: {
      'testId': widget.testId,
      'testTitle': widget.testTitle,
      'listeningScore': toToeicScore(listeningCorrect, listeningTotal),
      'readingScore': toToeicScore(readingCorrect, readingTotal),
      'totalCorrect': totalCorrect,
      'totalQuestions': questions.length,
      'userAnswers': Map<int, int>.from(_answers),
    });
  }

  void _showExitDialog(List<QuestionModel> questions) {
    _audioPlayer.pause();
    final answered = _answers.length;
    final total = questions.length;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'exit_confirm',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (ctx, anim, secondAnim, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
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
                  // Top accent bar
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.orange500,
                          AppColors.red500,
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.orange500.withValues(alpha: 0.15),
                          AppColors.red500.withValues(alpha: 0.08),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.logout_rounded,
                        color: AppColors.orange500,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Thoát bài thi?',
                    style: GoogleFonts.lexend(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSlate900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Bạn đã trả lời $answered/$total câu.\nBạn muốn làm gì?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        color: AppColors.textSlate500,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Continue button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Tiếp tục làm bài',
                          style: GoogleFonts.lexend(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Exit + Save row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _timer?.cancel();
                              _audioPlayer.stop();
                              context.pop();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.red500,
                              side: BorderSide(
                                  color: AppColors.red500.withValues(alpha: 0.3)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Thoát',
                              style: GoogleFonts.lexend(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _doSubmit(questions);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(
                                  color: AppColors.primary),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.save_outlined, size: 16),
                            label: Text(
                              'Lưu & Nộp',
                              style: GoogleFonts.lexend(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Practice mode: support explicit IDs and cross-test listening parts.
    final questionsAsync = (widget.questionIds != null &&
        widget.questionIds!.isNotEmpty)
      ? ref.watch(questionsByIdsProvider(widget.questionIds!))
      : (widget.partNumber != null && widget.isPracticeMode)
        ? ref.watch(
          questionsByListeningPartNumberProvider(widget.partNumber!))
        : widget.partId != null
          ? ref.watch(questionsByPartIdProvider(widget.partId!))
          : ref.watch(questionsByTestIdProvider(widget.testId));
    // Cache parts so onTap closures can check for next-part existence
    final partsValue = ref.watch(testPartsProvider(widget.testId)).valueOrNull;
    if (partsValue != null) _cachedParts = partsValue;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitDialog(questionsAsync.valueOrNull ?? []);
      },
      child: Scaffold(
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
        data: (allQuestions) {
          var questions = List<QuestionModel>.from(allQuestions);
          if (widget.randomizeQuestions) {
            questions.shuffle();
          }
          if (widget.questionLimit != null &&
              widget.questionLimit! < questions.length) {
            questions = questions.sublist(0, widget.questionLimit!);
          }
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

          // Always cache the latest questions list
          _cachedQuestions = questions;

          // Auto-load audio for first question — only once after questions load
          if (!_audioInitialized) {
            _audioInitialized = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_isAudioLoading) {
                final grpInit = _groupFor(_currentIndex, questions);
                final initAudio = grpInit
                    .map((i) => questions[i].audioUrl)
                    .firstWhere((u) => u != null, orElse: () => null);
                if (initAudio != null) _loadAudio(initAudio);
              }
            });
          }

          // ─── PART INTRO NAVIGATION ───
          // Triggered when _pendingPartIntroForPart is set by onTap
          if (_pendingPartIntroForPart != null && !_isShowingPartIntro) {
            final partNum = _pendingPartIntroForPart!;
            final nextIdx = _pendingPartIntroNextIndex!;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (!mounted || _isShowingPartIntro) return;
              setState(() {
                _isShowingPartIntro = true;
                _pendingPartIntroForPart = null;
                _pendingPartIntroNextIndex = null;
              });
              await context.push('/exam/part-intro', extra: {
                'testId': widget.testId,
                'testTitle': widget.testTitle,
                'partNumber': partNum,
                'isResume': true,
              });
              if (mounted) {
                setState(() => _isShowingPartIntro = false);
                final qs = _cachedQuestions;
                if (qs != null && nextIdx < qs.length) {
                  _goToQuestion(nextIdx, qs);
                  final nextGrp = _groupFor(nextIdx, qs);
                  final nextAudio = nextGrp
                      .map((i) => qs[i].audioUrl)
                      .firstWhere((u) => u != null, orElse: () => null);
                  if (nextAudio != null && !_audioPlayer.playing) {
                    await _loadAudio(nextAudio);
                    _audioPlayer.play();
                  }
                }
              }
            });
          }

          final totalQ = questions.length;
          final groupIndices = _groupFor(_currentIndex, questions);
          final isGroup = groupIndices.length > 1;

          // Debug: log group info for current question
          dev.log(
            'Q[$_currentIndex] orderIndex=${questions[_currentIndex].orderIndex} '
            'partId=${questions[_currentIndex].partId} '
            'passageId=${questions[_currentIndex].passageId} '
            'passageContent=${questions[_currentIndex].passageContent?.substring(0, (questions[_currentIndex].passageContent?.length ?? 0).clamp(0, 40))} '
            'groupIndices=$groupIndices',
            name: 'GroupDebug',
          );

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
                        // ── Top badge row ──────────────────────
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
                                  isGroup
                                      ? 'Câu ${_displayQuestionNumber(groupIndices.first, questions)}–${_displayQuestionNumber(groupIndices.last, questions)}'
                                      : 'Câu ${_displayQuestionNumber(_currentIndex, questions)}',
                                  style: GoogleFonts.lexend(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Part ${_cachedParts.where((p) => questions.isNotEmpty && p.id == questions[_currentIndex].partId).firstOrNull?.partNumber ?? 1}',
                                style: GoogleFonts.lexend(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSlate500,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${_displayQuestionNumber(_currentIndex, questions)}/$totalQ',
                                style: GoogleFonts.lexend(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSlate400,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Question card (shared audio/image) ─
                        _buildQuestionCard(questions[_currentIndex], hideText: isGroup),
                        const SizedBox(height: 20),

                        // ── For each question in the group ──────
                        ...groupIndices.map((qIdx) {
                          final q = questions[qIdx];
                          return _buildSingleQuestionBlock(
                            qIdx,
                            q,
                            questions,
                            groupIndices.length,
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
              // Audio bar — fixed at bottom
              _buildAudioBar(questions[_currentIndex], totalQ, questions),
            ],
          );
        },
      ),
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
                      onTap: () => _showExitDialog(questions),
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
                  // Overview grid icon
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showOverviewSheet(questions),
                      borderRadius: BorderRadius.circular(9999),
                      child: Tooltip(
                        message: 'Tổng quan',
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(Icons.grid_view_rounded,
                              size: 20, color: AppColors.textSlate400),
                        ),
                      ),
                    ),
                  ),
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

  void _showOverviewSheet(List<QuestionModel> questions) {
    final answered = _answers.length;
    final unanswered = questions.length - answered;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (_, scrollCtrl) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.borderSlate200,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                    child: Row(
                      children: [
                        Text(
                          'Tổng quan bài thi',
                          style: GoogleFonts.lexend(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSlate900,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: AppColors.textSlate400),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),
                  // Stats
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        _buildOverviewStat(
                          AppColors.primary,
                          '$answered',
                          'Đã làm',
                        ),
                        const SizedBox(width: 12),
                        _buildOverviewStat(
                          AppColors.orange500,
                          '$unanswered',
                          'Chưa làm',
                        ),
                        const SizedBox(width: 12),
                        _buildOverviewStat(
                          AppColors.textSlate500,
                          '${questions.length}',
                          'Tổng',
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.borderSlate100),
                  // Grid
                  Expanded(
                    child: GridView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1,
                      ),
                      itemCount: questions.length,
                      itemBuilder: (_, i) {
                        final isAnswered = _answers.containsKey(i);
                        final isCurrent = i == _currentIndex;

                        Color bg;
                        Color fg;
                        BoxBorder? border;

                        if (isCurrent) {
                          bg = AppColors.primary;
                          fg = Colors.white;
                          border = Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              width: 3);
                        } else if (isAnswered) {
                          bg = AppColors.primary.withValues(alpha: 0.12);
                          fg = AppColors.primary;
                        } else {
                          bg = AppColors.slate100;
                          fg = AppColors.textSlate400;
                        }

                        return GestureDetector(
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _goToQuestion(i, questions);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(12),
                              border: border,
                              boxShadow: isCurrent
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                '${_displayQuestionNumber(i, questions)}',
                                style: GoogleFonts.lexend(
                                  fontSize: 14,
                                  fontWeight: isCurrent
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: fg,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Bottom legend
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendDot(AppColors.primary, 'Đang làm'),
                          const SizedBox(width: 20),
                          _buildLegendDot(
                              AppColors.primary.withValues(alpha: 0.12),
                              'Đã làm'),
                          const SizedBox(width: 20),
                          _buildLegendDot(AppColors.slate100, 'Chưa làm'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOverviewStat(Color color, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.lexend(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.lexend(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.lexend(
            fontSize: 11,
            color: AppColors.textSlate500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(QuestionModel question, {bool hideText = false}) {
    final hasPassage = question.passageContent != null &&
        question.passageContent!.isNotEmpty;
    final isReadingCard = hasPassage;

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
              color: isReadingCard
                  ? const Color(0xFFEFF6FF).withValues(alpha: 0.8)
                  : const Color(0xFFFEF9C3).withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              border: Border(
                bottom: BorderSide(
                  color: isReadingCard
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                      : const Color(0xFFEAB308).withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isReadingCard
                      ? Icons.article_outlined
                      : (question.imageUrl != null
                          ? Icons.image
                          : Icons.headphones),
                  color: isReadingCard
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFCA8A04),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  isReadingCard ? 'ĐOẠN VĂN' : 'SELECT THE ANSWER',
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isReadingCard
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFCA8A04),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Passage text (Part 6 / Part 7)
          if (hasPassage)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                question.passageContent!,
                style: GoogleFonts.lexend(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSlate800,
                  height: 1.7,
                ),
              ),
            )
          // Image
          else if (question.imageUrl != null)
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
          // Single question text (no passage, no image)
          else if (!hideText && question.questionText != null)
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

  /// Renders a single question sub-block inside a group.
  /// [groupSize] == 1 → no sub-label shown (same as before).
  Widget _buildSingleQuestionBlock(
    int qIdx,
    QuestionModel q,
    List<QuestionModel> questions,
    int groupSize,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub-question label when inside a group (e.g. "Câu 32", "Câu 33")
          if (groupSize > 1) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.indigo100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Câu ${_displayQuestionNumber(qIdx, questions)}',
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.indigo600,
                      ),
                    ),
                  ),
                  if (q.questionText != null) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        q.questionText!,
                        style: GoogleFonts.lexend(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSlate800,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else if (q.questionText != null) ...[
            // Single question — show question text inside card already, skip
          ],
          // Answer options
          ...q.options.asMap().entries.map((entry) {
            final idx = entry.key;
            final opt = entry.value;
            final letter = String.fromCharCode(65 + idx);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildAnswerOption(
                qIdx,
                idx,
                letter,
                opt.content,
                questions,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAnswerOption(
      int questionIdx, int optionIdx, String letter, String text, List<QuestionModel> questions) {
    final isSelected = _answers[questionIdx] == optionIdx;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final alreadyAnswered = _answers.containsKey(questionIdx);
          setState(() => _answers[questionIdx] = optionIdx);

          if (alreadyAnswered) return;

          // Determine if the entire group is now fully answered
          final group = _groupFor(questionIdx, questions);
          final allGroupAnswered =
              group.every((i) => _answers.containsKey(i));

          if (!allGroupAnswered) return; // Still unanswered questions in group

          // All group answered → check if we need to move to next group
          final lastOfGroup = group.last;
          final nextIndex = lastOfGroup + 1;
          final currentPartId = questions[group.first].partId;

          // Is this group the last in the current part?
          final isLastOfPart = nextIndex >= questions.length ||
              questions[nextIndex].partId != currentPartId;

          if (isLastOfPart && !widget.isPracticeMode) {
            final currentPart =
                _cachedParts.where((p) => p.id == currentPartId).firstOrNull;
            final currentPartNumber = currentPart?.partNumber ?? 1;
            final nextPartNumber = currentPartNumber + 1;
            final nextPartExists =
                _cachedParts.any((p) => p.partNumber == nextPartNumber);

            if (nextPartExists) {
              _audioPlayer.pause();
              Future.delayed(const Duration(milliseconds: 600), () {
                if (mounted) {
                  setState(() {
                    _pendingPartIntroForPart = nextPartNumber;
                    _pendingPartIntroNextIndex = nextIndex;
                  });
                }
              });
              return;
            }
          }

          // Advance to next group
          if (nextIndex < questions.length) {
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) _goToQuestion(nextIndex, questions);
            });
          }
        },
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
    // Audio may be on any question in the group (usually the first)
    final grp = _groupFor(_currentIndex, questions);
    final hasAudio = grp.any((i) => questions[i].audioUrl != null);
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
                        () {
                          final grp = _groupFor(_currentIndex, questions);
                          return grp.length > 1
                              ? 'Câu ${_displayQuestionNumber(grp.first, questions)}–${_displayQuestionNumber(grp.last, questions)} · Audio'
                              : 'Câu ${_displayQuestionNumber(_currentIndex, questions)} · Audio';
                        }(),
                        style: GoogleFonts.lexend(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'TOEIC Listening Part ${_cachedParts.where((p) => questions.isNotEmpty && p.id == questions[_currentIndex].partId).firstOrNull?.partNumber ?? 1}',
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
