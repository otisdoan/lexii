import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/subscription/subscription_providers.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/exam/data/models/test_model.dart';
import 'package:lexii/features/exam/presentation/providers/test_providers.dart';

const int _kMaxGridItems = 6;
const int _kFreeUnlockedExamCount = 3;

class FulltestGrid extends ConsumerWidget {
  const FulltestGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fullTestsAsync = ref.watch(fullTestsProvider);
    final isPremiumAsync = ref.watch(isPremiumProvider);

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
              fullTestsAsync.maybeWhen(
                data: (tests) => tests.length > _kMaxGridItems
                    ? GestureDetector(
                        onTap: () {
                          final isPremiumUser =
                              isPremiumAsync.valueOrNull ?? false;
                          _showAllTests(
                            context,
                            tests,
                            isPremiumUser: isPremiumUser,
                          );
                        },
                        child: Text(
                          'Xem thêm (${tests.length})',
                          style: GoogleFonts.lexend(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                orElse: () => const SizedBox.shrink(),
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
              final isPremiumUser = isPremiumAsync.valueOrNull ?? false;
              final displayed = tests.take(_kMaxGridItems).toList();
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.72,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayed.length,
                itemBuilder: (context, index) {
                  final test = displayed[index];
                  final lockedByFreeLimit =
                      !isPremiumUser && index >= _kFreeUnlockedExamCount;
                  final lockedByPremiumTag = !isPremiumUser && test.isPremium;
                  return _TestCard(
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

  void _showAllTests(
    BuildContext context,
    List<TestModel> tests, {
    required bool isPremiumUser,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.borderSlate200,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    Text(
                      'Tất cả Fulltest',
                      style: GoogleFonts.lexend(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSlate900,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${tests.length} đề',
                        style: GoogleFonts.lexend(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.borderSlate100),
              // List
              Expanded(
                child: ListView.separated(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: tests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final test = tests[i];
                    final lockedByFreeLimit =
                        !isPremiumUser && i >= _kFreeUnlockedExamCount;
                    final lockedByPremiumTag = !isPremiumUser && test.isPremium;
                    return _TestListTile(
                      test: test,
                      isLocked: lockedByFreeLimit || lockedByPremiumTag,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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
          Icon(Icons.quiz_outlined, size: 48, color: AppColors.textSlate400),
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
          const Icon(Icons.error_outline, size: 48, color: Color(0xFFDC2626)),
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

// ── List tile used in "Xem thêm" bottom sheet ──────────────
class _TestListTile extends StatelessWidget {
  final TestModel test;
  final bool isLocked;

  const _TestListTile({required this.test, required this.isLocked});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          if (isLocked) {
            Navigator.of(context).pop();
            context.push('/upgrade');
            return;
          }
          Navigator.of(context).pop(); // close sheet
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
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderSlate100),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.description,
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test.title,
                      maxLines: 1,
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
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: AppColors.textSlate500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLocked)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.lock, size: 18, color: AppColors.amber600),
                ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSlate400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Grid card (unchanged layout) ────────────────────────────
class _TestCard extends StatelessWidget {
  final TestModel test;
  final bool isLocked;

  const _TestCard({required this.test, required this.isLocked});

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
                      '${test.duration} min • ${test.totalQuestions} questions',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: AppColors.textSlate500,
                      ),
                    ),
                    const Spacer(),
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
