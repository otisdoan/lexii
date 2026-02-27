import 'package:flutter/material.dart';
import 'package:lexii/core/theme/app_colors.dart';

/// Represents a practice part (e.g. Part 1, Part 2...) in a skill section
class PracticePart {
  final String title;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final int totalQuestions;
  final int correctAnswers;
  final double progressPercent;
  final bool isLocked;

  const PracticePart({
    required this.title,
    required this.icon,
    this.iconBgColor = AppColors.teal50,
    this.iconColor = AppColors.primary,
    this.totalQuestions = 0,
    this.correctAnswers = 0,
    this.progressPercent = 0,
    this.isLocked = false,
  });
}

/// Configuration for a skill practice detail screen
class SkillConfig {
  final String title;
  final IconData headerIcon;
  final List<PracticePart> parts;

  const SkillConfig({
    required this.title,
    required this.headerIcon,
    required this.parts,
  });
}
