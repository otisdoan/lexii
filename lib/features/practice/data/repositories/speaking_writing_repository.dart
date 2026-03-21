import 'dart:math';
import 'dart:convert';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:lexii/config/gemini_api_key.dart';
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
  final List<String> vocabularyHighlights;
  final Map<String, int> taskScores;
  final List<String> errors;
  final List<String> missingDetails;
  final List<String> wrongInformation;
  final String aiSuggestedAnswer;

  const AiScoreBundle({
    required this.overall,
    required this.grammar,
    required this.vocabulary,
    required this.coherence,
    required this.pronunciation,
    required this.fluency,
    required this.feedback,
    required this.correctedVersion,
    this.vocabularyHighlights = const [],
    this.taskScores = const {},
    this.errors = const [],
    this.missingDetails = const [],
    this.wrongInformation = const [],
    this.aiSuggestedAnswer = '',
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
    required String taskType,
    required String prompt,
    required String answer,
  }) {
    final words = answer.trim().isEmpty
        ? <String>[]
        : answer.trim().split(RegExp(r'\s+'));
    final count = words.length;

    final promptTokens = _extractEnglishTokens(prompt);
    final answerTokens = _extractEnglishTokens(answer);
    final taskMatchRatio = _tokenOverlapRatio(promptTokens, answerTokens);

    final grammar = _clamp(35 + min(count, 140) ~/ 3, 20, 95);
    final vocabulary = _clamp(30 + min(count, 160) ~/ 4 + (taskMatchRatio * 8).round(), 20, 95);
    final coherence = _clamp(25 + min(count, 180) ~/ 5 + (taskMatchRatio * 12).round(), 20, 95);
    final overall = ((grammar + vocabulary + coherence) / 3).round();

    final corrected = answer.trim().isEmpty
        ? 'Bạn chưa có nội dung bài viết để hệ thống chỉnh sửa.'
        : _polishTranscript(answer.trim());

    final taskScores = _buildWritingTaskScores(
      taskType: taskType,
      grammar: grammar,
      vocabulary: vocabulary,
      coherence: coherence,
      taskMatchRatio: taskMatchRatio,
    );

    final errors = _buildWritingHeuristicErrors(
      taskType: taskType,
      answer: answer,
      taskMatchRatio: taskMatchRatio,
    );

    final feedback = _buildWritingTaskFeedback(
      taskType: taskType,
      overall: overall,
      taskScores: taskScores,
      taskMatchRatio: taskMatchRatio,
      errors: errors,
    );

    return AiScoreBundle(
      overall: overall,
      grammar: grammar,
      vocabulary: vocabulary,
      coherence: coherence,
      pronunciation: 0,
      fluency: 0,
      feedback: feedback,
      correctedVersion: corrected,
      vocabularyHighlights: _buildImportantWordsFromPrompt(prompt),
      taskScores: taskScores,
      errors: errors,
      aiSuggestedAnswer: _buildWritingSuggestedAnswer(
        taskType: taskType,
        prompt: prompt,
        corrected: corrected,
      ),
    );
  }

  Future<AiScoreBundle> evaluateWritingByGemini({
    required String taskType,
    required String prompt,
    required String answer,
  }) async {
    final apiKey = _resolveGeminiApiKey();
    if (apiKey.isEmpty) {
      final fallback = evaluateWritingByAi(
        taskType: taskType,
        prompt: prompt,
        answer: answer,
      );

      return AiScoreBundle(
        overall: fallback.overall,
        grammar: fallback.grammar,
        vocabulary: fallback.vocabulary,
        coherence: fallback.coherence,
        pronunciation: 0,
        fluency: 0,
        feedback:
            '${fallback.feedback}\n\nLưu ý: Chưa cấu hình GEMINI_API_KEY nên hệ thống đang dùng AI nội bộ (fallback).',
        correctedVersion: fallback.correctedVersion,
        vocabularyHighlights: fallback.vocabularyHighlights,
        taskScores: fallback.taskScores,
        errors: fallback.errors,
        aiSuggestedAnswer: fallback.aiSuggestedAnswer,
      );
    }

    final model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(temperature: 0.2),
    );

    final content = answer.trim().isEmpty
        ? '(người học chưa có nội dung rõ ràng, hãy trả phản hồi theo hướng dẫn cải thiện cụ thể)'
        : answer.trim();

    final promptText = _buildGeminiWritingPrompt(
      taskType: taskType,
      prompt: prompt,
      answer: content,
    );

    final response = await model
        .generateContent([Content.text(promptText)])
        .timeout(const Duration(seconds: 20));

    final raw = response.text ?? '';
    final jsonObject = _extractJsonObject(raw);
    final data = jsonDecode(jsonObject) as Map<String, dynamic>;

    return _mapGeminiWritingResult(
      taskType: taskType,
      prompt: prompt,
      data: data,
      fallbackAnswer: content,
    );
  }

  AiScoreBundle evaluateSpeakingByAi({
    required String taskType,
    required String prompt,
    required String transcript,
    required int durationSeconds,
  }) {
    final words = transcript.trim().isEmpty
      ? <String>[]
      : transcript.trim().split(RegExp(r'\s+'));
    final count = words.length;

    final promptTokens = _extractEnglishTokens(prompt);
    final answerTokens = _extractEnglishTokens(transcript);
    final taskMatchRatio = _tokenOverlapRatio(promptTokens, answerTokens);
    final taskMatchScore = _clamp((taskMatchRatio * 100).round(), 20, 98);

    final durationScore = _clamp(25 + min(durationSeconds, 120) ~/ 2, 20, 95);
    final lengthScore = _clamp(20 + min(count, 140) ~/ 2, 20, 95);

    final wordsPerMinute = durationSeconds <= 0
      ? 0.0
      : (count / durationSeconds) * 60;
    final fluencyPenalty = (wordsPerMinute < 70 || wordsPerMinute > 190) ? 10 : 0;

    final pronunciation = _clamp(((taskMatchScore * 0.45) + (durationScore * 0.35) + (lengthScore * 0.2)).round(), 20, 98);
    final fluency = _clamp((durationScore - fluencyPenalty + 8), 20, 98);
    final grammar = _clamp(((lengthScore * 0.4) + (taskMatchScore * 0.6)).round() - 6, 20, 98);
    final vocabulary = _clamp(((lengthScore * 0.5) + (taskMatchScore * 0.5)).round(), 20, 98);
    final coherence = _clamp(((taskMatchScore * 0.7) + (fluency * 0.3)).round(), 20, 98);

    final taskScores = _buildTaskScores(
      taskType: taskType,
      overall: 0,
      pronunciation: pronunciation,
      fluency: fluency,
      grammar: grammar,
      vocabulary: vocabulary,
      coherence: coherence,
      taskMatchScore: taskMatchScore,
    );

    final overall = _overallFromTaskScores(taskScores);

    final errors = _buildHeuristicErrors(
      taskType: taskType,
      transcript: transcript,
      taskMatchRatio: taskMatchRatio,
      wordsPerMinute: wordsPerMinute,
    );

    final corrected = transcript.trim().isEmpty
      ? 'Bạn chưa có transcript để hệ thống chỉnh sửa. Hãy ghi âm lại và nộp bài để nhận phản hồi chính xác hơn.'
      : _polishTranscript(transcript.trim());

    final vocabHighlights = _buildImportantWordsFromPrompt(prompt);

    final feedback = _buildTaskSpecificFeedback(
      taskType: taskType,
      overall: overall,
      taskMatchRatio: taskMatchRatio,
      taskScores: taskScores,
      errors: errors,
    );

      final aiSuggestedAnswer = _buildSuggestedAnswer(
        taskType: taskType,
        prompt: prompt,
        correctedTranscript: corrected,
      );

    return AiScoreBundle(
      overall: overall,
      pronunciation: pronunciation,
      fluency: fluency,
      grammar: grammar,
      vocabulary: vocabulary,
      coherence: coherence,
      feedback: feedback,
      correctedVersion: corrected,
      vocabularyHighlights: vocabHighlights,
      taskScores: taskScores,
      errors: errors,
      aiSuggestedAnswer: aiSuggestedAnswer,
    );
  }

  Future<AiScoreBundle> evaluateSpeakingByGemini({
    required String taskType,
    required String prompt,
    required String transcript,
    required int durationSeconds,
  }) async {
    final apiKey = _resolveGeminiApiKey();
    if (apiKey.isEmpty) {
      final fallback = evaluateSpeakingByAi(
        taskType: taskType,
        prompt: prompt,
        transcript: transcript,
        durationSeconds: durationSeconds,
      );

      return AiScoreBundle(
        overall: fallback.overall,
        grammar: fallback.grammar,
        vocabulary: fallback.vocabulary,
        coherence: fallback.coherence,
        pronunciation: fallback.pronunciation,
        fluency: fallback.fluency,
        feedback:
            '${fallback.feedback}\n\nLưu ý: Chưa cấu hình GEMINI_API_KEY nên hệ thống đang dùng AI nội bộ (fallback).',
        correctedVersion: fallback.correctedVersion,
        vocabularyHighlights: fallback.vocabularyHighlights,
        taskScores: fallback.taskScores,
        errors: fallback.errors,
        missingDetails: fallback.missingDetails,
        wrongInformation: fallback.wrongInformation,
        aiSuggestedAnswer: fallback.aiSuggestedAnswer,
      );
    }

    final model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.2,
      ),
    );

    final safeTranscript = transcript.trim().isEmpty
        ? '(người dùng chưa có transcript rõ ràng, hãy đánh giá dựa trên dữ liệu hiện có và nêu khuyến nghị cụ thể)'
        : transcript.trim();

    final fullPrompt = _buildGeminiSpeakingPrompt(
      taskType: taskType,
      prompt: prompt,
      transcript: safeTranscript,
      durationSeconds: durationSeconds,
    );

    final response = await model
        .generateContent([
          Content.text(fullPrompt),
        ])
        .timeout(const Duration(seconds: 20));

    final raw = response.text ?? '';
    final jsonObject = _extractJsonObject(raw);
    final data = jsonDecode(jsonObject) as Map<String, dynamic>;

    return _mapGeminiSpeakingResult(
      taskType: taskType,
      prompt: prompt,
      data: data,
      fallbackTranscript: safeTranscript,
    );
  }

  Future<String> transcribeSpeakingAudioWithGemini({
    required String audioPath,
    String localeHint = 'en-US',
  }) async {
    final apiKey = _resolveGeminiApiKey();
    if (apiKey.isEmpty) return '';

    final file = File(audioPath);
    if (!await file.exists()) return '';

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return '';

    final model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.0,
      ),
    );

    final response = await model
        .generateContent([
          Content.multi([
            TextPart(
              'Transcribe this spoken English audio for TOEIC practice. '
              'Return plain text only, no markdown, no notes. '
              'Locale hint: $localeHint.',
            ),
            DataPart('audio/m4a', bytes),
          ]),
        ])
        .timeout(const Duration(seconds: 20));

    return (response.text ?? '').trim();
  }

  int _clamp(int value, int minValue, int maxValue) {
    if (value < minValue) return minValue;
    if (value > maxValue) return maxValue;
    return value;
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

  int _toScore(dynamic value) {
    final number = (value as num?)?.toInt() ?? 0;
    return _clamp(number, 0, 100);
  }

  List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    }
    return const [];
  }

  String _extractJsonObject(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      return trimmed;
    }

    final first = trimmed.indexOf('{');
    final last = trimmed.lastIndexOf('}');
    if (first >= 0 && last > first) {
      return trimmed.substring(first, last + 1);
    }

    throw const FormatException('Gemini response does not contain valid JSON object.');
  }

  Map<String, int> _buildTaskScores({
    required String taskType,
    required int overall,
    required int pronunciation,
    required int fluency,
    required int grammar,
    required int vocabulary,
    required int coherence,
    required int taskMatchScore,
  }) {
    switch (taskType) {
      case 'read_aloud':
        return {
          'Accuracy': taskMatchScore,
          'Pronunciation': pronunciation,
          'Fluency': fluency,
          'Intonation': _clamp((fluency + pronunciation) ~/ 2, 20, 98),
        };
      case 'describe_picture':
        return {
          'Content': taskMatchScore,
          'Vocabulary': vocabulary,
          'Grammar': grammar,
          'Fluency': fluency,
        };
      case 'respond_questions':
        return {
          'Relevance': taskMatchScore,
          'Grammar': grammar,
          'Vocabulary': vocabulary,
          'Fluency': fluency,
        };
      case 'respond_information':
        return {
          'Information Accuracy': taskMatchScore,
          'Completeness': coherence,
          'Grammar': grammar,
          'Fluency': fluency,
        };
      case 'express_opinion':
        return {
          'Opinion Clarity': coherence,
          'Reasoning': taskMatchScore,
          'Vocabulary': vocabulary,
          'Grammar': grammar,
          'Fluency': fluency,
        };
      default:
        return {
          'Pronunciation': pronunciation,
          'Fluency': fluency,
          'Grammar': grammar,
          'Vocabulary': vocabulary,
          'Coherence': coherence,
          'Overall': overall,
        };
    }
  }

  List<String> _buildHeuristicErrors({
    required String taskType,
    required String transcript,
    required double taskMatchRatio,
    required double wordsPerMinute,
  }) {
    final errors = <String>[];

    if (transcript.trim().split(RegExp(r'\s+')).length < 12) {
      errors.add('Nội dung quá ngắn, chưa đủ phát triển ý theo yêu cầu bài nói TOEIC.');
    }
    if (taskMatchRatio < 0.25) {
      errors.add('Câu trả lời bám đề chưa tốt, còn thiếu nhiều ý liên quan trực tiếp đến câu hỏi.');
    }
    if (wordsPerMinute > 200) {
      errors.add('Tốc độ nói quá nhanh, dễ làm giảm độ rõ ràng và độ chính xác phát âm.');
    } else if (wordsPerMinute > 0 && wordsPerMinute < 65) {
      errors.add('Tốc độ nói chậm, ngắt quãng nhiều, ảnh hưởng điểm Fluency.');
    }

    if (taskType == 'read_aloud') {
      errors.add('Cần chú ý nhấn trọng âm từ khóa và ngắt nhịp theo dấu câu để cải thiện Intonation.');
    }

    return errors;
  }

  String _buildSuggestedAnswer({
    required String taskType,
    required String prompt,
    required String correctedTranscript,
  }) {
    if (taskType == 'read_aloud') {
      return prompt;
    }

    if (correctedTranscript.trim().isNotEmpty) {
      return correctedTranscript;
    }

    return 'Gợi ý: xây dựng câu trả lời theo cấu trúc mở ý - phát triển ý - kết luận, dùng câu ngắn rõ nghĩa và từ nối mạch lạc.';
  }

  String _buildGeminiSpeakingPrompt({
    required String taskType,
    required String prompt,
    required String transcript,
    required int durationSeconds,
  }) {
    final schemaByTask = <String, String>{
      'read_aloud': '''
{
  "task_type": "read_aloud",
  "overall_score": 0,
  "accuracy_score": 0,
  "pronunciation_score": 0,
  "fluency_score": 0,
  "intonation_score": 0,
  "errors": [],
  "feedback": "",
  "ai_suggested_reading": ""
}
''',
      'describe_picture': '''
{
  "task_type": "describe_picture",
  "overall_score": 0,
  "content_score": 0,
  "vocabulary_score": 0,
  "grammar_score": 0,
  "fluency_score": 0,
  "missing_details": [],
  "errors": [],
  "feedback": "",
  "ai_suggested_answer": ""
}
''',
      'respond_questions': '''
{
  "task_type": "answer_question",
  "overall_score": 0,
  "relevance_score": 0,
  "grammar_score": 0,
  "vocabulary_score": 0,
  "fluency_score": 0,
  "errors": [],
  "feedback": "",
  "ai_suggested_answer": ""
}
''',
      'respond_information': '''
{
  "task_type": "respond_using_information",
  "overall_score": 0,
  "information_accuracy_score": 0,
  "completeness_score": 0,
  "grammar_score": 0,
  "fluency_score": 0,
  "wrong_information": [],
  "feedback": "",
  "ai_suggested_answer": ""
}
''',
      'express_opinion': '''
{
  "task_type": "express_opinion",
  "overall_score": 0,
  "opinion_clarity_score": 0,
  "reasoning_score": 0,
  "vocabulary_score": 0,
  "grammar_score": 0,
  "fluency_score": 0,
  "errors": [],
  "feedback": "",
  "ai_suggested_answer": ""
}
''',
    };

    final schema = schemaByTask[taskType] ?? schemaByTask['respond_questions']!;

    return '''
Bạn là giám khảo TOEIC Speaking chuyên nghiệp.
Chấm bài theo đúng task_type: $taskType.
Nhận xét bắt buộc bằng tiếng Việt có dấu, chuyên sâu, cụ thể lỗi sai.

Đầu vào:
- Prompt/Reference: $prompt
- User Transcript: $transcript
- Duration (seconds): $durationSeconds

Yêu cầu đầu ra:
- Trả về duy nhất JSON hợp lệ.
- Điểm số phải từ 0 đến 100.
- Có danh sách lỗi rõ ràng.
- Luôn có đáp án mẫu tốt hơn để người học tham khảo.

JSON schema bắt buộc:
$schema
''';
  }

  AiScoreBundle _mapGeminiSpeakingResult({
    required String taskType,
    required String prompt,
    required Map<String, dynamic> data,
    required String fallbackTranscript,
  }) {
    final rawOverall = _toScore(_readInt(data, const ['overall_score', 'overall']));
    final pronunciation = _toScore(_readInt(data, const ['pronunciation_score', 'pronunciation']));
    final fluency = _toScore(_readInt(data, const ['fluency_score', 'fluency']));
    final grammar = _toScore(_readInt(data, const ['grammar_score', 'grammar']));
    final vocabulary = _toScore(_readInt(data, const ['vocabulary_score', 'vocabulary']));
    final coherence = _toScore(
      _readInt(
        data,
        const ['coherence_score', 'relevance_score', 'reasoning_score', 'completeness_score', 'content_score'],
      ),
    );

    final Map<String, int> taskScores;
    switch (taskType) {
      case 'read_aloud':
        taskScores = {
          'Accuracy': _toScore(_readInt(data, const ['accuracy_score'])),
          'Pronunciation': pronunciation,
          'Fluency': fluency,
          'Intonation': _toScore(_readInt(data, const ['intonation_score'])),
        };
        break;
      case 'describe_picture':
        taskScores = {
          'Content': _toScore(_readInt(data, const ['content_score'])),
          'Vocabulary': vocabulary,
          'Grammar': grammar,
          'Fluency': fluency,
        };
        break;
      case 'respond_questions':
        taskScores = {
          'Relevance': _toScore(_readInt(data, const ['relevance_score'])),
          'Grammar': grammar,
          'Vocabulary': vocabulary,
          'Fluency': fluency,
        };
        break;
      case 'respond_information':
        taskScores = {
          'Information Accuracy': _toScore(_readInt(data, const ['information_accuracy_score'])),
          'Completeness': _toScore(_readInt(data, const ['completeness_score'])),
          'Grammar': grammar,
          'Fluency': fluency,
        };
        break;
      case 'express_opinion':
        taskScores = {
          'Opinion Clarity': _toScore(_readInt(data, const ['opinion_clarity_score'])),
          'Reasoning': _toScore(_readInt(data, const ['reasoning_score'])),
          'Vocabulary': vocabulary,
          'Grammar': grammar,
          'Fluency': fluency,
        };
        break;
      default:
        taskScores = {
          'Pronunciation': pronunciation,
          'Fluency': fluency,
          'Grammar': grammar,
          'Vocabulary': vocabulary,
          'Coherence': coherence,
        };
    }

    final suggestedAnswer = _readString(data, const ['ai_suggested_answer', 'ai_suggested_reading', 'correctedVersion']);

    final normalizedScores = _normalizeTaskScores(taskType, taskScores);
    final overall = _overallFromTaskScores(normalizedScores, fallback: rawOverall);

    return AiScoreBundle(
      overall: overall,
      pronunciation: pronunciation,
      fluency: fluency,
      grammar: grammar,
      vocabulary: vocabulary,
      coherence: coherence,
      feedback: _readString(data, const ['feedback']),
      correctedVersion: _readString(data, const ['correctedVersion', 'ai_suggested_answer', 'ai_suggested_reading']).isNotEmpty
          ? _readString(data, const ['correctedVersion', 'ai_suggested_answer', 'ai_suggested_reading'])
          : fallbackTranscript,
      vocabularyHighlights: _buildImportantWordsFromPrompt(prompt),
      taskScores: normalizedScores,
      errors: _toStringList(data['errors']),
      missingDetails: _toStringList(data['missing_details']),
      wrongInformation: _toStringList(data['wrong_information']),
      aiSuggestedAnswer: suggestedAnswer,
    );
  }

  Map<String, int> _buildWritingTaskScores({
    required String taskType,
    required int grammar,
    required int vocabulary,
    required int coherence,
    required double taskMatchRatio,
  }) {
    final relevance = _clamp((taskMatchRatio * 100).round(), 20, 98);
    switch (taskType) {
      case 'write_sentence_picture':
        return {
          'Content': relevance,
          'Vocabulary': vocabulary,
          'Grammar': grammar,
          'Fluency': coherence,
        };
      case 'reply_email':
        return {
          'Relevance': relevance,
          'Grammar': grammar,
          'Vocabulary': vocabulary,
          'Completeness': coherence,
        };
      case 'opinion_essay':
        return {
          'Opinion Clarity': coherence,
          'Reasoning': relevance,
          'Vocabulary': vocabulary,
          'Grammar': grammar,
        };
      default:
        return {
          'Coherence': coherence,
          'Grammar': grammar,
          'Vocabulary': vocabulary,
        };
    }
  }

  List<String> _buildWritingHeuristicErrors({
    required String taskType,
    required String answer,
    required double taskMatchRatio,
  }) {
    final errors = <String>[];
    final words = answer.trim().isEmpty ? 0 : answer.trim().split(RegExp(r'\s+')).length;

    if (words < 30) {
      errors.add('Bài viết còn ngắn, chưa phát triển đủ ý theo yêu cầu của dạng bài.');
    }
    if (taskMatchRatio < 0.25) {
      errors.add('Nội dung bám đề chưa tốt, cần trả lời sát yêu cầu của đề hơn.');
    }
    if (taskType == 'reply_email' && !answer.contains('@') && !answer.toLowerCase().contains('dear')) {
      errors.add('Dạng email nên có mở đầu và ngữ điệu lịch sự rõ ràng.');
    }
    if (taskType == 'opinion_essay' && !answer.toLowerCase().contains('because')) {
      errors.add('Bài opinion cần nêu lý do rõ ràng, nên dùng các từ nối như because, therefore, however.');
    }

    return errors;
  }

  String _buildWritingTaskFeedback({
    required String taskType,
    required int overall,
    required Map<String, int> taskScores,
    required double taskMatchRatio,
    required List<String> errors,
  }) {
    final scoreLine = taskScores.entries.map((e) => '- ${e.key}: ${e.value}/100').join('\n');
    final errorLine = errors.isEmpty
        ? '- Bài viết tương đối ổn định, cần tiếp tục mở rộng lập luận và ví dụ.'
        : errors.map((e) => '- $e').join('\n');

    final plan = switch (taskType) {
      'write_sentence_picture' => 'Đảm bảo mô tả đủ đối tượng, hành động và bối cảnh xuất hiện trong hình.',
      'reply_email' => 'Viết theo bố cục email rõ: chào mở đầu, trả lời trọng tâm, đề xuất hành động tiếp theo.',
      'opinion_essay' => 'Nêu quan điểm ở mở bài, mỗi đoạn thân bài có 1 lý do + 1 ví dụ cụ thể.',
      _ => 'Giữ câu ngắn gọn, mạch lạc và dùng từ nối để liên kết ý tốt hơn.',
    };

    return '''
1) Đánh giá tổng quan:
- Overall: $overall/100
- Mức độ bám đề: ${(taskMatchRatio * 100).toStringAsFixed(0)}%

2) Điểm thành phần:
$scoreLine

3) Lỗi cần sửa:
$errorLine

4) Gợi ý cải thiện:
- $plan
''';
  }

  String _buildWritingSuggestedAnswer({
    required String taskType,
    required String prompt,
    required String corrected,
  }) {
    if (corrected.trim().isNotEmpty) return corrected;
    if (taskType == 'reply_email') {
      return 'Dear Sir/Madam,\nThank you for your email. I would like to suggest rescheduling the workshop to next Tuesday at 9:00 AM. Please let me know if this works for you.\nBest regards,';
    }
    return 'Bài mẫu gợi ý: trả lời đúng trọng tâm đề, dùng câu rõ nghĩa, có từ nối và ví dụ cụ thể.';
  }

  String _buildGeminiWritingPrompt({
    required String taskType,
    required String prompt,
    required String answer,
  }) {
    return '''
Bạn là giám khảo TOEIC Writing chuyên nghiệp.
Hãy chấm đúng theo task_type: $taskType.
Nhận xét bằng tiếng Việt có dấu, chuyên sâu, nêu lỗi cụ thể.

Đầu vào:
- Đề bài: $prompt
- Bài viết học viên: $answer

Trả về duy nhất JSON hợp lệ theo schema:
{
  "overall_score": 0,
  "grammar_score": 0,
  "vocabulary_score": 0,
  "coherence_score": 0,
  "task_scores": {"criterion": 0},
  "errors": [],
  "feedback": "",
  "ai_suggested_answer": "",
  "corrected_version": "",
  "vocabulary_important": ["word (type): nghĩa"]
}
''';
  }

  AiScoreBundle _mapGeminiWritingResult({
    required String taskType,
    required String prompt,
    required Map<String, dynamic> data,
    required String fallbackAnswer,
  }) {
    final grammar = _toScore(_readInt(data, const ['grammar_score', 'grammar']));
    final vocabulary = _toScore(_readInt(data, const ['vocabulary_score', 'vocabulary']));
    final coherence = _toScore(_readInt(data, const ['coherence_score', 'coherence']));

    final rawTaskScores = <String, int>{};
    final taskScoresData = data['task_scores'];
    if (taskScoresData is Map) {
      for (final entry in taskScoresData.entries) {
        rawTaskScores[entry.key.toString()] = _toScore(entry.value);
      }
    }

    final taskScores = rawTaskScores.isNotEmpty
        ? rawTaskScores
        : _buildWritingTaskScores(
            taskType: taskType,
            grammar: grammar,
            vocabulary: vocabulary,
            coherence: coherence,
            taskMatchRatio: _tokenOverlapRatio(
              _extractEnglishTokens(prompt),
              _extractEnglishTokens(fallbackAnswer),
            ),
          );

    final overall = _toScore(_readInt(data, const ['overall_score', 'overall'])) > 0
        ? _toScore(_readInt(data, const ['overall_score', 'overall']))
        : _overallFromTaskScores(taskScores);

    return AiScoreBundle(
      overall: overall,
      grammar: grammar,
      vocabulary: vocabulary,
      coherence: coherence,
      pronunciation: 0,
      fluency: 0,
      feedback: _readString(data, const ['feedback']),
      correctedVersion: _readString(data, const ['corrected_version', 'correctedVersion']).isNotEmpty
          ? _readString(data, const ['corrected_version', 'correctedVersion'])
          : fallbackAnswer,
      vocabularyHighlights: _toStringList(data['vocabulary_important']).isNotEmpty
          ? _toStringList(data['vocabulary_important'])
          : _buildImportantWordsFromPrompt(prompt),
      taskScores: taskScores,
      errors: _toStringList(data['errors']),
      aiSuggestedAnswer: _readString(data, const ['ai_suggested_answer', 'corrected_version']),
    );
  }

  Map<String, int> _normalizeTaskScores(String taskType, Map<String, int> taskScores) {
    if (taskType == 'read_aloud') {
      return {
        'Accuracy': _toScore(taskScores['Accuracy']),
        'Pronunciation': _toScore(taskScores['Pronunciation']),
        'Fluency': _toScore(taskScores['Fluency']),
        'Intonation': _toScore(taskScores['Intonation']),
      };
    }
    return taskScores;
  }

  int _overallFromTaskScores(Map<String, int> taskScores, {int fallback = 0}) {
    if (taskScores.isEmpty) return fallback;
    final values = taskScores.values.toList();
    final total = values.fold<int>(0, (sum, v) => sum + v);
    return _clamp((total / values.length).round(), 0, 100);
  }

  String _buildTaskSpecificFeedback({
    required String taskType,
    required int overall,
    required double taskMatchRatio,
    required Map<String, int> taskScores,
    required List<String> errors,
  }) {
    final scoreLine = taskScores.entries.map((e) => '- ${e.key}: ${e.value}/100').join('\n');
    final errorLine = errors.isEmpty
        ? '- Chưa phát hiện lỗi lớn, cần tiếp tục duy trì độ ổn định.'
        : errors.map((e) => '- $e').join('\n');

    final plan = switch (taskType) {
      'read_aloud' => 'Luyện đọc theo cụm ý, nhấn trọng âm từ khóa và ngắt nghỉ đúng dấu câu để tăng Accuracy + Intonation.',
      'describe_picture' => 'Mô tả theo thứ tự: tổng quan -> đối tượng chính -> hành động -> bối cảnh để tránh thiếu ý.',
      'respond_questions' => 'Trả lời trực tiếp câu hỏi ở câu đầu, sau đó thêm 1-2 câu giải thích ngắn có ví dụ.',
      'respond_information' => 'Đối chiếu kỹ dữ liệu trước khi nói; ưu tiên nêu mốc thời gian/số liệu chính xác trước.',
      'express_opinion' => 'Nêu quan điểm rõ ngay câu đầu, theo sau là ít nhất 2 lý do và 1 ví dụ thực tế.',
      _ => 'Giữ cấu trúc trả lời rõ ràng: mở ý, phát triển ý, kết luận.',
    };

    return '''
1) Tổng quan bài nói:
- Overall: $overall/100
- Mức độ bám đề: ${(taskMatchRatio * 100).toStringAsFixed(0)}%

2) Điểm thành phần:
$scoreLine

3) Lỗi cần cải thiện:
$errorLine

4) Hướng nâng điểm:
- $plan
''';
  }

  int _readInt(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return 0;
  }

  String _readString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  List<String> _extractEnglishTokens(String text) {
    return RegExp(r"[A-Za-z']+")
        .allMatches(text.toLowerCase())
        .map((m) => m.group(0) ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }

  double _tokenOverlapRatio(List<String> promptTokens, List<String> answerTokens) {
    if (promptTokens.isEmpty || answerTokens.isEmpty) return 0.0;

    final promptSet = promptTokens.toSet();
    final answerSet = answerTokens.toSet();
    final overlap = promptSet.intersection(answerSet).length;
    return overlap / promptSet.length;
  }

  String _polishTranscript(String input) {
    final cleaned = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) return cleaned;

    final first = cleaned[0].toUpperCase();
    final rest = cleaned.length > 1 ? cleaned.substring(1) : '';
    final sentence = '$first$rest';
    if (RegExp(r'[.!?]$').hasMatch(sentence)) return sentence;
    return '$sentence.';
  }

  List<String> _buildImportantWordsFromPrompt(String prompt) {
    final stopWords = {
      'the', 'and', 'for', 'that', 'with', 'this', 'have', 'from', 'your', 'you',
      'are', 'was', 'were', 'about', 'into', 'their', 'they', 'there', 'then',
      'than', 'what', 'when', 'where', 'which', 'while', 'because', 'before',
      'after', 'during', 'very', 'really', 'just', 'usually', 'today', 'every',
    };

    final tokens = _extractEnglishTokens(prompt)
        .where((w) => w.length >= 5 && !stopWords.contains(w))
        .toList();

    final unique = <String>[];
    for (final token in tokens) {
      if (!unique.contains(token)) unique.add(token);
      if (unique.length >= 5) break;
    }

    return unique
        .map(
          (word) => '$word (${_inferWordType(word)}): ${_inferVietnameseMeaning(word)}',
        )
        .toList();
  }

  String _inferWordType(String word) {
    final lower = word.toLowerCase();
    final knownType = _toeicWordInfo[lower]?.$1;
    if (knownType != null) return knownType;

    if (lower.endsWith('tion') || lower.endsWith('ment') || lower.endsWith('ness')) {
      return 'noun';
    }
    if (lower.endsWith('ly')) return 'adverb';
    if (lower.endsWith('ive') || lower.endsWith('al') || lower.endsWith('ous')) {
      return 'adjective';
    }
    if (lower.endsWith('ing') || lower.endsWith('ed') || lower.endsWith('ize')) {
      return 'verb';
    }

    return 'word';
  }

  String _inferVietnameseMeaning(String word) {
    final lower = word.toLowerCase();
    final knownMeaning = _toeicWordInfo[lower]?.$2;
    if (knownMeaning != null) return knownMeaning;
    return 'từ vựng quan trọng trong đề, cần nắm ngữ cảnh sử dụng';
  }

  static const Map<String, (String, String)> _toeicWordInfo = {
    'company': ('noun', 'công ty'),
    'support': ('verb', 'hỗ trợ'),
    'portal': ('noun', 'cổng thông tin'),
    'response': ('noun', 'phản hồi'),
    'service': ('noun', 'dịch vụ'),
    'quality': ('noun', 'chất lượng'),
    'customer': ('noun', 'khách hàng'),
    'schedule': ('noun', 'lịch trình'),
    'arrive': ('verb', 'đến nơi'),
    'meeting': ('noun', 'cuộc họp'),
    'productivity': ('noun', 'năng suất'),
    'remotely': ('adverb', 'từ xa'),
    'employees': ('noun', 'nhân viên'),
    'workshop': ('noun', 'hội thảo'),
    'presentation': ('noun', 'bài thuyết trình'),
    'information': ('noun', 'thông tin'),
    'opinion': ('noun', 'quan điểm'),
    'vocabulary': ('noun', 'từ vựng'),
    'grammar': ('noun', 'ngữ pháp'),
    'fluency': ('noun', 'độ trôi chảy'),
    'pronunciation': ('noun', 'phát âm'),
    'accuracy': ('noun', 'độ chính xác'),
    'intonation': ('noun', 'ngữ điệu'),
    'describe': ('verb', 'mô tả'),
    'picture': ('noun', 'hình ảnh'),
    'question': ('noun', 'câu hỏi'),
    'answer': ('verb', 'trả lời'),
  };

  String _resolveGeminiApiKey() {
    final fromFile = kGeminiApiKey.trim();
    if (fromFile.isNotEmpty && fromFile != 'PASTE_YOUR_GEMINI_API_KEY_HERE') {
      return fromFile;
    }

    return const String.fromEnvironment('GEMINI_API_KEY').trim();
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
