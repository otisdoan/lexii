import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/home/presentation/widgets/bottom_nav_bar.dart';
import 'package:lexii/features/theory/data/models/theory_models.dart';
import 'package:lexii/features/theory/presentation/providers/theory_providers.dart';

class TheoryPage extends StatelessWidget {
  const TheoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TheoryVocabularyPage();
  }
}

class TheoryVocabularyPage extends ConsumerStatefulWidget {
  const TheoryVocabularyPage({super.key});

  @override
  ConsumerState<TheoryVocabularyPage> createState() =>
      _TheoryVocabularyPageState();
}

class _TheoryVocabularyPageState extends ConsumerState<TheoryVocabularyPage> {
  static const int _pageSize = 20;
  static const List<String> _scoreLevels = ['450+', '600+', '800+', '990+'];

  final TextEditingController _dictionarySearchController =
      TextEditingController();
  final TextEditingController _learnSearchController = TextEditingController();

  bool _showDictionary = true;
  bool _initializedFromRouteTab = false;
  String _dictionarySearch = '';
  String _learnSearch = '';
  int? _lessonFilter;
  String? _scoreFilter;
  bool _savedOnlyFilter = false;
  int _page = 0;
  Set<String> _savedWordIds = <String>{};
  Timer? _dictionaryDebounce;
  final AudioPlayer _dictionaryAudioPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _dictionaryPlayerSub;
  bool _dictionaryLoading = false;
  bool _dictionaryAudioPlaying = false;
  String _dictionaryError = '';
  _DictionaryLookupResult? _dictionaryResult;

  @override
  void initState() {
    super.initState();
    _loadSavedVocabularyIds();
    _dictionaryPlayerSub = _dictionaryAudioPlayer.playerStateStream.listen((
      state,
    ) {
      final processing = state.processingState;
      if (!mounted) return;

      if (processing == ProcessingState.completed) {
        if (_dictionaryAudioPlaying) {
          setState(() {
            _dictionaryAudioPlaying = false;
          });
        }
        _dictionaryAudioPlayer.stop();
        return;
      }

      final isActive =
          state.playing &&
          processing != ProcessingState.completed &&
          processing != ProcessingState.idle;

      if (_dictionaryAudioPlaying != isActive) {
        setState(() {
          _dictionaryAudioPlaying = isActive;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializedFromRouteTab) return;

    final params = GoRouterState.of(context).uri.queryParameters;
    final tab = params['tab'];
    if (tab != null && tab.toLowerCase() == 'learn') {
      _showDictionary = false;
    }

    final saved = params['saved'];
    if (saved != null) {
      final normalized = saved.trim().toLowerCase();
      if (normalized == '1' || normalized == 'true' || normalized == 'yes') {
        _savedOnlyFilter = true;
        _showDictionary = false;
        _page = 0;
      }
    }
    _initializedFromRouteTab = true;
  }

  @override
  void dispose() {
    _dictionaryDebounce?.cancel();
    _dictionaryPlayerSub?.cancel();
    _dictionaryAudioPlayer.dispose();
    _dictionarySearchController.dispose();
    _learnSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedVocabularyIds() async {
    try {
      final saved = await ref
          .read(theoryRepositoryProvider)
          .getSavedVocabularyIds();
      if (!mounted) return;
      setState(() {
        _savedWordIds = saved;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _savedWordIds = <String>{};
      });
    }
  }

  Future<void> _toggleSavedVocabulary(String wordId) async {
    final wasSaved = _savedWordIds.contains(wordId);
    final nextSaved = !wasSaved;

    setState(() {
      if (wasSaved) {
        _savedWordIds.remove(wordId);
      } else {
        _savedWordIds.add(wordId);
      }
      _page = 0;
    });

    try {
      await ref
          .read(theoryRepositoryProvider)
          .setVocabularySaved(vocabularyId: wordId, isSaved: nextSaved);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (wasSaved) {
          _savedWordIds.add(wordId);
        } else {
          _savedWordIds.remove(wordId);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không lưu được từ vựng lúc này. Vui lòng thử lại.',
            style: GoogleFonts.lexend(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: AppColors.red500,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessonsAsync = ref.watch(lessonNumbersProvider);

    final filteredSourceAsync = ref.watch(
      vocabularyProvider(
        VocabFilter(lesson: _lessonFilter, scoreLevel: _scoreFilter),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Column(
          children: [
            _PageHeader(title: 'Từ vựng & Từ điển'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _SegmentTabs(
                      showDictionary: _showDictionary,
                      onDictionaryTap: () {
                        if (!_showDictionary) {
                          setState(() => _showDictionary = true);
                        }
                      },
                      onLearnTap: () {
                        if (_showDictionary) {
                          setState(() => _showDictionary = false);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    if (_showDictionary)
                      _DictionaryView(
                        searchController: _dictionarySearchController,
                        search: _dictionarySearch,
                        isLoading: _dictionaryLoading,
                        isPlayingAudio: _dictionaryAudioPlaying,
                        error: _dictionaryError,
                        result: _dictionaryResult,
                        onChanged: _onDictionaryChanged,
                        onPlayAudio: _onPlayDictionaryAudio,
                        onSuggestionTap: (value) {
                          _dictionarySearchController.text = value;
                          _onDictionaryChanged(value, immediate: true);
                        },
                      )
                    else
                      _LearnView(
                        sourceAsync: filteredSourceAsync,
                        lessonsAsync: lessonsAsync,
                        searchController: _learnSearchController,
                        search: _learnSearch,
                        lessonFilter: _lessonFilter,
                        scoreFilter: _scoreFilter,
                        page: _page,
                        pageSize: _pageSize,
                        scoreLevels: _scoreLevels,
                        savedWordIds: _savedWordIds,
                        savedOnlyFilter: _savedOnlyFilter,
                        onSearchChanged: (value) {
                          setState(() {
                            _learnSearch = value;
                            _page = 0;
                          });
                        },
                        onClearSearch: () {
                          _learnSearchController.clear();
                          setState(() {
                            _learnSearch = '';
                            _page = 0;
                          });
                        },
                        onLessonChanged: (value) {
                          setState(() {
                            _lessonFilter = value;
                            _page = 0;
                          });
                        },
                        onScoreChanged: (value) {
                          setState(() {
                            _scoreFilter = value;
                            _page = 0;
                          });
                        },
                        onSavedOnlyChanged: (value) {
                          setState(() {
                            _savedOnlyFilter = value;
                            _page = 0;
                          });
                        },
                        onToggleSaved: _toggleSavedVocabulary,
                        onPageChanged: (value) => setState(() => _page = value),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTap: (index) => _onNavTap(context, index),
      ),
    );
  }

  void _onDictionaryChanged(String value, {bool immediate = false}) {
    setState(() => _dictionarySearch = value);

    _dictionaryDebounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _dictionaryLoading = false;
        _dictionaryError = '';
        _dictionaryResult = null;
      });
      _dictionaryAudioPlayer.stop();
      return;
    }

    final delay = immediate ? Duration.zero : const Duration(milliseconds: 450);
    _dictionaryDebounce = Timer(delay, () => _lookupDictionary(value));
  }

  Future<void> _lookupDictionary(String value) async {
    final query = value.trim();
    if (query.isEmpty) return;

    setState(() {
      _dictionaryLoading = true;
      _dictionaryError = '';
    });

    try {
      final uri = Uri.parse(
        'https://api.dictionaryapi.dev/api/v2/entries/en/${Uri.encodeComponent(query)}',
      );
      final response = await http.get(uri);

      if (!mounted || _dictionarySearch.trim() != query) {
        return;
      }

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is List && body.isNotEmpty) {
          final first = body.first;
          if (first is Map<String, dynamic>) {
            setState(() {
              _dictionaryResult = _DictionaryLookupResult.fromJson(first);
              _dictionaryLoading = false;
              _dictionaryError = '';
            });
            _dictionaryAudioPlayer.stop();
            return;
          }
        }
      }

      String message = 'Không tìm thấy từ này';
      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic> && body['message'] is String) {
          message = body['message'] as String;
        }
      } catch (_) {}

      setState(() {
        _dictionaryResult = null;
        _dictionaryLoading = false;
        _dictionaryError = message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _dictionaryResult = null;
        _dictionaryLoading = false;
        _dictionaryError = 'Không thể kết nối từ điển. Vui lòng thử lại.';
      });
    }
  }

  Future<void> _onPlayDictionaryAudio() async {
    final result = _dictionaryResult;
    if (result == null || result.audioUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Từ này chưa có audio phát âm.',
            style: GoogleFonts.lexend(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: AppColors.slate700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      if (_dictionaryAudioPlaying) {
        await _dictionaryAudioPlayer.stop();
        return;
      }

      await _dictionaryAudioPlayer.setUrl(result.audioUrl);
      await _dictionaryAudioPlayer.play();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không phát được audio. Vui lòng thử lại.',
            style: GoogleFonts.lexend(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: AppColors.red500,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        return;
      case 1:
        return;
      case 2:
        context.go('/exam/mock-test');
        return;
      case 3:
        context.go('/upgrade');
        return;
      case 4:
        context.go('/settings');
        return;
    }
  }
}

class TheoryGrammarPage extends ConsumerStatefulWidget {
  const TheoryGrammarPage({super.key});

  @override
  ConsumerState<TheoryGrammarPage> createState() => _TheoryGrammarPageState();
}

class _TheoryGrammarPageState extends ConsumerState<TheoryGrammarPage> {
  final TextEditingController _searchController = TextEditingController();

  bool _initializedFromRouteFilter = false;
  int? _lessonFilter;
  bool _savedOnlyFilter = false;
  String _search = '';
  String? _expandedId;
  Set<String> _savedGrammarIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadSavedGrammarIds();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializedFromRouteFilter) return;

    final saved = GoRouterState.of(context).uri.queryParameters['saved'];
    if (saved != null) {
      final normalized = saved.trim().toLowerCase();
      if (normalized == '1' || normalized == 'true' || normalized == 'yes') {
        _savedOnlyFilter = true;
      }
    }

    _initializedFromRouteFilter = true;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedGrammarIds() async {
    try {
      final saved = await ref
          .read(theoryRepositoryProvider)
          .getSavedGrammarIds();
      if (!mounted) return;
      setState(() {
        _savedGrammarIds = saved;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _savedGrammarIds = <String>{};
      });
    }
  }

  Future<void> _toggleSavedGrammar(String grammarId) async {
    final wasSaved = _savedGrammarIds.contains(grammarId);
    final nextSaved = !wasSaved;

    setState(() {
      if (wasSaved) {
        _savedGrammarIds.remove(grammarId);
      } else {
        _savedGrammarIds.add(grammarId);
      }
    });

    try {
      await ref
          .read(theoryRepositoryProvider)
          .setGrammarSaved(grammarId: grammarId, isSaved: nextSaved);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (wasSaved) {
          _savedGrammarIds.add(grammarId);
        } else {
          _savedGrammarIds.remove(grammarId);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không lưu được ngữ pháp lúc này. Vui lòng thử lại.',
            style: GoogleFonts.lexend(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: AppColors.red500,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessonsAsync = ref.watch(lessonNumbersProvider);
    final grammarAsync = ref.watch(grammarProvider(_lessonFilter));
    final lessons = lessonsAsync.valueOrNull ?? const <int>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Column(
          children: [
            const _PageHeader(title: 'Ngữ pháp'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SearchBox(
                          controller: _searchController,
                          value: _search,
                          hintText: 'Tìm ngữ pháp, công thức, ví dụ...',
                          onChanged: (value) => setState(() => _search = value),
                          onClear: () {
                            _searchController.clear();
                            setState(() => _search = '');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => _openFilterModal(context, lessons),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.borderSlate200,
                              ),
                            ),
                            child: const Icon(
                              Icons.filter_list,
                              color: AppColors.slate700,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  lessonsAsync.when(
                    data: (_) => Text(
                      'Bộ lọc: ${_lessonFilter == null ? 'Tất cả bài' : 'Bài $_lessonFilter'} · ${_savedOnlyFilter ? 'Ngữ pháp đã lưu' : 'Mọi ngữ pháp'}',
                      style: GoogleFonts.lexend(
                        fontSize: 11,
                        color: AppColors.textSlate500,
                      ),
                    ),
                    loading: () => Text(
                      'Đang tải bộ lọc...',
                      style: GoogleFonts.lexend(
                        fontSize: 11,
                        color: AppColors.textSlate400,
                      ),
                    ),
                    error: (_, __) => Text(
                      'Không tải được bộ lọc bài học.',
                      style: GoogleFonts.lexend(
                        fontSize: 11,
                        color: AppColors.red500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  grammarAsync.when(
                    data: (items) {
                      final query = _search.trim().toLowerCase();
                      final filtered = items.where((g) {
                        if (_savedOnlyFilter &&
                            !_savedGrammarIds.contains(g.id)) {
                          return false;
                        }
                        if (query.isEmpty) return true;
                        final inTitle = g.title.toLowerCase().contains(query);
                        final inContent = g.content.toLowerCase().contains(
                          query,
                        );
                        final inFormula = (g.formula ?? '')
                            .toLowerCase()
                            .contains(query);
                        final inExamples = g.examples.any(
                          (e) => e.toLowerCase().contains(query),
                        );
                        return inTitle || inContent || inFormula || inExamples;
                      }).toList();

                      if (filtered.isEmpty) {
                        return const _EmptyBox(
                          icon: Icons.find_in_page,
                          title: 'Không tìm thấy ngữ pháp',
                          subtitle: 'Hãy đổi từ khóa hoặc bộ lọc bài.',
                        );
                      }

                      if (_expandedId == null) {
                        _expandedId = filtered.first.id;
                      }

                      return Column(
                        children: filtered
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _GrammarExpandableCard(
                                  item: item,
                                  isOpen: _expandedId == item.id,
                                  isSaved: _savedGrammarIds.contains(item.id),
                                  onToggle: () {
                                    setState(() {
                                      _expandedId = _expandedId == item.id
                                          ? null
                                          : item.id;
                                    });
                                  },
                                  onToggleSaved: () =>
                                      _toggleSavedGrammar(item.id),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                    loading: () => const _ListLoading(count: 5),
                    error: (e, _) => _EmptyBox(
                      icon: Icons.error_outline,
                      title: 'Không tải được dữ liệu',
                      subtitle: '$e',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTap: (index) => _onNavTap(context, index),
      ),
    );
  }

  Future<void> _openFilterModal(BuildContext context, List<int> lessons) async {
    int? selectedLesson = _lessonFilter;
    bool selectedSavedOnly = _savedOnlyFilter;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.borderSlate200,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Bộ lọc ngữ pháp',
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSlate900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bài học',
                      style: GoogleFonts.lexend(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FilterPill(
                          label: 'Tất cả bài',
                          active: selectedLesson == null,
                          onTap: () =>
                              setModalState(() => selectedLesson = null),
                        ),
                        ...lessons.map(
                          (lesson) => _FilterPill(
                            label: 'Bài $lesson',
                            active: selectedLesson == lesson,
                            onTap: () =>
                                setModalState(() => selectedLesson = lesson),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Danh mục',
                      style: GoogleFonts.lexend(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FilterPill(
                          label: 'Mọi ngữ pháp',
                          active: !selectedSavedOnly,
                          onTap: () =>
                              setModalState(() => selectedSavedOnly = false),
                        ),
                        _FilterPill(
                          label: 'Ngữ pháp đã lưu',
                          active: selectedSavedOnly,
                          onTap: () =>
                              setModalState(() => selectedSavedOnly = true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _lessonFilter = selectedLesson;
                            _savedOnlyFilter = selectedSavedOnly;
                          });
                          Navigator.of(sheetContext).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Áp dụng',
                          style: GoogleFonts.lexend(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        return;
      case 1:
        return;
      case 2:
        context.go('/exam/mock-test');
        return;
      case 3:
        context.go('/upgrade');
        return;
      case 4:
        context.go('/settings');
        return;
    }
  }
}

class _DictionaryView extends StatelessWidget {
  final TextEditingController searchController;
  final String search;
  final bool isLoading;
  final bool isPlayingAudio;
  final String error;
  final _DictionaryLookupResult? result;
  final ValueChanged<String> onChanged;
  final VoidCallback onPlayAudio;
  final ValueChanged<String> onSuggestionTap;

  const _DictionaryView({
    required this.searchController,
    required this.search,
    required this.isLoading,
    required this.isPlayingAudio,
    required this.error,
    required this.result,
    required this.onChanged,
    required this.onPlayAudio,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = search.trim();

    return Column(
      children: [
        _SearchBox(
          controller: searchController,
          value: search,
          hintText: 'Nhập từ tiếng Anh để tra cứu...',
          onChanged: onChanged,
          onClear: () {
            searchController.clear();
            onChanged('');
          },
        ),
        const SizedBox(height: 12),
        if (normalized.isEmpty)
          _DictionaryHint(
            onTapWord: onSuggestionTap,
            suggestions: const [
              'opportunity',
              'knowledge',
              'environment',
              'strategy',
              'deadline',
            ],
          )
        else if (isLoading)
          const _ListLoading(count: 1)
        else if (error.isNotEmpty)
          _EmptyBox(
            icon: Icons.auto_fix_high,
            title: 'Không tìm thấy từ',
            subtitle: error,
          )
        else if (result != null)
          _DictionaryApiCard(
            result: result!,
            isPlayingAudio: isPlayingAudio,
            onPlayAudio: onPlayAudio,
          )
        else
          const _EmptyBox(
            icon: Icons.auto_fix_high,
            title: 'Không tìm thấy từ',
            subtitle: 'Thử nhập một từ khác.',
          ),
      ],
    );
  }
}

class _LearnView extends StatelessWidget {
  final AsyncValue<List<VocabularyModel>> sourceAsync;
  final AsyncValue<List<int>> lessonsAsync;
  final TextEditingController searchController;
  final String search;
  final int? lessonFilter;
  final String? scoreFilter;
  final int page;
  final int pageSize;
  final List<String> scoreLevels;
  final Set<String> savedWordIds;
  final bool savedOnlyFilter;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<int?> onLessonChanged;
  final ValueChanged<String?> onScoreChanged;
  final ValueChanged<bool> onSavedOnlyChanged;
  final Future<void> Function(String wordId) onToggleSaved;
  final ValueChanged<int> onPageChanged;

  const _LearnView({
    required this.sourceAsync,
    required this.lessonsAsync,
    required this.searchController,
    required this.search,
    required this.lessonFilter,
    required this.scoreFilter,
    required this.page,
    required this.pageSize,
    required this.scoreLevels,
    required this.savedWordIds,
    required this.savedOnlyFilter,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onLessonChanged,
    required this.onScoreChanged,
    required this.onSavedOnlyChanged,
    required this.onToggleSaved,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final query = search.trim().toLowerCase();
    final lessons = lessonsAsync.valueOrNull ?? const <int>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _SearchBox(
                controller: searchController,
                value: search,
                hintText: 'Tìm kiếm từ vựng...',
                onChanged: onSearchChanged,
                onClear: onClearSearch,
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _openFilterModal(context, lessons),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSlate200),
                  ),
                  child: const Icon(
                    Icons.filter_list,
                    color: AppColors.slate700,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Bộ lọc: ${lessonFilter == null ? 'Tất cả bài' : 'Bài $lessonFilter'} · ${scoreFilter ?? 'Mọi cấp'} · ${savedOnlyFilter ? 'Từ vựng đã lưu' : 'Mọi từ vựng'}',
          style: GoogleFonts.lexend(
            fontSize: 11,
            color: AppColors.textSlate500,
          ),
        ),
        const SizedBox(height: 8),
        sourceAsync.when(
          data: (words) {
            final filtered = words.where((word) {
              final matchesSearch =
                  query.isEmpty ||
                  word.word.toLowerCase().contains(query) ||
                  word.definition.toLowerCase().contains(query);
              if (!matchesSearch) return false;
              if (savedOnlyFilter && !savedWordIds.contains(word.id)) {
                return false;
              }
              return true;
            }).toList();

            if (filtered.isEmpty) {
              return const _EmptyBox(
                icon: Icons.bookmark_border,
                title: 'Không tìm thấy từ vựng nào',
                subtitle: 'Hãy đổi từ khóa hoặc bộ lọc.',
              );
            }

            return _VocabularyPlayground(
              words: filtered,
              page: page,
              pageSize: pageSize,
              onPageChanged: onPageChanged,
              savedWordIds: savedWordIds,
              onToggleSaved: onToggleSaved,
            );
          },
          loading: () => const _ListLoading(count: 5),
          error: (e, _) => _EmptyBox(
            icon: Icons.error_outline,
            title: 'Không tải được dữ liệu',
            subtitle: '$e',
          ),
        ),
      ],
    );
  }

  Future<void> _openFilterModal(BuildContext context, List<int> lessons) async {
    int? selectedLesson = lessonFilter;
    String? selectedScore = scoreFilter;
    bool selectedSavedOnly = savedOnlyFilter;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.borderSlate200,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Bộ lọc từ vựng',
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSlate900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bài học',
                      style: GoogleFonts.lexend(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FilterPill(
                          label: 'Tất cả bài',
                          active: selectedLesson == null,
                          onTap: () =>
                              setModalState(() => selectedLesson = null),
                        ),
                        ...lessons.map(
                          (lesson) => _FilterPill(
                            label: 'Bài $lesson',
                            active: selectedLesson == lesson,
                            onTap: () =>
                                setModalState(() => selectedLesson = lesson),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Mức điểm',
                      style: GoogleFonts.lexend(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FilterPill(
                          label: 'Mọi cấp',
                          active: selectedScore == null,
                          onTap: () =>
                              setModalState(() => selectedScore = null),
                        ),
                        ...scoreLevels.map(
                          (level) => _FilterPill(
                            label: level,
                            active: selectedScore == level,
                            onTap: () =>
                                setModalState(() => selectedScore = level),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Danh mục',
                      style: GoogleFonts.lexend(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FilterPill(
                          label: 'Mọi từ vựng',
                          active: !selectedSavedOnly,
                          onTap: () =>
                              setModalState(() => selectedSavedOnly = false),
                        ),
                        _FilterPill(
                          label: 'Từ vựng đã lưu',
                          active: selectedSavedOnly,
                          onTap: () =>
                              setModalState(() => selectedSavedOnly = true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          onLessonChanged(selectedLesson);
                          onScoreChanged(selectedScore);
                          onSavedOnlyChanged(selectedSavedOnly);
                          Navigator.of(sheetContext).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Áp dụng',
                          style: GoogleFonts.lexend(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

enum _VocabGameMode {
  list,
  flashcard,
  quiz,
  matching,
  fillBlank,
  listening,
  spelling,
  speed,
  memory,
}

extension _VocabGameModeUi on _VocabGameMode {
  String get label {
    switch (this) {
      case _VocabGameMode.list:
        return 'Danh sách từ vựng';
      case _VocabGameMode.flashcard:
        return 'Flashcard';
      case _VocabGameMode.quiz:
        return 'Trắc nghiệm';
      case _VocabGameMode.matching:
        return 'Nối từ';
      case _VocabGameMode.fillBlank:
        return 'Điền từ';
      case _VocabGameMode.listening:
        return 'Nghe';
      case _VocabGameMode.spelling:
        return 'Chính tả';
      case _VocabGameMode.speed:
        return 'Tốc độ';
      case _VocabGameMode.memory:
        return 'Memory';
    }
  }

  IconData get icon {
    switch (this) {
      case _VocabGameMode.list:
        return Icons.view_list_rounded;
      case _VocabGameMode.flashcard:
        return Icons.style_rounded;
      case _VocabGameMode.quiz:
        return Icons.quiz_rounded;
      case _VocabGameMode.matching:
        return Icons.link_rounded;
      case _VocabGameMode.fillBlank:
        return Icons.edit_note_rounded;
      case _VocabGameMode.listening:
        return Icons.hearing_rounded;
      case _VocabGameMode.spelling:
        return Icons.spellcheck_rounded;
      case _VocabGameMode.speed:
        return Icons.timer_rounded;
      case _VocabGameMode.memory:
        return Icons.grid_view_rounded;
    }
  }
}

class _VocabularyPlayground extends StatefulWidget {
  final List<VocabularyModel> words;
  final int page;
  final int pageSize;
  final Set<String> savedWordIds;
  final Future<void> Function(String wordId) onToggleSaved;
  final ValueChanged<int> onPageChanged;

  const _VocabularyPlayground({
    required this.words,
    required this.page,
    required this.pageSize,
    required this.savedWordIds,
    required this.onToggleSaved,
    required this.onPageChanged,
  });

  @override
  State<_VocabularyPlayground> createState() => _VocabularyPlaygroundState();
}

class _VocabularyPlaygroundState extends State<_VocabularyPlayground> {
  _VocabGameMode _mode = _VocabGameMode.list;
  bool _englishToVietnamese = true;

  String get _wordSignature {
    if (widget.words.isEmpty) return 'empty';
    final sample = widget.words.take(8).map((e) => e.id).join('_');
    return '${widget.words.length}_${widget.words.first.id}_${widget.words.last.id}_$sample';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GameModeTabs(
          mode: _mode,
          onChanged: (value) => setState(() => _mode = value),
        ),
        const SizedBox(height: 10),
        if (_mode != _VocabGameMode.list)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                Text(
                  _englishToVietnamese ? 'Chế độ EN -> VI' : 'Chế độ VI -> EN',
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate700,
                  ),
                ),
                const Spacer(),
                Switch.adaptive(
                  value: _englishToVietnamese,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() => _englishToVietnamese = value);
                  },
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        _buildCurrentMode(),
      ],
    );
  }

  Widget _buildCurrentMode() {
    switch (_mode) {
      case _VocabGameMode.list:
        return _VocabularyListSection(
          words: widget.words,
          page: widget.page,
          pageSize: widget.pageSize,
          savedWordIds: widget.savedWordIds,
          onToggleSaved: widget.onToggleSaved,
          onPageChanged: widget.onPageChanged,
          onWordTap: _openWordDetail,
        );
      case _VocabGameMode.flashcard:
        return _FlashcardGame(
          key: ValueKey('flash_$_wordSignature$_englishToVietnamese'),
          words: widget.words,
          englishToVietnamese: _englishToVietnamese,
        );
      case _VocabGameMode.quiz:
        return _MultipleChoiceGame(
          key: ValueKey('quiz_$_wordSignature$_englishToVietnamese'),
          words: widget.words,
          englishToVietnamese: _englishToVietnamese,
        );
      case _VocabGameMode.matching:
        return _MatchingGame(
          key: ValueKey('matching_$_wordSignature'),
          words: widget.words,
        );
      case _VocabGameMode.fillBlank:
        return _FillBlankGame(
          key: ValueKey('blank_$_wordSignature$_englishToVietnamese'),
          words: widget.words,
          englishToVietnamese: _englishToVietnamese,
        );
      case _VocabGameMode.listening:
        return _ListeningQuizGame(
          key: ValueKey('listen_$_wordSignature$_englishToVietnamese'),
          words: widget.words,
          englishToVietnamese: _englishToVietnamese,
        );
      case _VocabGameMode.spelling:
        return _SpellingGame(
          key: ValueKey('spelling_$_wordSignature$_englishToVietnamese'),
          words: widget.words,
          englishToVietnamese: _englishToVietnamese,
        );
      case _VocabGameMode.speed:
        return _SpeedChallengeGame(
          key: ValueKey('speed_$_wordSignature$_englishToVietnamese'),
          words: widget.words,
          englishToVietnamese: _englishToVietnamese,
        );
      case _VocabGameMode.memory:
        return _MemoryGame(
          key: ValueKey('memory_$_wordSignature'),
          words: widget.words,
        );
    }
  }

  Future<void> _openWordDetail(VocabularyModel word) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _VocabularyWordDetailSheet(word: word),
    );
  }
}

class _GameModeTabs extends StatelessWidget {
  final _VocabGameMode mode;
  final ValueChanged<_VocabGameMode> onChanged;

  const _GameModeTabs({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final item = _VocabGameMode.values[index];
          final active = item == mode;
          return GestureDetector(
            onTap: () => onChanged(item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active ? AppColors.primary : AppColors.borderSlate200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 14,
                    color: active ? Colors.white : AppColors.textSlate600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.label,
                    style: GoogleFonts.lexend(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : AppColors.textSlate600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: _VocabGameMode.values.length,
      ),
    );
  }
}

class _VocabularyListSection extends StatelessWidget {
  final List<VocabularyModel> words;
  final int page;
  final int pageSize;
  final Set<String> savedWordIds;
  final Future<void> Function(String wordId) onToggleSaved;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<VocabularyModel> onWordTap;

  const _VocabularyListSection({
    required this.words,
    required this.page,
    required this.pageSize,
    required this.savedWordIds,
    required this.onToggleSaved,
    required this.onPageChanged,
    required this.onWordTap,
  });

  @override
  Widget build(BuildContext context) {
    final total = words.length;
    final totalPages = (total / pageSize).ceil();
    final safePage = page.clamp(0, totalPages - 1);
    final start = safePage * pageSize;
    final end = (start + pageSize > total) ? total : start + pageSize;
    final pageItems = words.sublist(start, end);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${start + 1}–$end trong $total từ',
          style: GoogleFonts.lexend(
            fontSize: 12,
            color: AppColors.textSlate500,
          ),
        ),
        const SizedBox(height: 8),
        ...pageItems.map(
          (word) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _LearningWordCard(
              word: word,
              isSaved: savedWordIds.contains(word.id),
              onTap: () => onWordTap(word),
              onToggleSaved: () => onToggleSaved(word.id),
            ),
          ),
        ),
        if (totalPages > 1)
          _PaginationBar(
            page: safePage,
            totalPages: totalPages,
            onChange: onPageChanged,
          ),
      ],
    );
  }
}

class _FlashcardGame extends StatefulWidget {
  final List<VocabularyModel> words;
  final bool englishToVietnamese;

  const _FlashcardGame({
    super.key,
    required this.words,
    required this.englishToVietnamese,
  });

  @override
  State<_FlashcardGame> createState() => _FlashcardGameState();
}

class _FlashcardGameState extends State<_FlashcardGame> {
  final Random _random = Random();
  final AudioPlayer _player = AudioPlayer();
  final FocusNode _keyboardFocusNode = FocusNode();
  final Map<String, String> _dictionaryAudioCache = <String, String>{};
  final Set<String> _dictionaryAudioNoResult = <String>{};

  late List<VocabularyModel> _deck;
  int _index = 0;
  bool _showBack = false;
  int _known = 0;
  int _unknown = 0;
  bool _trackProgress = true;
  bool _autoPlay = false;
  bool _showHint = false;
  bool _audioPlaying = false;
  bool _fullScreen = false;
  Timer? _autoTimer;
  String _lastDataSignature = '';
  final Set<String> _favorites = <String>{};

  @override
  void initState() {
    super.initState();
    _resetDeck();
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      final active =
          state.playing && state.processingState != ProcessingState.completed;
      if (_audioPlaying != active) {
        setState(() => _audioPlaying = active);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _FlashcardGame oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newSignature = _buildDataSignature(widget.words);
    if (newSignature != _lastDataSignature ||
        oldWidget.englishToVietnamese != widget.englishToVietnamese) {
      _resetDeck();
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _player.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_deck.isEmpty) {
      return const _EmptyBox(
        icon: Icons.style,
        title: 'Không có dữ liệu flashcard',
        subtitle: 'Hãy đổi bộ lọc hoặc từ khóa.',
      );
    }

    final current = _deck[_index % _deck.length];
    final front = widget.englishToVietnamese
        ? current.word
        : current.definition;
    final back = widget.englishToVietnamese ? current.definition : current.word;
    final hint = current.phonetic?.trim().isNotEmpty == true
        ? current.phonetic!.trim()
        : 'Bài ${current.lesson} · ${current.scoreLevel}';
    final isFavorite = _favorites.contains(current.id);

    final cardMaxWidth = _fullScreen ? 1200.0 : 1040.0;
    final cardHeight = _fullScreen ? 500.0 : 430.0;

    return Focus(
      autofocus: true,
      focusNode: _keyboardFocusNode,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _goPrev();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _goNext();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        width: double.infinity,
        color: const Color(0xFFF5F5F5),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: cardMaxWidth),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Column(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _flip,
                          child: Container(
                            width: double.infinity,
                            height: cardHeight,
                            color: const Color(0xFFF9F9F9),
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() => _showHint = !_showHint);
                                      },
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.lightbulb_outline,
                                            size: 18,
                                            color: AppColors.textSlate400,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Hiển thị gợi ý',
                                            style: GoogleFonts.lexend(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textSlate500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    _FlashcardTopIcon(
                                      icon: _audioPlaying
                                          ? Icons.graphic_eq
                                          : Icons.volume_up_rounded,
                                      onTap: _playAudio,
                                    ),
                                    const SizedBox(width: 12),
                                    _FlashcardTopIcon(
                                      icon: isFavorite
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      onTap: () {
                                        setState(() {
                                          if (isFavorite) {
                                            _favorites.remove(current.id);
                                          } else {
                                            _favorites.add(current.id);
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                if (_showHint)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: AppColors.borderSlate200,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      hint,
                                      style: GoogleFonts.lexend(
                                        fontSize: 12,
                                        color: AppColors.textSlate500,
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: Center(
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween<double>(
                                        begin: 0,
                                        end: _showBack ? pi : 0,
                                      ),
                                      duration: const Duration(
                                        milliseconds: 360,
                                      ),
                                      curve: Curves.easeInOut,
                                      builder: (context, value, child) {
                                        final isBack = value > (pi / 2);
                                        final display = isBack ? back : front;
                                        final rotate = isBack
                                            ? value - pi
                                            : value;
                                        return Transform(
                                          alignment: Alignment.center,
                                          transform: Matrix4.identity()
                                            ..setEntry(3, 2, 0.0012)
                                            ..rotateY(rotate),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                            ),
                                            child: Text(
                                              display,
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.lexend(
                                                fontSize: isBack ? 30 : 34,
                                                fontWeight: FontWeight.w500,
                                                color: const Color(0xFF333333),
                                                height: 1.25,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(18),
                            ),
                          ),
                          child: Text(
                            'Nhấp vào thẻ để lật',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lexend(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 920;

                      final progressToggle = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Theo dõi tiến độ',
                            style: GoogleFonts.lexend(
                              fontSize: 13,
                              color: AppColors.textSlate600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            height: 32,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: Switch.adaptive(
                                value: _trackProgress,
                                activeColor: AppColors.primary,
                                onChanged: (value) {
                                  setState(() => _trackProgress = value);
                                },
                              ),
                            ),
                          ),
                        ],
                      );

                      final navControls = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _FlashcardCircleButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            disabled: _deck.length <= 1,
                            onTap: _goPrev,
                          ),
                          const SizedBox(width: 10),
                          _FlashcardCircleButton(
                            icon: Icons.arrow_forward_ios_rounded,
                            disabled: _deck.length <= 1,
                            onTap: _goNext,
                          ),
                        ],
                      );

                      final rightControls = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _FlashcardTopIcon(
                            icon: _autoPlay
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            onTap: () {
                              setState(() => _autoPlay = !_autoPlay);
                              _setupAutoPlay();
                            },
                          ),
                          const SizedBox(width: 10),
                          _FlashcardTopIcon(
                            icon: _fullScreen
                                ? Icons.fullscreen_exit_rounded
                                : Icons.fullscreen_rounded,
                            onTap: () {
                              setState(() => _fullScreen = !_fullScreen);
                            },
                          ),
                        ],
                      );

                      if (isCompact) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                progressToggle,
                                const Spacer(),
                                rightControls,
                              ],
                            ),
                            const SizedBox(height: 10),
                            Center(child: navControls),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: progressToggle),
                          navControls,
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: rightControls,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                if (_trackProgress)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Thẻ ${_index + 1}/${_deck.length}',
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          color: AppColors.textSlate500,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Đã nhớ $_known',
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Chưa nhớ $_unknown',
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          color: AppColors.red500,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _markUnknown,
                        child: const Text('Không nhớ'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _markKnown,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Đã nhớ'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildDataSignature(List<VocabularyModel> words) {
    if (words.isEmpty) return 'empty';
    final sample = words.take(8).map((e) => e.id).join('_');
    return '${words.length}_${words.first.id}_${words.last.id}_$sample';
  }

  void _resetDeck() {
    _autoTimer?.cancel();
    _player.stop();
    _deck = List<VocabularyModel>.from(widget.words)..shuffle(_random);
    _index = 0;
    _showBack = false;
    _known = 0;
    _unknown = 0;
    _showHint = false;
    _audioPlaying = false;
    _autoPlay = false;
    _lastDataSignature = _buildDataSignature(widget.words);
  }

  void _setupAutoPlay() {
    _autoTimer?.cancel();
    if (!_autoPlay) return;
    _autoTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() => _showBack = !_showBack);
    });
  }

  void _flip() {
    setState(() => _showBack = !_showBack);
  }

  void _goNext() {
    if (_deck.length <= 1) return;
    setState(() {
      _showBack = false;
      _showHint = false;
      _index = (_index + 1) % _deck.length;
    });
  }

  void _goPrev() {
    if (_deck.length <= 1) return;
    setState(() {
      _showBack = false;
      _showHint = false;
      _index = (_index - 1 + _deck.length) % _deck.length;
    });
  }

  Future<void> _playAudio() async {
    if (_deck.isEmpty) return;
    final current = _deck[_index % _deck.length];
    final localUrl = (current.audioUrl ?? '').trim();
    final url = await _resolveAudioUrlForWord(current.word, localUrl: localUrl);

    if (url.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Từ này chưa có audio phát âm.',
            style: GoogleFonts.lexend(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: AppColors.slate700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      if (_audioPlaying) {
        await _player.stop();
        return;
      }
      await _player.setUrl(url);
      await _player.play();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không phát được audio. Vui lòng thử lại.',
            style: GoogleFonts.lexend(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: AppColors.red500,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<String> _resolveAudioUrlForWord(
    String word, {
    required String localUrl,
  }) async {
    if (localUrl.isNotEmpty) return localUrl;

    final query = word.trim();
    if (query.isEmpty) return '';

    final key = query.toLowerCase();
    final cached = _dictionaryAudioCache[key];
    if (cached != null) return cached;
    if (_dictionaryAudioNoResult.contains(key)) return '';

    try {
      final uri = Uri.parse(
        'https://api.dictionaryapi.dev/api/v2/entries/en/${Uri.encodeComponent(query)}',
      );
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        _dictionaryAudioNoResult.add(key);
        return '';
      }

      final body = jsonDecode(response.body);
      if (body is! List || body.isEmpty) {
        _dictionaryAudioNoResult.add(key);
        return '';
      }

      for (final item in body) {
        if (item is! Map<String, dynamic>) continue;

        final parsed = _DictionaryLookupResult.fromJson(item);
        final fromModel = parsed.audioUrl.trim();
        if (fromModel.isNotEmpty) {
          _dictionaryAudioCache[key] = fromModel;
          return fromModel;
        }

        final fromPhonetics = _extractAudioFromPhonetics(item);
        if (fromPhonetics.isNotEmpty) {
          _dictionaryAudioCache[key] = fromPhonetics;
          return fromPhonetics;
        }
      }

      _dictionaryAudioNoResult.add(key);
      return '';
    } catch (_) {
      return '';
    }
  }

  String _extractAudioFromPhonetics(Map<String, dynamic> entry) {
    final phonetics = entry['phonetics'];
    if (phonetics is! List) return '';

    for (final p in phonetics) {
      if (p is! Map<String, dynamic>) continue;
      final raw = (p['audio'] as String?)?.trim() ?? '';
      if (raw.isEmpty) continue;
      return raw.startsWith('//') ? 'https:$raw' : raw;
    }

    return '';
  }

  void _markKnown() {
    if (_deck.isEmpty) return;
    setState(() {
      _known += 1;
      _showBack = false;
      _showHint = false;
      _index = (_index + 1) % _deck.length;
    });
  }

  void _markUnknown() {
    if (_deck.isEmpty) return;
    final card = _deck[_index % _deck.length];
    setState(() {
      _unknown += 1;
      _showBack = false;
      _showHint = false;
      final currentPos = _index % _deck.length;
      _deck.removeAt(currentPos);

      if (_deck.isEmpty) {
        _deck.add(card);
        _index = 0;
        return;
      }

      // Spaced repetition: unknown words come back soon, not immediately.
      final insertPos = min(currentPos + 2, _deck.length);
      _deck.insert(insertPos, card);
      if (_index >= _deck.length) {
        _index = 0;
      }
    });
  }
}

class _FlashcardTopIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FlashcardTopIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.borderSlate200),
          ),
          child: Icon(icon, size: 19, color: AppColors.textSlate500),
        ),
      ),
    );
  }
}

class _FlashcardCircleButton extends StatelessWidget {
  final IconData icon;
  final bool disabled;
  final VoidCallback onTap;

  const _FlashcardCircleButton({
    required this.icon,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: disabled ? AppColors.slate100 : const Color(0xFFE5E7EB),
          ),
          child: Icon(
            icon,
            size: 17,
            color: disabled ? AppColors.textSlate300 : AppColors.textSlate600,
          ),
        ),
      ),
    );
  }
}

class _MultipleChoiceGame extends StatefulWidget {
  final List<VocabularyModel> words;
  final bool englishToVietnamese;

  const _MultipleChoiceGame({
    super.key,
    required this.words,
    required this.englishToVietnamese,
  });

  @override
  State<_MultipleChoiceGame> createState() => _MultipleChoiceGameState();
}

class _MultipleChoiceGameState extends State<_MultipleChoiceGame> {
  final Random _random = Random();
  late VocabularyModel _question;
  List<String> _options = const [];
  bool? _isCorrect;

  @override
  void initState() {
    super.initState();
    _next();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.words.length < 4) {
      return const _EmptyBox(
        icon: Icons.quiz,
        title: 'Cần ít nhất 4 từ',
        subtitle: 'Thêm dữ liệu để chơi trắc nghiệm.',
      );
    }

    final prompt = widget.englishToVietnamese
        ? _question.word
        : _question.definition;
    final answer = widget.englishToVietnamese
        ? _question.definition
        : _question.word;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSlate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            prompt,
            style: GoogleFonts.lexend(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textSlate900,
            ),
          ),
          const SizedBox(height: 10),
          ..._options.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: _isCorrect != null
                    ? null
                    : () => _answer(option == answer),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isCorrect != null && option == answer
                        ? AppColors.teal100
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSlate200),
                  ),
                  child: Text(
                    option,
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isCorrect != null)
            Text(
              _isCorrect! ? 'Chính xác!' : 'Sai rồi. Đáp án: $answer',
              style: GoogleFonts.lexend(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _isCorrect! ? AppColors.primary : AppColors.red500,
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _next, child: const Text('Câu mới')),
        ],
      ),
    );
  }

  void _answer(bool ok) {
    setState(() => _isCorrect = ok);
  }

  void _next() {
    final pool = List<VocabularyModel>.from(widget.words)..shuffle(_random);
    _question = pool.first;
    final answer = widget.englishToVietnamese
        ? _question.definition
        : _question.word;
    final optionsPool = widget.englishToVietnamese
        ? pool.map((e) => e.definition).toSet().toList()
        : pool.map((e) => e.word).toSet().toList();
    optionsPool.shuffle(_random);
    final options = [answer, ...optionsPool.where((e) => e != answer).take(3)]
      ..shuffle(_random);
    setState(() {
      _options = options;
      _isCorrect = null;
    });
  }
}

class _MatchingGame extends StatefulWidget {
  final List<VocabularyModel> words;

  const _MatchingGame({super.key, required this.words});

  @override
  State<_MatchingGame> createState() => _MatchingGameState();
}

class _MatchingGameState extends State<_MatchingGame> {
  final Random _random = Random();
  late List<VocabularyModel> _left;
  late List<VocabularyModel> _right;
  final Set<String> _matched = <String>{};
  String? _leftSelected;
  String? _rightSelected;
  int _attempts = 0;
  late DateTime _startedAt;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  Widget build(BuildContext context) {
    if (_left.length < 3) {
      return const _EmptyBox(
        icon: Icons.link,
        title: 'Cần ít nhất 3 cặp',
        subtitle: 'Thêm dữ liệu để chơi nối từ.',
      );
    }

    final elapsed = DateTime.now().difference(_startedAt).inSeconds;
    final accuracy = _attempts == 0
        ? 0
        : ((_matched.length / _attempts) * 100).round();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSlate100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Đúng ${_matched.length}/${_left.length}',
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  color: AppColors.textSlate500,
                ),
              ),
              const Spacer(),
              Text(
                '${elapsed}s · $accuracy%',
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  color: AppColors.textSlate500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: _left
                      .map(
                        (item) => _MatchOptionTile(
                          text: item.word,
                          active: _leftSelected == item.id,
                          done: _matched.contains(item.id),
                          onTap: () => _pickLeft(item.id),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: _right
                      .map(
                        (item) => _MatchOptionTile(
                          text: item.definition,
                          active: _rightSelected == item.id,
                          done: _matched.contains(item.id),
                          onTap: () => _pickRight(item.id),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _reset, child: const Text('Làm mới')),
        ],
      ),
    );
  }

  void _pickLeft(String id) {
    if (_matched.contains(id)) return;
    setState(() => _leftSelected = id);
    _check();
  }

  void _pickRight(String id) {
    if (_matched.contains(id)) return;
    setState(() => _rightSelected = id);
    _check();
  }

  void _check() {
    if (_leftSelected == null || _rightSelected == null) return;
    setState(() {
      _attempts += 1;
      if (_leftSelected == _rightSelected) {
        _matched.add(_leftSelected!);
      }
      _leftSelected = null;
      _rightSelected = null;
    });
  }

  void _reset() {
    final sample = (List<VocabularyModel>.from(
      widget.words,
    )..shuffle(_random)).take(min(6, widget.words.length)).toList();
    _left = sample;
    _right = List<VocabularyModel>.from(sample)..shuffle(_random);
    _matched.clear();
    _leftSelected = null;
    _rightSelected = null;
    _attempts = 0;
    _startedAt = DateTime.now();
    if (mounted) {
      setState(() {});
    }
  }
}

class _MatchOptionTile extends StatelessWidget {
  final String text;
  final bool active;
  final bool done;
  final VoidCallback onTap;

  const _MatchOptionTile({
    required this.text,
    required this.active,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: done ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: done
                ? AppColors.teal100
                : active
                ? const Color(0xFFEFF6FF)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: done
                  ? AppColors.primary
                  : active
                  ? AppColors.primary
                  : AppColors.borderSlate200,
            ),
          ),
          child: Text(
            text,
            style: GoogleFonts.lexend(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.slate700,
            ),
          ),
        ),
      ),
    );
  }
}

class _FillBlankGame extends StatefulWidget {
  final List<VocabularyModel> words;
  final bool englishToVietnamese;

  const _FillBlankGame({
    super.key,
    required this.words,
    required this.englishToVietnamese,
  });

  @override
  State<_FillBlankGame> createState() => _FillBlankGameState();
}

class _FillBlankGameState extends State<_FillBlankGame> {
  final Random _random = Random();
  final TextEditingController _controller = TextEditingController();
  late VocabularyModel _current;
  List<String> _suggestions = const [];
  bool? _ok;

  @override
  void initState() {
    super.initState();
    _next();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.words.length < 4) {
      return const _EmptyBox(
        icon: Icons.edit_note,
        title: 'Cần ít nhất 4 từ',
        subtitle: 'Thêm dữ liệu để chơi điền từ.',
      );
    }

    final answer = widget.englishToVietnamese
        ? _current.word
        : _current.definition;
    final sentence = widget.englishToVietnamese
        ? 'The word ____ means "${_current.definition}".'
        : 'Nghĩa tiếng Việt của "${_current.word}" là ____.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSlate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sentence,
            style: GoogleFonts.lexend(fontSize: 13, color: AppColors.slate700),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            style: GoogleFonts.lexend(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Điền đáp án...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderSlate200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderSlate200),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions
                .map(
                  (item) => GestureDetector(
                    onTap: () => setState(() => _controller.text = item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.borderSlate200),
                      ),
                      child: Text(
                        item,
                        style: GoogleFonts.lexend(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate700,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _next,
                  child: const Text('Đổi câu'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _ok =
                          _controller.text.trim().toLowerCase() ==
                          answer.trim().toLowerCase();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Kiểm tra'),
                ),
              ),
            ],
          ),
          if (_ok != null) ...[
            const SizedBox(height: 8),
            Text(
              _ok! ? 'Đúng rồi!' : 'Sai rồi. Đáp án đúng: $answer',
              style: GoogleFonts.lexend(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _ok! ? AppColors.primary : AppColors.red500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _next() {
    final pool = List<VocabularyModel>.from(widget.words)..shuffle(_random);
    _current = pool.first;
    final answer = widget.englishToVietnamese
        ? _current.word
        : _current.definition;
    final candidate = widget.englishToVietnamese
        ? pool.map((e) => e.word).toSet().toList()
        : pool.map((e) => e.definition).toSet().toList();
    candidate.shuffle(_random);
    _suggestions = [answer, ...candidate.where((e) => e != answer).take(3)]
      ..shuffle(_random);
    _controller.clear();
    setState(() => _ok = null);
  }
}

class _ListeningQuizGame extends StatefulWidget {
  final List<VocabularyModel> words;
  final bool englishToVietnamese;

  const _ListeningQuizGame({
    super.key,
    required this.words,
    required this.englishToVietnamese,
  });

  @override
  State<_ListeningQuizGame> createState() => _ListeningQuizGameState();
}

class _ListeningQuizGameState extends State<_ListeningQuizGame> {
  final Random _random = Random();
  final AudioPlayer _player = AudioPlayer();

  List<VocabularyModel> _audioWords = const [];
  VocabularyModel? _current;
  List<String> _options = const [];
  bool _playing = false;
  bool? _ok;

  @override
  void initState() {
    super.initState();
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _playing =
            state.playing && state.processingState != ProcessingState.completed;
      });
    });
    _prepare();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_audioWords.isEmpty || _current == null) {
      return const _EmptyBox(
        icon: Icons.hearing,
        title: 'Không có audio phát âm',
        subtitle: 'Game nghe cần từ có audio URL.',
      );
    }

    final answer = widget.englishToVietnamese
        ? _current!.definition
        : _current!.word;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSlate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _play,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                icon: Icon(_playing ? Icons.graphic_eq : Icons.volume_up),
                label: Text(_playing ? 'Đang phát...' : 'Phát lại'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: _next, child: const Text('Câu mới')),
            ],
          ),
          const SizedBox(height: 10),
          ..._options.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: _ok != null
                    ? null
                    : () => setState(() => _ok = option == answer),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _ok != null && option == answer
                        ? AppColors.teal100
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSlate200),
                  ),
                  child: Text(
                    option,
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_ok != null)
            Text(
              _ok! ? 'Chính xác!' : 'Sai rồi. Đáp án: $answer',
              style: GoogleFonts.lexend(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _ok! ? AppColors.primary : AppColors.red500,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _play() async {
    final item = _current;
    if (item == null || (item.audioUrl ?? '').isEmpty) return;
    try {
      await _player.setUrl(item.audioUrl!);
      await _player.play();
    } catch (_) {}
  }

  void _prepare() {
    _audioWords = widget.words
        .where((e) => (e.audioUrl ?? '').isNotEmpty)
        .toList();
    _next();
  }

  void _next() {
    if (_audioWords.isEmpty) {
      setState(() {
        _current = null;
        _options = const [];
      });
      return;
    }
    final pool = List<VocabularyModel>.from(_audioWords)..shuffle(_random);
    _current = pool.first;
    final answer = widget.englishToVietnamese
        ? _current!.definition
        : _current!.word;
    final candidate = widget.englishToVietnamese
        ? pool.map((e) => e.definition).toSet().toList()
        : pool.map((e) => e.word).toSet().toList();
    candidate.shuffle(_random);
    setState(() {
      _options = [answer, ...candidate.where((e) => e != answer).take(3)]
        ..shuffle(_random);
      _ok = null;
    });
  }
}

class _SpellingGame extends StatefulWidget {
  final List<VocabularyModel> words;
  final bool englishToVietnamese;

  const _SpellingGame({
    super.key,
    required this.words,
    required this.englishToVietnamese,
  });

  @override
  State<_SpellingGame> createState() => _SpellingGameState();
}

class _SpellingGameState extends State<_SpellingGame> {
  final Random _random = Random();
  final TextEditingController _controller = TextEditingController();
  late VocabularyModel _current;
  bool _strict = true;
  bool? _ok;

  @override
  void initState() {
    super.initState();
    _next();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.words.isEmpty) {
      return const _EmptyBox(
        icon: Icons.spellcheck,
        title: 'Không có dữ liệu',
        subtitle: 'Hãy đổi bộ lọc để chơi chính tả.',
      );
    }

    final answer = widget.englishToVietnamese
        ? _current.word
        : _current.definition;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSlate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.englishToVietnamese ? _current.definition : _current.word,
            style: GoogleFonts.lexend(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textSlate900,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            style: GoogleFonts.lexend(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Nhập đáp án...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderSlate200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderSlate200),
              ),
            ),
          ),
          Row(
            children: [
              Text(
                'Strict',
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  color: AppColors.slate700,
                ),
              ),
              const Spacer(),
              Switch.adaptive(
                value: _strict,
                activeColor: AppColors.primary,
                onChanged: (value) => setState(() => _strict = value),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _next,
                  child: const Text('Đổi từ'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final input = _controller.text.trim();
                    final ok = _strict
                        ? input.toLowerCase() == answer.trim().toLowerCase()
                        : _normalizeWord(input) == _normalizeWord(answer);
                    setState(() => _ok = ok);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Kiểm tra'),
                ),
              ),
            ],
          ),
          if (_ok != null) ...[
            const SizedBox(height: 8),
            Text(
              _ok! ? 'Đúng!' : 'Sai rồi. Đáp án: $answer',
              style: GoogleFonts.lexend(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _ok! ? AppColors.primary : AppColors.red500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _next() {
    final pool = List<VocabularyModel>.from(widget.words)..shuffle(_random);
    _current = pool.first;
    _controller.clear();
    setState(() => _ok = null);
  }
}

class _SpeedChallengeGame extends StatefulWidget {
  final List<VocabularyModel> words;
  final bool englishToVietnamese;

  const _SpeedChallengeGame({
    super.key,
    required this.words,
    required this.englishToVietnamese,
  });

  @override
  State<_SpeedChallengeGame> createState() => _SpeedChallengeGameState();
}

class _SpeedChallengeGameState extends State<_SpeedChallengeGame> {
  static const int _duration = 60;
  final Random _random = Random();

  Timer? _timer;
  bool _running = false;
  int _remaining = _duration;
  int _score = 0;
  int _total = 0;
  VocabularyModel? _current;
  List<String> _options = const [];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.words.length < 4) {
      return const _EmptyBox(
        icon: Icons.timer,
        title: 'Cần ít nhất 4 từ',
        subtitle: 'Thêm dữ liệu để chơi speed challenge.',
      );
    }

    final accuracy = _total == 0 ? 0 : ((_score / _total) * 100).round();
    final answer = _current == null
        ? ''
        : widget.englishToVietnamese
        ? _current!.definition
        : _current!.word;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSlate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_remaining}s',
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF92400E),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$_score/$_total · $accuracy%',
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  color: AppColors.textSlate500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!_running)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _start,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Bắt đầu 60 giây'),
              ),
            )
          else ...[
            Text(
              widget.englishToVietnamese
                  ? _current!.word
                  : _current!.definition,
              style: GoogleFonts.lexend(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textSlate900,
              ),
            ),
            const SizedBox(height: 10),
            ..._options.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _answer(option == answer),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSlate200),
                    ),
                    child: Text(
                      option,
                      style: GoogleFonts.lexend(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _start() {
    _timer?.cancel();
    setState(() {
      _running = true;
      _remaining = _duration;
      _score = 0;
      _total = 0;
    });
    _next();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remaining <= 1) {
        timer.cancel();
        setState(() => _running = false);
        return;
      }
      setState(() => _remaining -= 1);
    });
  }

  void _answer(bool ok) {
    if (!_running) return;
    setState(() {
      _total += 1;
      if (ok) {
        _score += 1;
      }
    });
    _next();
  }

  void _next() {
    final pool = List<VocabularyModel>.from(widget.words)..shuffle(_random);
    final current = pool.first;
    final answer = widget.englishToVietnamese
        ? current.definition
        : current.word;
    final candidate = widget.englishToVietnamese
        ? pool.map((e) => e.definition).toSet().toList()
        : pool.map((e) => e.word).toSet().toList();
    candidate.shuffle(_random);

    setState(() {
      _current = current;
      _options = [answer, ...candidate.where((e) => e != answer).take(3)]
        ..shuffle(_random);
    });
  }
}

class _MemoryGame extends StatefulWidget {
  final List<VocabularyModel> words;

  const _MemoryGame({super.key, required this.words});

  @override
  State<_MemoryGame> createState() => _MemoryGameState();
}

class _MemoryGameState extends State<_MemoryGame> {
  final Random _random = Random();
  List<_MemoryCard> _cards = const [];
  final Set<int> _matched = <int>{};
  final List<int> _flipped = <int>[];
  int _moves = 0;
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.length < 6) {
      return const _EmptyBox(
        icon: Icons.grid_view,
        title: 'Cần thêm dữ liệu',
        subtitle: 'Memory game cần ít nhất 3 cặp từ.',
      );
    }

    final done = _matched.length == _cards.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSlate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Lượt: $_moves',
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  color: AppColors.textSlate500,
                ),
              ),
              const Spacer(),
              Text(
                '${_seconds}s',
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  color: AppColors.textSlate500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            itemCount: _cards.length,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.14,
            ),
            itemBuilder: (context, index) {
              final card = _cards[index];
              final visible =
                  _matched.contains(index) || _flipped.contains(index);
              return InkWell(
                onTap: () => _onTap(index),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: visible ? Colors.white : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: visible
                          ? AppColors.borderSlate200
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      visible ? card.text : '?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lexend(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate700,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton(onPressed: _reset, child: const Text('Làm mới')),
              const Spacer(),
              if (done)
                Text(
                  'Hoàn thành trong ${_seconds}s',
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _onTap(int index) {
    if (_matched.contains(index) ||
        _flipped.contains(index) ||
        _flipped.length == 2) {
      return;
    }

    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _seconds += 1);
    });

    setState(() {
      _flipped.add(index);
    });

    if (_flipped.length < 2) return;

    _moves += 1;
    final first = _cards[_flipped[0]];
    final second = _cards[_flipped[1]];
    final match =
        first.pairId == second.pairId && first.isWord != second.isWord;

    if (match) {
      setState(() {
        _matched.addAll(_flipped);
        _flipped.clear();
      });
      if (_matched.length == _cards.length) {
        _timer?.cancel();
        _timer = null;
      }
      return;
    }

    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() => _flipped.clear());
    });
  }

  void _reset() {
    _timer?.cancel();
    _timer = null;
    _moves = 0;
    _seconds = 0;
    _flipped.clear();
    _matched.clear();

    final sample = (List<VocabularyModel>.from(
      widget.words,
    )..shuffle(_random)).take(min(6, widget.words.length)).toList();

    final cards = <_MemoryCard>[];
    for (final item in sample) {
      cards.add(_MemoryCard(pairId: item.id, text: item.word, isWord: true));
      cards.add(
        _MemoryCard(pairId: item.id, text: item.definition, isWord: false),
      );
    }
    cards.shuffle(_random);
    _cards = cards;
    if (mounted) {
      setState(() {});
    }
  }
}

class _MemoryCard {
  final String pairId;
  final String text;
  final bool isWord;

  const _MemoryCard({
    required this.pairId,
    required this.text,
    required this.isWord,
  });
}

String _normalizeWord(String text) {
  return text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

class _PageHeader extends StatelessWidget {
  final String title;

  const _PageHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                      return;
                    }
                    context.go('/home');
                  },
                  borderRadius: BorderRadius.circular(9999),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              Text(
                title,
                style: GoogleFonts.lexend(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentTabs extends StatelessWidget {
  final bool showDictionary;
  final VoidCallback onDictionaryTap;
  final VoidCallback onLearnTap;

  const _SegmentTabs({
    required this.showDictionary,
    required this.onDictionaryTap,
    required this.onLearnTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.45),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TabButton(
            icon: Icons.public,
            label: 'Từ điển',
            active: showDictionary,
            onTap: onDictionaryTap,
          ),
          _TabButton(
            icon: Icons.menu_book,
            label: 'Học từ vựng',
            active: !showDictionary,
            onTap: onLearnTap,
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: active ? AppColors.primary : AppColors.textSlate500,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.lexend(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? AppColors.primary : AppColors.textSlate500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final String value;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBox({
    required this.controller,
    required this.value,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSlate200),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.lexend(fontSize: 13),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.lexend(
            fontSize: 12,
            color: AppColors.textSlate400,
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 18,
            color: AppColors.textSlate400,
          ),
          suffixIcon: value.isEmpty
              ? null
              : IconButton(
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.textSlate400,
                  ),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.borderSlate200,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.lexend(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.textSlate600,
          ),
        ),
      ),
    );
  }
}

class _DictionaryHint extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onTapWord;

  const _DictionaryHint({required this.suggestions, required this.onTapWord});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSlate200),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome, color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          Text(
            'Tra từ ngay',
            style: GoogleFonts.lexend(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textSlate900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Nhập từ bất kỳ để xem nghĩa nhanh giống web.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lexend(
              fontSize: 12,
              color: AppColors.textSlate500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions
                .map(
                  (word) => GestureDetector(
                    onTap: () => onTapWord(word),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.borderSlate200),
                      ),
                      child: Text(
                        word,
                        style: GoogleFonts.lexend(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSlate600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _DictionaryLookupResult {
  final String word;
  final String phonetic;
  final String audioUrl;
  final List<_DictionaryMeaning> meanings;

  const _DictionaryLookupResult({
    required this.word,
    required this.phonetic,
    required this.audioUrl,
    required this.meanings,
  });

  factory _DictionaryLookupResult.fromJson(Map<String, dynamic> json) {
    String phonetic = '';
    final direct = json['phonetic'];
    if (direct is String) {
      phonetic = direct.trim();
    }

    final phonetics = json['phonetics'];
    String audioUrl = '';
    if (phonetics is List) {
      for (final item in phonetics) {
        if (phonetic.isEmpty &&
            item is Map<String, dynamic> &&
            item['text'] is String) {
          final text = (item['text'] as String).trim();
          if (text.isNotEmpty) {
            phonetic = text;
          }
        }
        if (audioUrl.isEmpty &&
            item is Map<String, dynamic> &&
            item['audio'] is String) {
          final rawAudio = (item['audio'] as String).trim();
          if (rawAudio.isNotEmpty) {
            audioUrl = rawAudio.startsWith('//') ? 'https:$rawAudio' : rawAudio;
          }
        }
        if (phonetic.isNotEmpty && audioUrl.isNotEmpty) break;
      }
    }

    final rawMeanings = json['meanings'];
    final meanings = <_DictionaryMeaning>[];
    if (rawMeanings is List) {
      for (final item in rawMeanings) {
        if (item is Map<String, dynamic>) {
          meanings.add(_DictionaryMeaning.fromJson(item));
        }
      }
    }

    return _DictionaryLookupResult(
      word: (json['word'] as String?) ?? '',
      phonetic: phonetic,
      audioUrl: audioUrl,
      meanings: meanings,
    );
  }
}

class _DictionaryMeaning {
  final String partOfSpeech;
  final List<String> definitions;

  const _DictionaryMeaning({
    required this.partOfSpeech,
    required this.definitions,
  });

  factory _DictionaryMeaning.fromJson(Map<String, dynamic> json) {
    final defs = <String>[];
    final rawDefs = json['definitions'];
    if (rawDefs is List) {
      for (final item in rawDefs) {
        if (item is Map<String, dynamic> && item['definition'] is String) {
          defs.add(item['definition'] as String);
        }
      }
    }
    return _DictionaryMeaning(
      partOfSpeech: (json['partOfSpeech'] as String?) ?? '',
      definitions: defs,
    );
  }
}

class _DictionaryApiCard extends StatelessWidget {
  final _DictionaryLookupResult result;
  final bool isPlayingAudio;
  final VoidCallback onPlayAudio;

  const _DictionaryApiCard({
    required this.result,
    required this.isPlayingAudio,
    required this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSlate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.word,
            style: GoogleFonts.lexend(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textSlate900,
            ),
          ),
          if (result.phonetic.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              result.phonetic,
              style: GoogleFonts.lexend(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AppColors.textSlate500,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: result.audioUrl.isEmpty ? null : onPlayAudio,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPlayingAudio
                      ? AppColors.red500.withValues(alpha: 0.16)
                      : AppColors.primary.withValues(alpha: 0.12),
                  foregroundColor: isPlayingAudio
                      ? AppColors.red500
                      : AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                icon: Icon(
                  isPlayingAudio ? Icons.volume_off : Icons.volume_up,
                  size: 16,
                ),
                label: Text(
                  isPlayingAudio ? 'Đang phát...' : 'Phát âm',
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${result.meanings.length} nghĩa',
                style: GoogleFonts.lexend(
                  fontSize: 11,
                  color: AppColors.textSlate500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (result.meanings.isEmpty)
            Text(
              'Không có nghĩa khả dụng cho từ này.',
              style: GoogleFonts.lexend(
                fontSize: 12,
                color: AppColors.textSlate600,
              ),
            )
          else
            ...result.meanings.map(
              (meaning) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (meaning.partOfSpeech.isNotEmpty)
                      Text(
                        meaning.partOfSpeech,
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    const SizedBox(height: 4),
                    ...meaning.definitions
                        .take(3)
                        .toList()
                        .asMap()
                        .entries
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '${entry.key + 1}. ${entry.value}',
                              style: GoogleFonts.lexend(
                                fontSize: 12,
                                color: AppColors.slate700,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            'Nguồn: DictionaryAPI.dev',
            style: GoogleFonts.lexend(
              fontSize: 11,
              color: AppColors.textSlate400,
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningWordCard extends StatelessWidget {
  final VocabularyModel word;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onToggleSaved;

  const _LearningWordCard({
    required this.word,
    required this.isSaved,
    required this.onTap,
    required this.onToggleSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSlate100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.teal100,
                ),
                child: const Icon(Icons.volume_up, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            word.word,
                            style: GoogleFonts.lexend(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSlate900,
                            ),
                          ),
                        ),
                        if (word.wordClass != null)
                          Text(
                            word.wordClass!,
                            style: GoogleFonts.lexend(
                              fontSize: 11,
                              color: AppColors.textSlate400,
                            ),
                          ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: onToggleSaved,
                          child: Icon(
                            isSaved
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 20,
                            color: isSaved
                                ? const Color(0xFFF59E0B)
                                : AppColors.textSlate400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      word.definition,
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: AppColors.textSlate600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VocabularyWordDetailSheet extends StatefulWidget {
  final VocabularyModel word;

  const _VocabularyWordDetailSheet({required this.word});

  @override
  State<_VocabularyWordDetailSheet> createState() =>
      _VocabularyWordDetailSheetState();
}

class _VocabularyWordDetailSheetState
    extends State<_VocabularyWordDetailSheet> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _audioPlaying = false;
  bool _loading = true;
  String _error = '';
  _DictionaryLookupResult? _result;
  final Set<int> _expandedParts = <int>{0};

  @override
  void initState() {
    super.initState();
    _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      final active =
          state.playing && state.processingState != ProcessingState.completed;
      if (_audioPlaying != active) {
        setState(() => _audioPlaying = active);
      }
    });
    _load();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    final query = widget.word.word.trim();
    if (query.isEmpty) {
      setState(() {
        _result = _fallbackFromWord(widget.word);
        _loading = false;
      });
      return;
    }

    try {
      final uri = Uri.parse(
        'https://api.dictionaryapi.dev/api/v2/entries/en/${Uri.encodeComponent(query)}',
      );
      final response = await http.get(uri);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is List && body.isNotEmpty) {
          final first = body.first;
          if (first is Map<String, dynamic>) {
            final parsed = _DictionaryLookupResult.fromJson(first);
            setState(() {
              _result = parsed.meanings.isEmpty
                  ? _fallbackFromWord(widget.word)
                  : parsed;
              _loading = false;
            });
            return;
          }
        }
      }

      setState(() {
        _result = _fallbackFromWord(widget.word);
        _loading = false;
        _error =
            'Không lấy được dữ liệu chi tiết từ API. Đang dùng dữ liệu nội bộ.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _result = _fallbackFromWord(widget.word);
        _loading = false;
        _error = 'Không thể kết nối từ điển. Đang dùng dữ liệu nội bộ.';
      });
    }
  }

  _DictionaryLookupResult _fallbackFromWord(VocabularyModel w) {
    return _DictionaryLookupResult(
      word: w.word,
      phonetic: (w.phonetic ?? '').trim(),
      audioUrl: (w.audioUrl ?? '').trim(),
      meanings: [
        _DictionaryMeaning(
          partOfSpeech: (w.wordClass ?? 'unknown').trim().isEmpty
              ? 'unknown'
              : w.wordClass!.trim(),
          definitions: [w.definition],
        ),
      ],
    );
  }

  Future<void> _playAudio() async {
    final data = _result;
    if (data == null || data.audioUrl.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Từ này chưa có audio phát âm.',
            style: GoogleFonts.lexend(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: AppColors.slate700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      if (_audioPlaying) {
        await _audioPlayer.stop();
        return;
      }
      await _audioPlayer.setUrl(data.audioUrl);
      await _audioPlayer.play();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không phát được audio. Vui lòng thử lại.',
            style: GoogleFonts.lexend(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: AppColors.red500,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.92;

    return Container(
      height: maxHeight,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.borderSlate200,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _loading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Đang tra từ "${widget.word.word}"...',
                          style: GoogleFonts.lexend(
                            fontSize: 13,
                            color: AppColors.textSlate500,
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final data = _result ?? _fallbackFromWord(widget.word);

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, Color(0xFF4EA39B)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chi tiết từ vựng',
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: const Color(0xFFE4FFFC),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                data.word,
                style: GoogleFonts.lexend(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              if (data.phonetic.isNotEmpty)
                Text(
                  data.phonetic,
                  style: GoogleFonts.robotoMono(
                    fontSize: 14,
                    color: const Color(0xFFD1FFF9),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: _playAudio,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.22),
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    icon: Icon(
                      _audioPlaying
                          ? Icons.graphic_eq_rounded
                          : Icons.volume_up_rounded,
                      size: 18,
                    ),
                    label: Text(_audioPlaying ? 'Đang phát...' : 'Phát âm'),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${data.meanings.length} nhóm nghĩa',
                    style: GoogleFonts.lexend(
                      fontSize: 12,
                      color: const Color(0xFFD1FFF9),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.orange50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFD8B0)),
            ),
            child: Text(
              _error,
              style: GoogleFonts.lexend(
                fontSize: 12,
                color: AppColors.slate700,
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        ...data.meanings.asMap().entries.map((entry) {
          final idx = entry.key;
          final meaning = entry.value;
          final isOpen = _expandedParts.contains(idx);
          final defs = meaning.definitions;
          final previewCount = isOpen ? defs.length : min(defs.length, 2);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSlate100),
              ),
              child: Column(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      setState(() {
                        if (isOpen) {
                          _expandedParts.remove(idx);
                        } else {
                          _expandedParts.add(idx);
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.teal50,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _partOfSpeechAbbr(meaning.partOfSpeech),
                              style: GoogleFonts.lexend(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _toTitleCase(meaning.partOfSpeech),
                              style: GoogleFonts.lexend(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSlate600,
                              ),
                            ),
                          ),
                          Icon(
                            isOpen
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textSlate400,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      children: List.generate(previewCount, (i) {
                        final text = defs[i];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: i == previewCount - 1 ? 0 : 8,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 3),
                                width: 18,
                                height: 18,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Text(
                                  '${i + 1}',
                                  style: GoogleFonts.lexend(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  text,
                                  style: GoogleFonts.lexend(
                                    fontSize: 13,
                                    color: AppColors.textSlate600,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                  if (!isOpen && defs.length > previewCount)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        '+${defs.length - previewCount} nghĩa khác',
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'Nguồn: DictionaryAPI.dev',
            style: GoogleFonts.lexend(
              fontSize: 11,
              color: AppColors.textSlate400,
            ),
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  String _toTitleCase(String value) {
    final text = value.trim();
    if (text.isEmpty) return 'Unknown';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  String _partOfSpeechAbbr(String value) {
    switch (value.toLowerCase()) {
      case 'noun':
        return 'n.';
      case 'verb':
        return 'v.';
      case 'adjective':
        return 'adj.';
      case 'adverb':
        return 'adv.';
      case 'pronoun':
        return 'pron.';
      case 'preposition':
        return 'prep.';
      case 'conjunction':
        return 'conj.';
      case 'interjection':
        return 'interj.';
      case 'determiner':
        return 'det.';
      default:
        return value.toLowerCase();
    }
  }
}

class _GrammarExpandableCard extends StatelessWidget {
  final GrammarModel item;
  final bool isOpen;
  final bool isSaved;
  final VoidCallback onToggle;
  final VoidCallback onToggleSaved;

  const _GrammarExpandableCard({
    required this.item,
    required this.isOpen,
    required this.isSaved,
    required this.onToggle,
    required this.onToggleSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSlate100),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'B${item.lesson}',
                        style: GoogleFonts.lexend(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: GoogleFonts.lexend(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSlate800,
                            ),
                          ),
                          if ((item.formula ?? '').isNotEmpty)
                            Text(
                              item.formula!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.lexend(
                                fontSize: 11,
                                color: AppColors.textSlate400,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onToggleSaved,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                      splashRadius: 18,
                      icon: Icon(
                        isSaved
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 20,
                        color: isSaved
                            ? const Color(0xFFF59E0B)
                            : AppColors.textSlate400,
                      ),
                    ),
                    Icon(
                      isOpen ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textSlate400,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: AppColors.borderSlate100),
                  const SizedBox(height: 10),
                  Text(
                    item.content,
                    style: GoogleFonts.lexend(
                      fontSize: 12,
                      height: 1.5,
                      color: AppColors.slate700,
                    ),
                  ),
                  if ((item.formula ?? '').isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.slate900,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.formula!,
                        style: GoogleFonts.robotoMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                  if (item.examples.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ...item.examples.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${entry.key + 1}',
                                style: GoogleFonts.lexend(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: GoogleFonts.lexend(
                                  fontSize: 12,
                                  color: AppColors.slate700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int page;
  final int totalPages;
  final ValueChanged<int> onChange;

  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: page == 0 ? null : () => onChange(page - 1),
              icon: const Icon(Icons.chevron_left, size: 18),
              label: const Text('Trước'),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSlate200),
            ),
            child: Text(
              '${page + 1}/$totalPages',
              style: GoogleFonts.lexend(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.slate700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: page >= totalPages - 1
                  ? null
                  : () => onChange(page + 1),
              icon: const Icon(Icons.chevron_right, size: 18),
              label: const Text('Sau'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListLoading extends StatelessWidget {
  final int count;

  const _ListLoading({required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (index) => Container(
          width: double.infinity,
          height: 86,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSlate100),
          ),
        ),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyBox({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSlate100),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSlate400, size: 36),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.lexend(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textSlate800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.lexend(
              fontSize: 12,
              color: AppColors.textSlate500,
            ),
          ),
        ],
      ),
    );
  }
}
