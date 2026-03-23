import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/practice/domain/entities/practice_part.dart';

/// Part list item card giống web: icon vuông, tiến độ per-part,
/// nhãn "Premium" khi locked.
class PracticePartCard extends StatelessWidget {
  final PracticePart part;
  final VoidCallback? onTap;

  const PracticePartCard({super.key, required this.part, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLocked = part.isLocked;
    final secondaryValue = part.secondaryMetricValue ?? part.correctAnswers;
    final progressValue =
        part.progressOverride ??
        (part.totalQuestions > 0 ? secondaryValue / part.totalQuestions : 0);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isLocked ? onTap : (onTap ?? () {}),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isLocked
                  ? const Color(0xFFFDE68A)
                  : AppColors.borderSlate100,
            ),
            color: isLocked ? const Color(0xFFFFFBEB) : Colors.white,
            boxShadow: isLocked
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Icon vuông (giống web)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isLocked ? const Color(0xFFFEF3C7) : part.iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  part.icon,
                  size: 24,
                  color: isLocked ? const Color(0xFFD97706) : part.iconColor,
                ),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      part.title,
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isLocked
                            ? const Color(0xFF92400E)
                            : AppColors.textSlate800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // "X đã làm · Y đúng · Z câu" (giống web)
                    Text(
                      '${part.totalAnswered} đã làm · $secondaryValue ${part.secondaryMetricLabel} · ${part.totalQuestions} câu',
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: AppColors.textSlate500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Progress bar nhỏ bên trong card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(9999),
                      child: LinearProgressIndicator(
                        value: progressValue.clamp(0, 1),
                        minHeight: 4,
                        backgroundColor: isLocked
                            ? const Color(0xFFFDE68A)
                            : AppColors.slate100,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isLocked
                              ? const Color(0xFFD97706)
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Lock badge hoặc chevron
              if (isLocked)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock,
                        size: 12,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Premium',
                        style: GoogleFonts.lexend(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.textSlate400,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Legacy part list item — giữ lại cho tương thích ngược.
class PartListItem extends StatelessWidget {
  final PracticePart part;
  final VoidCallback? onTap;

  const PartListItem({super.key, required this.part, this.onTap});

  @override
  Widget build(BuildContext context) {
    return PracticePartCard(part: part, onTap: onTap);
  }
}
