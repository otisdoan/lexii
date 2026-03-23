import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lexii/screens/splash_screen.dart';
import 'package:lexii/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:lexii/features/auth/presentation/pages/sign_up_page.dart';
import 'package:lexii/features/home/presentation/pages/dashboard_page.dart';
import 'package:lexii/features/home/presentation/pages/notifications_page.dart';
import 'package:lexii/features/practice/presentation/pages/practice_detail_page.dart';
import 'package:lexii/features/practice/presentation/pages/practice_part_intro_page.dart';
import 'package:lexii/features/practice/presentation/pages/practice_part_result_page.dart';
import 'package:lexii/features/practice/presentation/pages/reading_question_page.dart';
import 'package:lexii/features/practice/presentation/pages/writing_question_page.dart';
import 'package:lexii/features/practice/presentation/pages/writing_result_page.dart';
import 'package:lexii/features/practice/presentation/pages/speaking_question_page.dart';
import 'package:lexii/features/practice/data/repositories/practice_repository.dart';
import 'package:lexii/features/practice/data/models/writing_prompt_model.dart';
import 'package:lexii/features/exam/presentation/pages/mock_test_page.dart';
import 'package:lexii/features/exam/presentation/pages/test_start_page.dart';
import 'package:lexii/features/exam/presentation/pages/part_intro_page.dart';
import 'package:lexii/features/exam/presentation/pages/listening_question_page.dart';
import 'package:lexii/features/exam/data/models/question_model.dart';
import 'package:lexii/features/exam/presentation/pages/score_certificate_page.dart';
import 'package:lexii/features/exam/presentation/pages/result_page.dart';
import 'package:lexii/features/exam/presentation/pages/answer_review_page.dart';
import 'package:lexii/features/exam/presentation/pages/answer_detail_page.dart';
import 'package:lexii/features/settings/presentation/pages/settings_page.dart';
import 'package:lexii/features/settings/presentation/pages/support_page.dart';
import 'package:lexii/features/settings/presentation/pages/test_attempt_detail_page.dart';
import 'package:lexii/features/settings/presentation/pages/test_history_page.dart';
import 'package:lexii/features/settings/presentation/pages/transactions_page.dart';
import 'package:lexii/features/settings/presentation/pages/reviews_page.dart';
import 'package:lexii/features/settings/presentation/pages/upgrade_page.dart';
import 'package:lexii/features/settings/presentation/pages/payment_result_page.dart';
import 'package:lexii/features/settings/presentation/pages/study_reminder_page.dart';
import 'package:lexii/features/theory/presentation/pages/theory_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppRouter {
  static late final GoRouter router;

  static Future<void> init() async {
    router = GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) {
        final uri = state.uri;
        if (uri.scheme != 'lexii') return null;

        final host = uri.host.toLowerCase();
        final path = uri.path.toLowerCase();

        final isAuthDeepLink =
            host == 'home' ||
            host == 'login-callback' ||
            path == '/home' ||
            path.endsWith('/login-callback');
        if (isAuthDeepLink) {
          final auth = Supabase.instance.client.auth;
          final isAuthenticated = auth.currentSession != null;
          return isAuthenticated ? '/home' : '/auth/signup';
        }

        final isPaymentDeepLink =
            host == 'payment-result' || path.endsWith('/payment-result');
        if (isPaymentDeepLink) {
          final statusRaw =
              (uri.queryParameters['status'] ??
                      uri.queryParameters['code'] ??
                      '')
                  .toLowerCase();
          final status = switch (statusRaw) {
            'success' || 'paid' || '00' || '0' => 'success',
            'cancel' || 'cancelled' || 'canceled' => 'cancel',
            'pending' || 'processing' => 'pending',
            _ => 'failed',
          };
          final orderCode =
              uri.queryParameters['orderCode'] ??
              uri.queryParameters['order_code'];
          return orderCode == null || orderCode.isEmpty
              ? '/payment/result?status=$status'
              : '/payment/result?status=$status&orderCode=$orderCode';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          name: 'splash',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const SplashScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        ),
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
                  final tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: Curves.easeInOut));
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
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const DashboardPage(),
          ),
        ),
        GoRoute(
          path: '/home/notifications',
          name: 'homeNotifications',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const NotificationsPage(),
            transitionsBuilder: _slideRightTransition,
          ),
        ),
        // Practice part intro
        GoRoute(
          path: '/practice/part-intro',
          name: 'practicePartIntro',
          pageBuilder: (context, state) {
            final partData = state.extra as PracticePartData;
            return CustomTransitionPage(
              key: state.pageKey,
              child: PracticePartIntroPage(partData: partData),
              transitionsBuilder: _slideRightTransition,
            );
          },
        ),
        // Practice part result
        GoRoute(
          path: '/practice/part-result',
          name: 'practicePartResult',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return CustomTransitionPage(
              key: state.pageKey,
              child: PracticePartResultPage(
                testId: extra['testId'] as String? ?? '',
                partId: extra['partId'] as String? ?? '',
                partTitle: extra['partTitle'] as String? ?? '',
                section: extra['section'] as String? ?? 'listening',
                correct: extra['correct'] as int? ?? 0,
                total: extra['total'] as int? ?? 0,
                userAnswers: (extra['userAnswers'] as Map<int, int>?) ?? {},
                questionsOverride: (extra['questions'] as List?)
                    ?.cast<QuestionModel>(),
              ),
              transitionsBuilder: _slideRightTransition,
            );
          },
        ),
        // Practice skill routes
        GoRoute(
          path: '/practice/reading-question',
          name: 'readingQuestion',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return CustomTransitionPage(
              key: state.pageKey,
              child: ReadingQuestionPage(
                testId: extra['testId'] as String? ?? '',
                partId: extra['partId'] as String? ?? '',
                partNumber: extra['partNumber'] as int?,
                partTitle: extra['partTitle'] as String? ?? '',
                questionLimit: extra['questionLimit'] as int?,
                questionIds: (extra['questionIds'] as List?)?.cast<String>(),
                randomizeQuestions:
                    extra['randomizeQuestions'] as bool? ?? false,
              ),
              transitionsBuilder: _slideRightTransition,
            );
          },
        ),
        GoRoute(
          path: '/practice/writing-question',
          name: 'writingQuestion',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return CustomTransitionPage(
              key: state.pageKey,
              child: WritingQuestionPage(
                partNumber: extra['partNumber'] as int? ?? 1,
                partTitle: extra['partTitle'] as String? ?? '',
                questionLimit: extra['questionLimit'] as int?,
              ),
              transitionsBuilder: _slideRightTransition,
            );
          },
        ),
        GoRoute(
          path: '/practice/speaking-question',
          name: 'speakingQuestion',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final taskType = extra['taskType'] as String?;
            int partNumber = extra['partNumber'] as int? ?? 1;
            if (extra['partNumber'] == null && taskType != null) {
              switch (taskType) {
                case 'read_aloud':
                  partNumber = 1;
                case 'describe_picture':
                  partNumber = 2;
                case 'respond_questions':
                  partNumber = 3;
                case 'respond_information':
                  partNumber = 4;
                case 'express_opinion':
                  partNumber = 5;
                default:
                  partNumber = 1;
              }
            }
            return CustomTransitionPage(
              key: state.pageKey,
              child: SpeakingQuestionPage(
                partNumber: partNumber,
                partTitle: extra['partTitle'] as String? ?? '',
                questionLimit: extra['questionLimit'] as int?,
              ),
              transitionsBuilder: _slideRightTransition,
            );
          },
        ),
        GoRoute(
          path: '/practice/writing-result',
          name: 'writingResult',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return CustomTransitionPage(
              key: state.pageKey,
              child: WritingResultPage(
                partTitle: extra['partTitle'] as String? ?? '',
                prompts:
                    (extra['prompts'] as List?)?.cast<WritingPromptModel>() ??
                    [],
                userAnswers:
                    (extra['userAnswers'] as Map?)?.cast<String, String>() ??
                    {},
              ),
              transitionsBuilder: _slideRightTransition,
            );
          },
        ),
        // Practice skill routes
        GoRoute(
          path: '/practice/listening',
          name: 'listening',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const PracticeDetailPage(skill: 'listening'),
            transitionsBuilder: _slideUpTransition,
          ),
        ),
        GoRoute(
          path: '/practice/reading',
          name: 'reading',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const PracticeDetailPage(skill: 'reading'),
            transitionsBuilder: _slideUpTransition,
          ),
        ),
        GoRoute(
          path: '/practice/speaking',
          name: 'speaking',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const PracticeDetailPage(skill: 'speaking'),
            transitionsBuilder: _slideUpTransition,
          ),
        ),
        GoRoute(
          path: '/practice/writing',
          name: 'writing',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const PracticeDetailPage(skill: 'writing'),
            transitionsBuilder: _slideUpTransition,
          ),
        ),
        // Theory
        GoRoute(
          path: '/theory',
          name: 'theory',
          pageBuilder: (context, state) =>
              NoTransitionPage(key: state.pageKey, child: const TheoryPage()),
        ),
        GoRoute(
          path: '/theory/vocabulary',
          name: 'theoryVocabulary',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const TheoryVocabularyPage(),
          ),
        ),
        GoRoute(
          path: '/theory/grammar',
          name: 'theoryGrammar',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const TheoryGrammarPage(),
          ),
        ),
        // Settings & Upgrade
        GoRoute(
          path: '/settings',
          name: 'settings',
          pageBuilder: (context, state) =>
              NoTransitionPage(key: state.pageKey, child: const SettingsPage()),
        ),
        GoRoute(
          path: '/settings/test-history',
          name: 'testHistory',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const TestHistoryPage(),
            transitionsBuilder: _slideRightTransition,
          ),
        ),
        GoRoute(
          path: '/settings/test-history/:attemptId',
          name: 'testAttemptDetail',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: TestAttemptDetailPage(
              attemptId: state.pathParameters['attemptId'] ?? '',
            ),
            transitionsBuilder: _slideRightTransition,
          ),
        ),
        GoRoute(
          path: '/settings/transactions',
          name: 'transactions',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const TransactionsPage(),
            transitionsBuilder: _slideRightTransition,
          ),
        ),
        GoRoute(
          path: '/settings/support',
          name: 'support',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const SupportPage(),
            transitionsBuilder: _slideRightTransition,
          ),
        ),
        GoRoute(
          path: '/settings/study-reminder',
          name: 'studyReminder',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const StudyReminderPage(),
            transitionsBuilder: _slideRightTransition,
          ),
        ),
        GoRoute(
          path: '/settings/reviews',
          name: 'reviews',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const ReviewsPage(),
            transitionsBuilder: _slideRightTransition,
          ),
        ),
        GoRoute(
          path: '/upgrade',
          name: 'upgrade',
          pageBuilder: (context, state) =>
              NoTransitionPage(key: state.pageKey, child: const UpgradePage()),
        ),
        GoRoute(
          path: '/payment/result',
          name: 'paymentResult',
          pageBuilder: (context, state) {
            final status = (state.uri.queryParameters['status'] ?? 'failed')
                .toLowerCase();
            final orderCode = state.uri.queryParameters['orderCode'];
            return CustomTransitionPage(
              key: state.pageKey,
              child: PaymentResultPage(status: status, orderCode: orderCode),
              transitionsBuilder: _slideUpTransition,
            );
          },
        ),
        GoRoute(
          path: '/exam/mock-test',
          name: 'mockTest',
          pageBuilder: (context, state) =>
              NoTransitionPage(key: state.pageKey, child: const MockTestPage()),
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
                partNumber: extra['partNumber'] as int? ?? 1,
                isResume: extra['isResume'] as bool? ?? false,
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
                partId: extra['partId'] as String?,
                partNumber: extra['partNumber'] as int?,
                isPracticeMode: extra['isPracticeMode'] as bool? ?? false,
                questionLimit: extra['questionLimit'] as int?,
                questionIds: (extra['questionIds'] as List?)?.cast<String>(),
                randomizeQuestions:
                    extra['randomizeQuestions'] as bool? ?? false,
              ),
              transitionsBuilder: _slideRightTransition,
            );
          },
        ),
        // Score certificate
        GoRoute(
          path: '/exam/score',
          name: 'examScore',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return CustomTransitionPage(
              key: state.pageKey,
              child: ScoreCertificatePage(
                testId: extra['testId'] as String? ?? '',
                testTitle: extra['testTitle'] as String? ?? 'Test',
                listeningScore: (extra['listeningScore'] as num?)?.toInt() ?? 5,
                readingScore: (extra['readingScore'] as num?)?.toInt() ?? 5,
                totalCorrect: (extra['totalCorrect'] as num?)?.toInt() ?? 0,
                totalQuestions:
                    (extra['totalQuestions'] as num?)?.toInt() ?? 200,
                userAnswers: (extra['userAnswers'] as Map<int, int>?) ?? {},
              ),
              transitionsBuilder: _slideRightTransition,
            );
          },
        ),
        // Result breakdown
        GoRoute(
          path: '/exam/result',
          name: 'examResult',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return CustomTransitionPage(
              key: state.pageKey,
              child: ResultPage(
                testId: extra['testId'] as String? ?? '',
                testTitle: extra['testTitle'] as String? ?? 'Test',
                userAnswers: (extra['userAnswers'] as Map<int, int>?) ?? {},
              ),
              transitionsBuilder: _slideRightTransition,
            );
          },
        ),
        // Answer review
        GoRoute(
          path: '/exam/answer-review',
          name: 'answerReview',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return CustomTransitionPage(
              key: state.pageKey,
              child: AnswerReviewPage(
                testId: extra['testId'] as String? ?? '',
                testTitle: extra['testTitle'] as String? ?? 'Test',
                userAnswers: (extra['userAnswers'] as Map<int, int>?) ?? {},
                section: extra['section'] as String? ?? 'listening',
                partId: extra['partId'] as String?,
                questionIds: (extra['questionIds'] as List?)?.cast<String>(),
              ),
              transitionsBuilder: _slideRightTransition,
            );
          },
        ),
        // Answer detail
        GoRoute(
          path: '/exam/answer-detail',
          name: 'answerDetail',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return CustomTransitionPage(
              key: state.pageKey,
              child: AnswerDetailPage(
                testId: extra['testId'] as String? ?? '',
                testTitle: extra['testTitle'] as String? ?? 'Test',
                questionIndex: extra['questionIndex'] as int? ?? 0,
                userAnswers: (extra['userAnswers'] as Map<int, int>?) ?? {},
                partId: extra['partId'] as String?,
                questionIds: (extra['questionIds'] as List?)?.cast<String>(),
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
    final tween = Tween(
      begin: begin,
      end: end,
    ).chain(CurveTween(curve: Curves.easeOutCubic));
    return SlideTransition(position: animation.drive(tween), child: child);
  }

  static Widget _slideRightTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(1.0, 0.0);
    const end = Offset.zero;
    final tween = Tween(
      begin: begin,
      end: end,
    ).chain(CurveTween(curve: Curves.easeOutCubic));
    return SlideTransition(position: animation.drive(tween), child: child);
  }
}
