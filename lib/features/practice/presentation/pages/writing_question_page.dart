import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/practice/data/models/writing_prompt_model.dart';
import 'package:lexii/features/practice/presentation/providers/practice_providers.dart';

class WritingQuestionPage extends ConsumerStatefulWidget {
  final int partNumber;
  final String partTitle;
  final int? questionLimit;

  const WritingQuestionPage({
    super.key,
    required this.partNumber,
    required this.partTitle,
    this.questionLimit,
  });

  @override
  ConsumerState<WritingQuestionPage> createState() =>
      _WritingQuestionPageState();
}

class _WritingQuestionPageState extends ConsumerState<WritingQuestionPage> {
  int _currentIndex = 0;

  /// promptId → user's typed answer
  final Map<String, String> _answers = {};
  final TextEditingController _controller = TextEditingController();
  bool _submitting = false;
  List<WritingPromptModel>? _loadedPrompts;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveCurrentAnswer(WritingPromptModel prompt) {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      _answers[prompt.id] = text;
    }
  }

  void _loadAnswerForIndex(List<WritingPromptModel> prompts, int index) {
    final existing = _answers[prompts[index].id] ?? '';
    _controller.text = existing;
  }

  @override
  Widget build(BuildContext context) {
    final writingRepo = ref.watch(writingRepositoryProvider);

    // We use a FutureProvider-like pattern manually to avoid re-reading
    return FutureBuilder<List<WritingPromptModel>>(
      future: _loadedPrompts == null
          ? writingRepo
                .getPromptsForPart(
                  widget.partNumber,
                  limit: widget.questionLimit,
                )
                .then((p) {
                  _loadedPrompts = p;
                  return p;
                })
          : Future.value(_loadedPrompts),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _loadedPrompts == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'Lỗi: ${snapshot.error}',
                style: GoogleFonts.lexend(color: AppColors.textSlate500),
              ),
            ),
          );
        }

        final prompts = snapshot.data ?? _loadedPrompts ?? [];

        if (prompts.isEmpty) {
          return _buildEmpty(context);
        }

        final prompt = prompts[_currentIndex];

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _showExitDialog(prompts);
          },
          child: Scaffold(
            backgroundColor: AppColors.backgroundLight,
            body: Column(
              children: [
                _buildHeader(context, prompts, prompt),
                _buildProgressBar(_currentIndex + 1, prompts.length),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(prompt),
                        const SizedBox(height: 16),
                        _buildPromptContent(prompt),
                        const SizedBox(height: 20),
                        _buildAnswerArea(prompt),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
                _buildBottomBar(context, prompts, prompt),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Header ────────────────────────────────────────────────────

  Widget _buildHeader(
    BuildContext context,
    List<WritingPromptModel> prompts,
    WritingPromptModel current,
  ) {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showExitDialog(prompts),
                  borderRadius: BorderRadius.circular(9999),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Câu ${_currentIndex + 1}',
                style: GoogleFonts.lexend(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.report_problem_outlined,
                color: Colors.white.withValues(alpha: 0.8),
                size: 20,
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.settings_outlined,
                color: Colors.white.withValues(alpha: 0.8),
                size: 20,
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.favorite_border,
                color: Colors.white.withValues(alpha: 0.8),
                size: 20,
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  'Giải thích',
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(int current, int total) {
    return Container(
      color: AppColors.primary,
      child: LinearProgressIndicator(
        value: total > 0 ? current / total : 0,
        backgroundColor: Colors.white.withValues(alpha: 0.3),
        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xCCFFFFFF)),
        minHeight: 6,
      ),
    );
  }

  // ── Section title ─────────────────────────────────────────────

  Widget _buildSectionTitle(WritingPromptModel prompt) {
    final String title;
    if (prompt.title != null && prompt.title!.isNotEmpty) {
      title = prompt.title!;
    } else {
      switch (prompt.partNumber) {
        case 1:
          title = 'Mô tả tranh';
        case 2:
          title = 'Phản hồi yêu cầu';
        case 3:
          title = 'Viết luận';
        default:
          title = 'Viết câu trả lời';
      }
    }

    return Text(
      title,
      style: GoogleFonts.lexend(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textSlate800,
      ),
    );
  }

  // ── Prompt content (image / passage / text) ───────────────────

  Widget _buildPromptContent(WritingPromptModel prompt) {
    final widgets = <Widget>[];

    // Image card (Part 1)
    if (prompt.imageUrl != null && prompt.imageUrl!.isNotEmpty) {
      widgets.add(
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CachedNetworkImage(
              imageUrl: prompt.imageUrl!,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                height: 220,
                color: AppColors.backgroundLight,
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                height: 220,
                color: AppColors.backgroundLight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: AppColors.textSlate300,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      prompt.title ?? 'Hình ảnh',
                      style: GoogleFonts.lexend(
                        color: AppColors.textSlate400,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      if (prompt.title != null) {
        widgets.add(const SizedBox(height: 8));
        widgets.add(
          Center(
            child: Text(
              prompt.title!,
              style: GoogleFonts.lexend(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textSlate500,
              ),
            ),
          ),
        );
      }
    }

    // Passage / email card (Part 2 / 3)
    if (prompt.passageText != null && prompt.passageText!.isNotEmpty) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 16));
      if (prompt.passageSubject != null) {
        widgets.add(
          Text(
            prompt.passageSubject!,
            style: GoogleFonts.lexend(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSlate500,
            ),
          ),
        );
        widgets.add(const SizedBox(height: 8));
      }
      widgets.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            prompt.passageText!,
            style: GoogleFonts.lexend(
              fontSize: 14,
              height: 1.7,
              color: const Color(0xFF333333),
            ),
          ),
        ),
      );
    }

    // Prompt instruction
    if (prompt.prompt.isNotEmpty && widgets.isNotEmpty) {
      widgets.add(const SizedBox(height: 12));
    }
    if (prompt.prompt.isNotEmpty) {
      widgets.add(
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  prompt.prompt,
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textSlate600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  // ── Answer text area ──────────────────────────────────────────

  Widget _buildAnswerArea(WritingPromptModel prompt) {
    // Restore saved answer for current prompt
    final saved = _answers[prompt.id] ?? '';
    if (_controller.text != saved && !_controller.text.contains(saved)) {
      // Only sync on first load for this prompt
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSlate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        maxLines: 8,
        minLines: 5,
        style: GoogleFonts.lexend(
          fontSize: 14,
          height: 1.6,
          color: AppColors.textSlate800,
        ),
        decoration: InputDecoration(
          hintText: 'Viết câu trả lời của bạn',
          hintStyle: GoogleFonts.lexend(
            color: AppColors.textSlate400,
            fontSize: 14,
          ),
          contentPadding: const EdgeInsets.all(16),
          border: InputBorder.none,
        ),
        onChanged: (text) => _answers[prompt.id] = text,
        textInputAction: TextInputAction.newline,
      ),
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────

  Widget _buildBottomBar(
    BuildContext context,
    List<WritingPromptModel> prompts,
    WritingPromptModel current,
  ) {
    final isLast = _currentIndex == prompts.length - 1;

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
          onPressed: _submitting
              ? null
              : () => isLast
                    ? _submit(prompts, current)
                    : _goNext(prompts, current),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.textSlate300,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            elevation: 4,
            shadowColor: AppColors.primary.withValues(alpha: 0.4),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  isLast ? 'Nộp bài' : 'Tiếp tục',
                  style: GoogleFonts.lexend(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }

  // ── Navigation ────────────────────────────────────────────────

  void _goNext(List<WritingPromptModel> prompts, WritingPromptModel current) {
    _saveCurrentAnswer(current);
    setState(() {
      _currentIndex++;
      _loadAnswerForIndex(prompts, _currentIndex);
    });
  }

  Future<void> _submit(
    List<WritingPromptModel> prompts,
    WritingPromptModel current,
  ) async {
    _saveCurrentAnswer(current);
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final repo = ref.read(writingRepositoryProvider);
      await repo.submitBatch(widget.partNumber, _answers);
      ref.invalidate(writingPartsProvider);
    } catch (_) {
      // Non-fatal
    }

    if (!mounted) return;
    context.pushReplacement(
      '/practice/writing-result',
      extra: {
        'partTitle': widget.partTitle,
        'prompts': prompts,
        'userAnswers': Map<String, String>.from(_answers),
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────

  Scaffold _buildEmpty(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.edit_off,
                size: 64,
                color: AppColors.textSlate300,
              ),
              const SizedBox(height: 16),
              Text(
                'Chưa có đề bài',
                style: GoogleFonts.lexend(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSlate600,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitDialog(List<WritingPromptModel> prompts) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Thoát luyện tập?',
          style: GoogleFonts.lexend(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Tiến trình của bạn sẽ không được lưu.',
          style: GoogleFonts.lexend(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Tiếp tục làm',
              style: GoogleFonts.lexend(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: Text(
              'Thoát',
              style: GoogleFonts.lexend(color: AppColors.red600),
            ),
          ),
        ],
      ),
    );
  }
}
