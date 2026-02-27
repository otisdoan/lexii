import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';

class NotebookSection extends StatelessWidget {
  const NotebookSection({super.key});

  @override
  Widget build(BuildContext context) {
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
            children: const [
              _NotebookCard(
                title: 'Từ vựng',
                subtitle: 'Đã lưu 12 từ',
                icon: Icons.star,
                iconColor: AppColors.yellow500,
              ),
              SizedBox(width: 16),
              _NotebookCard(
                title: 'Câu hỏi',
                subtitle: 'Đã lưu 5 câu',
                icon: Icons.bookmark,
                iconColor: AppColors.blue500,
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

  const _NotebookCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Top row
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
          // Review button
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    'Ôn tập ngay',
                    style: GoogleFonts.lexend(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
