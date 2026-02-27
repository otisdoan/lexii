import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/practice/domain/entities/practice_part.dart';

class PartListItem extends StatelessWidget {
  final PracticePart part;
  final VoidCallback? onTap;

  const PartListItem({super.key, required this.part, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (part.isLocked) {
      return _buildLockedCard();
    }
    return _buildUnlockedCard();
  }

  Widget _buildUnlockedCard() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSlate100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: part.iconBgColor,
                ),
                child: Center(
                  child: Icon(part.icon, size: 28, color: part.iconColor),
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      part.title,
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSlate800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Câu trả lời đúng: ${part.correctAnswers}/${part.totalQuestions}',
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            color: AppColors.textSlate500,
                          ),
                        ),
                        Text(
                          '${part.progressPercent.toInt()}%',
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(9999),
                      child: LinearProgressIndicator(
                        value: part.progressPercent / 100,
                        minHeight: 6,
                        backgroundColor: AppColors.slate100,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
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
  }

  Widget _buildLockedCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSlate100),
      ),
      child: Opacity(
        opacity: 0.75,
        child: Stack(
          children: [
            // Lock icon
            const Positioned(
              right: 0,
              top: 0,
              child: Icon(Icons.lock, color: AppColors.textSlate400, size: 20),
            ),
            Row(
              children: [
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.borderSlate200,
                  ),
                  child: Center(
                    child: Icon(
                      part.icon,
                      size: 28,
                      color: AppColors.textSlate500,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          part.title,
                          style: GoogleFonts.lexend(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSlate600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              part.totalQuestions > 0
                                  ? 'Câu trả lời đúng: ${part.correctAnswers}/${part.totalQuestions}'
                                  : 'Số câu hỏi: ${part.totalQuestions}',
                              style: GoogleFonts.lexend(
                                fontSize: 12,
                                color: AppColors.textSlate400,
                              ),
                            ),
                            Text(
                              '0%',
                              style: GoogleFonts.lexend(
                                fontSize: 12,
                                color: AppColors.textSlate400,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(9999),
                          child: const LinearProgressIndicator(
                            value: 0,
                            minHeight: 6,
                            backgroundColor: AppColors.borderSlate200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textSlate300,
                            ),
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
      ),
    );
  }
}
