import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/exam/data/models/question_model.dart';
import 'package:lexii/features/exam/presentation/providers/test_providers.dart';

class AnswerReviewPage extends ConsumerStatefulWidget {
  final String testId;
  final String testTitle;
  final Map<int, int> userAnswers;
  final String section; // 'listening' or 'reading'

  const AnswerReviewPage({
    super.key,
    required this.testId,
    required this.testTitle,
    this.userAnswers = const {},
    this.section = 'listening',
  });

  @override
  ConsumerState<AnswerReviewPage> createState() => _AnswerReviewPageState();
}

class _AnswerReviewPageState extends ConsumerState<AnswerReviewPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filter = 'all'; // all, correct, wrong

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.section == 'listening' ? 0 : 1,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(questionsByTestIdProvider(widget.testId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          // App bar
          Container(
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.pop(),
                        borderRadius: BorderRadius.circular(9999),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child:
                              Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.testTitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lexend(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            ),
          ),
          // Tabs
          Container(
            color: Colors.white,
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSlate400,
                  labelStyle: GoogleFonts.lexend(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: GoogleFonts.lexend(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'Nghe Hiểu'),
                    Tab(text: 'Đọc Hiểu'),
                  ],
                ),
                // Filters
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      _buildFilterChip('Tất cả', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Chọn đúng', 'correct'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Chọn sai', 'wrong'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: questionsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(child: Text('Lỗi: $e')),
              data: (questions) => TabBarView(
                controller: _tabController,
                children: [
                  _buildQuestionList(context, questions, 'listening'),
                  _buildQuestionList(context, questions, 'reading'),
                ],
              ),
            ),
          ),
          // Bottom bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.primary,
            child: SafeArea(
              top: false,
              child: Text(
                'Ấn vào từng câu để xem giải thích chi tiết',
                textAlign: TextAlign.center,
                style: GoogleFonts.lexend(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String filterValue) {
    final isActive = _filter == filterValue;
    return GestureDetector(
      onTap: () => setState(() => _filter = filterValue),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.slate100,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Text(
          label,
          style: GoogleFonts.lexend(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : AppColors.textSlate600,
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionList(
      BuildContext context, List<QuestionModel> allQuestions, String section) {
    // Determine which parts belong to this section
    final isListening = section == 'listening';

    // Group by part
    final partGroups = <String, List<_QuestionWithIndex>>{};
    for (int i = 0; i < allQuestions.length; i++) {
      final q = allQuestions[i];
      partGroups.putIfAbsent(q.partId, () => []).add(_QuestionWithIndex(q, i));
    }

    // Split by section (first 4 parts = listening, rest = reading)
    final allPartIds = partGroups.keys.toList();
    final sectionPartIds = isListening
        ? allPartIds.take(4.clamp(0, allPartIds.length)).toList()
        : allPartIds.skip(4.clamp(0, allPartIds.length)).toList();

    final partNames = isListening
        ? [
            'Part 1: Mô Tả Hình Ảnh',
            'Part 2: Hỏi & Đáp',
            'Part 3: Đoạn Hội Thoại',
            'Part 4: Bài Nói Ngắn'
          ]
        : [
            'Part 5: Hoàn Thành Câu',
            'Part 6: Hoàn Thành Đoạn Văn',
            'Part 7: Đọc Hiểu Đoạn Văn'
          ];

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sectionPartIds.length,
      itemBuilder: (context, partIdx) {
        final partId = sectionPartIds[partIdx];
        final questionsInPart = partGroups[partId]!;

        // Apply filter
        final filtered = questionsInPart.where((qi) {
          final selectedIdx = widget.userAnswers[qi.globalIndex];
          if (_filter == 'correct') {
            return selectedIdx != null &&
                selectedIdx < qi.question.options.length &&
                qi.question.options[selectedIdx].isCorrect;
          } else if (_filter == 'wrong') {
            if (selectedIdx == null) return true; // skipped = wrong
            return selectedIdx >= qi.question.options.length ||
                !qi.question.options[selectedIdx].isCorrect;
          }
          return true;
        }).toList();

        if (filtered.isEmpty && _filter != 'all') {
          return const SizedBox.shrink();
        }

        final name = partIdx < partNames.length
            ? partNames[partIdx]
            : 'Part ${partIdx + (isListening ? 1 : 5)}';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      name,
                      style: GoogleFonts.lexend(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              ...filtered.map((qi) =>
                  _buildQuestionItem(context, qi, allQuestions)),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuestionItem(BuildContext context, _QuestionWithIndex qi,
      List<QuestionModel> allQuestions) {
    final q = qi.question;
    final selectedIdx = widget.userAnswers[qi.globalIndex];
    final isSkipped = selectedIdx == null;
    final isCorrect = !isSkipped &&
        selectedIdx < q.options.length &&
        q.options[selectedIdx].isCorrect;

    // Status
    IconData statusIcon;
    Color statusColor;
    Color statusBg;
    if (isSkipped) {
      statusIcon = Icons.warning;
      statusColor = AppColors.yellow500;
      statusBg = AppColors.amber100;
    } else if (isCorrect) {
      statusIcon = Icons.check;
      statusColor = AppColors.green600;
      statusBg = AppColors.green100;
    } else {
      statusIcon = Icons.close;
      statusColor = AppColors.red500;
      statusBg = AppColors.red100;
    }

    // Find correct option index
    int? correctIdx;
    for (int i = 0; i < q.options.length; i++) {
      if (q.options[i].isCorrect) {
        correctIdx = i;
        break;
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.push('/exam/answer-detail', extra: {
            'testId': widget.testId,
            'testTitle': widget.testTitle,
            'questionIndex': qi.globalIndex,
            'userAnswers': widget.userAnswers,
          });
        },
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSlate100),
            ),
            child: Row(
              children: [
                // Status icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: statusBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  'Câu ${qi.globalIndex + 1}',
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSlate800,
                  ),
                ),
                const Spacer(),
                // Option circles
                Row(
                  children: List.generate(q.options.length, (i) {
                    final letter = String.fromCharCode(65 + i);
                    final isSelected = selectedIdx == i;
                    final isCorrectOption = correctIdx == i;

                    Color bg;
                    Color fg;
                    Border? border;

                    if (isSelected && !isCorrect) {
                      // Wrong selection
                      bg = AppColors.red500;
                      fg = Colors.white;
                    } else if (isCorrectOption) {
                      // Correct answer (show with ring if wrong was selected)
                      bg = AppColors.primary;
                      fg = Colors.white;
                      if (!isCorrect && !isSkipped) {
                        border = Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 2,
                        );
                      }
                    } else {
                      bg = Colors.white;
                      fg = AppColors.textSlate400;
                      border = Border.all(
                          color: AppColors.borderSlate200);
                    }

                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: bg,
                          shape: BoxShape.circle,
                          border: border,
                          boxShadow: (isSelected || isCorrectOption)
                              ? [
                                  BoxShadow(
                                    color: bg.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            letter,
                            style: GoogleFonts.lexend(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: fg,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionWithIndex {
  final QuestionModel question;
  final int globalIndex;
  const _QuestionWithIndex(this.question, this.globalIndex);
}
