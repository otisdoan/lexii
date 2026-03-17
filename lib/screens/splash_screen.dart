import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lexii/core/constants/app_constants.dart';

/// Professional full-screen splash screen with fade-in animation and automatic navigation
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _precacheImageAndNavigate();
    });
  }

  /// Initialize fade-in animation (1000ms duration)
  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  /// Precache image to avoid flicker and navigate after 2 seconds
  void _precacheImageAndNavigate() {
    // Precache the background image to prevent flickering
    precacheImage(
      const AssetImage('assets/images/anh-cho.jpg'),
      context,
    ).then((_) {
      // Navigate after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _navigateToNextScreen();
        }
      });
    }).catchError((e) {
      debugPrint('Error precaching image: $e');
      // Still navigate even if image fails to precache
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _navigateToNextScreen();
        }
      });
    });
  }

  /// Navigate to the appropriate screen based on onboarding status
  Future<void> _navigateToNextScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted =
        prefs.getBool(AppConstants.onboardingCompletedKey) ?? false;

    if (mounted) {
      // Use GoRouter for navigation instead of Navigator
      context.go(onboardingCompleted ? '/home' : '/onboarding');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: Stack(
          children: [
            // Full-bleed background image with BoxFit.cover
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/anh-cho.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Loading indicator at the bottom
            Positioned(
              bottom: 60.0,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        strokeWidth: 2.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
