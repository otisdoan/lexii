import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexii/features/exam/presentation/providers/test_providers.dart';
import 'package:lexii/features/practice/data/repositories/practice_repository.dart';
import 'package:lexii/features/practice/data/repositories/speaking_writing_repository.dart';
import 'package:lexii/features/practice/data/repositories/writing_repository.dart';

/// Provider for PracticeRepository
final practiceRepositoryProvider = Provider<PracticeRepository>((ref) {
  return PracticeRepository();
});

/// Provider for WritingRepository
final writingRepositoryProvider = Provider<WritingRepository>((ref) {
  return WritingRepository();
});

final speakingWritingRepositoryProvider = Provider<SpeakingWritingRepository>((
  ref,
) {
  return SpeakingWritingRepository();
});

/// Listening practice parts (1..4) aggregated from all full tests.
final listeningPracticePartsProvider = FutureProvider<List<PracticePartData>?>((
  ref,
) async {
  final repo = ref.watch(practiceRepositoryProvider);
  final parts = await repo.getListeningParts();
  if (parts.isEmpty) return null;
  return parts;
});

/// Wrong listening question IDs for the current user.
final wrongListeningQuestionIdsProvider = FutureProvider<List<String>>((
  ref,
) async {
  final repo = ref.watch(questionRepositoryProvider);
  return repo.getWrongQuestionIds(partNumber: null, limit: 200);
});

/// Wrong reading question IDs (Part 5-7) for the current user.
final wrongReadingQuestionIdsProvider = FutureProvider<List<String>>((
  ref,
) async {
  final repo = ref.watch(questionRepositoryProvider);
  return repo.getWrongQuestionIdsByPartNumbers(
    partNumbers: const [5, 6, 7],
    limit: 200,
  );
});

/// Reading parts (5–7) aggregated from all full tests.
final readingPracticePartsProvider = FutureProvider<List<PracticePartData>?>((
  ref,
) async {
  final repo = ref.watch(practiceRepositoryProvider);
  final parts = await repo.getReadingParts();
  if (parts.isEmpty) return null;
  return parts;
});

/// Writing parts (1–3) from writing_prompts table.
final writingPartsProvider = FutureProvider<List<PracticePartData>>((
  ref,
) async {
  final repo = ref.watch(practiceRepositoryProvider);
  return repo.getWritingParts();
});

/// Speaking parts (1–5) from speaking_questions table.
final speakingPartsProvider = FutureProvider<List<PracticePartData>>((
  ref,
) async {
  final repo = ref.watch(practiceRepositoryProvider);
  return repo.getSpeakingParts();
});

/// Practice history for dashboard (speaking + writing combined, most recent).
final dashboardPracticeHistoryProvider =
    FutureProvider<List<PracticeHistoryItem>>((ref) async {
      final repo = ref.watch(speakingWritingRepositoryProvider);
      final results = await Future.wait([
        repo.getSpeakingHistory(limit: 10),
        repo.getWritingHistory(limit: 10),
      ]);
      final combined = [...results[0], ...results[1]];
      combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return combined.take(10).toList();
    });
