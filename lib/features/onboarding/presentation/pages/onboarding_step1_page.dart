import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/core/constants/app_constants.dart';

class OnboardingStep1Page extends StatelessWidget {
  const OnboardingStep1Page({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Illustration area
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background blur blob
                  Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryLight.withValues(alpha: 0.5),
                    ),
                  ),
                  // Circle illustration
                  Container(
                    width: 256,
                    height: 256,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryLight,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.school_rounded,
                        size: 100,
                        color: AppColors.primary.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Bắt đầu hành trình chinh phục chứng chỉ IELTS nào!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lexend(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSlate900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Giờ thì hãy cùng tìm hiểu các Lexii giúp bạn tăng tối đa điểm IELTS nhé',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textDark,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        elevation: 4,
                        shadowColor: AppColors.primary.withValues(alpha: 0.3),
                      ),
                      child: Text(
                        'Bắt đầu nào',
                        style: GoogleFonts.lexend(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Trademark
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      AppConstants.trademarkDisclaimer,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textSlate400,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
