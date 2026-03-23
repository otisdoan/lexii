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
  final int totalAnswered;
  final double progressPercent;
  final bool isLocked;
  final String secondaryMetricLabel;
  final int? secondaryMetricValue;
  final double? progressOverride;

  const PracticePart({
    required this.title,
    required this.icon,
    this.iconBgColor = AppColors.teal50,
    this.iconColor = AppColors.primary,
    this.totalQuestions = 0,
    this.correctAnswers = 0,
    this.totalAnswered = 0,
    this.progressPercent = 0,
    this.isLocked = false,
    this.secondaryMetricLabel = 'đúng',
    this.secondaryMetricValue,
    this.progressOverride,
  });

  PracticePart copyWith({
    String? title,
    IconData? icon,
    Color? iconBgColor,
    Color? iconColor,
    int? totalQuestions,
    int? correctAnswers,
    int? totalAnswered,
    double? progressPercent,
    bool? isLocked,
    String? secondaryMetricLabel,
    int? secondaryMetricValue,
    double? progressOverride,
  }) {
    return PracticePart(
      title: title ?? this.title,
      icon: icon ?? this.icon,
      iconBgColor: iconBgColor ?? this.iconBgColor,
      iconColor: iconColor ?? this.iconColor,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      totalAnswered: totalAnswered ?? this.totalAnswered,
      progressPercent: progressPercent ?? this.progressPercent,
      isLocked: isLocked ?? this.isLocked,
      secondaryMetricLabel: secondaryMetricLabel ?? this.secondaryMetricLabel,
      secondaryMetricValue: secondaryMetricValue ?? this.secondaryMetricValue,
      progressOverride: progressOverride ?? this.progressOverride,
    );
  }
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
