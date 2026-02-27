import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: AppColors.borderSlate200),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.local_library,
                label: 'Luyện tập',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.schedule,
                label: 'Lịch sử',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.workspace_premium,
                label: 'Chứng chỉ',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.diamond,
                label: 'Nâng cấp',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
                badge: '-50%',
              ),
              _NavItem(
                icon: Icons.settings,
                label: 'Cài đặt',
                isActive: currentIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final String? badge;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon container
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9999),
                    color: isActive
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: isActive ? AppColors.primary : AppColors.textSlate400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.lexend(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color:
                        isActive ? AppColors.primary : AppColors.textSlate500,
                  ),
                ),
              ],
            ),
            // Badge
            if (badge != null)
              Positioned(
                top: -8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.red500,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: Colors.white, width: 1),
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
          ],
        ),
      ),
    );
  }
}
