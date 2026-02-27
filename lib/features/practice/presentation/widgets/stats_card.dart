import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';

class StatsCard extends StatelessWidget {
  final IconData icon;
  final int totalAnswered;
  final int correctAnswers;
  final double progressPercent;

  const StatsCard({
    super.key,
    required this.icon,
    this.totalAnswered = 0,
    this.correctAnswers = 0,
    this.progressPercent = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSlate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon area
            Container(
              width: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(icon, size: 40, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 16),
            // Stats area
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title
                  Text(
                    'Tiến độ chung',
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSlate800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Stats row
                  Row(
                    children: [
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            color: AppColors.textSlate500,
                          ),
                          children: [
                            const TextSpan(text: 'Số câu đã làm: '),
                            TextSpan(
                              text: '$totalAnswered',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSlate800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '•',
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            color: AppColors.textSlate500,
                          ),
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            color: AppColors.textSlate500,
                          ),
                          children: [
                            const TextSpan(text: 'Trả lời đúng: '),
                            TextSpan(
                              text: '$correctAnswers',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress bar
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Hoàn thành',
                            style: GoogleFonts.lexend(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSlate500,
                            ),
                          ),
                          Text(
                            '${progressPercent.toInt()}%',
                            style: GoogleFonts.lexend(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(9999),
                        child: LinearProgressIndicator(
                          value: progressPercent / 100,
                          minHeight: 8,
                          backgroundColor: AppColors.slate100,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
