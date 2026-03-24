import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/practice/data/repositories/writing_repository.dart';

/// DB-backed data for one practice part (e.g. Part 1 Listening).
class PracticePartData {
  final String testPartId;
  final String testId;
  final List<String> partIds;
  final int partNumber;
  final String title;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final int totalQuestions;
  final int correctAnswers;
  final int totalAnswered;
  final bool isLocked;

  /// 'mcq_audio' | 'mcq_text' | 'free_text'
  final String questionType;

  const PracticePartData({
    required this.testPartId,
    required this.testId,
    this.partIds = const [],
    required this.partNumber,
    required this.title,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.totalAnswered,
    required this.isLocked,
    this.questionType = 'mcq_audio',
  });

  double get progressPercent =>
      totalQuestions > 0 ? correctAnswers / totalQuestions * 100 : 0;

  PracticePartData copyWith({
    String? testPartId,
    String? testId,
    List<String>? partIds,
    int? partNumber,
    String? title,
    IconData? icon,
    Color? iconBgColor,
    Color? iconColor,
    int? totalQuestions,
    int? correctAnswers,
    int? totalAnswered,
    bool? isLocked,
    String? questionType,
  }) {
    return PracticePartData(
      testPartId: testPartId ?? this.testPartId,
      testId: testId ?? this.testId,
      partIds: partIds ?? this.partIds,
      partNumber: partNumber ?? this.partNumber,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      iconBgColor: iconBgColor ?? this.iconBgColor,
      iconColor: iconColor ?? this.iconColor,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      totalAnswered: totalAnswered ?? this.totalAnswered,
      isLocked: isLocked ?? this.isLocked,
      questionType: questionType ?? this.questionType,
    );
  }
}

class PracticeRepository {
  final SupabaseClient _client;

  PracticeRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  static const int _pageSize = 1000;

  Future<List<Map<String, dynamic>>> _fetchAllQuestionsByPartIds({
    required List<String> partIds,
    required String columns,
  }) async {
    if (partIds.isEmpty) return const <Map<String, dynamic>>[];

    final rows = <Map<String, dynamic>>[];
    int from = 0;

    while (true) {
      final page =
          await _client
                  .from('questions')
                  .select(columns)
                  .inFilter('part_id', partIds)
                  .range(from, from + _pageSize - 1)
              as List<dynamic>;

      if (page.isEmpty) break;

      rows.addAll(page.map((e) => Map<String, dynamic>.from(e as Map)));

      if (page.length < _pageSize) break;
      from += _pageSize;
    }

    return rows;
  }

  // ── Part display metadata ────────────────────────────────────
  static const _blue50 = Color(0xFFEFF6FF);
  static const _blue600 = Color(0xFF2563EB);
  static const _purple50 = Color(0xFFFAF5FF);
  static const _purple600 = Color(0xFF9333EA);
  static const _teal50 = Color(0xFFF0FDFA);
  static const _teal600 = Color(0xFF0D9488);
  static const _green50 = Color(0xFFF0FDF4);
  static const _green600 = Color(0xFF16A34A);
  static const _amber50 = Color(0xFFFFFBEB);
  static const _amber600 = Color(0xFFD97706);

  static String _listeningTitle(int n) {
    switch (n) {
      case 1:
        return 'Part 1: Mô tả tranh';
      case 2:
        return 'Part 2: Hỏi & Đáp';
      case 3:
        return 'Part 3: Đoạn Hội Thoại';
      case 4:
        return 'Part 4: Bài Nói Chuyện Ngắn';
      default:
        return 'Part $n';
    }
  }

  static IconData _listeningIcon(int n) {
    switch (n) {
      case 1:
        return Icons.image;
      case 2:
        return Icons.record_voice_over;
      case 3:
        return Icons.forum;
      case 4:
        return Icons.graphic_eq;
      default:
        return Icons.quiz;
    }
  }

  static Color _listeningBg(int n) {
    switch (n) {
      case 1:
        return _blue50;
      case 2:
        return _purple50;
      case 3:
        return _teal50;
      case 4:
        return _green50;
      default:
        return AppColors.teal50;
    }
  }

  static Color _listeningFg(int n) {
    switch (n) {
      case 1:
        return _blue600;
      case 2:
        return _purple600;
      case 3:
        return _teal600;
      case 4:
        return _green600;
      default:
        return AppColors.primary;
    }
  }

  // ── Public API ───────────────────────────────────────────────

  /// Returns Part 1–4 data for [testId], enriched with the current user's
  /// progress (history from all full tests).
  Future<List<PracticePartData>> getListeningParts() async {
    developer.log(
      'Loading listening parts across all full tests',
      name: 'PracticeRepo',
    );

    final testsResponse =
        await _client
                .from('tests')
                .select('id')
                .eq('type', 'full_test')
                .order('created_at', ascending: true)
            as List<dynamic>;

    if (testsResponse.isEmpty) return [];

    final testIds = testsResponse.map((t) => t['id'] as String).toList();
    final fallbackTestId = testIds.first;

    final partsResponse =
        await _client
                .from('test_parts')
                .select('id, part_number, test_id')
                .inFilter('test_id', testIds)
                .inFilter('part_number', [1, 2, 3, 4])
                .order('part_number', ascending: true)
            as List<dynamic>;

    if (partsResponse.isEmpty) return [];

    final partNumberById = <String, int>{};
    final partIdsByNumber = <int, List<String>>{
      1: <String>[],
      2: <String>[],
      3: <String>[],
      4: <String>[],
    };

    for (final part in partsResponse) {
      final partId = part['id'] as String;
      final partNumber = (part['part_number'] as num).toInt();
      partNumberById[partId] = partNumber;
      partIdsByNumber[partNumber]?.add(partId);
    }

    final allPartIds = partNumberById.keys.toList();

    final questionsResponse = await _fetchAllQuestionsByPartIds(
      partIds: allPartIds,
      columns: 'id, part_id',
    );

    final questionCountsByPartId = <String, int>{};
    for (final q in questionsResponse) {
      final pid = q['part_id'] as String;
      questionCountsByPartId[pid] = (questionCountsByPartId[pid] ?? 0) + 1;
    }

    final progressByPartNumber = <int, _PartStats>{};
    final userId = _client.auth.currentUser?.id;

    if (userId != null) {
      final historyResponse =
          await _client
                  .from('listening_answer_history')
                  .select('is_correct, questions!inner(part_id)')
                  .eq('user_id', userId)
              as List<dynamic>;

      for (final row in historyResponse) {
        final questionPartId =
            (row['questions'] as Map<String, dynamic>)['part_id'] as String;
        final partNumber = partNumberById[questionPartId];
        if (partNumber == null) continue;
        final stats = progressByPartNumber[partNumber] ?? _PartStats();
        stats.answered++;
        if ((row['is_correct'] as bool?) ?? false) stats.correct++;
        progressByPartNumber[partNumber] = stats;
      }
    }

    return [1, 2, 3, 4].map((partNumber) {
      final partIds = partIdsByNumber[partNumber] ?? const <String>[];
      final totalQuestions = partIds.fold<int>(
        0,
        (sum, partId) => sum + (questionCountsByPartId[partId] ?? 0),
      );
      final stats = progressByPartNumber[partNumber] ?? _PartStats();

      return PracticePartData(
        testPartId: partIds.isNotEmpty ? partIds.first : 'part-$partNumber',
        testId: fallbackTestId,
        partIds: partIds,
        partNumber: partNumber,
        title: _listeningTitle(partNumber),
        icon: _listeningIcon(partNumber),
        iconBgColor: _listeningBg(partNumber),
        iconColor: _listeningFg(partNumber),
        totalQuestions: totalQuestions,
        totalAnswered: stats.answered,
        correctAnswers: stats.correct,
        isLocked: totalQuestions == 0,
        questionType: 'mcq_audio',
      );
    }).toList();
  }

  // ── Reading metadata ─────────────────────────────────────────

  static String _readingTitle(int n) {
    switch (n) {
      case 5:
        return 'Part 5: Điền Vào Câu';
      case 6:
        return 'Part 6: Điền Vào Đoạn Văn';
      case 7:
        return 'Part 7: Đọc Hiểu Đoạn Văn';
      default:
        return 'Part $n';
    }
  }

  static IconData _readingIcon(int n) {
    switch (n) {
      case 5:
        return Icons.text_fields;
      case 6:
        return Icons.article;
      case 7:
        return Icons.menu_book;
      default:
        return Icons.quiz;
    }
  }

  static Color _readingBg(int n) {
    switch (n) {
      case 5:
        return _blue50;
      case 6:
        return _purple50;
      case 7:
        return _green50;
      default:
        return AppColors.teal50;
    }
  }

  static Color _readingFg(int n) {
    switch (n) {
      case 5:
        return _blue600;
      case 6:
        return _purple600;
      case 7:
        return _green600;
      default:
        return AppColors.primary;
    }
  }

  /// Returns Part 5–7 data aggregated from all full tests, enriched with user progress.
  Future<List<PracticePartData>> getReadingParts() async {
    developer.log(
      'Loading reading parts across all full tests',
      name: 'PracticeRepo',
    );

    final testsResponse =
        await _client
                .from('tests')
                .select('id')
                .eq('type', 'full_test')
                .order('created_at', ascending: true)
            as List<dynamic>;

    if (testsResponse.isEmpty) return [];

    final testIds = testsResponse.map((t) => t['id'] as String).toList();
    final fallbackTestId = testIds.first;

    final partsResponse =
        await _client
                .from('test_parts')
                .select('id, part_number, test_id')
                .inFilter('test_id', testIds)
                .inFilter('part_number', [5, 6, 7])
                .order('part_number', ascending: true)
            as List<dynamic>;

    if (partsResponse.isEmpty) return [];

    final partNumberById = <String, int>{};
    final partIdsByNumber = <int, List<String>>{
      5: <String>[],
      6: <String>[],
      7: <String>[],
    };

    for (final part in partsResponse) {
      final partId = part['id'] as String;
      final partNumber = (part['part_number'] as num).toInt();
      partNumberById[partId] = partNumber;
      partIdsByNumber[partNumber]?.add(partId);
    }

    final allPartIds = partNumberById.keys.toList();

    final questionsResponse = await _fetchAllQuestionsByPartIds(
      partIds: allPartIds,
      columns: 'id, part_id',
    );

    final questionCountsByPartId = <String, int>{};
    for (final q in questionsResponse) {
      final pid = q['part_id'] as String;
      questionCountsByPartId[pid] = (questionCountsByPartId[pid] ?? 0) + 1;
    }

    final progressByPartNumber = <int, _PartStats>{};
    final userId = _client.auth.currentUser?.id;

    if (userId != null) {
      final attemptsResponse =
          await _client
                  .from('attempts')
                  .select('id')
                  .eq('user_id', userId)
                  .inFilter('test_id', testIds)
              as List<dynamic>;

      if (attemptsResponse.isNotEmpty) {
        final attemptIds = attemptsResponse
            .map((a) => a['id'] as String)
            .toList();

        final answersResponse =
            await _client
                    .from('answers')
                    .select('is_correct, questions!inner(part_id)')
                    .inFilter('attempt_id', attemptIds)
                as List<dynamic>;

        for (final row in answersResponse) {
          final questionPartId =
              (row['questions'] as Map<String, dynamic>)['part_id'] as String;
          final partNumber = partNumberById[questionPartId];
          if (partNumber == null) continue;
          final stats = progressByPartNumber[partNumber] ?? _PartStats();
          stats.answered++;
          if ((row['is_correct'] as bool?) ?? false) stats.correct++;
          progressByPartNumber[partNumber] = stats;
        }
      }
    }

    return [5, 6, 7].map((partNumber) {
      final partIds = partIdsByNumber[partNumber] ?? const <String>[];
      final totalQuestions = partIds.fold<int>(
        0,
        (sum, partId) => sum + (questionCountsByPartId[partId] ?? 0),
      );
      final stats = progressByPartNumber[partNumber] ?? _PartStats();

      return PracticePartData(
        testPartId: partIds.isNotEmpty ? partIds.first : 'part-$partNumber',
        testId: fallbackTestId,
        partIds: partIds,
        partNumber: partNumber,
        title: _readingTitle(partNumber),
        icon: _readingIcon(partNumber),
        iconBgColor: _readingBg(partNumber),
        iconColor: _readingFg(partNumber),
        totalQuestions: totalQuestions,
        totalAnswered: stats.answered,
        correctAnswers: stats.correct,
        isLocked: totalQuestions == 0,
        questionType: 'mcq_text',
      );
    }).toList();
  }

  /// Returns unanswered question IDs for one listening/reading practice part.
  ///
  /// [partIds] should include all concrete `test_parts.id` that belong to the
  /// selected aggregated practice part.
  Future<List<String>> getUnansweredQuestionIdsForPart({
    required List<String> partIds,
    required String questionType,
  }) async {
    try {
      if (partIds.isEmpty) return const <String>[];

      final questionRows = await _fetchAllQuestionsByPartIds(
        partIds: partIds,
        columns: 'id, part_id, order_index',
      );

      if (questionRows.isEmpty) return const <String>[];

      final partRank = <String, int>{
        for (int i = 0; i < partIds.length; i++) partIds[i]: i,
      };

      final orderedRows =
          List<Map<String, dynamic>>.from(
            questionRows.map((e) => Map<String, dynamic>.from(e as Map)),
          )..sort((a, b) {
            final partA = a['part_id'] as String? ?? '';
            final partB = b['part_id'] as String? ?? '';
            final rankA = partRank[partA] ?? 999999;
            final rankB = partRank[partB] ?? 999999;
            if (rankA != rankB) return rankA.compareTo(rankB);

            final orderA = (a['order_index'] as num?)?.toInt() ?? 0;
            final orderB = (b['order_index'] as num?)?.toInt() ?? 0;
            return orderA.compareTo(orderB);
          });

      final allQuestionIds = orderedRows
          .map((row) => row['id'] as String)
          .toList(growable: false);

      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return allQuestionIds;
      }

      final answeredIds = <String>{};

      if (questionType == 'mcq_audio') {
        final historyRows =
            await _client
                    .from('listening_answer_history')
                    .select('question_id')
                    .eq('user_id', userId)
                    .inFilter('question_id', allQuestionIds)
                as List<dynamic>;

        for (final row in historyRows) {
          final questionId = row['question_id'] as String?;
          if (questionId != null && questionId.isNotEmpty) {
            answeredIds.add(questionId);
          }
        }
      } else if (questionType == 'mcq_text') {
        final answerRows =
            await _client
                    .from('answers')
                    .select('question_id, option_id, attempts!inner(user_id)')
                    .eq('attempts.user_id', userId)
                    .inFilter('question_id', allQuestionIds)
                as List<dynamic>;

        for (final row in answerRows) {
          final optionId = row['option_id'] as String?;
          final questionId = row['question_id'] as String?;
          if (optionId != null &&
              optionId.isNotEmpty &&
              questionId != null &&
              questionId.isNotEmpty) {
            answeredIds.add(questionId);
          }
        }
      }

      return allQuestionIds
          .where((questionId) => !answeredIds.contains(questionId))
          .toList(growable: false);
    } catch (e, stack) {
      developer.log(
        'Error fetching unanswered question ids for practice part: $e',
        name: 'PracticeRepo',
        error: e,
        stackTrace: stack,
      );
      return const <String>[];
    }
  }

  // ── Writing metadata ─────────────────────────────────────────

  static String _writingTitle(int n) {
    switch (n) {
      case 1:
        return 'Part 1: Mô tả tranh';
      case 2:
        return 'Part 2: Phản hồi yêu cầu';
      case 3:
        return 'Part 3: Viết luận';
      default:
        return 'Part $n';
    }
  }

  static IconData _writingIcon(int n) {
    switch (n) {
      case 1:
        return Icons.image;
      case 2:
        return Icons.email;
      case 3:
        return Icons.edit_note;
      default:
        return Icons.edit;
    }
  }

  static Color _writingBg(int n) {
    switch (n) {
      case 1:
        return _blue50;
      case 2:
        return _purple50;
      case 3:
        return _amber50;
      default:
        return AppColors.teal50;
    }
  }

  static Color _writingFg(int n) {
    switch (n) {
      case 1:
        return _blue600;
      case 2:
        return _purple600;
      case 3:
        return _amber600;
      default:
        return AppColors.primary;
    }
  }

  /// Returns Parts 1–3 writing data backed by [writing_prompts] table.
  Future<List<PracticePartData>> getWritingParts() async {
    developer.log('Loading writing parts', name: 'PracticeRepo');

    final writingRepo = WritingRepository(client: _client);
    final promptCounts = await writingRepo.getPromptCounts();
    final submissionCounts = await writingRepo.getUserSubmissionCounts();

    return [1, 2, 3].map((partNumber) {
      final total = promptCounts[partNumber] ?? 0;
      final answered = submissionCounts[partNumber] ?? 0;
      return PracticePartData(
        testPartId: partNumber.toString(),
        testId: '',
        partNumber: partNumber,
        title: _writingTitle(partNumber),
        icon: _writingIcon(partNumber),
        iconBgColor: _writingBg(partNumber),
        iconColor: _writingFg(partNumber),
        totalQuestions: total,
        totalAnswered: answered,
        correctAnswers: 0,
        isLocked: false, // Writing is free
        questionType: 'free_text',
      );
    }).toList();
  }

  // ── Speaking metadata ─────────────────────────────────────────

  static String _speakingTitle(int n) {
    switch (n) {
      case 1:
        return 'Part 1: Read a Text Aloud';
      case 2:
        return 'Part 2: Describe a Picture';
      case 3:
        return 'Part 3: Respond to Questions';
      case 4:
        return 'Part 4: Respond using Information';
      case 5:
        return 'Part 5: Express an Opinion';
      default:
        return 'Part $n';
    }
  }

  static IconData _speakingIcon(int n) {
    switch (n) {
      case 1:
        return Icons.record_voice_over;
      case 2:
        return Icons.image;
      case 3:
        return Icons.question_answer;
      case 4:
        return Icons.fact_check;
      case 5:
        return Icons.campaign;
      default:
        return Icons.mic;
    }
  }

  static Color _speakingBg(int n) {
    switch (n) {
      case 1:
        return _amber50;
      case 2:
        return _blue50;
      case 3:
        return _teal50;
      case 4:
        return _purple50;
      case 5:
        return _green50;
      default:
        return AppColors.teal50;
    }
  }

  static Color _speakingFg(int n) {
    switch (n) {
      case 1:
        return _amber600;
      case 2:
        return _blue600;
      case 3:
        return _teal600;
      case 4:
        return _purple600;
      case 5:
        return _green600;
      default:
        return AppColors.primary;
    }
  }

  static int? _speakingPartFromTaskType(String? type) {
    switch ((type ?? '').trim().toLowerCase()) {
      case 'read_aloud':
        return 1;
      case 'describe_picture':
        return 2;
      case 'respond_questions':
        return 3;
      case 'respond_information':
        return 4;
      case 'express_opinion':
        return 5;
      default:
        return null;
    }
  }

  static int? _inferSpeakingPartFromQuestionId(String questionId) {
    if (questionId.startsWith('sp-read-')) return 1;
    if (questionId.startsWith('sp-picture-')) return 2;
    if (questionId.startsWith('sp-respond-')) return 3;
    if (questionId.startsWith('sp-info-')) return 4;
    if (questionId.startsWith('sp-opinion-')) return 5;
    return null;
  }

  Future<List<PracticePartData>> getSpeakingParts() async {
    developer.log('Loading speaking parts', name: 'PracticeRepo');

    // Align with web: count questions from speaking_prompts by part_number.
    final countsByPart = <int, int>{};
    try {
      final rows =
          await _client.from('speaking_prompts').select('part_number')
              as List<dynamic>;
      for (final row in rows) {
        final partNumber =
            ((row as Map<String, dynamic>)['part_number'] as num?)?.toInt();
        if (partNumber == null) continue;
        countsByPart[partNumber] = (countsByPart[partNumber] ?? 0) + 1;
      }
    } catch (_) {
      // If table is unavailable, keep UI usable with zero-count fallback.
    }

    final hasRemoteCounts = countsByPart.isNotEmpty;
    final userId = _client.auth.currentUser?.id;
    final answeredByPart = <int, int>{};
    final passedByPart = <int, int>{};

    if (userId != null) {
      try {
        final answerRows =
            await _client
                    .from('speaking_answers')
                    .select('id, question_id')
                    .eq('user_id', userId)
                as List<dynamic>;

        if (answerRows.isNotEmpty) {
          final answerIds = <String>[];
          final answerPartById = <String, int>{};
          final promptIds = answerRows
              .map(
                (e) => (e as Map<String, dynamic>)['question_id']?.toString(),
              )
              .whereType<String>()
              .toSet()
              .toList();

          final promptPartById = <String, int>{};
          if (promptIds.isNotEmpty) {
            final promptRows =
                await _client
                        .from('speaking_prompts')
                        .select('id, part_number')
                        .inFilter('id', promptIds)
                    as List<dynamic>;
            for (final row in promptRows) {
              final map = row as Map<String, dynamic>;
              final id = map['id']?.toString();
              final part = (map['part_number'] as num?)?.toInt();
              if (id != null && part != null) {
                promptPartById[id] = part;
              }
            }
          }

          final unresolvedPromptIds = promptIds
              .where((id) => !promptPartById.containsKey(id))
              .toList();
          final questionPartById = <String, int>{};
          if (unresolvedPromptIds.isNotEmpty) {
            try {
              final questionRows =
                  await _client
                          .from('speaking_questions')
                          .select('id, type')
                          .inFilter('id', unresolvedPromptIds)
                      as List<dynamic>;
              for (final row in questionRows) {
                final map = row as Map<String, dynamic>;
                final id = map['id']?.toString();
                final part = _speakingPartFromTaskType(map['type']?.toString());
                if (id != null && part != null) {
                  questionPartById[id] = part;
                }
              }
            } catch (_) {
              // Optional fallback source only.
            }
          }

          for (final row in answerRows) {
            final map = row as Map<String, dynamic>;
            final answerId = map['id']?.toString();
            final promptId = map['question_id']?.toString();
            if (answerId == null || promptId == null) continue;
            final part =
                promptPartById[promptId] ??
                questionPartById[promptId] ??
                _inferSpeakingPartFromQuestionId(promptId);
            if (part == null) continue;
            answerIds.add(answerId);
            answerPartById[answerId] = part;
            answeredByPart[part] = (answeredByPart[part] ?? 0) + 1;
          }

          if (answerIds.isNotEmpty) {
            final aiRows =
                await _client
                        .from('ai_speaking_evaluations')
                        .select('answer_id, overall_score')
                        .inFilter('answer_id', answerIds)
                    as List<dynamic>;
            for (final row in aiRows) {
              final map = row as Map<String, dynamic>;
              final answerId = map['answer_id']?.toString();
              final score = (map['overall_score'] as num?)?.toInt() ?? 0;
              if (answerId == null || score < 60) continue;
              final part = answerPartById[answerId];
              if (part == null) continue;
              passedByPart[part] = (passedByPart[part] ?? 0) + 1;
            }
          }
        }
      } catch (_) {
        // Keep screen usable even if answer/evaluation tables are unavailable.
      }
    }

    return [1, 2, 3, 4, 5].map((partNumber) {
      final total = countsByPart[partNumber] ?? (hasRemoteCounts ? 0 : 5);
      final answered = answeredByPart[partNumber] ?? 0;
      return PracticePartData(
        testPartId: partNumber.toString(),
        testId: '',
        partNumber: partNumber,
        title: _speakingTitle(partNumber),
        icon: _speakingIcon(partNumber),
        iconBgColor: _speakingBg(partNumber),
        iconColor: _speakingFg(partNumber),
        totalQuestions: total,
        totalAnswered: answered,
        correctAnswers: passedByPart[partNumber] ?? 0,
        isLocked: false,
        questionType: 'voice',
      );
    }).toList();
  }
}

class _PartStats {
  int answered = 0;
  int correct = 0;
}
