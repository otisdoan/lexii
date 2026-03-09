import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/practice/data/repositories/practice_repository.dart';

class PracticePartIntroPage extends StatefulWidget {
  final PracticePartData partData;

  const PracticePartIntroPage({super.key, required this.partData});

  @override
  State<PracticePartIntroPage> createState() => _PracticePartIntroPageState();
}

class _PracticePartIntroPageState extends State<PracticePartIntroPage> {
  late int _selectedCount;
  bool _reviewMode = false;

  @override
  void initState() {
    super.initState();
    _selectedCount = widget.partData.totalQuestions > 0
        ? widget.partData.totalQuestions
        : 0;
  }

  List<int> get _countOptions {
    final total = widget.partData.totalQuestions;
    if (total <= 0) {
      // Writing parts may have 0 in totalQuestions initially but still be playable
      if (widget.partData.questionType == 'free_text') return [5, 10];
      return [0];
    }
    final opts = <int>{total};
    if (total >= 30) opts.add(20);
    if (total >= 20) opts.add(10);
    if (total >= 10) opts.add(5);
    return opts.toList()..sort();
  }

  static String _instructionForPart(PracticePartData part) {
    if (part.questionType == 'mcq_text') {
      switch (part.partNumber) {
        case 5:
          return 'Đọc câu và chọn từ đúng nhất để điền vào chỗ trống. Chọn đáp án A, B, C hoặc D.';
        case 6:
          return 'Đọc đoạn văn có chỗ trống và chọn từ hoặc cụm từ phù hợp nhất. Chọn đáp án A, B, C hoặc D.';
        case 7:
          return 'Đọc đoạn văn và trả lời các câu hỏi bên dưới. Chọn đáp án A, B, C hoặc D.';
        default:
          return 'Đọc và chọn đáp án đúng nhất.';
      }
    }
    if (part.questionType == 'free_text') {
      switch (part.partNumber) {
        case 1:
          return 'Nhìn vào hình ảnh và viết 1–2 câu mô tả những gì bạn thấy bằng tiếng Anh.';
        case 2:
          return 'Đọc email và viết phản hồi. Câu trả lời nên bao gồm đủ thông tin theo yêu cầu.';
        case 3:
          return 'Đọc chủ đề và viết bài luận bày tỏ ý kiến của bạn. Viết ít nhất 3 đoạn văn.';
        default:
          return 'Viết câu trả lời của bạn bằng tiếng Anh.';
      }
    }
    // mcq_audio (listening)
    switch (part.partNumber) {
      case 1:
        return 'For each question, you will see a picture and you will hear four short statements about the picture. They will be spoken only once. Choose the best answer A, B, C or D.';
      case 2:
        return 'You will hear a question or statement and three responses. They will be spoken only once. Choose the best response A, B or C.';
      case 3:
        return 'You will hear some conversations between two or more people. You will be asked to answer three questions about what the speakers say in each conversation. Choose the best answer A, B, C or D.';
      case 4:
        return 'You will hear some short talks given by a single speaker. You will be asked to answer three questions about what the speaker says in each talk. Choose the best answer A, B, C or D.';
      default:
        return 'Choose the best answer for each question.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final part = widget.partData;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildAppBar(context, part.title),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsRow(part),
                  const SizedBox(height: 24),
                  _buildInstructionCard(part),
                  const SizedBox(height: 16),
                  _buildUpgradeNote(),
                  const SizedBox(height: 130),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomSheet(context, part),
    );
  }

  Widget _buildAppBar(BuildContext context, String title) {
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 40),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lexend(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(PracticePartData part) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Part icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: part.iconBgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Icon(part.icon, size: 40, color: part.iconColor),
          ),
        ),
        const SizedBox(width: 16),
        // Stats
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _statRow('Số câu đã làm', '${part.totalAnswered}',
                  AppColors.primary),
              const SizedBox(height: 6),
              _statRow('Trả lời đúng', '${part.correctAnswers}',
                  AppColors.green600),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hoàn thành',
                    style: GoogleFonts.lexend(
                      fontSize: 11,
                      color: AppColors.textSlate500,
                    ),
                  ),
                  Text(
                    '${part.progressPercent.round()}%',
                    style: GoogleFonts.lexend(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSlate500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: part.progressPercent / 100,
                  minHeight: 6,
                  backgroundColor: AppColors.slate200,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(part.iconColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statRow(String label, String value, Color valueColor) {
    return Row(
      children: [
        Text(
          '$label ',
          style: GoogleFonts.lexend(
            fontSize: 13,
            color: AppColors.textSlate500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.lexend(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionCard(PracticePartData part) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSlate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Câu hỏi',
            style: GoogleFonts.lexend(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              color: AppColors.textSlate800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _instructionForPart(part),
            style: GoogleFonts.lexend(
              fontSize: 13,
              color: AppColors.textSlate600,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeNote() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        'Nâng cấp để tải toàn bộ bài tập về máy, tải dữ liệu nhanh hơn, ổn định hơn',
        textAlign: TextAlign.center,
        style: GoogleFonts.lexend(
          fontSize: 11,
          color: AppColors.textSlate400,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context, PracticePartData part) {
    final opts = _countOptions;
    final safeCount = opts.contains(_selectedCount)
        ? _selectedCount
        : (opts.isNotEmpty ? opts.last : 0);

    return Container(
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
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 20 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Controls row
          Row(
            children: [
              // Question count selector
              Row(
                children: [
                  Text(
                    'Số câu hỏi: ',
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSlate600,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.borderSlate200),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: safeCount,
                        isDense: true,
                        style: GoogleFonts.lexend(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSlate800,
                        ),
                        items: opts
                            .map((n) => DropdownMenuItem(
                                  value: n,
                                  child: Text('$n'),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _selectedCount = v);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Review mode toggle
              Row(
                children: [
                  Text(
                    'Kiểm tra',
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSlate600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: _reviewMode,
                      onChanged: (v) => setState(() => _reviewMode = v),
                      activeThumbColor: AppColors.primary,
                      activeTrackColor:
                          AppColors.primary.withValues(alpha: 0.4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Start button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (part.totalQuestions > 0 || part.questionType == 'free_text')
                  ? () {
                      if (part.questionType == 'free_text') {
                        // Writing
                        context.push('/practice/writing-question', extra: {
                          'partNumber':
                              int.tryParse(part.testPartId) ?? part.partNumber,
                          'partTitle': part.title,
                          'questionLimit': safeCount,
                        });
                      } else if (part.questionType == 'mcq_text') {
                        // Reading
                        context.push('/practice/reading-question', extra: {
                          'testId': part.testId,
                          'partId': part.testPartId,
                          'partTitle': part.title,
                          'questionLimit': safeCount,
                        });
                      } else {
                        // Listening (default)
                        context.push('/exam/question', extra: {
                          'testId': part.testId,
                          'testTitle': part.title,
                          'partId': part.testPartId,
                          'isPracticeMode': true,
                          'questionLimit': safeCount,
                        });
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.textSlate400,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
              ),
              child: Text(
                'Bắt đầu nào',
                style: GoogleFonts.lexend(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
