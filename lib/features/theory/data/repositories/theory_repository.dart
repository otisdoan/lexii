import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lexii/features/theory/data/models/theory_models.dart';

class TheoryRepository {
  final SupabaseClient _client;

  TheoryRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<List<VocabularyModel>> getVocabulary({
    int? lesson,
    String? scoreLevel,
  }) async {
    var query = _client.from('vocabulary').select();

    if (lesson != null) {
      query = query.eq('lesson', lesson);
    }
    if (scoreLevel != null) {
      query = query.eq('score_level', scoreLevel);
    }

    final data = await query.order('sort_order', ascending: true);
    return (data as List)
        .map((e) => VocabularyModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<GrammarModel>> getGrammar({int? lesson}) async {
    var query = _client.from('grammar').select();

    if (lesson != null) {
      query = query.eq('lesson', lesson);
    }

    final data = await query
        .order('lesson', ascending: true)
        .order('sort_order', ascending: true);
    return (data as List)
        .map((e) => GrammarModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns distinct lesson numbers available (for filter dropdown).
  Future<List<int>> getLessonNumbers() async {
    final data = await _client
        .from('vocabulary')
        .select('lesson')
        .order('lesson', ascending: true);
    final Set<int> seen = {};
    final List<int> result = [];
    for (final row in data as List) {
      final n = (row['lesson'] as num).toInt();
      if (seen.add(n)) result.add(n);
    }
    return result;
  }
}
