import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/practice/data/repositories/speaking_writing_repository.dart';
import 'package:lexii/features/practice/presentation/providers/practice_providers.dart';

class SwHistoryPage extends ConsumerWidget {
  final bool isSpeaking;

  const SwHistoryPage({
    super.key,
    required this.isSpeaking,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(speakingWritingRepositoryProvider);
    final future = isSpeaking
        ? repo.getSpeakingHistory(limit: 40)
        : repo.getWritingHistory(limit: 40);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          isSpeaking ? 'Lịch sử luyện nói' : 'Lịch sử luyện viết',
          style: GoogleFonts.lexend(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<PracticeHistoryItem>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Không tải được lịch sử.',
                style: GoogleFonts.lexend(color: AppColors.textSlate500),
              ),
            );
          }

          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return Center(
              child: Text(
                'Bạn chưa có bài làm nào.',
                style: GoogleFonts.lexend(color: AppColors.textSlate500),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return _HistoryCard(item: item, isSpeaking: isSpeaking);
            },
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final PracticeHistoryItem item;
  final bool isSpeaking;

  const _HistoryCard({
    required this.item,
    required this.isSpeaking,
  });

  @override
  Widget build(BuildContext context) {
    final date = _formatDate(item.createdAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSlate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _typeLabel(item.questionType, isSpeaking),
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSlate800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.isAi ? AppColors.indigo100 : AppColors.teal100,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.isAi ? 'AI' : 'Thường',
                  style: GoogleFonts.lexend(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: item.isAi ? AppColors.indigo600 : AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: GoogleFonts.lexend(
              fontSize: 11,
              color: AppColors.textSlate400,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.prompt,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.lexend(
              fontSize: 12,
              color: AppColors.textSlate500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.answerText.isEmpty ? '(Không có nội dung)' : item.answerText,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.lexend(
              fontSize: 13,
              color: AppColors.textSlate600,
              height: 1.5,
            ),
          ),
          if (isSpeaking && item.durationSeconds != null) ...[
            const SizedBox(height: 8),
            Text(
              'Thời lượng: ${item.durationSeconds}s',
              style: GoogleFonts.lexend(
                fontSize: 12,
                color: AppColors.textSlate500,
              ),
            ),
          ],
          if (item.ai != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _metric('Overall', item.ai!.overall),
                _metric('Grammar', item.ai!.grammar),
                _metric('Vocab', item.ai!.vocabulary),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _metric(String label, int value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.slate50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: GoogleFonts.lexend(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSlate800,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.lexend(
                fontSize: 10,
                color: AppColors.textSlate500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${dt.year} $hh:$min';
  }

  String _typeLabel(String type, bool speaking) {
    const speakingMap = {
      'read_aloud': 'Đọc đoạn văn',
      'describe_picture': 'Mô tả hình ảnh',
      'respond_questions': 'Trả lời câu hỏi',
      'respond_information': 'Trả lời theo thông tin',
      'express_opinion': 'Trình bày quan điểm',
    };

    const writingMap = {
      'write_sentence_picture': 'Viết câu theo hình ảnh',
      'reply_email': 'Trả lời email',
      'opinion_essay': 'Viết luận nêu quan điểm',
    };

    return speaking
        ? (speakingMap[type] ?? type)
        : (writingMap[type] ?? type);
  }
}
