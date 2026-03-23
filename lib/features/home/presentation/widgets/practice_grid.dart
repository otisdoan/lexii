import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/core/subscription/subscription_providers.dart';

class PracticeGrid extends ConsumerWidget {
  const PracticeGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremiumAsync = ref.watch(isPremiumProvider);
    final isPremiumUser = isPremiumAsync.valueOrNull ?? false;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Luyện tập',
                style: GoogleFonts.lexend(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSlate800,
                ),
              ),
            ),

          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _PracticeCard(
              icon: Icons.headphones,
              title: 'Nghe Hiểu',
              subtitle: 'Listening',
              route: '/practice/listening',
            ),
            _PracticeCard(
              icon: Icons.menu_book,
              title: 'Đọc Hiểu',
              subtitle: 'Reading',
              route: '/practice/reading',
            ),
            _PracticeCard(
              icon: Icons.mic,
              title: 'Luyện nói',
              subtitle: isPremiumUser ? 'Speaking' : 'Premium',
              route: isPremiumUser ? '/practice/speaking' : '/upgrade',
              isLocked: !isPremiumUser,
              iconBgColor: AppColors.orange50,
              iconColor: AppColors.orange500,
            ),
            _PracticeCard(
              icon: Icons.edit,
              title: 'Viết',
              subtitle: isPremiumUser ? 'Writing' : 'Premium',
              route: isPremiumUser ? '/practice/writing' : '/upgrade',
              isLocked: !isPremiumUser,
              iconBgColor: AppColors.purple50,
              iconColor: AppColors.purple500,
            ),
          ],
        ),
      ],
    );
  }
}

class _PracticeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final bool isLocked;
  final Color iconBgColor;
  final Color iconColor;

  const _PracticeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    this.isLocked = false,
    this.iconBgColor = AppColors.teal50,
    this.iconColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLocked ? const Color(0xFFFED7AA) : AppColors.borderSlate100,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: iconBgColor,
                    ),
                    child: Icon(icon, size: 24, color: iconColor),
                  ),
                  if (isLocked)
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFD97706),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.lock,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isLocked ? const Color(0xFF92400E) : AppColors.textSlate900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  color: isLocked ? const Color(0xFFD97706) : AppColors.textSlate500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

