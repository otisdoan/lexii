import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';

class PartIntroPage extends StatelessWidget {
  final String testId;
  final String testTitle;

  const PartIntroPage({
    super.key,
    required this.testId,
    required this.testTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Teal header
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                child: Row(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.pop(),
                        borderRadius: BorderRadius.circular(9999),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 40),
                        child: Text(
                          'TOEIC Listening Part 1',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lexend(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Main content
          Expanded(
            child: Stack(
              children: [
                // Scrollable content
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        'PART 1: PHOTOGRAPHS',
                        style: GoogleFonts.lexend(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSlate900,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Description
                      Text(
                        'For each question in this part, you will see a picture in your test book and you will hear four short statements. The statements will be spoken just one time. They will not be printed in your test book and will be spoken only one time. Select the best description of the picture.',
                        style: GoogleFonts.lexend(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSlate600,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Divider
                      Center(
                        child: Container(
                          width: 96,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.textSlate400.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Bottom CTA
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white,
                          Colors.white,
                        ],
                        stops: const [0.0, 0.3, 1.0],
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          context.push('/exam/question', extra: {
                            'testId': testId,
                            'testTitle': testTitle,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          elevation: 6,
                          shadowColor: AppColors.primary.withValues(alpha: 0.3),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Bắt đầu',
                              style: GoogleFonts.lexend(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
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
