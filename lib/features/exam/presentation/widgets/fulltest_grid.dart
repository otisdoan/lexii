import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/exam/data/models/test_model.dart';
import 'package:lexii/features/exam/presentation/providers/test_providers.dart';

class FulltestGrid extends ConsumerWidget {
  const FulltestGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fullTestsAsync = ref.watch(fullTestsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fulltest',
                style: GoogleFonts.lexend(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSlate900,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'Xem thêm',
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Content from database
          fullTestsAsync.when(
            loading: () => const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (error, stack) => _buildErrorState(error.toString()),
            data: (tests) {
              if (tests.isEmpty) {
                return _buildEmptyState();
              }
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
                  return _TestCard(test: test);
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
          Icon(
            Icons.quiz_outlined,
            size: 48,
            color: AppColors.textSlate400,
          ),
          const SizedBox(height: 12),
          Text(
            'Chưa có đề thi nào',
            style: GoogleFonts.lexend(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSlate500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Đề thi sẽ được cập nhật sớm',
            style: GoogleFonts.lexend(
              fontSize: 12,
              color: AppColors.textSlate400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(height: 12),
          Text(
            'Lỗi tải dữ liệu',
            style: GoogleFonts.lexend(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFDC2626),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.lexend(
              fontSize: 11,
              color: const Color(0xFFB91C1C),
            ),
          ),
        ],
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  final TestModel test;

  const _TestCard({required this.test});

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
          onTap: () => context.push('/exam/test-start', extra: {
            'testId': test.id,
            'testTitle': test.title,
            'duration': test.duration,
            'totalQuestions': test.totalQuestions,
          }),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                // Lock icon for premium
                if (test.isPremium)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Icon(
                      Icons.lock,
                      size: 20,
                      color: AppColors.amber600,
                    ),
                  ),
                // Content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.description,
                          size: 28,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Title
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
                    // Info
                    Text(
                      '${test.duration} min • ${test.totalQuestions} questions',
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
                          'Start',
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
