import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';

class NewExamBanner extends StatelessWidget {
  const NewExamBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.slate900,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.slate900,
                    AppColors.slate800,
                  ],
                ),
              ),
            ),
          ),
          // Glow effect
          Positioned(
            right: -40,
            bottom: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          'MỚI NHẤT',
                          style: GoogleFonts.lexend(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Chớp thời cơ\nmở đề thi mới',
                        style: GoogleFonts.lexend(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: InkWell(
                    onTap: () {},
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_forward,
                        color: AppColors.slate900,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
