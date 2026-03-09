/// Represents a single question with its options and media
class QuestionModel {
  final String id;
  final String partId;
  final String? passageId;
  final String? passageContent; // fetched from passages table
  final String? questionText;
  final int orderIndex;
  final List<OptionModel> options;
  final List<QuestionMediaModel> media;

  const QuestionModel({
    required this.id,
    required this.partId,
    this.passageId,
    this.passageContent,
    this.questionText,
    required this.orderIndex,
    this.options = const [],
    this.media = const [],
  });

  /// Returns a copy with passageContent filled in.
  QuestionModel withPassageContent(String content) => QuestionModel(
        id: id,
        partId: partId,
        passageId: passageId,
        passageContent: content,
        questionText: questionText,
        orderIndex: orderIndex,
        options: options,
        media: media,
      );

  /// Image URL from media (type = 'image')
  String? get imageUrl {
    final img = media.where((m) => m.type == 'image').toList();
    return img.isNotEmpty ? img.first.url : null;
  }

  /// Audio URL from media (type = 'audio')
  String? get audioUrl {
    final audio = media.where((m) => m.type == 'audio').toList();
    return audio.isNotEmpty ? audio.first.url : null;
  }

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final optionsRaw = json['question_options'] as List<dynamic>? ?? [];
    final mediaRaw = json['question_media'] as List<dynamic>? ?? [];

    return QuestionModel(
      id: json['id'] as String,
      partId: json['part_id'] as String,
      passageId: json['passage_id'] as String?,
      questionText: json['question_text'] as String?,
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
      options: optionsRaw
          .map((o) => OptionModel.fromJson(o as Map<String, dynamic>))
          .toList(),
      media: mediaRaw
          .map((m) => QuestionMediaModel.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// A single answer option (A, B, C, D)
class OptionModel {
  final String id;
  final String content;
  final bool isCorrect;

  const OptionModel({
    required this.id,
    required this.content,
    required this.isCorrect,
  });

  factory OptionModel.fromJson(Map<String, dynamic> json) {
    return OptionModel(
      id: json['id'] as String,
      content: (json['content'] as String?) ?? '',
      isCorrect: (json['is_correct'] as bool?) ?? false,
    );
  }
}

/// Media attached to a question (image, audio, text)
class QuestionMediaModel {
  final String id;
  final String type;
  final String url;

  const QuestionMediaModel({
    required this.id,
    required this.type,
    required this.url,
  });

  factory QuestionMediaModel.fromJson(Map<String, dynamic> json) {
    return QuestionMediaModel(
      id: json['id'] as String,
      type: (json['type'] as String?) ?? 'text',
      url: (json['url'] as String?) ?? '',
    );
  }
}
