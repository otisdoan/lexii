import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/subscription/subscription_providers.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/exam/data/models/test_model.dart';
import 'package:lexii/features/exam/presentation/providers/test_providers.dart';

const int _kFreeUnlockedExamCount = 3;

class MinitestGrid extends ConsumerWidget {
  final List<TestModel>? testsOverride;

  const MinitestGrid({super.key, this.testsOverride});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final miniTestsAsync = testsOverride == null
        ? ref.watch(miniTestsProvider)
        : AsyncValue.data(testsOverride!);
    final isPremiumAsync = ref.watch(isPremiumProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Section header
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Mini Test',
                style: GoogleFonts.lexend(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSlate900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          miniTestsAsync.when(
            loading: () => const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (error, stack) => _buildEmptyState(),
            data: (tests) {
              if (tests.isEmpty) {
                return _buildEmptyState();
              }
              final isPremiumUser = isPremiumAsync.valueOrNull ?? false;
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.72,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tests.length,
                itemBuilder: (context, index) {
                  final test = tests[index];
                  final lockedByFreeLimit =
                      !isPremiumUser && index >= _kFreeUnlockedExamCount;
                  final lockedByPremiumTag = !isPremiumUser && test.isPremium;
                  return _MiniTestCard(
                    test: test,
                    isLocked: lockedByFreeLimit || lockedByPremiumTag,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSlate100),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_outlined, size: 48, color: AppColors.textSlate400),
          const SizedBox(height: 12),
          Text(
            'Chưa có minitest nào',
            style: GoogleFonts.lexend(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSlate500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Minitest sẽ được cập nhật sớm',
            style: GoogleFonts.lexend(
              fontSize: 12,
              color: AppColors.textSlate400,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTestCard extends StatelessWidget {
  final TestModel test;
  final bool isLocked;

  const _MiniTestCard({required this.test, required this.isLocked});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            if (isLocked) {
              context.push('/upgrade');
              return;
            }
            context.push(
              '/exam/test-start',
              extra: {
                'testId': test.id,
                'testTitle': test.title,
                'duration': test.duration,
                'totalQuestions': test.totalQuestions,
              },
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                if (isLocked)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Icon(
                      Icons.lock,
                      size: 20,
                      color: AppColors.amber600,
                    ),
                  ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.teal100,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.timer,
                          size: 28,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      test.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSlate900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${test.duration} phút • ${test.totalQuestions} câu',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: AppColors.textSlate500,
                      ),
                    ),
                    const Spacer(),
                    // Start button
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.slate100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Bắt đầu',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSlate600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
