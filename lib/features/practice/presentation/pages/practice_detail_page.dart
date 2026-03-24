import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/subscription/subscription_providers.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/practice/data/repositories/practice_repository.dart';
import 'package:lexii/features/practice/domain/entities/practice_part.dart';
import 'package:lexii/features/practice/presentation/providers/practice_providers.dart';
import 'package:lexii/features/practice/presentation/widgets/part_list_item.dart';

class PracticeDetailPage extends ConsumerWidget {
  /// 'listening' | 'reading'
  final String skill;

  const PracticeDetailPage({super.key, required this.skill});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (skill == 'listening') {
      return const _ListeningPracticePage();
    }
    if (skill == 'reading') {
      return const _ReadingPracticePage();
    }
    if (skill == 'writing') {
      return const _WritingPracticePage();
    }
    if (skill == 'speaking') {
      return const _SpeakingPracticePage();
    }
    return const SizedBox.shrink();
  }
}

// ── Shared config ───────────────────────────────────────────
const _skillConfig = {
  'listening': _SkillMeta(
    title: 'Listening',
    subtitle: 'Luyện tập từng phần',
    icon: Icons.headphones,
    bgColor: Color(0xFFDBEAFE),
    fgColor: Color(0xFF2563EB),
  ),
  'reading': _SkillMeta(
    title: 'Reading',
    subtitle: 'Luyện tập từng phần',
    icon: Icons.menu_book,
    bgColor: Color(0xFFDCFCE7),
    fgColor: Color(0xFF16A34A),
  ),
  'writing': _SkillMeta(
    title: 'Writing',
    subtitle: 'Luyện tập từng phần',
    icon: Icons.edit_note,
    bgColor: Color(0xFFF3E8FF),
    fgColor: Color(0xFF9333EA),
  ),
  'speaking': _SkillMeta(
    title: 'Speaking',
    subtitle: 'Luyện tập từng phần',
    icon: Icons.mic,
    bgColor: Color(0xFFFFF7ED),
    fgColor: Color(0xFFEA580C),
  ),
};

class _SkillMeta {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color bgColor;
  final Color fgColor;
  const _SkillMeta({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.bgColor,
    required this.fgColor,
  });
}

// ── Listening ──────────────────────────────────────────────
class _ListeningPracticePage extends ConsumerWidget {
  const _ListeningPracticePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partsAsync = ref.watch(listeningPracticePartsProvider);
    final isPremiumAsync = ref.watch(isPremiumProvider);
    final meta = _skillConfig['listening']!;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          _buildHeader(context, meta),
          Expanded(
            child: partsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => _buildNoData(
                icon: Icons.error_outline,
                title: 'Lỗi tải dữ liệu',
                subtitle: e.toString(),
                iconColor: const Color(0xFFDC2626),
                titleColor: const Color(0xFFDC2626),
              ),
              data: (parts) {
                if (parts == null) {
                  return _buildNoData(
                    icon: Icons.library_books_outlined,
                    title: 'Chưa có đề thi nào',
                    subtitle:
                        'Cần có ít nhất một đề Fulltest trong database\nđể bắt đầu luyện tập.',
                  );
                }
                final isPremiumUser = isPremiumAsync.valueOrNull ?? false;
                return _PracticeContent(
                  parts: parts,
                  isPremiumUser: isPremiumUser,
                  skill: 'listening',
                  meta: meta,
                  onWrongTap: (partFirst, wrongIds) async {
                    final ids = wrongIds;
                    if (ids.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Bạn chưa có câu sai để luyện lại.',
                            style: GoogleFonts.lexend(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    context.push(
                      '/exam/question',
                      extra: {
                        'testId': partFirst.testId,
                        'testTitle': 'Luyện tập câu sai',
                        'isPracticeMode': true,
                        'questionIds': ids,
                        'randomizeQuestions': false,
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reading ───────────────────────────────────────────────
class _ReadingPracticePage extends ConsumerWidget {
  const _ReadingPracticePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partsAsync = ref.watch(readingPracticePartsProvider);
    final isPremiumAsync = ref.watch(isPremiumProvider);
    final meta = _skillConfig['reading']!;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          _buildHeader(context, meta),
          Expanded(
            child: partsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => _buildNoData(
                icon: Icons.error_outline,
                title: 'Lỗi tải dữ liệu',
                subtitle: e.toString(),
                iconColor: const Color(0xFFDC2626),
                titleColor: const Color(0xFFDC2626),
              ),
              data: (parts) {
                if (parts == null) {
                  return _buildNoData(
                    icon: Icons.library_books_outlined,
                    title: 'Chưa có đề thi nào',
                    subtitle:
                        'Cần có ít nhất một đề Fulltest trong database\nđể bắt đầu luyện tập.',
                  );
                }
                final isPremiumUser = isPremiumAsync.valueOrNull ?? false;
                return _PracticeContent(
                  parts: parts,
                  isPremiumUser: isPremiumUser,
                  skill: 'reading',
                  meta: meta,
                  onWrongTap: (partFirst, wrongIds) async {
                    final ids = wrongIds;
                    if (ids.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Bạn chưa có câu sai để luyện lại.',
                            style: GoogleFonts.lexend(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    context.push(
                      '/exam/question',
                      extra: {
                        'testId': partFirst.testId,
                        'testTitle': 'Luyện tập câu sai',
                        'isPracticeMode': true,
                        'questionIds': ids,
                        'randomizeQuestions': false,
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Writing ───────────────────────────────────────────────
class _WritingPracticePage extends ConsumerWidget {
  const _WritingPracticePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partsAsync = ref.watch(writingPartsProvider);
    final isPremiumAsync = ref.watch(isPremiumProvider);
    final meta = _skillConfig['writing']!;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          _buildHeader(context, meta),
          Expanded(
            child: partsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => _buildNoData(
                icon: Icons.error_outline,
                title: 'Lỗi tải dữ liệu',
                subtitle: e.toString(),
                iconColor: const Color(0xFFDC2626),
                titleColor: const Color(0xFFDC2626),
              ),
              data: (parts) {
                final isPremiumUser = isPremiumAsync.valueOrNull ?? false;
                return _PracticeContent(
                  parts: parts,
                  isPremiumUser: isPremiumUser,
                  skill: 'writing',
                  meta: meta,
                  onWrongTap: (partFirst, wrongIds) {},
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Speaking ──────────────────────────────────────────────
class _SpeakingPracticePage extends ConsumerWidget {
  const _SpeakingPracticePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partsAsync = ref.watch(speakingPartsProvider);
    final isPremiumAsync = ref.watch(isPremiumProvider);
    final meta = _skillConfig['speaking']!;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          _buildHeader(context, meta),
          Expanded(
            child: partsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => _buildNoData(
                icon: Icons.error_outline,
                title: 'Lỗi tải dữ liệu',
                subtitle: e.toString(),
                iconColor: const Color(0xFFDC2626),
                titleColor: const Color(0xFFDC2626),
              ),
              data: (parts) {
                final isPremiumUser = isPremiumAsync.valueOrNull ?? false;
                return _PracticeContent(
                  parts: parts,
                  isPremiumUser: isPremiumUser,
                  skill: 'speaking',
                  meta: meta,
                  onWrongTap: (partFirst, wrongIds) {},
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared header ──────────────────────────────────────────
Widget _buildHeader(BuildContext context, _SkillMeta meta) {
  return Container(
    decoration: BoxDecoration(
      color: AppColors.primary,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
        child: Row(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.pop(),
                borderRadius: BorderRadius.circular(9999),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.arrow_back, color: Colors.white, size: 26),
                ),
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(meta.icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meta.title,
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    meta.subtitle,
                    style: GoogleFonts.lexend(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ── Shared content builder ────────────────────────────────
class _PracticeContent extends ConsumerWidget {
  final List<PracticePartData> parts;
  final bool isPremiumUser;
  final String skill;
  final _SkillMeta meta;
  final void Function(PracticePartData partFirst, List<String> wrongIds)
  onWrongTap;

  const _PracticeContent({
    required this.parts,
    required this.isPremiumUser,
    required this.skill,
    required this.meta,
    required this.onWrongTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showMistakeCard = skill == 'listening' || skill == 'reading';
    final isSpeakingOrWriting = skill == 'speaking' || skill == 'writing';
    final wrongIdsAsync = skill == 'listening'
        ? ref.watch(wrongListeningQuestionIdsProvider)
        : skill == 'reading'
        ? ref.watch(wrongReadingQuestionIdsProvider)
        : const AsyncValue.data(<String>[]);
    final wrongCount = wrongIdsAsync.valueOrNull?.length ?? 0;

    final totalQuestions = parts.fold(0, (s, p) => s + p.totalQuestions);
    final totalAnswered = parts.fold(0, (s, p) => s + p.totalAnswered);
    final correctAnswers = parts.fold(0, (s, p) => s + p.correctAnswers);
    final progressNumerator = isSpeakingOrWriting
        ? totalAnswered
        : correctAnswers;
    final progressPercent = totalQuestions > 0
        ? (progressNumerator / totalQuestions * 100)
        : 0.0;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        if (skill == 'listening') {
          ref.invalidate(listeningPracticePartsProvider);
        } else if (skill == 'reading') {
          ref.invalidate(readingPracticePartsProvider);
        } else if (skill == 'writing') {
          ref.invalidate(writingPartsProvider);
        } else if (skill == 'speaking') {
          ref.invalidate(speakingPartsProvider);
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatsCard(
              title: 'Tiến độ chung',
              leftLabel: isSpeakingOrWriting ? 'Tổng câu' : 'Đã làm',
              leftValue: isSpeakingOrWriting
                  ? '$totalQuestions'
                  : '$totalAnswered',
              centerLabel: isSpeakingOrWriting ? 'Đã nộp' : 'Đúng',
              centerValue: isSpeakingOrWriting
                  ? '$totalAnswered'
                  : '$correctAnswers',
              rightLabel: isSpeakingOrWriting ? 'Hoàn thành' : 'Tỷ lệ',
              rightValue: '${progressPercent.toInt()}%',
              progressPercent: progressPercent,
            ),
            const SizedBox(height: 16),
            if (showMistakeCard) ...[
              _MistakeCard(
                wrongCount: wrongCount,
                onTap: () async {
                  final wrongIds = wrongIdsAsync.valueOrNull ?? [];
                  onWrongTap(parts.first, wrongIds);
                },
              ),
              const SizedBox(height: 24),
            ],

            // Danh sách Part
            Text(
              'Danh sách Part',
              style: GoogleFonts.lexend(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textSlate800,
              ),
            ),
            const SizedBox(height: 12),
            ...parts.asMap().entries.map((entry) {
              final index = entry.key;
              final part = entry.value;
              final isLocked = !isPremiumUser && index > 0;
              final isSpeakingOrWritingPart =
                  skill == 'speaking' || skill == 'writing';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PracticePartCard(
                  part: PracticePart(
                    title: part.title,
                    icon: part.icon,
                    iconBgColor: part.iconBgColor,
                    iconColor: part.iconColor,
                    totalQuestions: part.totalQuestions,
                    correctAnswers: part.correctAnswers,
                    progressPercent: part.progressPercent,
                    isLocked: isLocked,
                    totalAnswered: part.totalAnswered,
                    secondaryMetricLabel: isSpeakingOrWritingPart
                        ? 'hoàn thành'
                        : 'đúng',
                    secondaryMetricValue: isSpeakingOrWritingPart
                        ? part.totalAnswered
                        : part.correctAnswers,
                    progressOverride: isSpeakingOrWritingPart
                        ? (part.totalQuestions > 0
                              ? part.totalAnswered / part.totalQuestions
                              : 0)
                        : null,
                  ),
                  onTap: isLocked
                      ? () => context.push('/upgrade')
                      : () => _onPartTap(context, ref, part),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _onPartTap(
    BuildContext context,
    WidgetRef ref,
    PracticePartData part,
  ) async {
    final supportsUnansweredMode =
        (skill == 'listening' || skill == 'reading') &&
        (part.questionType == 'mcq_audio' || part.questionType == 'mcq_text') &&
        part.totalQuestions > 0 &&
        part.totalAnswered > 0;

    if (!supportsUnansweredMode) {
      _showCountModal(context, ref, part);
      return;
    }

    final restartFromStart = await _showRestartChoiceDialog(context);
    if (restartFromStart == null || !context.mounted) return;

    if (restartFromStart) {
      _showCountModal(
        context,
        ref,
        part,
        availableQuestionIds: null,
        availableTotalOverride: part.totalQuestions,
        availabilityLabel: 'câu hỏi có sẵn',
      );
      return;
    }

    final unansweredIds = await _loadUnansweredQuestionIds(context, ref, part);
    if (!context.mounted) return;

    if (unansweredIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bạn đã hoàn thành tất cả câu hỏi của part này.',
            style: GoogleFonts.lexend(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _showCountModal(
      context,
      ref,
      part,
      availableQuestionIds: unansweredIds,
      availableTotalOverride: unansweredIds.length,
      availabilityLabel: 'câu chưa làm',
    );
  }

  Future<bool?> _showRestartChoiceDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Luyện tập tiếp',
            style: GoogleFonts.lexend(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textSlate800,
            ),
          ),
          content: Text(
            'Bạn có muốn luyện tập lại từ đầu không?',
            style: GoogleFonts.lexend(
              fontSize: 14,
              color: AppColors.textSlate600,
              height: 1.5,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Từ chối',
                style: GoogleFonts.lexend(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Chấp nhận',
                style: GoogleFonts.lexend(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<List<String>> _loadUnansweredQuestionIds(
    BuildContext context,
    WidgetRef ref,
    PracticePartData part,
  ) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final repo = ref.read(practiceRepositoryProvider);
      return await repo.getUnansweredQuestionIdsForPart(
        partIds: part.partIds,
        questionType: part.questionType,
      );
    } finally {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  void _showCountModal(
    BuildContext context,
    WidgetRef ref,
    PracticePartData part, {
    List<String>? availableQuestionIds,
    int? availableTotalOverride,
    String availabilityLabel = 'câu hỏi có sẵn',
  }) {
    final isSpeakingOrWriting = skill == 'speaking' || skill == 'writing';
    final totalAvailable = availableTotalOverride ?? part.totalQuestions;
    int selectedCount = totalAvailable > 0
        ? (isSpeakingOrWriting
              ? (totalAvailable >= 1 ? 1 : totalAvailable)
              : (totalAvailable > 10 ? 10 : totalAvailable))
        : totalAvailable;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final opts = _buildOptions(
            totalAvailable,
            compactStepOne: isSpeakingOrWriting,
          );

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: 20 + MediaQuery.of(ctx).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              skill == 'listening'
                                  ? 'Listening'
                                  : skill == 'reading'
                                  ? 'Reading'
                                  : skill == 'speaking'
                                  ? 'Speaking'
                                  : 'Writing',
                              style: GoogleFonts.lexend(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        part.title,
                        style: GoogleFonts.lexend(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalAvailable $availabilityLabel',
                        style: GoogleFonts.lexend(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Số câu luyện tập
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Số câu luyện tập',
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$selectedCount câu',
                        style: GoogleFonts.lexend(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Preset chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: opts.map((n) {
                    final isSelected = selectedCount == n;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedCount = n),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.borderSlate200,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          n == totalAvailable ? 'Tất cả' : '$n',
                          style: GoogleFonts.lexend(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSlate600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (totalAvailable > 1) ...[
                  const SizedBox(height: 12),
                  SliderTheme(
                    data: SliderTheme.of(ctx).copyWith(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.slate200,
                      thumbColor: AppColors.primary,
                      overlayColor: AppColors.primary.withValues(alpha: 0.15),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      min: 1,
                      max: totalAvailable.toDouble(),
                      divisions: totalAvailable - 1,
                      value: selectedCount.clamp(1, totalAvailable).toDouble(),
                      onChanged: (v) {
                        setModalState(() => selectedCount = v.round());
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Summary
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.help_outline,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$selectedCount câu hỏi',
                              style: GoogleFonts.lexend(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSlate800,
                              ),
                            ),
                            Text(
                              'Bạn sẽ luyện $selectedCount câu từ ${part.title}${availableQuestionIds != null ? ' (chưa làm)' : ''}',
                              style: GoogleFonts.lexend(
                                fontSize: 12,
                                color: AppColors.textSlate500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(
                            color: AppColors.borderSlate200,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Hủy bỏ',
                          style: GoogleFonts.lexend(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSlate600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: selectedCount > 0
                            ? () {
                                Navigator.pop(ctx);
                                _startPractice(
                                  context,
                                  ref,
                                  part,
                                  selectedCount,
                                  questionIdsPool: availableQuestionIds,
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          disabledBackgroundColor: AppColors.textSlate300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Bắt đầu ngay',
                              style: GoogleFonts.lexend(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _startPractice(
    BuildContext context,
    WidgetRef ref,
    PracticePartData part,
    int count, {
    List<String>? questionIdsPool,
  }) async {
    if (skill == 'writing') {
      await context.push(
        '/practice/writing-question',
        extra: {
          'partNumber': part.partNumber,
          'partTitle': part.title,
          'questionLimit': count,
        },
      );
      ref.invalidate(writingPartsProvider);
      return;
    }

    if (skill == 'speaking') {
      await context.push(
        '/practice/speaking-question',
        extra: {
          'partNumber': part.partNumber,
          'taskType': part.testPartId,
          'partTitle': part.title,
          'questionLimit': count,
        },
      );
      ref.invalidate(speakingPartsProvider);
      return;
    }

    if (questionIdsPool != null) {
      final selectedIds = questionIdsPool.take(count).toList(growable: false);
      if (selectedIds.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Không còn câu chưa làm để bắt đầu.',
                style: GoogleFonts.lexend(fontSize: 13, color: Colors.white),
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      await context.push(
        '/exam/question',
        extra: {
          'testId': part.testId,
          'testTitle': part.title,
          'partId': part.testPartId,
          'partNumber': part.partNumber,
          'isPracticeMode': true,
          'questionIds': selectedIds,
          'randomizeQuestions': false,
        },
      );

      if (skill == 'listening') {
        ref.invalidate(listeningPracticePartsProvider);
        ref.invalidate(wrongListeningQuestionIdsProvider);
      } else if (skill == 'reading') {
        ref.invalidate(readingPracticePartsProvider);
        ref.invalidate(wrongReadingQuestionIdsProvider);
      }
      return;
    }

    await context.push(
      '/practice/part-intro',
      extra: part.copyWith(totalQuestions: count),
    );

    if (skill == 'listening') {
      ref.invalidate(listeningPracticePartsProvider);
      ref.invalidate(wrongListeningQuestionIdsProvider);
    } else if (skill == 'reading') {
      ref.invalidate(readingPracticePartsProvider);
      ref.invalidate(wrongReadingQuestionIdsProvider);
    }
  }

  List<int> _buildOptions(int total, {bool compactStepOne = false}) {
    if (total <= 0) return [0];

    if (compactStepOne) {
      final allPresets = [1, 2, 3, 5, 10, 15, 20, 25, 30, 40, 50, 75, 100];
      final presets = allPresets.where((n) => n <= total && n >= 1).toList();
      if (!presets.contains(total)) presets.add(total);
      presets.sort();
      return presets;
    }

    final presets = [5, 10, 20, 50, 100].where((n) => n <= total).toList();
    if (!presets.contains(total)) presets.add(total);
    return presets;
  }
}

// ── Stats card giống web ─────────────────────────────────
class _StatsCard extends StatelessWidget {
  final String title;
  final String leftLabel;
  final String leftValue;
  final String centerLabel;
  final String centerValue;
  final String rightLabel;
  final String rightValue;
  final double progressPercent;

  const _StatsCard({
    required this.title,
    required this.leftLabel,
    required this.leftValue,
    required this.centerLabel,
    required this.centerValue,
    required this.rightLabel,
    required this.rightValue,
    required this.progressPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSlate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bar_chart,
                  size: 22,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.lexend(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSlate800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatItem(
                label: leftLabel,
                value: leftValue,
                color: AppColors.textSlate800,
              ),
              _StatItem(
                label: centerLabel,
                value: centerValue,
                color: AppColors.green600,
              ),
              _StatItem(
                label: rightLabel,
                value: rightValue,
                color: AppColors.textSlate400,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              value: progressPercent / 100,
              minHeight: 6,
              backgroundColor: AppColors.slate100,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.lexend(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: 12,
              color: AppColors.textSlate500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mistake practice card giống web ───────────────────────
class _MistakeCard extends StatelessWidget {
  final int wrongCount;
  final VoidCallback onTap;

  const _MistakeCard({required this.wrongCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFED7AA)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.history_edu,
                size: 18,
                color: Color(0xFFF97316),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Luyện tập câu sai',
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSlate800,
                    ),
                  ),
                  Text(
                    'Tổng số câu sai: $wrongCount',
                    style: GoogleFonts.lexend(
                      fontSize: 12,
                      color: AppColors.textSlate500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Color(0xFFF97316)),
          ],
        ),
      ),
    );
  }
}

// ── Empty / error state ───────────────────────────────────
Widget _buildNoData({
  required IconData icon,
  required String title,
  required String subtitle,
  Color iconColor = AppColors.textSlate300,
  Color titleColor = AppColors.textSlate600,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: iconColor),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.lexend(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.lexend(
              fontSize: 13,
              color: AppColors.textSlate400,
              height: 1.5,
            ),
          ),
        ],
      ),
    ),
  );
}
