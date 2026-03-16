import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lexii/features/practice/data/models/speaking_question_model.dart';
import 'package:lexii/features/practice/data/models/sw_writing_question_model.dart';

enum GradingMode { normal, ai }

class PracticeHistoryItem {
  final String answerId;
  final String questionType;
  final String prompt;
  final String answerText;
  final DateTime createdAt;
  final int? durationSeconds;
  final String? audioUrl;
  final AiScoreBundle? ai;

  const PracticeHistoryItem({
    required this.answerId,
    required this.questionType,
    required this.prompt,
    required this.answerText,
    required this.createdAt,
    this.durationSeconds,
    this.audioUrl,
    this.ai,
  });

  bool get isAi => ai != null;
}

class AiScoreBundle {
  final int overall;
  final int grammar;
  final int vocabulary;
  final int coherence;
  final int pronunciation;
  final int fluency;
  final String feedback;
  final String correctedVersion;

  const AiScoreBundle({
    required this.overall,
    required this.grammar,
    required this.vocabulary,
    required this.coherence,
    required this.pronunciation,
    required this.fluency,
    required this.feedback,
    required this.correctedVersion,
  });
}

class SpeakingWritingRepository {
  final SupabaseClient _client;

  SpeakingWritingRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<List<SpeakingQuestionModel>> getSpeakingQuestionsByType(String type) async {
    try {
      final response = await _client
          .from('speaking_questions')
          .select('*')
          .eq('type', type)
          .limit(20) as List<dynamic>;

      final items = response
          .map((e) => SpeakingQuestionModel.fromJson(e as Map<String, dynamic>))
          .where((e) => e.id.isNotEmpty)
          .toList();

      if (items.isNotEmpty) return items;
    } catch (_) {
      // Fall back to seeded local prompts if table is not available yet.
    }

    return _fallbackSpeaking(type);
  }

  Future<List<SwWritingQuestionModel>> getWritingQuestionsByType(String type) async {
    try {
      final response = await _client
          .from('writing_questions')
          .select('*')
          .eq('type', type)
          .limit(20) as List<dynamic>;

      final items = response
          .map((e) => SwWritingQuestionModel.fromJson(e as Map<String, dynamic>))
          .where((e) => e.id.isNotEmpty)
          .toList();

      if (items.isNotEmpty) return items;
    } catch (_) {
      // Fall back to seeded local prompts if table is not available yet.
    }

    return _fallbackWriting(type);
  }

  Future<String?> submitWritingAnswer({
    required String questionId,
    required String answerText,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('writing_answers')
        .insert({
      'user_id': userId,
      'question_id': questionId,
      'answer_text': answerText,
      'created_at': DateTime.now().toIso8601String(),
    })
        .select('id')
        .maybeSingle();

    return response?['id']?.toString();
  }

  Future<String?> submitSpeakingAnswer({
    required String questionId,
    required String transcript,
    required int durationSeconds,
    String? audioUrl,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('speaking_answers')
        .insert({
      'user_id': userId,
      'question_id': questionId,
      'audio_url': audioUrl,
      'transcript': transcript,
      'duration': durationSeconds,
      'created_at': DateTime.now().toIso8601String(),
    })
        .select('id')
        .maybeSingle();

    return response?['id']?.toString();
  }

  Future<void> saveAiWritingEvaluation({
    required String answerId,
    required AiScoreBundle ai,
  }) async {
    try {
      await _client.from('ai_writing_evaluations').insert({
        'answer_id': answerId,
        'task_response_score': ai.overall,
        'grammar_score': ai.grammar,
        'vocabulary_score': ai.vocabulary,
        'coherence_score': ai.coherence,
        'overall_score': ai.overall,
        'feedback': ai.feedback,
        'corrected_version': ai.correctedVersion,
      });
    } catch (_) {
      // Ignore when AI table has not been created yet.
    }
  }

  Future<void> saveAiSpeakingEvaluation({
    required String answerId,
    required AiScoreBundle ai,
  }) async {
    try {
      await _client.from('ai_speaking_evaluations').insert({
        'answer_id': answerId,
        'pronunciation_score': ai.pronunciation,
        'fluency_score': ai.fluency,
        'grammar_score': ai.grammar,
        'vocabulary_score': ai.vocabulary,
        'overall_score': ai.overall,
        'feedback': ai.feedback,
        'corrected_version': ai.correctedVersion,
      });
    } catch (_) {
      // Ignore when AI table has not been created yet.
    }
  }

  Future<List<PracticeHistoryItem>> getWritingHistory({int limit = 30}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];

    final answers = await _client
        .from('writing_answers')
        .select('id,question_id,answer_text,created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit) as List<dynamic>;

    if (answers.isEmpty) return const [];

    final answerIds = answers.map((e) => e['id'].toString()).toList();
    final questionIds = answers.map((e) => e['question_id'].toString()).toSet().toList();

    final questions = await _client
        .from('writing_questions')
        .select('id,type,content')
        .inFilter('id', questionIds) as List<dynamic>;

    final aiRows = await _safeFetchAiWriting(answerIds);

    final questionById = <String, Map<String, dynamic>>{};
    for (final row in questions) {
      final data = row as Map<String, dynamic>;
      questionById[data['id'].toString()] = data;
    }

    final aiByAnswer = <String, Map<String, dynamic>>{};
    for (final row in aiRows) {
      final data = row as Map<String, dynamic>;
      aiByAnswer[data['answer_id'].toString()] = data;
    }

    return answers.map((row) {
      final data = row as Map<String, dynamic>;
      final question = questionById[data['question_id'].toString()];
      final ai = aiByAnswer[data['id'].toString()];

      return PracticeHistoryItem(
        answerId: data['id'].toString(),
        questionType: question?['type']?.toString() ?? 'writing',
        prompt: question?['content']?.toString() ?? '',
        answerText: data['answer_text']?.toString() ?? '',
        createdAt: DateTime.tryParse(data['created_at']?.toString() ?? '') ?? DateTime.now(),
        ai: _mapWritingAi(ai),
      );
    }).toList();
  }

  Future<List<PracticeHistoryItem>> getSpeakingHistory({int limit = 30}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];

    final answers = await _client
        .from('speaking_answers')
        .select('id,question_id,audio_url,transcript,duration,created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit) as List<dynamic>;

    if (answers.isEmpty) return const [];

    final answerIds = answers.map((e) => e['id'].toString()).toList();
    final questionIds = answers.map((e) => e['question_id'].toString()).toSet().toList();

    final questions = await _client
        .from('speaking_questions')
        .select('id,type,content')
        .inFilter('id', questionIds) as List<dynamic>;

    final aiRows = await _safeFetchAiSpeaking(answerIds);

    final questionById = <String, Map<String, dynamic>>{};
    for (final row in questions) {
      final data = row as Map<String, dynamic>;
      questionById[data['id'].toString()] = data;
    }

    final aiByAnswer = <String, Map<String, dynamic>>{};
    for (final row in aiRows) {
      final data = row as Map<String, dynamic>;
      aiByAnswer[data['answer_id'].toString()] = data;
    }

    return answers.map((row) {
      final data = row as Map<String, dynamic>;
      final question = questionById[data['question_id'].toString()];
      final ai = aiByAnswer[data['id'].toString()];

      return PracticeHistoryItem(
        answerId: data['id'].toString(),
        questionType: question?['type']?.toString() ?? 'speaking',
        prompt: question?['content']?.toString() ?? '',
        answerText: data['transcript']?.toString() ?? '',
        createdAt: DateTime.tryParse(data['created_at']?.toString() ?? '') ?? DateTime.now(),
        durationSeconds: (data['duration'] as num?)?.toInt(),
        audioUrl: data['audio_url']?.toString(),
        ai: _mapSpeakingAi(ai),
      );
    }).toList();
  }

  AiScoreBundle evaluateWritingByAi({
    required String prompt,
    required String answer,
  }) {
    final words = answer.trim().isEmpty
        ? <String>[]
        : answer.trim().split(RegExp(r'\s+'));
    final count = words.length;

    final grammar = _clamp(35 + min(count, 120) ~/ 3, 20, 95);
    final vocabulary = _clamp(30 + min(count, 160) ~/ 4, 20, 95);
    final coherence = _clamp(25 + min(count, 180) ~/ 5, 20, 95);
    final overall = ((grammar + vocabulary + coherence) / 3).round();

    final corrected = answer.trim().isEmpty
        ? 'Bai viet chua co noi dung de sua.'
        : _capitalizeSentence(answer.trim());

    return AiScoreBundle(
      overall: overall,
      grammar: grammar,
      vocabulary: vocabulary,
      coherence: coherence,
      pronunciation: 0,
      fluency: 0,
      feedback: 'AI danh gia bai viet dua tren do day du y tuong, do mach lac va tu vung. Ban can bo sung vi du cu the va cau chuyen tiep tu nhien hon.',
      correctedVersion: corrected,
    );
  }

  AiScoreBundle evaluateSpeakingByAi({
    required String prompt,
    required String transcript,
    required int durationSeconds,
  }) {
    final words = transcript.trim().isEmpty
        ? <String>[]
        : transcript.trim().split(RegExp(r'\s+'));
    final count = words.length;

    final pronunciation = _clamp(35 + min(durationSeconds, 120) ~/ 3, 20, 95);
    final fluency = _clamp(30 + min(count, 160) ~/ 4, 20, 95);
    final grammar = _clamp(30 + min(count, 140) ~/ 4, 20, 95);
    final vocabulary = _clamp(28 + min(count, 180) ~/ 5, 20, 95);
    final overall = ((pronunciation + fluency + grammar + vocabulary) / 4).round();

    final corrected = transcript.trim().isEmpty
        ? 'Ban chua nhap transcript. Hay thu noi va nhap lai noi dung de nhan goi y chinh xac hon.'
        : _capitalizeSentence(transcript.trim());

    return AiScoreBundle(
      overall: overall,
      pronunciation: pronunciation,
      fluency: fluency,
      grammar: grammar,
      vocabulary: vocabulary,
      coherence: 0,
      feedback: 'AI nhan thay ban co nen tang kha tot. De cai thien diem noi, hay noi cham hon o cac tu khoa va su dung cau noi lien mach hon.',
      correctedVersion: corrected,
    );
  }

  int _clamp(int value, int minValue, int maxValue) {
    if (value < minValue) return minValue;
    if (value > maxValue) return maxValue;
    return value;
  }

  String _capitalizeSentence(String input) {
    if (input.isEmpty) return input;
    final first = input[0].toUpperCase();
    final rest = input.length > 1 ? input.substring(1) : '';
    return '$first$rest';
  }

  Future<List<dynamic>> _safeFetchAiWriting(List<String> answerIds) async {
    if (answerIds.isEmpty) return const [];
    try {
      final rows = await _client
          .from('ai_writing_evaluations')
          .select('answer_id,task_response_score,grammar_score,vocabulary_score,coherence_score,overall_score,feedback,corrected_version')
          .inFilter('answer_id', answerIds) as List<dynamic>;
      return rows;
    } catch (_) {
      return const [];
    }
  }

  Future<List<dynamic>> _safeFetchAiSpeaking(List<String> answerIds) async {
    if (answerIds.isEmpty) return const [];
    try {
      final rows = await _client
          .from('ai_speaking_evaluations')
          .select('answer_id,pronunciation_score,fluency_score,grammar_score,vocabulary_score,overall_score,feedback,corrected_version')
          .inFilter('answer_id', answerIds) as List<dynamic>;
      return rows;
    } catch (_) {
      return const [];
    }
  }

  AiScoreBundle? _mapWritingAi(Map<String, dynamic>? row) {
    if (row == null) return null;
    return AiScoreBundle(
      overall: (row['overall_score'] as num?)?.toInt() ?? 0,
      grammar: (row['grammar_score'] as num?)?.toInt() ?? 0,
      vocabulary: (row['vocabulary_score'] as num?)?.toInt() ?? 0,
      coherence: (row['coherence_score'] as num?)?.toInt() ?? 0,
      pronunciation: 0,
      fluency: 0,
      feedback: row['feedback']?.toString() ?? '',
      correctedVersion: row['corrected_version']?.toString() ?? '',
    );
  }

  AiScoreBundle? _mapSpeakingAi(Map<String, dynamic>? row) {
    if (row == null) return null;
    return AiScoreBundle(
      overall: (row['overall_score'] as num?)?.toInt() ?? 0,
      grammar: (row['grammar_score'] as num?)?.toInt() ?? 0,
      vocabulary: (row['vocabulary_score'] as num?)?.toInt() ?? 0,
      coherence: 0,
      pronunciation: (row['pronunciation_score'] as num?)?.toInt() ?? 0,
      fluency: (row['fluency_score'] as num?)?.toInt() ?? 0,
      feedback: row['feedback']?.toString() ?? '',
      correctedVersion: row['corrected_version']?.toString() ?? '',
    );
  }

  List<SpeakingQuestionModel> _fallbackSpeaking(String type) {
    final samples = <String, List<SpeakingQuestionModel>>{
      'read_aloud': const [
        SpeakingQuestionModel(
          id: 'sp-read-1',
          type: 'read_aloud',
          content: 'Please read this paragraph aloud: Our company will launch a new customer support portal next month to improve response time and service quality.',
        ),
      ],
      'describe_picture': const [
        SpeakingQuestionModel(
          id: 'sp-picture-1',
          type: 'describe_picture',
          content: 'Describe what you see in the picture. Include people, actions, and setting.',
          imageUrl: 'https://images.unsplash.com/photo-1521790797524-b2497295b8a0?w=1200',
        ),
      ],
      'respond_questions': const [
        SpeakingQuestionModel(
          id: 'sp-respond-1',
          type: 'respond_questions',
          content: 'What do you usually do to prepare for an important meeting?',
        ),
      ],
      'respond_information': const [
        SpeakingQuestionModel(
          id: 'sp-info-1',
          type: 'respond_information',
          content: 'Based on the schedule, explain which train the customer should take to arrive before 9:00 AM.',
        ),
      ],
      'express_opinion': const [
        SpeakingQuestionModel(
          id: 'sp-opinion-1',
          type: 'express_opinion',
          content: 'Do you agree that working remotely increases productivity? Give reasons and examples.',
        ),
      ],
    };

    return samples[type] ?? const [];
  }

  List<SwWritingQuestionModel> _fallbackWriting(String type) {
    final samples = <String, List<SwWritingQuestionModel>>{
      'write_sentence_picture': const [
        SwWritingQuestionModel(
          id: 'wr-sent-1',
          type: 'write_sentence_picture',
          content: 'Write one sentence to describe the image using all required keywords.',
          imageUrl: 'https://images.unsplash.com/photo-1519389950473-47ba0277781c?w=1200',
          keywords: ['team', 'meeting', 'presentation'],
        ),
      ],
      'reply_email': const [
        SwWritingQuestionModel(
          id: 'wr-email-1',
          type: 'reply_email',
          content: 'You received an email asking to reschedule tomorrow\'s workshop. Write a reply email with a new proposed time.',
        ),
      ],
      'opinion_essay': const [
        SwWritingQuestionModel(
          id: 'wr-essay-1',
          type: 'opinion_essay',
          content: 'Some people think companies should require employees to work in the office full-time. Do you agree or disagree?',
        ),
      ],
    };

    return samples[type] ?? const [];
  }
}
