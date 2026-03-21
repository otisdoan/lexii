import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexii/features/exam/data/models/attempt_history_model.dart';
import 'package:lexii/features/exam/data/models/test_model.dart';
import 'package:lexii/features/exam/data/models/question_model.dart';
import 'package:lexii/features/exam/data/models/test_part_model.dart';
import 'package:lexii/features/exam/data/repositories/test_repository.dart';
import 'package:lexii/features/exam/data/repositories/question_repository.dart';

/// Provider for TestRepository
final testRepositoryProvider = Provider<TestRepository>((ref) {
  return TestRepository();
});

/// Provider for QuestionRepository
final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepository();
});

/// Provider for fulltests
final fullTestsProvider = FutureProvider<List<TestModel>>((ref) async {
  final repo = ref.watch(testRepositoryProvider);
  return repo.getFullTests();
});

/// Provider for minitests
final miniTestsProvider = FutureProvider<List<TestModel>>((ref) async {
  final repo = ref.watch(testRepositoryProvider);
  return repo.getMiniTests();
});

/// Provider for questions by test ID (family provider)
final questionsByTestIdProvider = FutureProvider.family<List<QuestionModel>, String>((ref, testId) async {
  final repo = ref.watch(questionRepositoryProvider);
  return repo.getQuestionsByTestId(testId);
});

/// Provider for test parts by test ID — includes part_name, description, question count
final testPartsProvider = FutureProvider.family<List<TestPartModel>, String>((ref, testId) async {
  final repo = ref.watch(questionRepositoryProvider);
  return repo.getTestParts(testId);
});

/// Provider for questions filtered by a single part ID (used in practice mode)
final questionsByPartIdProvider =
    FutureProvider.family<List<QuestionModel>, String>((ref, partId) async {
  final repo = ref.watch(questionRepositoryProvider);
  return repo.getQuestionsByPartId(partId);
});

/// Provider for listening questions by part number (1..4) across all full tests.
final questionsByListeningPartNumberProvider =
    FutureProvider.family<List<QuestionModel>, int>((ref, partNumber) async {
  final repo = ref.watch(questionRepositoryProvider);
  return repo.getQuestionsByListeningPartNumber(partNumber);
});

/// Provider for reading questions by part number (5..7) across all full tests.
final questionsByReadingPartNumberProvider =
    FutureProvider.family<List<QuestionModel>, int>((ref, partNumber) async {
  final repo = ref.watch(questionRepositoryProvider);
  return repo.getQuestionsByReadingPartNumber(partNumber);
});

/// Provider for questions by explicit question IDs.
final questionsByIdsProvider =
    FutureProvider.family<List<QuestionModel>, List<String>>((ref, ids) async {
  final repo = ref.watch(questionRepositoryProvider);
  return repo.getQuestionsByIds(ids);
});

/// Provider for exam attempt history in settings.
final attemptHistoryProvider =
    FutureProvider.autoDispose.family<List<AttemptHistoryItemModel>, int>((ref, limit) async {
  final repo = ref.watch(questionRepositoryProvider);
  return repo.getUserAttemptHistory(limit: limit);
});

/// Provider for one attempt detail.
final attemptDetailProvider =
    FutureProvider.autoDispose.family<AttemptDetailModel?, String>((ref, attemptId) async {
  final repo = ref.watch(questionRepositoryProvider);
  return repo.getAttemptDetail(attemptId);
});

