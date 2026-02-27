import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lexii/core/constants/app_constants.dart';
import 'package:lexii/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:lexii/features/auth/presentation/pages/sign_up_page.dart';
import 'package:lexii/features/home/presentation/pages/dashboard_page.dart';

class AppRouter {
  static late final GoRouter router;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted =
        prefs.getBool(AppConstants.onboardingCompletedKey) ?? false;

    router = GoRouter(
      initialLocation: onboardingCompleted ? '/home' : '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const OnboardingScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/auth/signup',
          name: 'signup',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const SignUpPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              final tween = Tween(begin: begin, end: end)
                  .chain(CurveTween(curve: Curves.easeInOut));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          ),
        ),
        GoRoute(
          path: '/home',
          name: 'home',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const DashboardPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
      ],
    );
  }
}
