import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/exam/data/models/question_model.dart';
import 'package:lexii/features/exam/presentation/providers/test_providers.dart';

/// Part info for Vietnamese labels
class _PartInfo {
  final String name;
  final int partNumber;
  final String section; // 'listening' or 'reading'
  const _PartInfo(this.name, this.partNumber, this.section);
}

const _partInfos = [
  _PartInfo('Part 1: Mô tả hình ảnh', 1, 'listening'),
  _PartInfo('Part 2: Hỏi & Đáp', 2, 'listening'),
  _PartInfo('Part 3: Đoạn hội thoại', 3, 'listening'),
  _PartInfo('Part 4: Bài nói ngắn', 4, 'listening'),
  _PartInfo('Part 5: Hoàn thành câu', 5, 'reading'),
  _PartInfo('Part 6: Hoàn thành đoạn văn', 6, 'reading'),
  _PartInfo('Part 7: Đọc hiểu đoạn văn', 7, 'reading'),
];

class ResultPage extends ConsumerWidget {
  final String testId;
  final String testTitle;
  final Map<int, int> userAnswers;

  const ResultPage({
    super.key,
    required this.testId,
    required this.testTitle,
    this.userAnswers = const {},
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(questionsByTestIdProvider(testId));

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
                        'Kết quả',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lexend(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Expanded(
            child: questionsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(child: Text('Lỗi: $e')),
              data: (questions) =>
                  _buildContent(context, questions),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<QuestionModel> questions) {
    // Group questions by part
    final partGroups = <String, List<QuestionModel>>{};
    for (final q in questions) {
      partGroups.putIfAbsent(q.partId, () => []).add(q);
    }

    // Build sections
    final listeningParts = <_SectionData>[];
    final readingParts = <_SectionData>[];

    int globalIdx = 0;
    for (final partId in partGroups.keys) {
      final partQuestions = partGroups[partId]!;
      int correct = 0;
      for (final q in partQuestions) {
        final selectedIdx = userAnswers[globalIdx];
        if (selectedIdx != null &&
            selectedIdx < q.options.length &&
            q.options[selectedIdx].isCorrect) {
          correct++;
        }
        globalIdx++;
      }

      // Determine part number from order (simplified)
      final partNum = listeningParts.length + readingParts.length + 1;
      final isListening = partNum <= 4;
      final info = partNum <= _partInfos.length
          ? _partInfos[partNum - 1]
          : _PartInfo('Part $partNum', partNum,
              isListening ? 'listening' : 'reading');

      final section = _SectionData(
        name: info.name,
        correct: correct,
        total: partQuestions.length,
      );

      if (info.section == 'listening') {
        listeningParts.add(section);
      } else {
        readingParts.add(section);
      }
    }

    final totalListeningCorrect =
        listeningParts.fold(0, (s, p) => s + p.correct);
    final totalListeningQuestions =
        listeningParts.fold(0, (s, p) => s + p.total);
    final totalReadingCorrect =
        readingParts.fold(0, (s, p) => s + p.correct);
    final totalReadingQuestions =
        readingParts.fold(0, (s, p) => s + p.total);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSectionCard(
            context,
            title: 'Nghe Hiểu',
            correct: totalListeningCorrect,
            total: totalListeningQuestions,
            parts: listeningParts,
            questions: questions,
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            context,
            title: 'Đọc Hiểu',
            correct: totalReadingCorrect,
            total: totalReadingQuestions,
            parts: readingParts,
            questions: questions,
          ),
          const SizedBox(height: 16),
          Text(
            'Kết quả được cập nhật lúc ${TimeOfDay.now().format(context)}',
            style: GoogleFonts.lexend(
              fontSize: 12,
              color: AppColors.textSlate400,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required int correct,
    required int total,
    required List<_SectionData> parts,
    required List<QuestionModel> questions,
  }) {
    final pct = total > 0 ? (correct / total * 100).round() : 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSlate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.borderSlate100),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$pct%',
                      style: GoogleFonts.lexend(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSlate500,
                      ),
                    ),
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
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSlate900,
                        ),
                      ),
                      Text(
                        '$correct/$total câu đúng',
                        style: GoogleFonts.lexend(
                          fontSize: 13,
                          color: AppColors.textSlate500,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      context.push('/exam/answer-review', extra: {
                        'testId': testId,
                        'testTitle': testTitle,
                        'userAnswers': userAnswers,
                        'section': title == 'Nghe Hiểu'
                            ? 'listening'
                            : 'reading',
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: Text(
                        'Chi tiết',
                        style: GoogleFonts.lexend(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.orange500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Parts
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: parts.asMap().entries.map((entry) {
                final part = entry.value;
                final partPct =
                    part.total > 0 ? part.correct / part.total : 0.0;
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: entry.key < parts.length - 1 ? 16 : 0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              part.name,
                              style: GoogleFonts.lexend(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSlate800,
                              ),
                            ),
                          ),
                          Text(
                            '${(partPct * 100).round()}% (${part.correct}/${part.total})',
                            style: GoogleFonts.lexend(
                              fontSize: 12,
                              color: AppColors.textSlate400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: partPct.clamp(0.02, 1.0),
                          minHeight: 8,
                          backgroundColor: AppColors.slate100,
                          valueColor: const AlwaysStoppedAnimation(
                              AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionData {
  final String name;
  final int correct;
  final int total;
  const _SectionData({
    required this.name,
    required this.correct,
    required this.total,
  });
}
