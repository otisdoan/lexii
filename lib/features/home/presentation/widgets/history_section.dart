import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/exam/presentation/providers/test_providers.dart';
import 'package:lexii/features/practice/presentation/providers/practice_providers.dart';

class HistorySection extends ConsumerStatefulWidget {
  const HistorySection({super.key});

  @override
  ConsumerState<HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends ConsumerState<HistorySection> {
  int _activeTab = 0; // 0 = Thi, 1 = Luyện tập

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSlate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lịch sử',
                style: GoogleFonts.lexend(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSlate800,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _TabButton(
                      label: 'Thi',
                      isActive: _activeTab == 0,
                      onTap: () => setState(() => _activeTab = 0),
                    ),
                    _TabButton(
                      label: 'Luyện tập',
                      isActive: _activeTab == 1,
                      onTap: () => setState(() => _activeTab = 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _activeTab == 0
              ? const _ExamHistoryContent()
              : const _PracticeHistoryContent(),
        ],
      ),
    );
  }
}

class _PracticeHistoryContent extends ConsumerWidget {
  const _PracticeHistoryContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(dashboardPracticeHistoryProvider);

    return historyAsync.when(
      loading: () => _buildLoading(),
      error: (e, _) => _buildError('Không tải được lịch sử luyện tập.'),
      data: (items) {
        if (items.isEmpty) {
          return _buildEmpty(
            icon: Icons.history_edu,
            message: 'Chưa có lịch sử luyện tập nào.\nHãy bắt đầu ngay!',
            actionLabel: 'Bắt đầu nào',
            onAction: () => context.push('/practice/listening'),
          );
        }

        return Column(
          children: items.take(5).map((item) {
            final isSpeaking =
                item.questionType == 'speaking' || item.answerText.isEmpty;
            final score = item.ai?.overall;
            final modeLabel = isSpeaking ? 'Luyện nói' : 'Luyện viết';
            final iconBg = isSpeaking ? AppColors.orange50 : AppColors.purple50;
            final iconColor = isSpeaking
                ? AppColors.orange500
                : AppColors.purple500;

            return InkWell(
              onTap: isSpeaking
                  ? () => context.push('/practice/speaking')
                  : () => context.push('/practice/writing'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isSpeaking ? Icons.mic : Icons.edit_note,
                        size: 18,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.prompt.length > 40
                                ? '${item.prompt.substring(0, 40)}...'
                                : item.prompt,
                            style: GoogleFonts.lexend(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSlate800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$modeLabel · ${_formatDate(item.createdAt)}',
                            style: GoogleFonts.lexend(
                              fontSize: 11,
                              color: AppColors.textSlate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (score != null)
                      _ScoreBadge(score: score)
                    else
                      Text(
                        _formatDate(item.createdAt),
                        style: GoogleFonts.lexend(
                          fontSize: 11,
                          color: AppColors.textSlate400,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ExamHistoryContent extends ConsumerWidget {
  const _ExamHistoryContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(attemptHistoryProvider(5));

    return historyAsync.when(
      loading: () => _buildLoading(),
      error: (e, _) => _buildError('Không tải được lịch sử thi.'),
      data: (items) {
        if (items.isEmpty) {
          return _buildEmpty(
            icon: Icons.quiz,
            message:
                'Chưa có lịch sử thi nào.\nHoàn thành bài thi đầu tiên để xem kết quả!',
            actionLabel: 'Đi thi thử',
            onAction: () => context.push('/exam/mock-test'),
          );
        }

        return Column(
          children: items.take(5).map((item) {
            return InkWell(
              onTap: () => context.push('/settings/test-history/${item.id}'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.teal50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.testTitle,
                            style: GoogleFonts.lexend(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSlate800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Đề thi · ${item.answeredCount} câu',
                            style: GoogleFonts.lexend(
                              fontSize: 11,
                              color: AppColors.textSlate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item.score} điểm',
                          style: GoogleFonts.lexend(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _getScoreColor(item.score),
                          ),
                        ),
                        Text(
                          _formatDate(item.submittedAt),
                          style: GoogleFonts.lexend(
                            fontSize: 11,
                            color: AppColors.textSlate400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.lexend(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? AppColors.textSlate800 : AppColors.textSlate500,
          ),
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int score;

  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.indigo100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$score/100',
        style: GoogleFonts.lexend(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.indigo600,
        ),
      ),
    );
  }
}

Widget _buildLoading() {
  return Column(
    children: List.generate(
      3,
      (i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    width: 160,
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 10,
                    width: 100,
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildEmpty({
  required IconData icon,
  required String message,
  required String actionLabel,
  required VoidCallback onAction,
}) {
  return Column(
    children: [
      const SizedBox(height: 8),
      Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.slate50,
        ),
        child: Icon(icon, size: 28, color: AppColors.textSlate300),
      ),
      const SizedBox(height: 12),
      Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.lexend(
          fontSize: 13,
          color: AppColors.textSlate500,
          height: 1.5,
        ),
      ),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: onAction,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            actionLabel,
            style: GoogleFonts.lexend(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
    ],
  );
}

Widget _buildError(String message) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: GoogleFonts.lexend(fontSize: 13, color: AppColors.red500),
    ),
  );
}

String _formatDate(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inMinutes < 1) return 'Vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  if (diff.inDays < 7) return '${diff.inDays} ngày trước';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

Color _getScoreColor(int score) {
  if (score >= 85) return AppColors.green600;
  if (score >= 65) return const Color(0xFFD97706);
  return AppColors.red500;
}
