import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/core/constants/app_constants.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(color: AppColors.borderSlate100),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40),
          Text(
            AppConstants.appName,
            style: GoogleFonts.lexend(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textSlate800,
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(9999),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.tune,
                  size: 24,
                  color: AppColors.textSlate600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
