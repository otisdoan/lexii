import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';

class SpeakingWritingSection extends StatelessWidget {
  const SpeakingWritingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Speaking & Writing',
                style: GoogleFonts.lexend(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSlate900,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/practice/speaking'),
                child: Text(
                  'Luyện ngay',
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
          // Speaking card
          _SwCard(
            icon: Icons.mic,
            title: 'TOEIC Speaking',
            subtitle: 'Luyện nói theo chủ đề TOEIC',
            iconBgColor: const Color(0xFFFFEDD5), // orange-100
            iconColor: const Color(0xFFEA580C), // orange-600
            onTap: () => context.push('/practice/speaking'),
          ),
          const SizedBox(height: 16),
          // Writing card
          _SwCard(
            icon: Icons.edit_note,
            title: 'TOEIC Writing',
            subtitle: 'Luyện viết theo dạng bài TOEIC',
            iconBgColor: const Color(0xFFDBEAFE), // blue-100
            iconColor: const Color(0xFF2563EB), // blue-600
            onTap: () => context.push('/practice/writing'),
          ),
        ],
      ),
    );
  }
}

class _SwCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _SwCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconBgColor,
    required this.iconColor,
    required this.onTap,
  });

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
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Icon(icon, size: 28, color: iconColor)),
                ),
                const SizedBox(width: 16),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.lexend(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSlate900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.lexend(
                          fontSize: 14,
                          color: AppColors.textSlate500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Start button
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Bắt đầu',
                    style: GoogleFonts.lexend(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSlate600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
