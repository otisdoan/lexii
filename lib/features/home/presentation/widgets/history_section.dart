import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';

class HistorySection extends StatelessWidget {
  const HistorySection({super.key});

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
          // Header with toggle
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
              // Tab toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _TabButton(label: 'Luyện tập', isActive: true),
                    _TabButton(label: 'Thi', isActive: false),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Empty state
          Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.slate50,
                ),
                child: const Icon(
                  Icons.history_edu,
                  size: 36,
                  color: AppColors.textSlate300,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: Text(
                  'Bạn chưa có lịch sử luyện tập nào. Hãy bắt đầu ngay!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    color: AppColors.textSlate500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Bắt đầu nào',
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;

  const _TabButton({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
