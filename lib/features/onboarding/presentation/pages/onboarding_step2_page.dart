import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';

class OnboardingStep2Page extends StatelessWidget {
  const OnboardingStep2Page({
    super.key,
    required this.onAgree,
    required this.onLater,
  });

  final VoidCallback onAgree;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 48, 32, 0),
              child: Column(
                children: [
                  Text(
                    'Nhắc nhở hàng ngày',
                    style: GoogleFonts.lexend(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Hãy đăng ký nhận nhắc nhở mỗi ngày để duy trì tiến độ học tập nha?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lexend(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSlate500,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            // Phone Mockup Illustration
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: _PhoneMockup(),
                ),
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
              child: Column(
                children: [
                  // Primary - Đồng ý
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onAgree,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: AppColors.primary.withValues(alpha: 0.2),
                      ),
                      child: Text(
                        'Đồng ý',
                        style: GoogleFonts.lexend(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Secondary - Để sau
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onLater,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSlate500,
                        side: const BorderSide(
                          color: AppColors.borderSlate200,
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Để sau',
                        style: GoogleFonts.lexend(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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

class _PhoneMockup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      height: 420,
      decoration: BoxDecoration(
        color: AppColors.slate800,
        borderRadius: BorderRadius.circular(48),
        border: Border.all(color: AppColors.slate700, width: 6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(42),
        child: Stack(
          children: [
            // Screen content
            Container(
              color: AppColors.slate100,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Notification card with floating animation
                  _NotificationCard(),
                  const SizedBox(height: 32),
                  // Abstract UI lines
                  Opacity(
                    opacity: 0.2,
                    child: Column(
                      children: [
                        Container(
                          height: 16,
                          width: 180,
                          decoration: BoxDecoration(
                            color: AppColors.textSlate300,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.borderSlate200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.borderSlate200,
                                  borderRadius: BorderRadius.circular(12),
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
            // Gradient overlay inside phone
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.teal50.withValues(alpha: 0.5),
                      Colors.white.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
            ),
            // Notch
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 80,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.slate700,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatefulWidget {
  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSlate200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Mascot icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'L',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lexii',
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSlate600,
                        ),
                      ),
                      Text(
                        'Vừa xong',
                        style: GoogleFonts.lexend(
                          fontSize: 10,
                          color: AppColors.textSlate400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bạn ơi, đến giờ học rồi',
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate800,
                    ),
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
