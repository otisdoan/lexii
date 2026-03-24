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

  Future<int> getVocabularyCount() async {
    try {
      final data = await _client.from('vocabulary').select('id');
      return (data as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> getGrammarCount() async {
    try {
      final data = await _client.from('grammar').select('id');
      return (data as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<Set<String>> getSavedVocabularyIds() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return <String>{};

    final data = await _client
        .from('user_saved_vocabulary')
        .select('vocabulary_id')
        .eq('user_id', userId);

    return (data as List)
        .map((e) => (e as Map<String, dynamic>)['vocabulary_id'] as String)
        .toSet();
  }

  Future<Set<String>> getSavedGrammarIds() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return <String>{};

    final data = await _client
        .from('user_saved_grammar')
        .select('grammar_id')
        .eq('user_id', userId);

    return (data as List)
        .map((e) => (e as Map<String, dynamic>)['grammar_id'] as String)
        .toSet();
  }

  Future<void> setVocabularySaved({
    required String vocabularyId,
    required bool isSaved,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Bạn cần đăng nhập để lưu từ vựng.');
    }

    final table = _client.from('user_saved_vocabulary');
    if (isSaved) {
      await table.upsert({
        'user_id': userId,
        'vocabulary_id': vocabularyId,
      }, onConflict: 'user_id,vocabulary_id');
      return;
    }

    await table
        .delete()
        .eq('user_id', userId)
        .eq('vocabulary_id', vocabularyId);
  }

  Future<void> setGrammarSaved({
    required String grammarId,
    required bool isSaved,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Bạn cần đăng nhập để lưu ngữ pháp.');
    }

    final table = _client.from('user_saved_grammar');
    if (isSaved) {
      await table.upsert({
        'user_id': userId,
        'grammar_id': grammarId,
      }, onConflict: 'user_id,grammar_id');
      return;
    }

    await table.delete().eq('user_id', userId).eq('grammar_id', grammarId);
  }
}
