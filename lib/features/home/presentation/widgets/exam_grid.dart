import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';

class ExamGrid extends StatelessWidget {
  const ExamGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Luyện thi',
            style: GoogleFonts.lexend(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textSlate800,
            ),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.9,
          children: [
            _ExamCard(
              icon: Icons.laptop_chromebook,
              title: 'Thi thử Online',
              bgColor: AppColors.indigo100,
              iconColor: AppColors.indigo600,
              onTap: () => context.push('/exam/mock-test'),
            ),
            _ExamCard(
              icon: Icons.quiz,
              title: 'Thi thử',
              bgColor: AppColors.teal100,
              iconColor: AppColors.primary,
              onTap: () => context.push('/exam/mock-test'),
            ),
            _ExamCard(
              icon: Icons.verified,
              title: 'Bao đỗ',
              bgColor: AppColors.red100,
              iconColor: AppColors.red600,
              badge: 'HOT',
              onTap: () {},
            ),
            _ExamCard(
              icon: Icons.import_contacts,
              title: 'Lý thuyết',
              bgColor: AppColors.green100,
              iconColor: AppColors.green600,
              badge: 'FREE',
              onTap: () => context.push('/theory'),
            ),
            _ExamCard(
              icon: Icons.upgrade,
              title: 'Nâng cấp',
              bgColor: AppColors.amber100,
              iconColor: AppColors.amber600,
              onTap: () => context.push('/upgrade'),
            ),
            _ExamCard(
              icon: Icons.settings,
              title: 'Cài đặt',
              bgColor: AppColors.slate100,
              iconColor: AppColors.textSlate600,
              onTap: () => context.push('/settings'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ExamCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color bgColor;
  final Color iconColor;
  final String? badge;
  final VoidCallback onTap;

  const _ExamCard({
    required this.icon,
    required this.title,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
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
          child: Stack(
            children: [
              // Badge
              if (badge != null)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      badge!,
                      style: GoogleFonts.lexend(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              // Content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: bgColor,
                    ),
                    child: Icon(icon, size: 20, color: iconColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lexend(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSlate900,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
