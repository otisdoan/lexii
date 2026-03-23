import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/practice/data/models/writing_prompt_model.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexii/features/practice/presentation/providers/practice_providers.dart';
import 'package:lexii/features/practice/data/repositories/speaking_writing_repository.dart'
    show AiScoreBundle;

class WritingResultPage extends ConsumerStatefulWidget {
  final String partTitle;
  final List<WritingPromptModel> prompts;
  final Map<String, String> userAnswers;

  const WritingResultPage({
    super.key,
    required this.partTitle,
    required this.prompts,
    required this.userAnswers,
  });

  @override
  ConsumerState<WritingResultPage> createState() => _WritingResultPageState();
}

class _WritingResultPageState extends ConsumerState<WritingResultPage> {
  final Map<String, AiScoreBundle> _aiResults = {};
  final Map<String, bool> _evaluating = {};

  Future<void> _evaluateAnswer(WritingPromptModel prompt) async {
    final answer = widget.userAnswers[prompt.id];
    if (answer == null || answer.trim().isEmpty) return;

    if (_evaluating[prompt.id] == true) return;

    setState(() {
      _evaluating[prompt.id] = true;
    });

    final repo = ref.read(speakingWritingRepositoryProvider);
    try {
      final taskType = 'writing_${prompt.partNumber}';
      final ai = await repo
          .evaluateWritingByGemini(
            taskType: taskType,
            prompt: prompt.prompt.isNotEmpty
                ? prompt.prompt
                : prompt.title ?? '',
            answer: answer,
          )
          .timeout(const Duration(seconds: 25));

      if (mounted) {
        setState(() {
          _aiResults[prompt.id] = ai;
        });
      }
    } catch (_) {
      try {
        final taskType = 'writing_${prompt.partNumber}';
        final ai = repo.evaluateWritingByAi(
          taskType: taskType,
          prompt: prompt.prompt.isNotEmpty ? prompt.prompt : prompt.title ?? '',
          answer: answer,
        );
        if (mounted) {
          setState(() {
            _aiResults[prompt.id] = ai;
          });
        }
      } catch (_) {}
    } finally {
      if (mounted) {
        setState(() {
          _evaluating[prompt.id] = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final answeredCount = widget.prompts
        .where((p) => widget.userAnswers.containsKey(p.id))
        .length;

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
                    widget.prompts.length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _buildAnswerCard(i, widget.prompts[i]),
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
                  onTap: () {
                    ref.invalidate(writingPartsProvider);
                    context.go('/practice/writing');
                  },
                  borderRadius: BorderRadius.circular(9999),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.home_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
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
              child: Icon(Icons.edit_note, color: AppColors.primary, size: 36),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.partTitle,
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSlate800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đã hoàn thành $answeredCount/${widget.prompts.length} câu',
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    color: AppColors.textSlate500,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: widget.prompts.isNotEmpty
                        ? answeredCount / widget.prompts.length
                        : 0,
                    minHeight: 6,
                    backgroundColor: AppColors.slate200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
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
    final userAnswer = widget.userAnswers[prompt.id];
    final hasAnswer = userAnswer != null && userAnswer.trim().isNotEmpty;

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
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSlate800,
                      ),
                    ),
                  ),
                ),
                if (hasAnswer &&
                    _aiResults[prompt.id] == null &&
                    _evaluating[prompt.id] != true)
                  TextButton.icon(
                    onPressed: () => _evaluateAnswer(prompt),
                    icon: const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFFF97316),
                      size: 16,
                    ),
                    label: Text(
                      'Chấm bằng AI',
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: const Color(0xFFC2410C),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                if (_evaluating[prompt.id] == true)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFF97316),
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    prompt.title ?? _defaultSectionTitle(prompt.partNumber),
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
                if (hasAnswer && _aiResults[prompt.id] != null) ...[
                  const SizedBox(height: 16),
                  _buildAiFeedbackCard(_aiResults[prompt.id]!),
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
            style: GoogleFonts.lexend(fontSize: 14, height: 1.6, color: color),
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
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.teal50,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
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

  Widget _buildAiFeedbackCard(AiScoreBundle ai) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFEDD5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFFEA580C),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Nhận xét từ AI',
                style: GoogleFonts.lexend(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF9A3412),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ai.feedback,
            style: GoogleFonts.lexend(
              fontSize: 14,
              height: 1.6,
              color: const Color(0xFF9A3412),
            ),
          ),
          if (ai.errors.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFEDD5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.rule,
                        color: Color(0xFF9A3412),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Các lỗi cần lưu ý',
                        style: GoogleFonts.lexend(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF9A3412),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ai.errors.join('\n- '),
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      height: 1.5,
                      color: const Color(0xFFC2410C),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (ai.correctedVersion.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFDCFCE7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFF16A34A),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Phiên bản cải thiện',
                        style: GoogleFonts.lexend(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ai.correctedVersion,
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      height: 1.5,
                      color: const Color(0xFF16A34A),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
