import 'package:flutter/material.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/practice/domain/entities/practice_part.dart';

/// Predefined skill configurations for all 4 practice skills
class SkillConfigs {
  SkillConfigs._();

  static const Color _blue50 = Color(0xFFEFF6FF);
  static const Color _blue600 = Color(0xFF2563EB);
  static const Color _purple50 = Color(0xFFFAF5FF);
  static const Color _purple600 = Color(0xFF9333EA);

  static SkillConfig get listening => SkillConfig(
    title: 'Nghe Hiểu',
    headerIcon: Icons.headphones,
    parts: [
      PracticePart(
        title: 'Part 1: Mô tả tranh',
        icon: Icons.image,
        iconBgColor: _blue50,
        iconColor: _blue600,
        progressPercent: 10,
      ),
      PracticePart(
        title: 'Part 2: Hỏi & Đáp',
        icon: Icons.record_voice_over,
        iconBgColor: _purple50,
        iconColor: _purple600,
        progressPercent: 5,
      ),
      PracticePart(
        title: 'Part 3: Đoạn Hội Thoại',
        icon: Icons.forum,
        iconBgColor: AppColors.slate100,
        iconColor: AppColors.textSlate500,
        isLocked: true,
      ),
      PracticePart(
        title: 'Part 4: Bài Nói Chuyện Ngắn',
        icon: Icons.graphic_eq,
        iconBgColor: AppColors.slate100,
        iconColor: AppColors.textSlate500,
        isLocked: true,
      ),
      PracticePart(
        title: 'Luyện tập câu sai',
        icon: Icons.history_edu,
        iconBgColor: AppColors.slate100,
        iconColor: AppColors.textSlate500,
        isLocked: true,
      ),
    ],
  );

  static SkillConfig get reading => SkillConfig(
    title: 'Đọc Hiểu',
    headerIcon: Icons.menu_book,
    parts: [
      PracticePart(
        title: 'Part 5: Điền Vào Câu',
        icon: Icons.image,
        iconBgColor: _blue50,
        iconColor: _blue600,
        progressPercent: 10,
      ),
      PracticePart(
        title: 'Part 6: Điền Vào Đoạn Văn',
        icon: Icons.record_voice_over,
        iconBgColor: _purple50,
        iconColor: _purple600,
        progressPercent: 5,
      ),
      PracticePart(
        title: 'Part 7: Đọc Hiểu Đoạn Văn',
        icon: Icons.forum,
        iconBgColor: AppColors.slate100,
        iconColor: AppColors.textSlate500,
        isLocked: true,
      ),
      PracticePart(
        title: 'Luyện tập câu sai',
        icon: Icons.history_edu,
        iconBgColor: AppColors.slate100,
        iconColor: AppColors.textSlate500,
        isLocked: true,
      ),
    ],
  );

  static SkillConfig get speaking => SkillConfig(
    title: 'Luyện nói',
    headerIcon: Icons.mic,
    parts: [
      PracticePart(
        title: 'Part 1: Đọc văn bản',
        icon: Icons.record_voice_over,
        iconBgColor: _blue50,
        iconColor: _blue600,
        progressPercent: 10,
      ),
      PracticePart(
        title: 'Part 2: Mô tả tranh',
        icon: Icons.image,
        iconBgColor: _purple50,
        iconColor: _purple600,
        progressPercent: 5,
      ),
      PracticePart(
        title: 'Part 3: Trả lời câu hỏi (1)',
        icon: Icons.forum,
        iconBgColor: AppColors.slate100,
        iconColor: AppColors.textSlate500,
        isLocked: true,
      ),
      PracticePart(
        title: 'Part 3: Trả lời câu hỏi (2)',
        icon: Icons.forum,
        iconBgColor: AppColors.slate100,
        iconColor: AppColors.textSlate500,
        isLocked: true,
      ),
      PracticePart(
        title: 'Part 4: Đề xuất giải pháp',
        icon: Icons.graphic_eq,
        iconBgColor: AppColors.slate100,
        iconColor: AppColors.textSlate500,
        isLocked: true,
      ),
      PracticePart(
        title: 'Thể hiện quan điểm',
        icon: Icons.history_edu,
        iconBgColor: AppColors.slate100,
        iconColor: AppColors.textSlate500,
        isLocked: true,
      ),
    ],
  );

  static SkillConfig get writing => SkillConfig(
    title: 'Viết',
    headerIcon: Icons.edit,
    parts: [
      PracticePart(
        title: 'Part 1: Mô tả tranh',
        icon: Icons.image,
        iconBgColor: _blue50,
        iconColor: _blue600,
        progressPercent: 10,
      ),
      PracticePart(
        title: 'Part 2: Phản hồi yêu cầu',
        icon: Icons.email,
        iconBgColor: _purple50,
        iconColor: _purple600,
        progressPercent: 5,
      ),
      PracticePart(
        title: 'Viết luận',
        icon: Icons.history_edu,
        iconBgColor: AppColors.slate100,
        iconColor: AppColors.textSlate500,
        isLocked: true,
      ),
    ],
  );
}
