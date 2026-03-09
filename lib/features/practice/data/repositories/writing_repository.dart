import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lexii/features/practice/data/models/writing_prompt_model.dart';

class WritingRepository {
  final SupabaseClient _client;

  WritingRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Fetch writing prompts for a specific part number.
  Future<List<WritingPromptModel>> getPromptsForPart(int partNumber,
      {int? limit}) async {
    developer.log('Fetching writing prompts for part $partNumber',
        name: 'WritingRepo');

    var query = _client
        .from('writing_prompts')
        .select()
        .eq('part_number', partNumber)
        .order('order_index', ascending: true);

    if (limit != null) query = query.limit(limit);

    final response = await query as List<dynamic>;
    return response
        .map((json) =>
            WritingPromptModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Returns {partNumber → totalPromptCount} for all writing parts.
  Future<Map<int, int>> getPromptCounts() async {
    final response = await _client
        .from('writing_prompts')
        .select('part_number') as List<dynamic>;

    final counts = <int, int>{};
    for (final row in response) {
      final pn = (row['part_number'] as num).toInt();
      counts[pn] = (counts[pn] ?? 0) + 1;
    }
    return counts;
  }

  /// Returns {partNumber → submissionCount} for the current user.
  Future<Map<int, int>> getUserSubmissionCounts() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return {};

    final response = await _client
        .from('writing_submissions')
        .select('part_number')
        .eq('user_id', userId) as List<dynamic>;

    final counts = <int, int>{};
    for (final row in response) {
      final pn = (row['part_number'] as num).toInt();
      counts[pn] = (counts[pn] ?? 0) + 1;
    }
    return counts;
  }

  /// Submit a batch of written answers (promptId → content).
  Future<void> submitBatch(
    int partNumber,
    Map<String, String> promptAnswers,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final rows = promptAnswers.entries.map((e) => {
          'user_id': userId,
          'prompt_id': e.key,
          'part_number': partNumber,
          'content': e.value,
          'submitted_at': DateTime.now().toIso8601String(),
        }).toList();

    if (rows.isEmpty) return;
    await _client.from('writing_submissions').insert(rows);
  }
}
