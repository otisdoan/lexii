import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/exam/data/models/question_model.dart';
import 'package:lexii/features/exam/presentation/providers/test_providers.dart';

class PracticePartResultPage extends ConsumerWidget {
  final String testId;
  final String partId;
  final String partTitle;
  final String section;
  final int correct;
  final int total;
  final Map<int, int> userAnswers;
  final List<QuestionModel>? questionsOverride;

  const PracticePartResultPage({
    super.key,
    required this.testId,
    required this.partId,
    required this.partTitle,
    this.section = 'listening',
    required this.correct,
    required this.total,
    required this.userAnswers,
    this.questionsOverride,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final percent = total > 0 ? (correct / total * 100).round() : 0;

    if (questionsOverride != null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: _buildBody(context, percent, questionsOverride!),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(context),
      );
    }

    final questionsAsync = ref.watch(questionsByPartIdProvider(partId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          _buildAppBar(context),
          Expanded(
            child: questionsAsync.when(
              loading: () => _buildBody(context, percent, []),
              error: (_, _) => _buildBody(context, percent, []),
              data: (questions) => _buildBody(context, percent, questions),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context) {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.pop(),
                  borderRadius: BorderRadius.circular(999),
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 40),
                  child: Text(
                    'Kết quả',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lexend(
                      fontSize: 17,
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

  // ── Body ──────────────────────────────────────────────────────

  Widget _buildBody(
      BuildContext context, int percent, List<QuestionModel> questions) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _buildSummaryCard(percent),
        const SizedBox(height: 12),
        _buildScoreCard(percent),
        const SizedBox(height: 12),
        _buildChart(percent),
        const SizedBox(height: 12),
        _buildWrongQuestionsSection(context, questions),
      ],
    );
  }

  // ── Summary card ─────────────────────────────────────────────

  Widget _buildSummaryCard(int percent) {
    final (evalText, evalColor) = _evaluation(percent);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration,
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: const Center(
              child: Icon(
                Icons.emoji_events_rounded,
                size: 36,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bạn đã hoàn thành bài luyện tập',
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    color: AppColors.textSlate600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  partTitle,
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF97316),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  evalText,
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    color: evalColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Score card ───────────────────────────────────────────────

  Widget _buildScoreCard(int percent) {
    final isGood = percent >= 60;
    final badgeText = '$percent%';
    final textColor = isGood ? AppColors.green600 : AppColors.red500;
    final bgColor = isGood ? AppColors.green100 : AppColors.red100;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kết quả: $correct/$total',
                style: GoogleFonts.lexend(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSlate800,
                ),
              ),
              _badge(badgeText, textColor, bgColor),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              height: 1,
              color: AppColors.slate100,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tỷ lệ trung bình của bạn:',
                style: GoogleFonts.lexend(
                  fontSize: 13,
                  color: AppColors.textSlate500,
                ),
              ),
              _badge(badgeText, textColor, bgColor),
            ],
          ),
        ],
      ),
    );
  }

  // ── Performance chart ─────────────────────────────────────────

  Widget _buildChart(int percent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THỐNG KÊ HIỆU SUẤT',
            style: GoogleFonts.lexend(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSlate400,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Y-axis label
                SizedBox(
                  width: 36,
                  child: Align(
                    alignment: Alignment(
                        0, 1 - 2 * (percent / 100).clamp(0.0, 1.0)),
                    child: Text(
                      '$percent%',
                      style: GoogleFonts.lexend(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                // Chart canvas
                Expanded(
                  child: CustomPaint(
                    painter: _ChartPainter(percent: percent / 100),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Tỉ lệ / Lần thử',
              style: GoogleFonts.lexend(
                fontSize: 10,
                color: AppColors.textSlate400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Wrong questions section ──────────────────────────────────

  Widget _buildWrongQuestionsSection(
      BuildContext context, List<QuestionModel> questions) {
    final wrongItems =
        questions.isEmpty ? <_WrongItem>[] : _buildWrongList(questions);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              'Danh sách câu hỏi sai:',
              style: GoogleFonts.lexend(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textSlate800,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.slate100),
          if (questions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Đang tải danh sách câu hỏi...',
                style: GoogleFonts.lexend(
                  fontSize: 13,
                  color: AppColors.textSlate500,
                ),
              ),
            )
          else if (wrongItems.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Không có câu sai! Xuất sắc 🎉',
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  color: AppColors.green600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            ...wrongItems.take(5).map(
                  (item) => _buildWrongItem(context, item),
                ),
          if (questions.isNotEmpty)
            Material(
              color: const Color(0xFFFFFBEB),
              child: InkWell(
                onTap: () => context.push('/exam/answer-review', extra: {
                  'testId': testId,
                  'testTitle': partTitle,
                  'userAnswers': userAnswers,
                  'section': section,
                  'partId': partId.isNotEmpty ? partId : null,
                  'questionIds': questions.map((q) => q.id).toList(),
                }),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Xem tất cả câu trả lời',
                        style: GoogleFonts.lexend(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.amber600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: AppColors.amber600,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWrongItem(BuildContext context, _WrongItem item) {
    final letter = item.correctOptionIndex >= 0
        ? String.fromCharCode(65 + item.correctOptionIndex)
        : '?';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: partId.isEmpty
            ? null
            : () => context.push('/exam/answer-detail', extra: {
                  'testId': testId,
                  'testTitle': partTitle,
                  'questionIndex': item.questionIndex,
                  'userAnswers': userAnswers,
                  'partId': partId,
                }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            border:
                Border(bottom: BorderSide(color: AppColors.slate100)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Câu hỏi: ${item.displayNumber} — Đáp án đúng: $letter',
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    color: AppColors.textSlate600,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textSlate300,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.pop(),
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
                'Tiếp tục',
                style: GoogleFonts.lexend(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              // Pop result page, then pop intro page → lands on practice list
              context.pop();
              context.pop();
            },
            child: Text(
              'Luyện tập các loại bài khác',
              style: GoogleFonts.lexend(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────

  static BoxDecoration get _cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  static Widget _badge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.lexend(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  static (String, Color) _evaluation(int percent) {
    if (percent >= 80) {
      return ('Xuất sắc! Tiếp tục phát huy.', AppColors.green600);
    }
    if (percent >= 60) {
      return ('Khá tốt! Hãy cố gắng hơn.', AppColors.primary);
    }
    if (percent >= 40) {
      return ('Cần cố gắng thêm.', AppColors.amber600);
    }
    return ('Bạn cần cố gắng hơn nữa', AppColors.red500);
  }

  List<_WrongItem> _buildWrongList(List<QuestionModel> questions) {
    final wrong = <_WrongItem>[];
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final selected = userAnswers[i];
      final isCorrect = selected != null &&
          selected < q.options.length &&
          q.options[selected].isCorrect;
      if (!isCorrect) {
        int correctIdx = -1;
        for (int j = 0; j < q.options.length; j++) {
          if (q.options[j].isCorrect) {
            correctIdx = j;
            break;
          }
        }
        wrong.add(_WrongItem(
          questionIndex: i,
          displayNumber: '${i + 1}',
          correctOptionIndex: correctIdx,
        ));
      }
    }
    return wrong;
  }
}

// ── Data classes ──────────────────────────────────────────────

class _WrongItem {
  final int questionIndex;
  final String displayNumber;
  final int correctOptionIndex;

  const _WrongItem({
    required this.questionIndex,
    required this.displayNumber,
    required this.correctOptionIndex,
  });
}

// ── Chart painter ─────────────────────────────────────────────

class _ChartPainter extends CustomPainter {
  final double percent; // 0..1

  const _ChartPainter({required this.percent});

  @override
  void paint(Canvas canvas, Size size) {
    final p = percent.clamp(0.0, 1.0);
    final axisColor = const Color(0xFFE2E8F0);
    final dotColor = AppColors.primary;

    // Axes
    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(0, size.height), axisPaint);
    canvas.drawLine(
        Offset(0, size.height), Offset(size.width, size.height), axisPaint);

    // Dashed horizontal line at percentage height
    final y = size.height * (1 - p);
    final dashPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.4)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    double dashX = 0;
    while (dashX < size.width) {
      canvas.drawLine(
        Offset(dashX, y),
        Offset((dashX + 8).clamp(0, size.width), y),
        dashPaint,
      );
      dashX += 14;
    }

    // Dot at x=30%
    final dotX = size.width * 0.3;
    // Outer glow
    canvas.drawCircle(
      Offset(dotX, y),
      10,
      Paint()
        ..color = dotColor.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );
    // Filled dot
    canvas.drawCircle(
      Offset(dotX, y),
      5,
      Paint()
        ..color = dotColor
        ..style = PaintingStyle.fill,
    );
    // White ring inside
    canvas.drawCircle(
      Offset(dotX, y),
      5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.percent != percent;
}
