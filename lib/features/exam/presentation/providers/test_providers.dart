import 'package:flutter_riverpod/flutter_riverpod.dart';
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

