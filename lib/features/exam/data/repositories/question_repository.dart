import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lexii/features/exam/data/models/question_model.dart';

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
          .order('order_index', ascending: true);

      developer.log('Questions fetched: ${questionsResponse.length}',
          name: 'QuestionRepo');

      return questionsResponse
          .map((json) => QuestionModel.fromJson(json))
          .toList();
    } catch (e, stack) {
      developer.log('Error fetching questions: $e',
          name: 'QuestionRepo', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Fetch questions for a specific part
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
          .order('order_index', ascending: true);

      return (response as List)
          .map((json) => QuestionModel.fromJson(json))
          .toList();
    } catch (e, stack) {
      developer.log('Error fetching questions by part: $e',
          name: 'QuestionRepo', error: e, stackTrace: stack);
      rethrow;
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
}
