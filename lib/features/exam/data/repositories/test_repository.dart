import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lexii/features/exam/data/models/test_model.dart';

class TestRepository {
  final SupabaseClient _client;

  TestRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Fetch all fulltests (type = 'full_test')
  Future<List<TestModel>> getFullTests() async {
    try {
      final response = await _client
          .from('tests')
          .select()
          .eq('type', 'full_test')
          .order('created_at', ascending: false);

      developer.log('Fulltest response: $response', name: 'TestRepository');

      if (response.isEmpty) {
        // Fallback: try without type filter
        developer.log('No full_test found, trying all tests...', name: 'TestRepository');
        return getAllTests();
      }

      return (response as List)
          .map((json) => TestModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      developer.log('Error fetching fulltests: $e', name: 'TestRepository', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Fetch all minitests (type = 'mini_test')
  Future<List<TestModel>> getMiniTests() async {
    try {
      final response = await _client
          .from('tests')
          .select()
          .eq('type', 'mini_test')
          .order('created_at', ascending: false);

      developer.log('Minitest response: $response', name: 'TestRepository');

      return (response as List)
          .map((json) => TestModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      developer.log('Error fetching minitests: $e', name: 'TestRepository', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Fetch all tests (no type filter)
  Future<List<TestModel>> getAllTests() async {
    try {
      final response = await _client
          .from('tests')
          .select()
          .order('created_at', ascending: false);

      developer.log('All tests response: $response', name: 'TestRepository');

      return (response as List)
          .map((json) => TestModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      developer.log('Error fetching all tests: $e', name: 'TestRepository', error: e, stackTrace: stack);
      rethrow;
    }
  }
}
