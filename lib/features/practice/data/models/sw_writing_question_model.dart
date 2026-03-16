class SwWritingQuestionModel {
  final String id;
  final String type;
  final String content;
  final String? imageUrl;
  final List<String> keywords;

  const SwWritingQuestionModel({
    required this.id,
    required this.type,
    required this.content,
    this.imageUrl,
    this.keywords = const [],
  });

  factory SwWritingQuestionModel.fromJson(Map<String, dynamic> json) {
    final rawKeywords = json['keywords'];
    List<String> parsedKeywords = const [];
    if (rawKeywords is List) {
      parsedKeywords = rawKeywords.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    } else if (rawKeywords is String && rawKeywords.trim().isNotEmpty) {
      parsedKeywords = rawKeywords
          .split(RegExp(r'[,;|]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return SwWritingQuestionModel(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      imageUrl: json['image_url'] as String?,
      keywords: parsedKeywords,
    );
  }
}
