import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/subscription/subscription_providers.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/practice/data/repositories/practice_repository.dart';
import 'package:lexii/features/practice/domain/entities/practice_part.dart';
import 'package:lexii/features/practice/domain/entities/skill_configs.dart';
import 'package:lexii/features/practice/presentation/providers/practice_providers.dart';
import 'package:lexii/features/practice/presentation/widgets/stats_card.dart';
import 'package:lexii/features/practice/presentation/widgets/mistake_practice_card.dart';
import 'package:lexii/features/practice/presentation/widgets/part_list_item.dart';

class PracticeDetailPage extends ConsumerWidget {
  /// 'listening' | 'reading' | 'speaking' | 'writing'
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
    return _StaticSkillPage(config: _staticConfig);
  }

  SkillConfig get _staticConfig {
    switch (skill) {
      case 'reading':
        return SkillConfigs.reading;
      case 'speaking':
        return SkillConfigs.speaking;
      case 'writing':
        return SkillConfigs.writing;
      default:
        return SkillConfigs.listening;
    }
  }
}

// ── Reading — DB-backed ────────────────────────────────────────
class _ReadingPracticePage extends ConsumerWidget {
  const _ReadingPracticePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partsAsync = ref.watch(readingPracticePartsProvider);
    final isPremiumAsync = ref.watch(isPremiumProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          _buildAppBar(context, 'Đọc Hiểu'),
          Expanded(
            child: partsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => _buildError(e.toString()),
              data: (parts) {
                if (parts == null) return _buildNoTests();
                final isPremiumUser = isPremiumAsync.valueOrNull ?? false;
                return _buildReadingContent(
                  context,
                  ref,
                  parts,
                  isPremiumUser: isPremiumUser,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingContent(
    BuildContext context,
    WidgetRef ref,
    List<PracticePartData> parts, {
    required bool isPremiumUser,
  }) {
    final wrongIdsAsync = ref.watch(wrongReadingQuestionIdsProvider);
    final wrongCount = wrongIdsAsync.valueOrNull?.length ?? 0;
    final totalQuestions = parts.fold(0, (s, p) => s + p.totalQuestions);
    final totalAnswered = parts.fold(0, (s, p) => s + p.totalAnswered);
    final correctAnswers = parts.fold(0, (s, p) => s + p.correctAnswers);
    final progressPercent = totalQuestions > 0
        ? correctAnswers / totalQuestions * 100
        : 0.0;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.refresh(readingPracticePartsProvider.future),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            StatsCard(
              icon: Icons.menu_book,
              totalAnswered: totalAnswered,
              correctAnswers: correctAnswers,
              progressPercent: progressPercent,
            ),
            const SizedBox(height: 20),
            MistakePracticeCard(
              subtitle: 'Tổng số câu sai: $wrongCount',
              onTap: () async {
                final wrongIds =
                    await ref.read(wrongReadingQuestionIdsProvider.future);
                if (wrongIds.isEmpty) {
                  if (context.mounted) {
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
                  }
                  return;
                }

                if (!context.mounted) return;
                context.push('/practice/reading-question', extra: {
                  'testId': parts.first.testId,
                  'partTitle': 'Luyện tập câu sai',
                  'questionIds': wrongIds,
                  'randomizeQuestions': false,
                });
              },
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Các phần thi',
                style: GoogleFonts.lexend(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSlate800,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...parts.asMap().entries.map((entry) {
              final index = entry.key;
              final part = entry.value;
              final isLocked = part.isLocked || (!isPremiumUser && index > 0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PartListItem(
                  part: PracticePart(
                    title: part.title,
                    icon: part.icon,
                    iconBgColor: part.iconBgColor,
                    iconColor: part.iconColor,
                    totalQuestions: part.totalQuestions,
                    correctAnswers: part.correctAnswers,
                    progressPercent: part.progressPercent,
                    isLocked: isLocked,
                  ),
                  onTap: isLocked
                      ? null
                      : () => context.push('/practice/part-intro', extra: part),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNoTests() => _buildErrorWidget(
    Icons.library_books_outlined,
    'Chưa có đề thi nào',
    'Cần có ít nhất một đề Fulltest trong database\nđể bắt đầu luyện tập.',
  );

  Widget _buildError(String message) => _buildErrorWidget(
    Icons.error_outline,
    'Lỗi tải dữ liệu',
    message,
    iconColor: const Color(0xFFDC2626),
    titleColor: const Color(0xFFDC2626),
  );

  Widget _buildErrorWidget(
    IconData icon,
    String title,
    String subtitle, {
    Color iconColor = AppColors.textSlate300,
    Color titleColor = AppColors.textSlate600,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: iconColor),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.lexend(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                fontSize: 14,
                color: AppColors.textSlate400,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Writing — DB-backed ───────────────────────────────────────
class _WritingPracticePage extends ConsumerWidget {
  const _WritingPracticePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partsAsync = ref.watch(writingPartsProvider);
    final isPremiumAsync = ref.watch(isPremiumProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          _buildAppBar(context, 'Viết'),
          Expanded(
            child: partsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Lỗi: $e',
                  style: GoogleFonts.lexend(color: AppColors.textSlate500),
                ),
              ),
              data: (parts) {
                final isPremiumUser = isPremiumAsync.valueOrNull ?? false;
                return _buildWritingContent(
                  context,
                  ref,
                  parts,
                  isPremiumUser: isPremiumUser,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWritingContent(
    BuildContext context,
    WidgetRef ref,
    List<PracticePartData> parts, {
    required bool isPremiumUser,
  }) {
    final totalQuestions = parts.fold(0, (s, p) => s + p.totalQuestions);
    final totalAnswered = parts.fold(0, (s, p) => s + p.totalAnswered);
    final progressPercent = totalQuestions > 0
        ? totalAnswered / totalQuestions * 100
        : 0.0;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.refresh(writingPartsProvider.future),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            StatsCard(
              icon: Icons.edit_note,
              totalAnswered: totalAnswered,
              correctAnswers: 0,
              progressPercent: progressPercent,
            ),
            const SizedBox(height: 20),
            const MistakePracticeCard(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Các phần thi',
                style: GoogleFonts.lexend(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSlate800,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...parts.asMap().entries.map((entry) {
              final index = entry.key;
              final part = entry.value;
              final isLocked = part.isLocked || (!isPremiumUser && index > 0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PartListItem(
                  part: PracticePart(
                    title: part.title,
                    icon: part.icon,
                    iconBgColor: part.iconBgColor,
                    iconColor: part.iconColor,
                    totalQuestions: part.totalQuestions,
                    correctAnswers: 0,
                    progressPercent: part.progressPercent,
                    isLocked: isLocked,
                  ),
                  onTap: isLocked
                      ? null
                      : () => context.push('/practice/part-intro', extra: part),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Listening — DB-backed ─────────────────────────────────────
class _ListeningPracticePage extends ConsumerWidget {
  const _ListeningPracticePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partsAsync = ref.watch(listeningPracticePartsProvider);
    final isPremiumAsync = ref.watch(isPremiumProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          _buildAppBar(context, 'Nghe Hiểu'),
          Expanded(
            child: partsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => _buildError(e.toString()),
              data: (parts) {
                if (parts == null) return _buildNoTests();
                final isPremiumUser = isPremiumAsync.valueOrNull ?? false;
                return _buildContent(
                  context,
                  ref,
                  parts,
                  isPremiumUser: isPremiumUser,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<PracticePartData> parts, {
    required bool isPremiumUser,
  }) {
    final wrongIdsAsync = ref.watch(wrongListeningQuestionIdsProvider);
    final wrongCount = wrongIdsAsync.valueOrNull?.length ?? 0;
    final totalQuestions = parts.fold(0, (s, p) => s + p.totalQuestions);
    final totalAnswered = parts.fold(0, (s, p) => s + p.totalAnswered);
    final correctAnswers = parts.fold(0, (s, p) => s + p.correctAnswers);
    final progressPercent = totalQuestions > 0
        ? correctAnswers / totalQuestions * 100
        : 0.0;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.refresh(listeningPracticePartsProvider.future),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            StatsCard(
              icon: Icons.headphones,
              totalAnswered: totalAnswered,
              correctAnswers: correctAnswers,
              progressPercent: progressPercent,
            ),
            const SizedBox(height: 20),
            MistakePracticeCard(
              subtitle: 'Tổng số câu sai: $wrongCount',
              onTap: () async {
                final wrongIds =
                    await ref.read(wrongListeningQuestionIdsProvider.future);
                if (wrongIds.isEmpty) {
                  if (context.mounted) {
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
                  }
                  return;
                }

                if (!context.mounted) return;
                context.push('/exam/question', extra: {
                  'testId': parts.first.testId,
                  'testTitle': 'Luyện tập câu sai',
                  'isPracticeMode': true,
                  'questionIds': wrongIds,
                  'randomizeQuestions': false,
                });
              },
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Các phần thi',
                style: GoogleFonts.lexend(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSlate800,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...parts.asMap().entries.map((entry) {
              final index = entry.key;
              final part = entry.value;
              final isLocked = part.isLocked || (!isPremiumUser && index > 0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PartListItem(
                  part: PracticePart(
                    title: part.title,
                    icon: part.icon,
                    iconBgColor: part.iconBgColor,
                    iconColor: part.iconColor,
                    totalQuestions: part.totalQuestions,
                    correctAnswers: part.correctAnswers,
                    progressPercent: part.progressPercent,
                    isLocked: isLocked,
                  ),
                  onTap: isLocked
                      ? null
                      : () => context.push('/practice/part-intro', extra: part),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNoTests() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.library_books_outlined,
              size: 64,
              color: AppColors.textSlate300,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có đề thi nào',
              style: GoogleFonts.lexend(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textSlate600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cần có ít nhất một đề Fulltest trong database\nđể bắt đầu luyện tập.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                fontSize: 14,
                color: AppColors.textSlate400,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Color(0xFFDC2626)),
            const SizedBox(height: 16),
            Text(
              'Lỗi tải dữ liệu',
              style: GoogleFonts.lexend(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                fontSize: 12,
                color: AppColors.textSlate500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Static page (Reading / Speaking / Writing) ────────────────
class _StaticSkillPage extends ConsumerWidget {
  final SkillConfig config;

  const _StaticSkillPage({required this.config});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremiumUser = ref.watch(isPremiumProvider).valueOrNull ?? false;
    final displayParts = config.parts.asMap().entries.map((entry) {
      final index = entry.key;
      final part = entry.value;
      return PracticePart(
        title: part.title,
        icon: part.icon,
        iconBgColor: part.iconBgColor,
        iconColor: part.iconColor,
        totalQuestions: part.totalQuestions,
        correctAnswers: part.correctAnswers,
        progressPercent: part.progressPercent,
        isLocked: part.isLocked || (!isPremiumUser && index > 0),
      );
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          _buildAppBar(context, config.title),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  StatsCard(icon: config.headerIcon),
                  const SizedBox(height: 20),
                  const MistakePracticeCard(),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Các phần thi',
                      style: GoogleFonts.lexend(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSlate800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...displayParts.map(
                    (part) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: PartListItem(
                        part: part,
                        onTap: part.isLocked
                            ? null
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Tính năng đang phát triển',
                                      style: GoogleFonts.lexend(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    backgroundColor: AppColors.primary,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared AppBar builder ─────────────────────────────────────
Widget _buildAppBar(BuildContext context, String title) {
  return Container(
    decoration: BoxDecoration(
      color: AppColors.primary,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(16),
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
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
        child: Row(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.pop(),
                borderRadius: BorderRadius.circular(9999),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 40),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lexend(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
