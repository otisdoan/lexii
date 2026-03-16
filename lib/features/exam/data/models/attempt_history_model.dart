import 'package:lexii/features/exam/data/models/question_model.dart';

class AttemptHistoryItemModel {
  final String id;
  final String testId;
  final String testTitle;
  final int score;
  final DateTime submittedAt;
  final int answeredCount;
  final int correctCount;

  const AttemptHistoryItemModel({
    required this.id,
    required this.testId,
    required this.testTitle,
    required this.score,
    required this.submittedAt,
    required this.answeredCount,
    required this.correctCount,
  });
}

class AttemptQuestionDetailModel {
  final QuestionModel question;
  final int partNumber;
  final String? selectedOptionId;
  final bool isCorrect;

  const AttemptQuestionDetailModel({
    required this.question,
    required this.partNumber,
    required this.selectedOptionId,
    required this.isCorrect,
  });

  bool get isAnswered => selectedOptionId != null && selectedOptionId!.isNotEmpty;
}

class AttemptDetailModel {
  final String id;
  final String testId;
  final String testTitle;
  final int score;
  final DateTime submittedAt;
  final int answeredCount;
  final int correctCount;
  final List<AttemptQuestionDetailModel> questionDetails;

  const AttemptDetailModel({
    required this.id,
    required this.testId,
    required this.testTitle,
    required this.score,
    required this.submittedAt,
    required this.answeredCount,
    required this.correctCount,
    required this.questionDetails,
  });
}
