import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexii/features/exam/presentation/providers/test_providers.dart';
import 'package:lexii/features/practice/data/repositories/practice_repository.dart';
import 'package:lexii/features/practice/data/repositories/writing_repository.dart';

/// Provider for PracticeRepository
final practiceRepositoryProvider = Provider<PracticeRepository>((ref) {
  return PracticeRepository();
});

/// Provider for WritingRepository
final writingRepositoryProvider = Provider<WritingRepository>((ref) {
  return WritingRepository();
});

/// Listening parts for a given testId, enriched with user progress.
final listeningPartsProvider =
    FutureProvider.family<List<PracticePartData>, String>((ref, testId) async {
  final repo = ref.watch(practiceRepositoryProvider);
  return repo.getListeningParts(testId);
});

/// Resolves the first available full-test ID, then delegates to
/// [listeningPartsProvider]. Returns null if no tests exist yet.
final listeningPracticePartsProvider =
    FutureProvider<List<PracticePartData>?>((ref) async {
  final tests = await ref.watch(fullTestsProvider.future);
  if (tests.isEmpty) return null;
  final testId = tests.first.id;
  return ref.watch(listeningPartsProvider(testId).future);
});

/// Reading parts (5–7) for a given testId.
final readingPartsProvider =
    FutureProvider.family<List<PracticePartData>, String>((ref, testId) async {
  final repo = ref.watch(practiceRepositoryProvider);
  return repo.getReadingParts(testId);
});

/// Resolves the first available full-test ID for reading practice.
final readingPracticePartsProvider =
    FutureProvider<List<PracticePartData>?>((ref) async {
  final tests = await ref.watch(fullTestsProvider.future);
  if (tests.isEmpty) return null;
  final testId = tests.first.id;
  return ref.watch(readingPartsProvider(testId).future);
});

/// Writing parts (1–3) from writing_prompts table.
final writingPartsProvider =
    FutureProvider<List<PracticePartData>>((ref) async {
  final repo = ref.watch(practiceRepositoryProvider);
  return repo.getWritingParts();
});
