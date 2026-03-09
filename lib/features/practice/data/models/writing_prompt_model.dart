class WritingPromptModel {
  final String id;
  final int partNumber;
  final String? title;
  final String prompt;
  final String? imageUrl;
  final String? passageText;
  final String? passageSubject;
  final String? modelAnswer;
  final String? hintWords;
  final int orderIndex;

  const WritingPromptModel({
    required this.id,
    required this.partNumber,
    this.title,
    required this.prompt,
    this.imageUrl,
    this.passageText,
    this.passageSubject,
    this.modelAnswer,
    this.hintWords,
    required this.orderIndex,
  });

  factory WritingPromptModel.fromJson(Map<String, dynamic> json) {
    return WritingPromptModel(
      id: json['id'] as String,
      partNumber: (json['part_number'] as num).toInt(),
      title: json['title'] as String?,
      prompt: json['prompt'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      passageText: json['passage_text'] as String?,
      passageSubject: json['passage_subject'] as String?,
      modelAnswer: json['model_answer'] as String?,
      hintWords: json['hint_words'] as String?,
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
    );
  }
}
