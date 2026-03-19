import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/exam/data/models/question_model.dart';
import 'package:lexii/features/exam/presentation/providers/test_providers.dart';
import 'package:lexii/features/practice/presentation/providers/practice_providers.dart';

class ReadingQuestionPage extends ConsumerStatefulWidget {
  final String testId;
  final String partId;
  final int? partNumber;
  final String partTitle;
  final int? questionLimit;
  final List<String>? questionIds;
  final bool randomizeQuestions;

  const ReadingQuestionPage({
    super.key,
    required this.testId,
    required this.partId,
    this.partNumber,
    required this.partTitle,
    this.questionLimit,
    this.questionIds,
    this.randomizeQuestions = false,
  });

  @override
  ConsumerState<ReadingQuestionPage> createState() =>
      _ReadingQuestionPageState();
}

class _ReadingQuestionPageState extends ConsumerState<ReadingQuestionPage> {
  int _currentIndex = 0;
  final Map<int, int> _answers = {}; // questionIndex → selectedOptionIndex
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final questionsAsync = widget.questionIds != null && widget.questionIds!.isNotEmpty
        ? ref.watch(questionsByIdsProvider(widget.questionIds!))
        : (widget.partNumber != null
              ? ref.watch(questionsByReadingPartNumberProvider(widget.partNumber!))
              : ref.watch(questionsByPartIdProvider(widget.partId)));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitDialog();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: questionsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(
            child: Text(
              'Lỗi tải câu hỏi: $e',
              style: GoogleFonts.lexend(color: AppColors.textSlate500),
            ),
          ),
          data: (allQuestions) {
            final questionsPool = List<QuestionModel>.from(allQuestions);
            if (widget.randomizeQuestions) {
              questionsPool.shuffle();
            }
            var questions = widget.questionLimit != null &&
                    widget.questionLimit! < questionsPool.length
                ? questionsPool.sublist(0, widget.questionLimit!)
                : questionsPool;

            // Sau khi chọn bộ câu ngẫu nhiên, sắp xếp lại theo thứ tự gốc trong đề
            questions.sort(
              (a, b) => a.orderIndex.compareTo(b.orderIndex),
            );

            if (questions.isEmpty) {
              return _buildEmpty(context);
            }

            final q = questions[_currentIndex];
            return Column(
              children: [
                _buildHeader(
                  context,
                  _currentIndex + 1,
                  questions.length,
                  questions,
                ),
                _buildProgressBar(_currentIndex + 1, questions.length),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildQuestionMeta(_currentIndex + 1, questions.length),
                        const SizedBox(height: 12),
                        if (q.passageContent != null) ...[
                          _buildPassageSection(q.passageContent!),
                          const SizedBox(height: 20),
                        ],
                        _buildQuestionCard(q, _currentIndex),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
                _buildBottomBar(
                  context,
                  questions,
                  _currentIndex,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────

  Widget _buildHeader(
    BuildContext context,
    int current,
    int total,
    List<QuestionModel> questions,
  ) {
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
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showExitDialog,
                  borderRadius: BorderRadius.circular(9999),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.arrow_back,
                      color: AppColors.textSlate800,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Câu $current/$total',
                style: GoogleFonts.lexend(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSlate800,
                ),
              ),
              const Spacer(),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showOverviewSheet(questions),
                  borderRadius: BorderRadius.circular(9999),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.grid_view_rounded,
                      size: 20,
                      color: AppColors.textSlate400,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _submitting ? null : () => _submit(questions),
                  borderRadius: BorderRadius.circular(9999),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
        ),
      ),
    );
  }

  Widget _buildProgressBar(int current, int total) {
    return Container(
      color: Colors.white,
      height: 4,
      child: LinearProgressIndicator(
        value: total > 0 ? current / total : 0,
        backgroundColor: AppColors.slate200,
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
        minHeight: 4,
      ),
    );
  }

  Widget _buildQuestionMeta(int current, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSlate100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Câu $current',
              style: GoogleFonts.lexend(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const Spacer(),
          Text(
            '$current/$total',
            style: GoogleFonts.lexend(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSlate500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Passage card ──────────────────────────────────────────────

  Widget _buildPassageSection(String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Đọc văn bản',
              style: GoogleFonts.lexend(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textSlate800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            content,
            style: GoogleFonts.lexend(
              fontSize: 15,
              height: 1.7,
              color: const Color(0xFF333333),
            ),
          ),
        ),
      ],
    );
  }

  // ── Question card ─────────────────────────────────────────────

  Widget _buildQuestionCard(QuestionModel q, int qIndex) {
    final selected = _answers[qIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (q.questionText != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSlate100),
            ),
            child: Text(
              q.questionText!,
              style: GoogleFonts.lexend(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.5,
                color: AppColors.textSlate800,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Options
        ...List.generate(q.options.length, (i) {
          final opt = q.options[i];
          final label = String.fromCharCode(65 + i); // A, B, C, D
          final isSelected = selected == i;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => setState(() => _answers[qIndex] = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.borderSlate200,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? []
                      : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.backgroundLight,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.borderSlate200,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          label,
                          style: GoogleFonts.lexend(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSlate600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        opt.content,
                        style: GoogleFonts.lexend(
                          fontSize: 14,
                          color: isSelected
                              ? AppColors.primary
                                : AppColors.textSlate600,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────

  Widget _buildBottomBar(
    BuildContext context,
    List<QuestionModel> questions,
    int currentIndex,
  ) {
    final isLast = currentIndex == questions.length - 1;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 20 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _currentIndex > 0 && !_submitting
                  ? () => setState(() => _currentIndex--)
                  : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSlate600,
                side: const BorderSide(color: AppColors.borderSlate200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                'Câu trước',
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: !_submitting
                  ? () => isLast
                      ? _submit(questions)
                      : setState(() => _currentIndex++)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.textSlate300,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isLast ? 'Nộp bài' : 'Câu tiếp',
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
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
          initialChildSize: 0.72,
          minChildSize: 0.45,
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                    child: Row(
                      children: [
                        Text(
                          'Tổng quan bài làm',
                          style: GoogleFonts.lexend(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSlate900,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.textSlate400,
                          ),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        _buildOverviewStat(AppColors.primary, '$answered', 'Đã làm'),
                        const SizedBox(width: 12),
                        _buildOverviewStat(AppColors.orange500, '$unanswered', 'Chưa làm'),
                        const SizedBox(width: 12),
                        _buildOverviewStat(AppColors.textSlate500, '${questions.length}', 'Tổng'),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.borderSlate100),
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
                            width: 3,
                          );
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
                            setState(() => _currentIndex = i);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(12),
                              border: border,
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
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
                            'Đã làm',
                          ),
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

  // ── Submit ────────────────────────────────────────────────────

  Future<void> _submit(List<QuestionModel> questions) async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final correct = _answers.entries.where((e) {
        final q = questions[e.key];
        if (e.value >= q.options.length) return false;
        return q.options[e.value].isCorrect;
      }).length;

      // Persist attempt (if user is logged in, silently skip if not)
      try {
        final repo = ref.read(questionRepositoryProvider);
        await repo.submitAttempt(
          testId: widget.testId,
          score: correct,
          questions: questions,
          userAnswers: _answers,
        );
        await repo.saveListeningPracticeTracking(
          questions: questions,
          userAnswers: _answers,
        );
        ref.invalidate(readingPracticePartsProvider);
        ref.invalidate(wrongReadingQuestionIdsProvider);
      } catch (_) {
        // Non-fatal — still show result
      }

      if (!mounted) return;
      context.pushReplacement('/practice/part-result', extra: {
        'testId': widget.testId,
        'partId': widget.partId,
        'partTitle': widget.partTitle,
        'section': 'reading',
        'correct': correct,
        'total': questions.length,
        'userAnswers': Map<int, int>.from(_answers),
        'questions': questions,
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.quiz_outlined,
                size: 64, color: AppColors.textSlate300),
            const SizedBox(height: 16),
            Text(
              'Chưa có câu hỏi',
              style: GoogleFonts.lexend(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textSlate600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Quay lại'),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog<bool>(
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
            child: Text('Tiếp tục làm',
                style: GoogleFonts.lexend(color: AppColors.primary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: Text('Thoát',
                style: GoogleFonts.lexend(color: AppColors.red600)),
          ),
        ],
      ),
    );
  }
}
