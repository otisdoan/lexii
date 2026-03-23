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
  int _currentGroupIndex = 0;
  final Map<int, int> _answers = {};
  bool _submitting = false;

  // ─── GROUP HELPERS ───────────────────────────────────────────
  List<List<int>> _buildGroups(List<QuestionModel> questions) {
    final groups = <List<int>>[];

    for (int i = 0; i < questions.length;) {
      final q = questions[i];
      final passageId = q.passageId;

      if (passageId != null) {
        final indices = <int>[];
        for (int j = 0; j < questions.length; j++) {
          if (questions[j].passageId == passageId) {
            indices.add(j);
          }
        }
        if (indices.length > 1) {
          groups.add(indices);
          i = indices.last + 1;
          continue;
        }
      }

      groups.add([i]);
      i++;
    }

    return groups;
  }

  /// Cắt mảng theo group hoàn chỉnh (không cắt ngang passage).
  List<QuestionModel> _truncateToCompleteGroups(
      List<QuestionModel> questions, int limit) {
    if (limit <= 0 || limit >= questions.length) return questions;

    final groups = _buildGroups(questions);
    final result = <QuestionModel>[];
    int count = 0;

    for (final groupIndices in groups) {
      if (count + groupIndices.length > limit) break;
      for (final idx in groupIndices) {
        result.add(questions[idx]);
      }
      count += groupIndices.length;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = widget.questionIds != null &&
            widget.questionIds!.isNotEmpty
        ? ref.watch(questionsByIdsProvider(widget.questionIds!))
        : (widget.partNumber != null
            ? ref.watch(
                questionsByReadingPartNumberProvider(widget.partNumber!))
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

            // Truncate to complete groups (never cut mid-passage)
            final questions = widget.questionLimit != null &&
                    widget.questionLimit! > 0
                ? _truncateToCompleteGroups(questionsPool, widget.questionLimit!)
                : questionsPool;

            if (questions.isEmpty) {
              return _buildEmpty(context);
            }

            final groups = _buildGroups(questions);

            if (_currentGroupIndex >= groups.length) {
              _currentGroupIndex = groups.length - 1;
            }
            if (_currentGroupIndex < 0) _currentGroupIndex = 0;

            final groupIndices = groups[_currentGroupIndex];
            final isGroup = groupIndices.length > 1;
            final firstQIdx = groupIndices.first;
            final firstQ = questions[firstQIdx];

            return Column(
              children: [
                _buildHeader(
                    questions: questions, answered: _answers.length),
                _buildProgressBar(_currentGroupIndex + 1, groups.length),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Group badge row
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.green600,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.green600
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  isGroup
                                      ? 'Câu ${groupIndices.first + 1}–${groupIndices.last + 1}'
                                      : 'Câu ${firstQIdx + 1}',
                                  style: GoogleFonts.lexend(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              if (widget.partNumber != null)
                                Text(
                                  'Part ${widget.partNumber}',
                                  style: GoogleFonts.lexend(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSlate500,
                                  ),
                                ),
                              const Spacer(),
                              Text(
                                '${_answers.length}/${questions.length}',
                                style: GoogleFonts.lexend(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSlate400,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Passage card
                        if (firstQ.passageContent != null) ...[
                          _buildPassageSection(firstQ.passageContent!),
                          const SizedBox(height: 20),
                        ],

                        // All questions in this group
                        ...groupIndices.map((qIdx) {
                          final q = questions[qIdx];
                          return _buildSingleQuestionCard(
                            q,
                            qIdx,
                            groupSize: groupIndices.length,
                          );
                        }),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
                _buildBottomBar(questions: questions, groups: groups),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader({
    required List<QuestionModel> questions,
    required int answered,
  }) {
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.partTitle,
                      style: GoogleFonts.lexend(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSlate800,
                      ),
                    ),
                    Text(
                      '$answered/${questions.length} đã trả lời',
                      style: GoogleFonts.lexend(
                        fontSize: 11,
                        color: AppColors.textSlate400,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showOverviewSheet(),
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
                  onTap: _submitting ? null : () => _submit(),
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
        valueColor:
            const AlwaysStoppedAnimation<Color>(AppColors.green600),
        minHeight: 4,
      ),
    );
  }

  Widget _buildPassageSection(String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.article_outlined,
                    size: 14,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ĐOẠN VĂN',
                    style: GoogleFonts.lexend(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2563EB),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
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
              color: AppColors.textSlate800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleQuestionCard(
    QuestionModel q,
    int qIdx, {
    required int groupSize,
  }) {
    final selected = _answers[qIdx];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question number + Part badge
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.green600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${qIdx + 1}',
                      style: GoogleFonts.lexend(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.partNumber != null)
                  Text(
                    'Part ${widget.partNumber}',
                    style: GoogleFonts.lexend(
                      fontSize: 12,
                      color: AppColors.textSlate400,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Question text
            if (q.questionText != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  q.questionText!,
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSlate800,
                    height: 1.4,
                  ),
                ),
              ),
            ],

            // Options
            ...List.generate(q.options.length, (i) {
              final opt = q.options[i];
              final optLabel = String.fromCharCode(65 + i);
              final isSelected = selected == i;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _answers[qIdx] = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.green600.withValues(alpha: 0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.green600
                            : AppColors.borderSlate100,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color:
                                    AppColors.green600.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppColors.green600
                                : AppColors.slate100,
                          ),
                          child: Center(
                            child: Text(
                              optLabel,
                              style: GoogleFonts.lexend(
                                fontSize: 15,
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
                                  ? AppColors.textSlate900
                                  : AppColors.textSlate600,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w500,
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
        ),
      ),
    );
  }

  Widget _buildBottomBar({
    required List<QuestionModel> questions,
    required List<List<int>> groups,
  }) {
    final isFirst = _currentGroupIndex == 0;
    final isLast = _currentGroupIndex == groups.length - 1;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 20 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0x0F000000),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: !isFirst && !_submitting
                  ? () => setState(() => _currentGroupIndex--)
                  : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSlate600,
                side: BorderSide(
                  color: isFirst
                      ? AppColors.slate100
                      : AppColors.borderSlate200,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chevron_left, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    'Câu trước',
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: !_submitting
                  ? () {
                      if (isLast) {
                        _submit();
                      } else {
                        setState(() => _currentGroupIndex++);
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green600,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.slate100,
                disabledForegroundColor: AppColors.textSlate400,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
                shadowColor: AppColors.green600.withValues(alpha: 0.4),
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
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLast ? 'Nộp bài' : 'Câu tiếp',
                          style: GoogleFonts.lexend(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (!isLast) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, size: 18),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOverviewSheet() {
    // Triggers rebuild when data is available
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final questionsAsync = widget.questionIds != null &&
              widget.questionIds!.isNotEmpty
          ? ref.read(questionsByIdsProvider(widget.questionIds!))
          : (widget.partNumber != null
              ? ref.read(
                  questionsByReadingPartNumberProvider(widget.partNumber!))
              : ref.read(questionsByPartIdProvider(widget.partId)));

      final questions = questionsAsync.valueOrNull ?? [];
      final questionsPool = List<QuestionModel>.from(questions);
      final finalQuestions = widget.questionLimit != null &&
              widget.questionLimit! > 0
          ? _truncateToCompleteGroups(questionsPool, widget.questionLimit!)
          : questionsPool;

      final correct = _answers.entries.where((e) {
        if (e.key < 0 || e.key >= finalQuestions.length) return false;
        final q = finalQuestions[e.key];
        if (e.value < 0 || e.value >= q.options.length) return false;
        return q.options[e.value].isCorrect;
      }).length;

      try {
        final repo = ref.read(questionRepositoryProvider);
        await repo.submitAttempt(
          testId: widget.testId,
          score: correct,
          questions: finalQuestions,
          userAnswers: _answers,
        );
        await repo.saveListeningPracticeTracking(
          questions: finalQuestions,
          userAnswers: _answers,
        );
        ref.invalidate(readingPracticePartsProvider);
        ref.invalidate(wrongReadingQuestionIdsProvider);
      } catch (_) {
        // Non-fatal
      }

      if (!mounted) return;
      context.pushReplacement('/practice/part-result', extra: {
        'testId': widget.testId,
        'partId': widget.partId,
        'partTitle': widget.partTitle,
        'section': 'reading',
        'correct': correct,
        'total': finalQuestions.length,
        'userAnswers': Map<int, int>.from(_answers),
        'questions': finalQuestions,
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

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
