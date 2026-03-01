/// Represents a part within a test (e.g. Part 1: Photographs)
/// Schema: test_parts(id, test_id, part_number, instructions)
class TestPartModel {
  final String id;
  final String testId;
  final int partNumber;
  /// Maps to DB column: instructions
  final String? instructions;
  final int questionCount;

  const TestPartModel({
    required this.id,
    required this.testId,
    required this.partNumber,
    this.instructions,
    this.questionCount = 0,
  });

  factory TestPartModel.fromJson(Map<String, dynamic> json) {
    final questionsRaw = json['questions'] as List<dynamic>? ?? [];
    return TestPartModel(
      id: json['id'] as String,
      testId: json['test_id'] as String,
      partNumber: (json['part_number'] as num?)?.toInt() ?? 1,
      instructions: json['instructions'] as String?,
      questionCount: questionsRaw.length,
    );
  }

  /// Display title, e.g. "Part 1"
  String get displayTitle => 'Part $partNumber';
}
