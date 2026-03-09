import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexii/features/theory/data/models/theory_models.dart';
import 'package:lexii/features/theory/data/repositories/theory_repository.dart';

final theoryRepositoryProvider = Provider<TheoryRepository>((ref) {
  return TheoryRepository();
});

/// Vocabulary filter state: (lesson, scoreLevel)
/// null means "all"
class VocabFilter {
  final int? lesson;
  final String? scoreLevel;
  const VocabFilter({this.lesson, this.scoreLevel});

  VocabFilter copyWith({Object? lesson = _sentinel, Object? scoreLevel = _sentinel}) {
    return VocabFilter(
      lesson: lesson == _sentinel ? this.lesson : lesson as int?,
      scoreLevel: scoreLevel == _sentinel ? this.scoreLevel : scoreLevel as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VocabFilter &&
      other.lesson == lesson &&
      other.scoreLevel == scoreLevel;

  @override
  int get hashCode => Object.hash(lesson, scoreLevel);
}

const _sentinel = Object();

final vocabFilterProvider = StateProvider<VocabFilter>(
  (ref) => const VocabFilter(lesson: 1),
);

final vocabularyProvider =
    FutureProvider.autoDispose.family<List<VocabularyModel>, VocabFilter>(
  (ref, filter) async {
    final repo = ref.watch(theoryRepositoryProvider);
    return repo.getVocabulary(
      lesson: filter.lesson,
      scoreLevel: filter.scoreLevel,
    );
  },
);

final grammarProvider =
    FutureProvider.autoDispose.family<List<GrammarModel>, int?>(
  (ref, lesson) async {
    final repo = ref.watch(theoryRepositoryProvider);
    return repo.getGrammar(lesson: lesson);
  },
);

final lessonNumbersProvider = FutureProvider.autoDispose<List<int>>(
  (ref) async {
    final repo = ref.watch(theoryRepositoryProvider);
    return repo.getLessonNumbers();
  },
);
