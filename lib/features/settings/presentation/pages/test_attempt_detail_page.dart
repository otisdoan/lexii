import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/exam/data/models/attempt_history_model.dart';
import 'package:lexii/features/exam/presentation/providers/test_providers.dart';

class TestAttemptDetailPage extends ConsumerWidget {
  final String attemptId;

  const TestAttemptDetailPage({
    super.key,
    required this.attemptId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(attemptDetailProvider(attemptId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Không tải được chi tiết bài làm.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                fontSize: 14,
                color: AppColors.textSlate500,
              ),
            ),
          ),
        ),
        data: (detail) {
          if (detail == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Không tìm thấy bài làm này.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    color: AppColors.textSlate500,
                  ),
                ),
              ),
            );
          }

          return Column(
            children: [
              _Header(detail: detail),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: detail.questionDetails.length,
                  itemBuilder: (context, index) {
                    return _QuestionCard(
                      index: index,
                      detail: detail.questionDetails[index],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AttemptDetailModel detail;

  const _Header({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            children: [
              Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.pop(),
                      borderRadius: BorderRadius.circular(9999),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Chi tiết bài làm',
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
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.testTitle,
                      style: GoogleFonts.lexend(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(detail.submittedAt),
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _HeaderPill(label: 'Điểm', value: '${detail.score}'),
                        const SizedBox(width: 8),
                        _HeaderPill(label: 'Đúng', value: '${detail.correctCount}'),
                        const SizedBox(width: 8),
                        _HeaderPill(label: 'Đã làm', value: '${detail.answeredCount}/${detail.questionDetails.length}'),
                      ],
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

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year • $hour:$minute';
  }
}

class _HeaderPill extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.lexend(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final AttemptQuestionDetailModel detail;

  const _QuestionCard({
    required this.index,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final question = detail.question;
    final status = _statusMeta(detail);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Câu ${index + 1} • Part ${detail.partNumber}',
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSlate600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status.background,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status.label,
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: status.color,
                  ),
                ),
              ),
            ],
          ),
          if (question.passageContent != null &&
              question.passageContent!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                question.passageContent!,
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  color: AppColors.textSlate600,
                ),
              ),
            ),
          ],
          if (question.imageUrl != null && question.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                question.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
          if ((question.questionText ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              question.questionText!,
              style: GoogleFonts.lexend(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSlate900,
              ),
            ),
          ],
          const SizedBox(height: 10),
          ...question.options.asMap().entries.map((entry) {
            final optionIndex = entry.key;
            final option = entry.value;
            final optionLetter = String.fromCharCode(65 + optionIndex);
            final isSelected = detail.selectedOptionId == option.id;
            final isCorrectOption = option.isCorrect;

            Color borderColor = AppColors.borderSlate200;
            Color bgColor = Colors.white;
            Color textColor = AppColors.slate700;

            if (isCorrectOption) {
              borderColor = AppColors.green600;
              bgColor = AppColors.green100.withValues(alpha: 0.35);
            }

            if (isSelected && !isCorrectOption) {
              borderColor = AppColors.red500;
              bgColor = AppColors.red100.withValues(alpha: 0.45);
            }

            if (isSelected && isCorrectOption) {
              borderColor = AppColors.green600;
              bgColor = AppColors.green100.withValues(alpha: 0.6);
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$optionLetter.',
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      option.content,
                      style: GoogleFonts.lexend(
                        fontSize: 13,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    Icon(
                      isCorrectOption ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: isCorrectOption ? AppColors.green600 : AppColors.red500,
                    ),
                  ],
                ],
              ),
            );
          }),
          if (!detail.isAnswered)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Bạn chưa chọn đáp án cho câu này.',
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  color: AppColors.orange500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  _StatusMeta _statusMeta(AttemptQuestionDetailModel detail) {
    if (!detail.isAnswered) {
      return _StatusMeta(
        label: 'Chưa làm',
        color: AppColors.amber600,
        background: AppColors.amber100,
      );
    }
    if (detail.isCorrect) {
      return _StatusMeta(
        label: 'Đúng',
        color: AppColors.green600,
        background: AppColors.green100,
      );
    }
    return _StatusMeta(
      label: 'Sai',
      color: AppColors.red600,
      background: AppColors.red100,
    );
  }
}

class _StatusMeta {
  final String label;
  final Color color;
  final Color background;

  const _StatusMeta({
    required this.label,
    required this.color,
    required this.background,
  });
}
