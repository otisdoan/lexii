import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';

class OnboardingFinalPage extends StatelessWidget {
  const OnboardingFinalPage({
    super.key,
    required this.onSignUp,
    required this.onSkip,
  });

  final VoidCallback onSignUp;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Spacer header
            const SizedBox(height: 48),

            // Illustration section
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _IllustrationSection(),
                ),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Đăng nhập để luyện thi hiệu quả hơn',
                textAlign: TextAlign.center,
                style: GoogleFonts.lexend(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Tham gia thi thử với đề thi sát 95% đề thi thật',
                textAlign: TextAlign.center,
                style: GoogleFonts.lexend(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSlate500,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDot(false),
                const SizedBox(width: 8),
                _buildActiveDot(),
                const SizedBox(width: 8),
                _buildDot(false),
              ],
            ),
            const SizedBox(height: 32),

            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Đăng ký / Đăng nhập button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onSignUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 6,
                        shadowColor: AppColors.primary.withValues(alpha: 0.3),
                      ),
                      child: Text(
                        'Đăng ký / Đăng nhập',
                        style: GoogleFonts.lexend(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bỏ qua button
                  TextButton(
                    onPressed: onSkip,
                    child: Text(
                      'Bỏ qua',
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSlate400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(bool active) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.primary : AppColors.textSlate300,
      ),
    );
  }

  Widget _buildActiveDot() {
    return Container(
      width: 24,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9999),
        color: AppColors.primary,
      ),
    );
  }
}

class _IllustrationSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background blob
          Container(
            width: 256,
            height: 256,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.teal50,
            ),
          ),
          // Main illustration placeholder
          Container(
            width: 256,
            height: 256,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.teal50.withValues(alpha: 0.5),
            ),
            child: Center(
              child: Icon(
                Icons.person_add_rounded,
                size: 80,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
            ),
          ),
          // Decorative eco icon
          Positioned(
            top: 20,
            right: 40,
            child: _BounceIcon(
              icon: Icons.eco_rounded,
              color: AppColors.teal200,
              size: 32,
            ),
          ),
          // Decorative lightbulb
          Positioned(
            bottom: 20,
            left: 40,
            child: Icon(
              Icons.lightbulb_rounded,
              size: 28,
              color: AppColors.teal200,
            ),
          ),
          // Small circle decoration
          Positioned(
            top: 120,
            left: 20,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.teal100,
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            right: 30,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.teal50,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BounceIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _BounceIcon({
    required this.icon,
    required this.color,
    required this.size,
  });

  @override
  State<_BounceIcon> createState() => _BounceIconState();
}

class _BounceIconState extends State<_BounceIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: -8).animate(
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
      child: Icon(widget.icon, size: widget.size, color: widget.color),
    );
  }
}
