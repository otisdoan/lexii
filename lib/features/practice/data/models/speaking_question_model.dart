class SpeakingQuestionModel {
  final String id;
  final String type;
  final String content;
  final String? imageUrl;
  final Map<String, dynamic> extraData;

  const SpeakingQuestionModel({
    required this.id,
    required this.type,
    required this.content,
    this.imageUrl,
    this.extraData = const {},
  });

  factory SpeakingQuestionModel.fromJson(Map<String, dynamic> json) {
    final extra = json['extra_data'];
    return SpeakingQuestionModel(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      imageUrl: json['image_url'] as String?,
      extraData: extra is Map<String, dynamic> ? extra : const {},
    );
  }
}
