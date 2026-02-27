import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lexii/core/constants/app_constants.dart';
import 'package:lexii/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:lexii/features/auth/presentation/pages/sign_up_page.dart';
import 'package:lexii/features/home/presentation/pages/dashboard_page.dart';
import 'package:lexii/features/practice/presentation/pages/practice_detail_page.dart';
import 'package:lexii/features/practice/domain/entities/skill_configs.dart';
import 'package:lexii/features/exam/presentation/pages/mock_test_page.dart';
import 'package:lexii/features/exam/presentation/pages/test_start_page.dart';
import 'package:lexii/features/exam/presentation/pages/part_intro_page.dart';
import 'package:lexii/features/exam/presentation/pages/listening_question_page.dart';

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
        // Practice skill routes
        GoRoute(
          path: '/practice/listening',
          name: 'listening',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: PracticeDetailPage(config: SkillConfigs.listening),
            transitionsBuilder: _slideUpTransition,
          ),
        ),
        GoRoute(
          path: '/practice/reading',
          name: 'reading',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: PracticeDetailPage(config: SkillConfigs.reading),
            transitionsBuilder: _slideUpTransition,
          ),
        ),
        GoRoute(
          path: '/practice/speaking',
          name: 'speaking',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: PracticeDetailPage(config: SkillConfigs.speaking),
            transitionsBuilder: _slideUpTransition,
          ),
        ),
        GoRoute(
          path: '/practice/writing',
          name: 'writing',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: PracticeDetailPage(config: SkillConfigs.writing),
            transitionsBuilder: _slideUpTransition,
          ),
        ),
        GoRoute(
          path: '/exam/mock-test',
          name: 'mockTest',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const MockTestPage(),
            transitionsBuilder: _slideUpTransition,
          ),
        ),
        // Test flow routes
        GoRoute(
          path: '/exam/test-start',
          name: 'testStart',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return CustomTransitionPage(
              key: state.pageKey,
              child: TestStartPage(
                testId: extra['testId'] as String? ?? '',
                testTitle: extra['testTitle'] as String? ?? 'Test',
                duration: extra['duration'] as int? ?? 120,
                totalQuestions: extra['totalQuestions'] as int? ?? 200,
              ),
              transitionsBuilder: _slideRightTransition,
            );
          },
        ),
        GoRoute(
          path: '/exam/part-intro',
          name: 'partIntro',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return CustomTransitionPage(
              key: state.pageKey,
              child: PartIntroPage(
                testId: extra['testId'] as String? ?? '',
                testTitle: extra['testTitle'] as String? ?? 'Test',
              ),
              transitionsBuilder: _slideRightTransition,
            );
          },
        ),
        GoRoute(
          path: '/exam/question',
          name: 'examQuestion',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return CustomTransitionPage(
              key: state.pageKey,
              child: ListeningQuestionPage(
                testId: extra['testId'] as String? ?? '',
                testTitle: extra['testTitle'] as String? ?? 'Test',
              ),
              transitionsBuilder: _slideRightTransition,
            );
          },
        ),
      ],
    );
  }

  static Widget _slideUpTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(0.0, 1.0);
    const end = Offset.zero;
    final tween = Tween(begin: begin, end: end)
        .chain(CurveTween(curve: Curves.easeOutCubic));
    return SlideTransition(
      position: animation.drive(tween),
      child: child,
    );
  }

  static Widget _slideRightTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(1.0, 0.0);
    const end = Offset.zero;
    final tween = Tween(begin: begin, end: end)
        .chain(CurveTween(curve: Curves.easeOutCubic));
    return SlideTransition(
      position: animation.drive(tween),
      child: child,
    );
  }
}
