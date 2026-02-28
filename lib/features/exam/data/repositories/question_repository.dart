import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lexii/features/exam/data/models/question_model.dart';

class QuestionRepository {
  final SupabaseClient _client;

  QuestionRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Fetch all questions for a test, with options and media
  /// Joins: tests → test_parts → questions → question_options + question_media
  Future<List<QuestionModel>> getQuestionsByTestId(String testId) async {
    try {
      // First get all part IDs for this test
      final partsResponse = await _client
          .from('test_parts')
          .select('id')
          .eq('test_id', testId)
          .order('part_number', ascending: true);

      developer.log('Parts for test $testId: $partsResponse', name: 'QuestionRepo');

      if (partsResponse.isEmpty) return [];

      final partIds = partsResponse.map((p) => p['id'] as String).toList();

      // Now fetch all questions with nested options and media
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

      developer.log('Questions fetched: ${questionsResponse.length}', name: 'QuestionRepo');

      return questionsResponse
          .map((json) => QuestionModel.fromJson(json))
          .toList();
    } catch (e, stack) {
      developer.log('Error fetching questions: $e', name: 'QuestionRepo', error: e, stackTrace: stack);
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
      developer.log('Error fetching questions by part: $e', name: 'QuestionRepo', error: e, stackTrace: stack);
      rethrow;
    }
  }
}
