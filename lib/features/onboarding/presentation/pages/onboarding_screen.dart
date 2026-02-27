import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lexii/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:lexii/features/onboarding/presentation/pages/onboarding_step1_page.dart';
import 'package:lexii/features/onboarding/presentation/pages/onboarding_step2_page.dart';
import 'package:lexii/features/onboarding/presentation/pages/onboarding_final_page.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNext() {
    final currentPage = ref.read(onboardingControllerProvider).currentPage;
    if (currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      ref.read(onboardingControllerProvider.notifier).nextPage();
    }
  }

  Future<void> _onSignUp() async {
    await ref.read(onboardingControllerProvider.notifier).completeOnboarding();
    if (mounted) {
      context.push('/auth/signup');
    }
  }

  Future<void> _onSkip() async {
    await ref.read(onboardingControllerProvider.notifier).completeOnboarding();
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          OnboardingStep1Page(onNext: _goToNext),
          OnboardingStep2Page(
            onAgree: _goToNext,
            onLater: _goToNext,
          ),
          OnboardingFinalPage(
            onSignUp: _onSignUp,
            onSkip: _onSkip,
          ),
        ],
      ),
    );
  }
}
