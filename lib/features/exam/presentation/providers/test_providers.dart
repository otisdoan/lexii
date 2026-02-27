import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexii/features/exam/data/models/test_model.dart';
import 'package:lexii/features/exam/data/repositories/test_repository.dart';

/// Provider for TestRepository
final testRepositoryProvider = Provider<TestRepository>((ref) {
  return TestRepository();
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
