import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/exam/data/models/question_model.dart';
import 'package:lexii/features/exam/presentation/providers/test_providers.dart';

class ReadingQuestionPage extends ConsumerStatefulWidget {
  final String testId;
  final String partId;
  final String partTitle;
  final int? questionLimit;

  const ReadingQuestionPage({
    super.key,
    required this.testId,
    required this.partId,
    required this.partTitle,
    this.questionLimit,
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
    final questionsAsync = ref.watch(questionsByPartIdProvider(widget.partId));

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
            final questions = widget.questionLimit != null &&
                    widget.questionLimit! < allQuestions.length
                ? allQuestions.sublist(0, widget.questionLimit!)
                : allQuestions;

            if (questions.isEmpty) {
              return _buildEmpty(context);
            }

            final q = questions[_currentIndex];
            return Column(
              children: [
                _buildHeader(context, _currentIndex + 1, questions.length),
                _buildProgressBar(_currentIndex + 1, questions.length),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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

  Widget _buildHeader(BuildContext context, int current, int total) {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              // Back
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showExitDialog,
                  borderRadius: BorderRadius.circular(9999),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child:
                        Icon(Icons.arrow_back, color: Colors.white, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // "Câu X"
              Text(
                'Câu $current',
                style: GoogleFonts.lexend(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              // Action icons
              Icon(Icons.report_problem_outlined,
                  color: Colors.white.withValues(alpha: 0.8), size: 20),
              const SizedBox(width: 8),
              Icon(Icons.settings_outlined,
                  color: Colors.white.withValues(alpha: 0.8), size: 20),
              const SizedBox(width: 8),
              Icon(Icons.favorite_border,
                  color: Colors.white.withValues(alpha: 0.8), size: 20),
              const Spacer(),
              // "Giải thích" button
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  'Giải thích',
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
      color: AppColors.primary,
      height: 6,
      child: LinearProgressIndicator(
        value: total > 0 ? current / total : 0,
        backgroundColor: Colors.white.withValues(alpha: 0.3),
        valueColor: const AlwaysStoppedAnimation<Color>(
          Color(0xCCFFFFFF),
        ),
        minHeight: 6,
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
    final hasAnswer = _answers[currentIndex] != null;

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
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: hasAnswer && !_submitting
              ? () => isLast
                  ? _submit(questions)
                  : setState(() => _currentIndex++)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.textSlate300,
            padding: const EdgeInsets.symmetric(vertical: 16),
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
                  isLast ? 'Nộp bài' : 'Tiếp tục',
                  style: GoogleFonts.lexend(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
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
      } catch (_) {
        // Non-fatal — still show result
      }

      if (!mounted) return;
      context.pushReplacement('/practice/part-result', extra: {
        'testId': widget.testId,
        'partId': widget.partId,
        'partTitle': widget.partTitle,
        'correct': correct,
        'total': questions.length,
        'userAnswers': Map<int, int>.from(_answers),
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
