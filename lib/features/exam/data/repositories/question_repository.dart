import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lexii/features/exam/data/models/attempt_history_model.dart';
import 'package:lexii/features/exam/data/models/question_model.dart';
import 'package:lexii/features/exam/data/models/test_part_model.dart';

class QuestionRepository {
  final SupabaseClient _client;

  QuestionRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Fetch all questions for a test, with options and media
  Future<List<QuestionModel>> getQuestionsByTestId(String testId) async {
    try {
      final partsResponse = await _client
          .from('test_parts')
          .select('id')
          .eq('test_id', testId)
          .order('part_number', ascending: true);

      developer.log('Parts for test $testId: $partsResponse',
          name: 'QuestionRepo');

      if (partsResponse.isEmpty) return [];

      final partIds =
          partsResponse.map((p) => p['id'] as String).toList();

      // First fetch questions
      final questionsResponse = await _client
          .from('questions')
          .select('''
            id,
            part_id,
            passage_id,
            question_text,
            order_index,
            question_options (id, content, is_correct),
            question_media (id, type, url)
          ''')
          .inFilter('part_id', partIds)
          .order('order_index', ascending: true) as List<dynamic>;

      developer.log('Questions fetched: ${questionsResponse.length}',
          name: 'QuestionRepo');

      // Collect unique passage IDs referenced by the questions
      final passageIds = questionsResponse
          .map((q) => q['passage_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();

      // Fetch passages by their IDs (not part_id) so we never miss any
      final passageMap = <String, String>{};
      if (passageIds.isNotEmpty) {
        final passagesResponse = await _client
            .from('passages')
            .select('id, content')
            .inFilter('id', passageIds) as List<dynamic>;

        developer.log('Passages fetched: ${passagesResponse.length}',
            name: 'QuestionRepo');

        for (final p in passagesResponse) {
          passageMap[p['id'] as String] = (p['content'] as String? ?? '');
        }
      }

      return questionsResponse.map((json) {
        final q = QuestionModel.fromJson(json);
        final content = q.passageId != null ? passageMap[q.passageId] : null;
        return content != null ? q.withPassageContent(content) : q;
      }).toList();
    } catch (e, stack) {
      developer.log('Error fetching questions: $e',
          name: 'QuestionRepo', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Fetch all parts for a test, including question count per part
  Future<List<TestPartModel>> getTestParts(String testId) async {
    try {
      final response = await _client
          .from('test_parts')
          .select('id, test_id, part_number, instructions, questions(id)')
          .eq('test_id', testId)
          .order('part_number', ascending: true);

      developer.log('Parts for test $testId: $response', name: 'QuestionRepo');

      return (response as List)
          .map((json) => TestPartModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      developer.log('Error fetching test parts: $e',
          name: 'QuestionRepo', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Fetch question for a specific part (with passage content if available)
  Future<List<QuestionModel>> getQuestionsByPartId(String partId) async {
    try {
      final response = await _client
          .from('questions')
          .select('''
            id,
            part_id,
            passage_id,
            question_text,
            order_index,
            question_options (id, content, is_correct),
            question_media (id, type, url)
          ''')
          .eq('part_id', partId)
          .order('order_index', ascending: true) as List<dynamic>;

      // Collect unique passage IDs to fetch content
      final passageIds = response
          .map((q) => q['passage_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();

      final passageMap = <String, String>{};
      if (passageIds.isNotEmpty) {
        final passagesResponse = await _client
            .from('passages')
            .select('id, content')
            .inFilter('id', passageIds) as List<dynamic>;
        for (final p in passagesResponse) {
          passageMap[p['id'] as String] = (p['content'] as String? ?? '');
        }
      }

      return response.map((json) {
        final q = QuestionModel.fromJson(json);
        final content = q.passageId != null ? passageMap[q.passageId] : null;
        return content != null ? q.withPassageContent(content) : q;
      }).toList();
    } catch (e, stack) {
      developer.log('Error fetching questions by part: $e',
          name: 'QuestionRepo', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Fetch questions for one listening part number (1..4) across all full tests.
  Future<List<QuestionModel>> getQuestionsByListeningPartNumber(
      int partNumber) async {
    try {
      final testsResponse = await _client
          .from('tests')
          .select('id')
          .eq('type', 'full_test') as List<dynamic>;
      if (testsResponse.isEmpty) return [];

      final testIds = testsResponse.map((t) => t['id'] as String).toList();
      final partsResponse = await _client
          .from('test_parts')
          .select('id, test_id')
          .inFilter('test_id', testIds)
          .eq('part_number', partNumber) as List<dynamic>;
      if (partsResponse.isEmpty) return [];

      final partIds = partsResponse.map((p) => p['id'] as String).toList();
      final response = await _client
          .from('questions')
          .select('''
            id,
            part_id,
            passage_id,
            question_text,
            order_index,
            question_options (id, content, is_correct),
            question_media (id, type, url)
          ''')
          .inFilter('part_id', partIds)
          .order('order_index', ascending: true) as List<dynamic>;

      final passageIds = response
          .map((q) => q['passage_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();

      final passageMap = <String, String>{};
      if (passageIds.isNotEmpty) {
        final passagesResponse = await _client
            .from('passages')
            .select('id, content')
            .inFilter('id', passageIds) as List<dynamic>;
        for (final p in passagesResponse) {
          passageMap[p['id'] as String] = (p['content'] as String? ?? '');
        }
      }

      final testOrder = <String, int>{};
      for (int i = 0; i < testIds.length; i++) {
        testOrder[testIds[i]] = i;
      }
      
      final partToTest = <String, String>{};
      for (final p in partsResponse) {
        partToTest[p['id'] as String] = p['test_id'] as String;
      }

      final result = response.map((json) {
        final q = QuestionModel.fromJson(json);
        final content = q.passageId != null ? passageMap[q.passageId] : null;
        return content != null ? q.withPassageContent(content) : q;
      }).toList();

      result.sort((a, b) {
        final testA = partToTest[a.partId] ?? '';
        final testB = partToTest[b.partId] ?? '';
        final orderA = testOrder[testA] ?? 0;
        final orderB = testOrder[testB] ?? 0;
        if (orderA != orderB) return orderA.compareTo(orderB);

        final audioA = a.audioUrl ?? '';
        final audioB = b.audioUrl ?? '';
        if (audioA != audioB) {
          if (audioA.isNotEmpty && audioB.isEmpty) return -1;
          if (audioA.isEmpty && audioB.isNotEmpty) return 1;
          return audioA.compareTo(audioB);
        }

        return a.orderIndex.compareTo(b.orderIndex);
      });

      return result;
    } catch (e, stack) {
      developer.log('Error fetching listening part questions: $e',
          name: 'QuestionRepo', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Fetch questions for one reading part number (5..7) across all full tests.
  Future<List<QuestionModel>> getQuestionsByReadingPartNumber(
      int partNumber) async {
    try {
      final testsResponse = await _client
          .from('tests')
          .select('id')
          .eq('type', 'full_test') as List<dynamic>;
      if (testsResponse.isEmpty) return [];

      final testIds = testsResponse.map((t) => t['id'] as String).toList();
      final partsResponse = await _client
          .from('test_parts')
          .select('id, test_id')
          .inFilter('test_id', testIds)
          .eq('part_number', partNumber) as List<dynamic>;
      if (partsResponse.isEmpty) return [];

      final partIds = partsResponse.map((p) => p['id'] as String).toList();
      final response = await _client
          .from('questions')
          .select('''
            id,
            part_id,
            passage_id,
            question_text,
            order_index,
            question_options (id, content, is_correct),
            question_media (id, type, url)
          ''')
          .inFilter('part_id', partIds)
          .order('order_index', ascending: true) as List<dynamic>;

      final passageIds = response
          .map((q) => q['passage_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();

      final passageMap = <String, String>{};
      if (passageIds.isNotEmpty) {
        final passagesResponse = await _client
            .from('passages')
            .select('id, content')
            .inFilter('id', passageIds) as List<dynamic>;
        for (final p in passagesResponse) {
          passageMap[p['id'] as String] = (p['content'] as String? ?? '');
        }
      }

      final testOrder = <String, int>{};
      for (int i = 0; i < testIds.length; i++) {
        testOrder[testIds[i]] = i;
      }
      
      final partToTest = <String, String>{};
      for (final p in partsResponse) {
        partToTest[p['id'] as String] = p['test_id'] as String;
      }

      final result = response.map((json) {
        final q = QuestionModel.fromJson(json);
        final content = q.passageId != null ? passageMap[q.passageId] : null;
        return content != null ? q.withPassageContent(content) : q;
      }).toList();

      result.sort((a, b) {
        final testA = partToTest[a.partId] ?? '';
        final testB = partToTest[b.partId] ?? '';
        final orderA = testOrder[testA] ?? 0;
        final orderB = testOrder[testB] ?? 0;
        if (orderA != orderB) return orderA.compareTo(orderB);

        final pA = a.passageId ?? '';
        final pB = b.passageId ?? '';
        if (pA != pB) {
          if (pA.isNotEmpty && pB.isEmpty) return -1;
          if (pA.isEmpty && pB.isNotEmpty) return 1;
          return pA.compareTo(pB);
        }

        return a.orderIndex.compareTo(b.orderIndex);
      });

      return result;
    } catch (e, stack) {
      developer.log('Error fetching reading part questions: $e',
          name: 'QuestionRepo', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Fetch questions by explicit IDs.
  Future<List<QuestionModel>> getQuestionsByIds(List<String> questionIds) async {
    try {
      if (questionIds.isEmpty) return [];

      final response = await _client
          .from('questions')
          .select('''
            id,
            part_id,
            passage_id,
            question_text,
            order_index,
            question_options (id, content, is_correct),
            question_media (id, type, url)
          ''')
          .inFilter('id', questionIds) as List<dynamic>;

      final passageIds = response
          .map((q) => q['passage_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();

      final passageMap = <String, String>{};
      if (passageIds.isNotEmpty) {
        final passagesResponse = await _client
            .from('passages')
            .select('id, content')
            .inFilter('id', passageIds) as List<dynamic>;
        for (final p in passagesResponse) {
          passageMap[p['id'] as String] = (p['content'] as String? ?? '');
        }
      }

      final result = response.map((json) {
        final q = QuestionModel.fromJson(json);
        final content = q.passageId != null ? passageMap[q.passageId] : null;
        return content != null ? q.withPassageContent(content) : q;
      }).toList();

      final indexMap = <String, int>{};
      for (int i = 0; i < questionIds.length; i++) {
        indexMap[questionIds[i]] = i;
      }

      result.sort((a, b) {
        final idxA = indexMap[a.id] ?? 999999;
        final idxB = indexMap[b.id] ?? 999999;
        return idxA.compareTo(idxB);
      });

      return result;
    } catch (e, stack) {
      developer.log('Error fetching questions by ids: $e',
          name: 'QuestionRepo', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Get wrong question IDs for the current user, optionally filtered by listening part.
  Future<List<String>> getWrongQuestionIds({int? partNumber, int limit = 100}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final rows = await _client
          .from('wrong_questions')
          .select('question_id, last_answered_at')
          .eq('user_id', userId)
          .order('last_answered_at', ascending: false)
          .limit(limit) as List<dynamic>;

      final orderedIds = rows.map((r) => r['question_id'] as String).toList();
      if (orderedIds.isEmpty || partNumber == null) return orderedIds;

      final questions = await _client
          .from('questions')
          .select('id, part_id')
          .inFilter('id', orderedIds) as List<dynamic>;
      if (questions.isEmpty) return [];

      final partIdByQuestionId = <String, String>{};
      final partIds = <String>{};
      for (final q in questions) {
        final qid = q['id'] as String;
        final pid = q['part_id'] as String;
        partIdByQuestionId[qid] = pid;
        partIds.add(pid);
      }

      final parts = await _client
          .from('test_parts')
          .select('id, part_number')
          .inFilter('id', partIds.toList()) as List<dynamic>;
      final numberByPartId = <String, int>{};
      for (final p in parts) {
        numberByPartId[p['id'] as String] = (p['part_number'] as num).toInt();
      }

      final filtered = <String>[];
      for (final qid in orderedIds) {
        final pid = partIdByQuestionId[qid];
        if (pid == null) continue;
        if (numberByPartId[pid] == partNumber) {
          filtered.add(qid);
        }
      }
      return filtered;
    } catch (e, stack) {
      developer.log('Error fetching wrong question ids: $e',
          name: 'QuestionRepo', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Get wrong question IDs filtered by any of [partNumbers].
  Future<List<String>> getWrongQuestionIdsByPartNumbers({
    required List<int> partNumbers,
    int limit = 100,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final rows = await _client
          .from('wrong_questions')
          .select('question_id, last_answered_at')
          .eq('user_id', userId)
          .order('last_answered_at', ascending: false)
          .limit(limit) as List<dynamic>;

      final orderedIds = rows.map((r) => r['question_id'] as String).toList();
      if (orderedIds.isEmpty) return [];

      final questions = await _client
          .from('questions')
          .select('id, part_id')
          .inFilter('id', orderedIds) as List<dynamic>;
      if (questions.isEmpty) return [];

      final partIdByQuestionId = <String, String>{};
      final partIds = <String>{};
      for (final q in questions) {
        final qid = q['id'] as String;
        final pid = q['part_id'] as String;
        partIdByQuestionId[qid] = pid;
        partIds.add(pid);
      }

      final parts = await _client
          .from('test_parts')
          .select('id, part_number')
          .inFilter('id', partIds.toList()) as List<dynamic>;
      final numberByPartId = <String, int>{};
      for (final p in parts) {
        numberByPartId[p['id'] as String] = (p['part_number'] as num).toInt();
      }

      final allowed = partNumbers.toSet();
      final filtered = <String>[];
      for (final qid in orderedIds) {
        final pid = partIdByQuestionId[qid];
        if (pid == null) continue;
        if (allowed.contains(numberByPartId[pid])) {
          filtered.add(qid);
        }
      }
      return filtered;
    } catch (e, stack) {
      developer.log('Error fetching wrong question ids by part numbers: $e',
          name: 'QuestionRepo', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Save per-question answer history and upsert wrong questions (deduplicated).
  Future<void> saveListeningPracticeTracking({
    required List<QuestionModel> questions,
    required Map<int, int> userAnswers,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      final now = DateTime.now().toIso8601String();
      final historyRows = <Map<String, dynamic>>[];
      final wrongSelections = <String, String?>{};

      for (int i = 0; i < questions.length; i++) {
        final q = questions[i];
        final selectedIdx = userAnswers[i];
        if (selectedIdx == null || selectedIdx < 0 || selectedIdx >= q.options.length) {
          continue;
        }

        final option = q.options[selectedIdx];
        historyRows.add({
          'user_id': userId,
          'question_id': q.id,
          'selected_option_id': option.id,
          'is_correct': option.isCorrect,
          'answered_at': now,
        });

        if (!option.isCorrect) {
          wrongSelections[q.id] = option.id;
        }
      }

      if (historyRows.isNotEmpty) {
        await _client.from('listening_answer_history').insert(historyRows);
      }

      if (wrongSelections.isEmpty) return;

      final wrongIds = wrongSelections.keys.toList();
      final existingRows = await _client
          .from('wrong_questions')
          .select('question_id, wrong_count')
          .eq('user_id', userId)
          .inFilter('question_id', wrongIds) as List<dynamic>;
      final existingCountByQuestion = <String, int>{
        for (final row in existingRows)
          row['question_id'] as String: (row['wrong_count'] as num?)?.toInt() ?? 0,
      };

      final upsertRows = wrongIds.map((questionId) {
        final previous = existingCountByQuestion[questionId] ?? 0;
        return {
          'user_id': userId,
          'question_id': questionId,
          'last_selected_option_id': wrongSelections[questionId],
          'wrong_count': previous + 1,
          'last_answered_at': now,
        };
      }).toList();

      await _client.from('wrong_questions').upsert(
            upsertRows,
            onConflict: 'user_id,question_id',
          );
    } catch (e, stack) {
      developer.log('Error saving listening practice tracking: $e',
          name: 'QuestionRepo', error: e, stackTrace: stack);
    }
  }

  /// Submit a test attempt — saves attempt + all answers to Supabase
  /// Returns the attempt ID
  Future<String> submitAttempt({
    required String testId,
    required int score,
    required List<QuestionModel> questions,
    required Map<int, int> userAnswers,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      // 1. Create the attempt record
      final attemptResponse = await _client
          .from('attempts')
          .insert({
            'user_id': userId,
            'test_id': testId,
            'score': score,
            'submitted_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      final attemptId = attemptResponse['id'] as String;
      developer.log('Attempt created: $attemptId', name: 'QuestionRepo');

      // 2. Build answers list
      final answerRows = <Map<String, dynamic>>[];
      for (int i = 0; i < questions.length; i++) {
        final q = questions[i];
        final selectedIdx = userAnswers[i];

        String? selectedOptionId;
        bool isCorrect = false;

        if (selectedIdx != null && selectedIdx < q.options.length) {
          selectedOptionId = q.options[selectedIdx].id;
          isCorrect = q.options[selectedIdx].isCorrect;
        }

        answerRows.add({
          'attempt_id': attemptId,
          'question_id': q.id,
          'option_id': selectedOptionId,
          'is_correct': isCorrect,
        });
      }

      // 3. Bulk insert answers
      if (answerRows.isNotEmpty) {
        await _client.from('answers').insert(answerRows);
        developer.log('Inserted ${answerRows.length} answers',
            name: 'QuestionRepo');
      }

      // 4. Push in-app notification for test completion (non-blocking)
      try {
        final testRow = await _client
            .from('tests')
            .select('title')
            .eq('id', testId)
            .maybeSingle();

        final testTitle = (testRow?['title'] as String?)?.trim();
        final submittedAt = DateTime.now();
        final dateLabel =
            '${submittedAt.day.toString().padLeft(2, '0')}/${submittedAt.month.toString().padLeft(2, '0')}/${submittedAt.year} '
            '${submittedAt.hour.toString().padLeft(2, '0')}:${submittedAt.minute.toString().padLeft(2, '0')}';

        await _client.from('notifications').insert({
          'recipient_user_id': userId,
          'type': 'test_completed',
          'title': 'Ban vua hoan thanh bai test',
          'body': '${(testTitle != null && testTitle.isNotEmpty) ? testTitle : 'Bai thi TOEIC'} - diem $score luc $dateLabel.',
          'metadata': {
            'attemptId': attemptId,
            'testId': testId,
            'testTitle': (testTitle != null && testTitle.isNotEmpty)
                ? testTitle
                : 'Bai thi TOEIC',
            'score': score,
            'submittedAt': submittedAt.toIso8601String(),
          },
        });
      } catch (notifyError, notifyStack) {
        developer.log(
          'Cannot create test completion notification: $notifyError',
          name: 'QuestionRepo',
          error: notifyError,
          stackTrace: notifyStack,
        );
      }

      return attemptId;
    } catch (e, stack) {
      developer.log('Error submitting attempt: $e',
          name: 'QuestionRepo', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Get all attempts for the current user on a specific test
  Future<List<Map<String, dynamic>>> getUserAttempts(String testId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('attempts')
          .select('id, score, started_at, submitted_at')
          .eq('user_id', userId)
          .eq('test_id', testId)
          .order('submitted_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e, stack) {
      developer.log('Error fetching user attempts: $e',
          name: 'QuestionRepo', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Get exam attempt history for the current user.
  Future<List<AttemptHistoryItemModel>> getUserAttemptHistory({
    int limit = 50,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final attemptsResponse = await _client
          .from('attempts')
          .select('id, test_id, score, submitted_at')
          .eq('user_id', userId)
          .order('submitted_at', ascending: false)
          .limit(limit) as List<dynamic>;

      if (attemptsResponse.isEmpty) return [];

      final attemptIds = attemptsResponse
          .map((attempt) => attempt['id'] as String)
          .toList();
      final testIds = attemptsResponse
          .map((attempt) => attempt['test_id'] as String)
          .toSet()
          .toList();

      final testsResponse = await _client
          .from('tests')
          .select('id, title')
          .inFilter('id', testIds) as List<dynamic>;

      final answersResponse = await _client
          .from('answers')
          .select('attempt_id, option_id, is_correct')
          .inFilter('attempt_id', attemptIds) as List<dynamic>;

      final testTitleById = <String, String>{
        for (final row in testsResponse)
          row['id'] as String: (row['title'] as String?) ?? 'Bài thi TOEIC',
      };

      final answeredByAttemptId = <String, int>{};
      final correctByAttemptId = <String, int>{};
      for (final row in answersResponse) {
        final attemptId = row['attempt_id'] as String;
        final optionId = row['option_id'] as String?;
        final isCorrect = (row['is_correct'] as bool?) ?? false;

        if (optionId != null && optionId.isNotEmpty) {
          answeredByAttemptId[attemptId] =
              (answeredByAttemptId[attemptId] ?? 0) + 1;
        }

        if (isCorrect) {
          correctByAttemptId[attemptId] =
              (correctByAttemptId[attemptId] ?? 0) + 1;
        }
      }

      return attemptsResponse.map((attempt) {
        final attemptId = attempt['id'] as String;
        return AttemptHistoryItemModel(
          id: attemptId,
          testId: attempt['test_id'] as String,
          testTitle:
              testTitleById[attempt['test_id'] as String] ?? 'Bài thi TOEIC',
          score: (attempt['score'] as num?)?.toInt() ?? 0,
          submittedAt: DateTime.tryParse(attempt['submitted_at'] as String? ?? '') ??
              DateTime.now(),
          answeredCount: answeredByAttemptId[attemptId] ?? 0,
          correctCount: correctByAttemptId[attemptId] ?? 0,
        );
      }).toList();
    } catch (e, stack) {
      developer.log('Error fetching attempt history: $e',
          name: 'QuestionRepo', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Get full detail for one attempt, including all questions in that test.
  Future<AttemptDetailModel?> getAttemptDetail(String attemptId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final attemptResponse = await _client
          .from('attempts')
          .select('id, test_id, score, submitted_at')
          .eq('id', attemptId)
          .eq('user_id', userId)
          .maybeSingle();

      if (attemptResponse == null) return null;

      final testId = attemptResponse['test_id'] as String;

      final testResponse = await _client
          .from('tests')
          .select('id, title')
          .eq('id', testId)
          .maybeSingle();

      final partsResponse = await _client
          .from('test_parts')
          .select('id, part_number')
          .eq('test_id', testId) as List<dynamic>;

      final answersResponse = await _client
          .from('answers')
          .select('question_id, option_id, is_correct')
          .eq('attempt_id', attemptId) as List<dynamic>;

      final questions = await getQuestionsByTestId(testId);

      final partNumberByPartId = <String, int>{
        for (final row in partsResponse)
          row['id'] as String: (row['part_number'] as num?)?.toInt() ?? 0,
      };

      final selectedOptionByQuestionId = <String, String?>{};
      final isCorrectByQuestionId = <String, bool>{};
      for (final row in answersResponse) {
        final questionId = row['question_id'] as String;
        selectedOptionByQuestionId[questionId] = row['option_id'] as String?;
        isCorrectByQuestionId[questionId] = (row['is_correct'] as bool?) ?? false;
      }

      final orderedQuestions = [...questions]
        ..sort((a, b) {
          final partA = partNumberByPartId[a.partId] ?? 999;
          final partB = partNumberByPartId[b.partId] ?? 999;
          if (partA != partB) return partA.compareTo(partB);
          return a.orderIndex.compareTo(b.orderIndex);
        });

      final details = orderedQuestions.map((question) {
        final selectedOptionId = selectedOptionByQuestionId[question.id];
        return AttemptQuestionDetailModel(
          question: question,
          partNumber: partNumberByPartId[question.partId] ?? 0,
          selectedOptionId: selectedOptionId,
          isCorrect: isCorrectByQuestionId[question.id] ?? false,
        );
      }).toList();

      final answeredCount =
          details.where((detail) => detail.isAnswered).length;
      final correctCount = details.where((detail) => detail.isCorrect).length;

      return AttemptDetailModel(
        id: attemptResponse['id'] as String,
        testId: testId,
        testTitle: (testResponse?['title'] as String?) ?? 'Bài thi TOEIC',
        score: (attemptResponse['score'] as num?)?.toInt() ?? 0,
        submittedAt:
            DateTime.tryParse(attemptResponse['submitted_at'] as String? ?? '') ??
                DateTime.now(),
        answeredCount: answeredCount,
        correctCount: correctCount,
        questionDetails: details,
      );
    } catch (e, stack) {
      developer.log('Error fetching attempt detail: $e',
          name: 'QuestionRepo', error: e, stackTrace: stack);
      return null;
    }
  }
}
