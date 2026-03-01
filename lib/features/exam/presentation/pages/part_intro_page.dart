import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/exam/data/models/test_part_model.dart';
import 'package:lexii/features/exam/presentation/providers/test_providers.dart';

// ─── TOEIC Part metadata (hardcoded — standardized across all TOEIC tests) ──────
class _PartMeta {
  final String name;
  final List<String> tips;
  const _PartMeta(this.name, this.tips);
}

const _partMeta = {
  1: _PartMeta('PHOTOGRAPHS', [
    'Nghe kỹ từng câu mô tả — mỗi câu chỉ được phát một lần.',
    'Tập trung vào chủ thể chính và hành động trong ảnh.',
    'Loại trừ những đáp án mô tả sai đối tượng hoặc hành động.',
  ]),
  2: _PartMeta('QUESTION—RESPONSE', [
    'Nghe kỹ câu hỏi để xác định dạng câu (What / Where / When / Who...).',
    'Chọn câu trả lời phù hợp nhất, không nhất thiết phải nhắc lại từ trong câu hỏi.',
    'Cẩn thận với các câu trả lời "bẫy" dùng cùng từ nhưng nghĩa lệch.',
  ]),
  3: _PartMeta('CONVERSATIONS', [
    'Đọc câu hỏi trước khi nghe để biết cần tìm thông tin gì.',
    'Chú ý mối quan hệ giữa các nhân vật và mục đích cuộc trò chuyện.',
    'Đôi khi câu trả lời được ngụ ý, không được nói trực tiếp.',
  ]),
  4: _PartMeta('TALKS', [
    'Đọc câu hỏi trước — đây là bài monologue nên thông tin đến theo thứ tự.',
    'Chú ý các từ chỉ mục đích: "The purpose of this announcement is...".',
    'Ghi nhớ các con số, địa điểm và thời gian nếu câu hỏi hỏi về chúng.',
  ]),
  5: _PartMeta('INCOMPLETE SENTENCES', [
    'Xác định loại từ cần điền (danh từ, động từ, tính từ, trạng từ).',
    'Chú ý thì động từ và sự kết hợp từ (collocation).',
    'Đọc cả câu để hiểu ngữ nghĩa trước khi chọn đáp án.',
  ]),
  6: _PartMeta('TEXT COMPLETION', [
    'Đọc lướt toàn bộ đoạn văn trước để nắm ý chính.',
    'Chú ý sự liên kết logic giữa các câu khi điền.',
    'Một số ô trống yêu cầu chọn cả câu — đọc cẩn thận ngữ cảnh.',
  ]),
  7: _PartMeta('READING COMPREHENSION', [
    'Đọc câu hỏi trước để biết cần tìm gì trong bài đọc.',
    'Không cần đọc từng từ — skimming và scanning hiệu quả hơn.',
    'Câu hỏi NOT/EXCEPT: tìm đáp án sai thay vì đúng.',
  ]),
};

class PartIntroPage extends ConsumerWidget {
  final String testId;
  final String testTitle;

  /// Số thứ tự Part (1–7). Mặc định = 1
  final int partNumber;

  /// Nếu true → "Bắt đầu" sẽ pop() về màn hình đang chờ thay vì push /exam/question
  final bool isResume;

  const PartIntroPage({
    super.key,
    required this.testId,
    required this.testTitle,
    this.partNumber = 1,
    this.isResume = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partsAsync = ref.watch(testPartsProvider(testId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: partsAsync.when(
        loading: () => _buildShell(context, part: null, isLoading: true),
        error: (err, _) =>
            _buildShell(context, part: null, errorMessage: err.toString()),
        data: (parts) {
          final part = parts.where((p) => p.partNumber == partNumber).firstOrNull;
          return _buildShell(context, part: part);
        },
      ),
    );
  }

  Widget _buildShell(
    BuildContext context, {
    required TestPartModel? part,
    bool isLoading = false,
    String? errorMessage,
  }) {
    final meta = _partMeta[partNumber] ?? _partMeta[1]!;
    final partName = meta.name;
    final tips = meta.tips;
    final questionCount = part?.questionCount ?? 0;
    // DB instructions override tips description only if set
    final description = (part?.instructions?.isNotEmpty == true)
        ? part!.instructions!
        : _defaultDescription(partNumber);

    return Column(
      children: [
        // ─── Header ──────────────────────────────────────────────
        _buildHeader(context, partNumber),

        // ─── Body ────────────────────────────────────────────────
        Expanded(
          child: isLoading
              ? _buildLoading()
              : errorMessage != null
                  ? _buildError(errorMessage)
                  : Stack(
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 40, 24, 140),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Part badge
                              _buildPartBadge(partNumber, isResume),
                              const SizedBox(height: 16),

                              // Title
                              Text(
                                'PART $partNumber: $partName',
                                style: GoogleFonts.lexend(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textSlate900,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Question count chip
                              if (questionCount > 0) ...[
                                _buildInfoChip(
                                  icon: Icons.quiz_outlined,
                                  label: '$questionCount câu hỏi',
                                  color: AppColors.primary,
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Description
                              Text(
                                description,
                                style: GoogleFonts.lexend(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textSlate600,
                                  height: 1.7,
                                ),
                              ),
                              const SizedBox(height: 40),

                              // Divider
                              Center(
                                child: Container(
                                  width: 80,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: AppColors.textSlate400
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Tips card
                              _buildTipsCard(tips),
                            ],
                          ),
                        ),

                        // ─── CTA pinned at bottom ───────────────
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding:
                                const EdgeInsets.fromLTRB(24, 32, 24, 32),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0),
                                  Colors.white,
                                  Colors.white,
                                ],
                                stops: const [0.0, 0.3, 1.0],
                              ),
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () => _onStart(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  elevation: 6,
                                  shadowColor: AppColors.primary
                                      .withValues(alpha: 0.35),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      isResume
                                          ? 'Bắt đầu Part $partNumber'
                                          : 'Bắt đầu làm bài',
                                      style: GoogleFonts.lexend(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      ],
    );
  }

  void _onStart(BuildContext context) {
    if (isResume) {
      // Pop back to ListeningQuestionPage which will advance to next question
      context.pop();
    } else {
      context.push('/exam/question', extra: {
        'testId': testId,
        'testTitle': testTitle,
      });
    }
  }

  // ─── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, int partNumber) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.pop(),
                  borderRadius: BorderRadius.circular(9999),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 40),
                  child: Text(
                    'TOEIC · Part $partNumber',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lexend(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
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

  // ─── Part badge ─────────────────────────────────────────────────────────
  Widget _buildPartBadge(int partNumber, bool isResume) {
    return Wrap(
      spacing: 8,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
          ),
          child: Text(
            'PART $partNumber',
            style: GoogleFonts.lexend(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (isResume)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.orange500.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: AppColors.orange500.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined,
                    size: 12, color: AppColors.orange500),
                const SizedBox(width: 4),
                Text(
                  'Đồng hồ đang chạy',
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.orange500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ─── Info chip ───────────────────────────────────────────────────────────
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tips card ───────────────────────────────────────────────────────────
  Widget _buildTipsCard(List<String> tips) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF9C3).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAB308).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  size: 18, color: Color(0xFFCA8A04)),
              const SizedBox(width: 8),
              Text(
                'Mẹo làm bài',
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFCA8A04),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 7),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFCA8A04),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tip,
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        color: const Color(0xFF854D0E),
                        height: 1.5,
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

  // ─── Loading skeleton ────────────────────────────────────────────────────
  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmer(width: 80, height: 28, radius: 20),
          const SizedBox(height: 18),
          _shimmer(width: 260, height: 32),
          const SizedBox(height: 16),
          _shimmer(width: 120, height: 24, radius: 20),
          const SizedBox(height: 24),
          _shimmer(width: double.infinity, height: 16),
          const SizedBox(height: 8),
          _shimmer(width: double.infinity, height: 16),
          const SizedBox(height: 8),
          _shimmer(width: 200, height: 16),
        ],
      ),
    );
  }

  Widget _shimmer({required double width, required double height, double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  // ─── Error state ─────────────────────────────────────────────────────────
  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 56, color: Colors.red.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text(
              'Không tải được dữ liệu',
              style: GoogleFonts.lexend(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSlate800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                  fontSize: 12, color: AppColors.textSlate400),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Default descriptions per part ──────────────────────────────────────
  static String _defaultDescription(int partNumber) {
    switch (partNumber) {
      case 1:
        return 'For each question in this part, you will see a picture in your test book and you will hear four short statements. The statements will be spoken just one time. They will not be printed in your test book. Select the best description of the picture.';
      case 2:
        return 'You will hear a question or statement and three responses spoken in English. They will not be printed in your test book and will be spoken only one time. Select the best response to the question or statement.';
      case 3:
        return 'You will hear some conversations between two or more people. You will be asked to answer three questions about what the speakers say in each conversation. Select the best response to each question.';
      case 4:
        return 'You will hear some talks given by a single speaker. You will be asked to answer three questions about what the speaker says in each talk. Select the best response to each question.';
      case 5:
        return 'A word or phrase is missing in each of the sentences below. Four answer choices are given below each sentence. Select the best answer to complete the sentence.';
      case 6:
        return 'Read the texts that follow. A word, phrase, or sentence is missing in parts of each text. Four answer choices for each question are given below the text. Select the best answer to complete the text.';
      case 7:
        return 'In this part you will read a selection of texts, such as magazine and newspaper articles, e-mails, and instant messages. Each text or set of texts is followed by several questions. Select the best answer for each question.';
      default:
        return 'Select the best answer to each question based on what is stated or implied in the text.';
    }
  }
}
