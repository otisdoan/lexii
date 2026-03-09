class VocabularyModel {
  final String id;
  final int lesson;
  final String word;
  final String? phonetic;
  final String definition;
  final String? wordClass;
  final String scoreLevel;
  final String? audioUrl;
  final int sortOrder;

  const VocabularyModel({
    required this.id,
    required this.lesson,
    required this.word,
    this.phonetic,
    required this.definition,
    this.wordClass,
    required this.scoreLevel,
    this.audioUrl,
    required this.sortOrder,
  });

  factory VocabularyModel.fromJson(Map<String, dynamic> json) {
    return VocabularyModel(
      id: json['id'] as String,
      lesson: (json['lesson'] as num).toInt(),
      word: json['word'] as String,
      phonetic: json['phonetic'] as String?,
      definition: json['definition'] as String,
      wordClass: json['word_class'] as String?,
      scoreLevel: json['score_level'] as String? ?? '450+',
      audioUrl: json['audio_url'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

class GrammarModel {
  final String id;
  final int lesson;
  final String title;
  final String content;
  final String? formula;
  final List<String> examples;
  final List<String> relatedTopics;
  final int sortOrder;

  const GrammarModel({
    required this.id,
    required this.lesson,
    required this.title,
    required this.content,
    this.formula,
    this.examples = const [],
    this.relatedTopics = const [],
    required this.sortOrder,
  });

  factory GrammarModel.fromJson(Map<String, dynamic> json) {
    return GrammarModel(
      id: json['id'] as String,
      lesson: (json['lesson'] as num).toInt(),
      title: json['title'] as String,
      content: json['content'] as String,
      formula: json['formula'] as String?,
      examples: (json['examples'] as List<dynamic>?)?.cast<String>() ?? [],
      relatedTopics:
          (json['related_topics'] as List<dynamic>?)?.cast<String>() ?? [],
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}
