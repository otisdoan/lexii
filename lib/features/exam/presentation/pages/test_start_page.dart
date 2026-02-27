import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';

class TestStartPage extends StatelessWidget {
  final String testId;
  final String testTitle;
  final int duration;
  final int totalQuestions;

  const TestStartPage({
    super.key,
    required this.testId,
    required this.testTitle,
    this.duration = 120,
    this.totalQuestions = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // Wave background
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.25,
            child: CustomPaint(
              painter: _WavePainter(),
              size: Size.infinite,
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                              color: AppColors.textSlate800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Main content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        // Title
                        Text(
                          testTitle,
                          style: GoogleFonts.lexend(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSlate800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Subtitle
                        Text(
                          'Thời gian: $duration phút • Câu hỏi: $totalQuestions',
                          style: GoogleFonts.lexend(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSlate600,
                          ),
                        ),
                        // Illustration
                        Expanded(
                          child: Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Background circle
                                Container(
                                  width: 220,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                  ),
                                ),
                                // Icon placeholder for mascot
                                Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                  ),
                                  child: const Icon(
                                    Icons.school,
                                    size: 80,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Info cards
                        Row(
                          children: [
                            Expanded(
                              child: _InfoCard(
                                icon: Icons.menu_book,
                                label: 'Dạng đề',
                                value: 'TOEIC Full',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _InfoCard(
                                icon: Icons.trending_up,
                                label: 'Độ khó',
                                value: 'Trung bình',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                // Bottom action
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            context.push('/exam/part-intro', extra: {
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
                      const SizedBox(height: 12),
                      Text(
                        'Hãy đảm bảo kết nối internet ổn định',
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          color: AppColors.textSlate400,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
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

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: 12,
              color: AppColors.textSlate500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.lexend(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSlate800,
            ),
          ),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.6);
    path1.quadraticBezierTo(
      size.width * 0.25, size.height * 0.3,
      size.width * 0.5, size.height * 0.5,
    );
    path1.quadraticBezierTo(
      size.width * 0.75, size.height * 0.7,
      size.width, size.height * 0.4,
    );
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint1);

    final paint2 = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, size.height * 0.8);
    path2.quadraticBezierTo(
      size.width * 0.4, size.height * 0.5,
      size.width * 0.7, size.height * 0.7,
    );
    path2.quadraticBezierTo(
      size.width * 0.9, size.height * 0.8,
      size.width, size.height * 0.6,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
