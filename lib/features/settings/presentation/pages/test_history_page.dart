import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/exam/data/models/attempt_history_model.dart';
import 'package:lexii/features/exam/presentation/providers/test_providers.dart';

class TestHistoryPage extends ConsumerWidget {
  const TestHistoryPage({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(attemptHistoryProvider(50));
    await ref.read(attemptHistoryProvider(50).future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(attemptHistoryProvider(50));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          Container(
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.pop(),
                        borderRadius: BorderRadius.circular(9999),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Lịch sử bài làm đề thi',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lexend(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => _refresh(ref),
              child: historyAsync.when(
                loading: () => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 240),
                    Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ],
                ),
                error: (error, _) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Không tải được lịch sử bài làm.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lexend(
                          fontSize: 14,
                          color: AppColors.textSlate500,
                        ),
                      ),
                    ),
                  ],
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Bạn chưa có bài thi nào được nộp.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lexend(
                              fontSize: 14,
                              color: AppColors.textSlate500,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _HistoryCard(item: item, onRefresh: () => _refresh(ref));
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final AttemptHistoryItemModel item;
  final Future<void> Function() onRefresh;

  const _HistoryCard({required this.item, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        await context.push('/settings/test-history/${item.id}');
        await onRefresh();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.testTitle,
                    style: GoogleFonts.lexend(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSlate900,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.teal50,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${item.score} điểm',
                    style: GoogleFonts.lexend(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _formatDateTime(item.submittedAt),
              style: GoogleFonts.lexend(
                fontSize: 12,
                color: AppColors.textSlate400,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatPill(label: 'Đã làm', value: '${item.answeredCount}'),
                const SizedBox(width: 8),
                _StatPill(label: 'Đúng', value: '${item.correctCount}'),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textSlate400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year • $hour:$minute';
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;

  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.lexend(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSlate600,
        ),
      ),
    );
  }
}
