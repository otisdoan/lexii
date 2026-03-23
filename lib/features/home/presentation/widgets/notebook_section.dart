import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/theory/presentation/providers/theory_providers.dart';

class NotebookSection extends ConsumerWidget {
  const NotebookSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabCountAsync = ref.watch(vocabularyCountProvider);
    final grammarCountAsync = ref.watch(grammarCountProvider);

    final vocabCount = vocabCountAsync.valueOrNull ?? 0;
    final grammarCount = grammarCountAsync.valueOrNull ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Sổ tay',
            style: GoogleFonts.lexend(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textSlate800,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 144,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _NotebookCard(
                title: 'Từ vựng',
                subtitle: vocabCount > 0 ? '$vocabCount từ' : 'Chưa có từ vựng',
                icon: Icons.star,
                iconColor: AppColors.yellow500,
                onTap: () => context.push('/theory/vocabulary?tab=learn'),
              ),
              const SizedBox(width: 16),
              _NotebookCard(
                title: 'Ngữ pháp',
                subtitle: grammarCount > 0
                    ? '$grammarCount câu hỏi'
                    : 'Chưa có ngữ pháp',
                icon: Icons.bookmark,
                iconColor: AppColors.orange500,
                onTap: () => context.push('/theory/grammar'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotebookCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _NotebookCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSlate800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: AppColors.textSlate500,
                      ),
                    ),
                  ],
                ),
                Icon(icon, color: iconColor),
              ],
            ),
            Material(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    'Học ngay',
                    style: GoogleFonts.lexend(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
