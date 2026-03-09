import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/practice/data/models/writing_prompt_model.dart';

class WritingResultPage extends StatelessWidget {
  final String partTitle;
  final List<WritingPromptModel> prompts;
  final Map<String, String> userAnswers; // promptId → answer

  const WritingResultPage({
    super.key,
    required this.partTitle,
    required this.prompts,
    required this.userAnswers,
  });

  @override
  Widget build(BuildContext context) {
    final answeredCount =
        prompts.where((p) => userAnswers.containsKey(p.id)).length;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(answeredCount),
                  const SizedBox(height: 24),
                  Text(
                    'Chi tiết câu trả lời',
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSlate800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(
                    prompts.length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _buildAnswerCard(i, prompts[i]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomBar(context),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
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
                  onTap: () => context.go('/practice/writing'),
                  borderRadius: BorderRadius.circular(9999),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.home_outlined,
                        color: Colors.white, size: 26),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Kết quả',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lexend(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 44),
            ],
          ),
        ),
      ),
    );
  }

  // ── Summary card ──────────────────────────────────────────────

  Widget _buildSummaryCard(int answeredCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(Icons.edit_note,
                  color: AppColors.primary, size: 36),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partTitle,
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSlate800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đã hoàn thành $answeredCount/${prompts.length} câu',
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    color: AppColors.textSlate500,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: prompts.isNotEmpty
                        ? answeredCount / prompts.length
                        : 0,
                    minHeight: 6,
                    backgroundColor: AppColors.slate200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Per-question answer card ──────────────────────────────────

  Widget _buildAnswerCard(int index, WritingPromptModel prompt) {
    final userAnswer = userAnswers[prompt.id];
    final hasAnswer =
        userAnswer != null && userAnswer.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question number header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.lexend(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    prompt.title ??
                        _defaultSectionTitle(prompt.partNumber),
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSlate600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User's answer
                _buildAnswerBlock(
                  label: 'Câu trả lời của bạn',
                  content: userAnswer ?? '(Chưa trả lời)',
                  color: hasAnswer
                      ? const Color(0xFF166534)
                      : AppColors.textSlate400,
                  bgColor: hasAnswer
                      ? const Color(0xFFF0FDF4)
                      : AppColors.backgroundLight,
                  borderColor: hasAnswer
                      ? const Color(0xFF86EFAC)
                      : AppColors.borderSlate200,
                  icon: hasAnswer
                      ? Icons.check_circle_outline
                      : Icons.radio_button_unchecked,
                ),
                // Model answer
                if (prompt.modelAnswer != null &&
                    prompt.modelAnswer!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildAnswerBlock(
                    label: 'Câu trả lời mẫu',
                    content: prompt.modelAnswer!,
                    color: const Color(0xFF1D4ED8),
                    bgColor: const Color(0xFFEFF6FF),
                    borderColor: const Color(0xFF93C5FD),
                    icon: Icons.lightbulb_outline,
                  ),
                ],
                // Hint words
                if (prompt.hintWords != null &&
                    prompt.hintWords!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildHintChips(prompt.hintWords!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerBlock({
    required String label,
    required String content,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.lexend(
              fontSize: 14,
              height: 1.6,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintChips(String hintWords) {
    final hints = hintWords.split(',').map((h) => h.trim()).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Từ gợi ý',
          style: GoogleFonts.lexend(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSlate500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: hints
              .map(
                (h) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.teal50,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    h,
                    style: GoogleFonts.lexend(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 20 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => context.go('/practice/writing'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            elevation: 4,
            shadowColor: AppColors.primary.withValues(alpha: 0.4),
          ),
          child: Text(
            'Hoàn thành',
            style: GoogleFonts.lexend(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────

  String _defaultSectionTitle(int partNumber) {
    switch (partNumber) {
      case 1:
        return 'Mô tả tranh';
      case 2:
        return 'Phản hồi yêu cầu';
      case 3:
        return 'Viết luận';
      default:
        return 'Câu hỏi';
    }
  }
}
