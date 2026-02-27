class TestModel {
  final String id;
  final String title;
  final int duration;
  final String type;
  final int totalQuestions;
  final bool isPremium;
  final DateTime? createdAt;

  const TestModel({
    required this.id,
    required this.title,
    required this.duration,
    required this.type,
    this.totalQuestions = 200,
    this.isPremium = false,
    this.createdAt,
  });

  factory TestModel.fromJson(Map<String, dynamic> json) {
    return TestModel(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? 'Untitled Test',
      duration: (json['duration'] as num?)?.toInt() ?? 120,
      type: (json['type'] as String?) ?? 'full_test',
      // Handle columns that might not exist yet
      totalQuestions: json.containsKey('total_questions')
          ? (json['total_questions'] as num?)?.toInt() ?? 200
          : 200,
      isPremium: json.containsKey('is_premium')
          ? (json['is_premium'] as bool?) ?? false
          : false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'duration': duration,
    'type': type,
    'total_questions': totalQuestions,
    'is_premium': isPremium,
  };
}
