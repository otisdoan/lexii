import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/home/presentation/widgets/bottom_nav_bar.dart';
import 'package:lexii/features/theory/data/models/theory_models.dart';
import 'package:lexii/features/theory/presentation/providers/theory_providers.dart';

class TheoryPage extends ConsumerStatefulWidget {
  const TheoryPage({super.key});

  @override
  ConsumerState<TheoryPage> createState() => _TheoryPageState();
}

class _TheoryPageState extends ConsumerState<TheoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _scoreLevels = ['Tất cả', '450+', '600+', '800+', '990+'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            _AppHeader(tabController: _tabController),
            // ── Body ─────────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _VocabularyTab(
                    scoreLevels: _scoreLevels,
                  ),
                  const _GrammarTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
        onTap: (index) => _onNavTap(context, index),
      ),
    );
  }

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        return;
      case 1:
        context.go('/exam/mock-test');
        return;
      case 2:
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

// ─── Header ───────────────────────────────────────────────────────────────────

class _AppHeader extends StatelessWidget {
  final TabController tabController;

  const _AppHeader({required this.tabController});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Column(
      children: [
        // Title row
        Container(
          color: AppColors.primary,
          padding: EdgeInsets.fromLTRB(4, topPadding + 4, 4, 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                    return;
                  }
                  context.go('/home');
                },
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Lý thuyết',
                    style: GoogleFonts.lexend(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        // Tabs
        Container(
          color: Colors.white,
          child: TabBar(
            controller: tabController,
            labelStyle: GoogleFonts.lexend(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: GoogleFonts.lexend(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSlate500,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(text: 'Từ vựng'),
              Tab(text: 'Ngữ pháp'),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Vocabulary Tab ───────────────────────────────────────────────────────────

class _VocabularyTab extends ConsumerStatefulWidget {
  final List<String> scoreLevels;

  const _VocabularyTab({
    required this.scoreLevels,
  });

  @override
  ConsumerState<_VocabularyTab> createState() => _VocabularyTabState();
}

class _VocabularyTabState extends ConsumerState<_VocabularyTab> {
  int _selectedLesson = 1;
  String _selectedScoreLevel = 'Tất cả';
  int _selectedMode = 0;

  static const _modes = [
    'Chọn',
    'Flashcards',
    'Định nghĩa',
    'Chọn từ',
    'Luyện nói',
  ];

  VocabFilter get _filter => VocabFilter(
        lesson: _selectedLesson,
        scoreLevel:
            _selectedScoreLevel == 'Tất cả' ? null : _selectedScoreLevel,
      );

  @override
  Widget build(BuildContext context) {
    final lessonsAsync = ref.watch(lessonNumbersProvider);
    final vocabAsync = ref.watch(vocabularyProvider(_filter));

    return Column(
      children: [
        // ── Controls ──────────────────────────────────────────────────
        Container(
          color: const Color(0xFFF5F5F5),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: lessonsAsync.when(
                      data: (lessons) => _FilterDropdown<int>(
                        value: _selectedLesson,
                        label: 'Bài $_selectedLesson',
                        items: lessons.isEmpty ? [1] : lessons,
                        itemLabel: (l) => 'Bài $l',
                        onChanged: (l) =>
                            setState(() => _selectedLesson = l),
                      ),
                      loading: () => _filterSkeleton('Bài...'),
                      error: (_, __) => _filterSkeleton('Bài 1'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FilterDropdown<String>(
                      value: _selectedScoreLevel,
                      label: _selectedScoreLevel,
                      items: widget.scoreLevels,
                      itemLabel: (s) => s,
                      onChanged: (s) =>
                          setState(() => _selectedScoreLevel = s),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Mode chips
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _modes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => _ActionChip(
                    label: _modes[i],
                    isActive: _selectedMode == i,
                    onTap: () => setState(() => _selectedMode = i),
                  ),
                ),
              ),
            ],
          ),
        ),
        // ── Content ───────────────────────────────────────────────────
        Expanded(
          child: vocabAsync.when(
            data: (words) {
              if (words.isEmpty) {
                return const _EmptyState(
                  message: 'Không có từ vựng cho bộ lọc này.',
                );
              }
              return _buildModeContent(context, words);
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  _VocabCardSkeleton(),
                  SizedBox(height: 12),
                  _VocabCardSkeleton(),
                  SizedBox(height: 12),
                  _VocabCardSkeleton(),
                ],
              ),
            ),
            error: (e, _) =>
                _EmptyState(message: 'Không tải được dữ liệu.\n$e'),
          ),
        ),
      ],
    );
  }

  Widget _buildModeContent(
      BuildContext context, List<VocabularyModel> words) {
    final key = '${_filter.lesson}_${_filter.scoreLevel}';
    switch (_selectedMode) {
      case 1:
        return _FlashcardMode(key: ValueKey('flash_$key'), words: words);
      case 2:
        return _DefinitionQuizMode(
            key: ValueKey('def_$key'), words: words);
      case 3:
        return _WordChoiceMode(
            key: ValueKey('word_$key'), words: words);
      case 4:
        return _SpeakingMode(
            key: ValueKey('speak_$key'), words: words);
      default: // 0 = Chọn
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: words.length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _VocabCard(
              vocab: words[i],
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _VocabDetailPage(vocab: words[i]),
                ),
              ),
            ),
          ),
        );
    }
  }

  Widget _filterSkeleton(String text) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.borderSlate200),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(text,
          style: GoogleFonts.lexend(
              fontSize: 13, color: AppColors.textSlate500)),
    );
  }
}

// ─── Grammar Tab ──────────────────────────────────────────────────────────────

class _GrammarTab extends ConsumerStatefulWidget {
  const _GrammarTab();

  @override
  ConsumerState<_GrammarTab> createState() => _GrammarTabState();
}

class _GrammarTabState extends ConsumerState<_GrammarTab> {
  int _selectedLesson = 1;

  @override
  Widget build(BuildContext context) {
    final lessonsAsync = ref.watch(lessonNumbersProvider);
    final grammarAsync = ref.watch(grammarProvider(_selectedLesson));

    return ListView(
      padding: const EdgeInsets.only(top: 16, bottom: 100),
      children: [
        // Lesson filter
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: lessonsAsync.when(
            data: (lessons) => _FilterDropdown<int>(
              value: _selectedLesson,
              label: 'Bài $_selectedLesson',
              items: lessons.isEmpty ? [1] : lessons,
              itemLabel: (l) => 'Bài $l',
              onChanged: (l) => setState(() => _selectedLesson = l),
            ),
            loading: () => const SizedBox(height: 40),
            error: (_, __) => const SizedBox(height: 40),
          ),
        ),

        grammarAsync.when(
          data: (grammars) {
            if (grammars.isEmpty) {
              return _EmptyState(
                  message: 'Chưa có nội dung ngữ pháp cho bài này.');
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: grammars
                    .asMap()
                    .entries
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _GrammarListItem(
                            grammar: e.value,
                            index: e.key,
                            onTap: () =>
                                _showGrammarDetail(context, e.value),
                          ),
                        ))
                    .toList(),
              ),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _VocabCardSkeleton(),
                SizedBox(height: 12),
                _VocabCardSkeleton(),
              ],
            ),
          ),
          error: (e, _) => _EmptyState(message: 'Không tải được dữ liệu.'),
        ),
      ],
    );
  }

  void _showGrammarDetail(BuildContext context, GrammarModel grammar) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GrammarDetailSheet(grammar: grammar),
    );
  }
}

// ─── Filter Dropdown ──────────────────────────────────────────────────────────

class _FilterDropdown<T> extends StatelessWidget {
  final T value;
  final String label;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;

  const _FilterDropdown({
    required this.value,
    required this.label,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet<T>(
          context: context,
          builder: (ctx) => _PickerSheet<T>(
            items: items,
            selected: value,
            itemLabel: itemLabel,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
        );
        if (result != null) onChanged(result);
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.borderSlate200),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.lexend(
                fontSize: 13,
                color: AppColors.textSlate600,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down,
                size: 18, color: AppColors.textSlate400),
          ],
        ),
      ),
    );
  }
}

class _PickerSheet<T> extends StatelessWidget {
  final List<T> items;
  final T selected;
  final String Function(T) itemLabel;

  const _PickerSheet({
    required this.items,
    required this.selected,
    required this.itemLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderSlate200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => ListTile(
              title: Text(
                itemLabel(item),
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  fontWeight: item == selected
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: item == selected
                      ? AppColors.primary
                      : AppColors.textSlate600,
                ),
              ),
              trailing: item == selected
                  ? const Icon(Icons.check, color: AppColors.primary, size: 20)
                  : null,
              onTap: () => Navigator.pop(context, item),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Action Chip ──────────────────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.borderSlate200,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.lexend(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.textSlate600,
          ),
        ),
      ),
    );
  }
}

// ─── Vocab Card ───────────────────────────────────────────────────────────────

class _VocabCard extends StatefulWidget {
  final VocabularyModel vocab;
  final VoidCallback? onTap;

  const _VocabCard({required this.vocab, this.onTap});

  @override
  State<_VocabCard> createState() => _VocabCardState();
}

class _VocabCardState extends State<_VocabCard> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final v = widget.vocab;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Play button
            GestureDetector(
              onTap: () => _onPlay(context),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Word content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        v.word,
                        style: GoogleFonts.lexend(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSlate800,
                        ),
                      ),
                      if (v.wordClass != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.teal100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            v.wordClass!,
                            style: GoogleFonts.lexend(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (v.phonetic != null && v.phonetic!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      v.phonetic!,
                      style: GoogleFonts.lexend(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSlate400,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    v.definition,
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      color: AppColors.textSlate600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _onAddNote(context),
                    child: Text(
                      'Thêm ghi chú',
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Favorite
            GestureDetector(
              onTap: () => setState(() => _isFavorite = !_isFavorite),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                  key: ValueKey(_isFavorite),
                  size: 26,
                  color: _isFavorite
                      ? AppColors.yellow500
                      : AppColors.textSlate300,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPlay(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Phát âm: ${widget.vocab.word}',
          style: GoogleFonts.lexend(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _onAddNote(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Tính năng đang phát triển',
          style: GoogleFonts.lexend(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ─── Grammar List Item ────────────────────────────────────────────────────────

class _GrammarListItem extends StatelessWidget {
  final GrammarModel grammar;
  final int index;
  final VoidCallback onTap;

  const _GrammarListItem({
    required this.grammar,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderSlate100),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  grammar.title,
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSlate800,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSlate300,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Grammar Detail Sheet ─────────────────────────────────────────────────────

class _GrammarDetailSheet extends StatelessWidget {
  final GrammarModel grammar;

  const _GrammarDetailSheet({required this.grammar});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Teal header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    grammar.title,
                    style: GoogleFonts.lexend(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grammar.title,
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3D6B64),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Formula box
                  if (grammar.formula != null &&
                      grammar.formula!.isNotEmpty) ...[  
                    Text(
                      'Công thức:',
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSlate500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7F7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        grammar.formula!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lexend(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Plain content (when no formula)
                  if ((grammar.formula == null || grammar.formula!.isEmpty) &&
                      grammar.content.isNotEmpty) ...[  
                    Text(
                      grammar.content,
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        color: AppColors.textSlate600,
                        height: 1.65,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Examples
                  if (grammar.examples.isNotEmpty) ...[  
                    Text(
                      'Ví dụ:',
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSlate800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...grammar.examples.map(
                      (ex) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 7),
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                ex,
                                style: GoogleFonts.lexend(
                                  fontSize: 14,
                                  color: AppColors.textSlate600,
                                  fontStyle: FontStyle.italic,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  // Related topics
                  if (grammar.relatedTopics.isNotEmpty) ...[  
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.borderSlate100),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ngữ pháp liên quan',
                            style: GoogleFonts.lexend(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSlate800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...grammar.relatedTopics.map(
                            (topic) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Row(
                                children: [
                                  const Text('👉 ',
                                      style: TextStyle(fontSize: 15)),
                                  Expanded(
                                    child: Text(
                                      topic,
                                      style: GoogleFonts.lexend(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared empty state ───────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded,
              size: 56, color: AppColors.textSlate300),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.lexend(
              fontSize: 13,
              color: AppColors.textSlate500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class _VocabCardSkeleton extends StatelessWidget {
  const _VocabCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.slate100,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 14,
                  width: 100,
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 11,
                  width: 160,
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Vocab Detail Page ────────────────────────────────────────────────────────

class _VocabDetailPage extends StatefulWidget {
  final VocabularyModel vocab;

  const _VocabDetailPage({required this.vocab});

  @override
  State<_VocabDetailPage> createState() => _VocabDetailPageState();
}

class _VocabDetailPageState extends State<_VocabDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _bookmarked = false;

  static const _wordClassMap = {
    'n': 'Danh từ',
    'v': 'Động từ',
    'adj': 'Tính từ',
    'adv': 'Trạng từ',
    'prep': 'Giới từ',
    'conj': 'Liên từ',
    'n/v': 'Danh từ / Động từ',
    'phr': 'Cụm từ',
  };

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  String get _wordClassName {
    final wc = widget.vocab.wordClass?.toLowerCase();
    if (wc == null) return 'Từ vựng';
    return _wordClassMap[wc] ?? widget.vocab.wordClass!;
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vocab;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // ── Teal Header ──────────────────────────────────────────────
          Container(
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 22),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              v.word,
                              style: GoogleFonts.lexend(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  TabBar(
                    controller: _tabCtrl,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelStyle: GoogleFonts.lexend(
                        fontSize: 13, fontWeight: FontWeight.w700),
                    unselectedLabelStyle: GoogleFonts.lexend(
                        fontSize: 13, fontWeight: FontWeight.w500),
                    tabs: const [
                      Tab(text: 'Từ vựng'),
                      Tab(text: 'Mẫu câu'),
                      Tab(text: 'Đồng nghĩa'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // ── Content ──────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // Từ vựng tab
                ListView(
                  padding: const EdgeInsets.only(bottom: 40),
                  children: [
                    // Word header
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  v.word,
                                  style: GoogleFonts.lexend(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (v.phonetic != null &&
                                    v.phonetic!.isNotEmpty)
                                  Row(
                                    children: [
                                      const Text('🇺🇸',
                                          style: TextStyle(fontSize: 18)),
                                      const SizedBox(width: 6),
                                      Text(
                                        v.phonetic!,
                                        style: GoogleFonts.lexend(
                                          fontSize: 14,
                                          color: AppColors.textSlate600,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () {},
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: AppColors.teal100,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.volume_up_rounded,
                                            size: 16,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              _iconBtn(Icons.mic_none_rounded, () {}),
                              const SizedBox(height: 10),
                              _iconBtn(
                                _bookmarked
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                () => setState(() => _bookmarked = !_bookmarked),
                                active: _bookmarked,
                              ),
                              const SizedBox(height: 10),
                              _iconBtn(Icons.image_outlined, () {}),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Meaning section
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF0FAFA),
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16)),
                            ),
                            child: Text(
                              _wordClassName,
                              style: GoogleFonts.lexend(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0D7A70),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 4,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        v.definition,
                                        style: GoogleFonts.lexend(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textSlate800,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.teal100,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          v.scoreLevel,
                                          style: GoogleFonts.lexend(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                _ComingSoonTab(label: 'Mẫu câu'),
                _ComingSoonTab(label: 'Đồng nghĩa'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, {bool active = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: active ? AppColors.teal100 : AppColors.slate100,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            size: 20,
            color: active ? AppColors.primary : AppColors.textSlate600),
      ),
    );
  }
}

// ─── Flashcard Mode ───────────────────────────────────────────────────────────

class _FlashcardMode extends StatefulWidget {
  final List<VocabularyModel> words;

  const _FlashcardMode({super.key, required this.words});

  @override
  State<_FlashcardMode> createState() => _FlashcardModeState();
}

class _FlashcardModeState extends State<_FlashcardMode> {
  int _index = 0;
  bool _flipped = false;

  @override
  Widget build(BuildContext context) {
    final word = widget.words[_index];
    final total = widget.words.length;

    return Column(
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_index + 1} / $total',
                      style: GoogleFonts.lexend(
                          fontSize: 13, color: AppColors.textSlate500)),
                  Text('Nhấn thẻ để lật',
                      style: GoogleFonts.lexend(
                          fontSize: 12, color: AppColors.textSlate400)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_index + 1) / total,
                  backgroundColor: AppColors.borderSlate100,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GestureDetector(
              onTap: () => setState(() => _flipped = !_flipped),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.93, end: 1.0).animate(
                        CurvedAnimation(
                            parent: anim, curve: Curves.easeOut)),
                    child: child,
                  ),
                ),
                child: _flipped
                    ? _buildCardBack(word,
                        key: ValueKey('back_$_index'))
                    : _buildCardFront(word,
                        key: ValueKey('front_$_index')),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _index > 0
                      ? () => setState(() {
                            _index--;
                            _flipped = false;
                          })
                      : null,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: Text('Trước',
                      style: GoogleFonts.lexend(
                          fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _index < total - 1
                      ? () => setState(() {
                            _index++;
                            _flipped = false;
                          })
                      : null,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text('Tiếp',
                      style: GoogleFonts.lexend(
                          fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardFront(VocabularyModel word, {Key? key}) {
    return Container(
      key: key,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (word.wordClass != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.teal100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                word.wordClass!,
                style: GoogleFonts.lexend(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary),
              ),
            ),
          const SizedBox(height: 20),
          Text(
            word.word,
            style: GoogleFonts.lexend(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: AppColors.textSlate800,
            ),
          ),
          if (word.phonetic != null && word.phonetic!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              word.phonetic!,
              style: GoogleFonts.lexend(
                fontSize: 16,
                color: AppColors.textSlate400,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app_rounded,
                  size: 16, color: AppColors.textSlate300),
              const SizedBox(width: 6),
              Text(
                'Nhấn để xem nghĩa',
                style: GoogleFonts.lexend(
                    fontSize: 12, color: AppColors.textSlate400),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(VocabularyModel word, {Key? key}) {
    return Container(
      key: key,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            word.word,
            style: GoogleFonts.lexend(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 24),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.25)),
          const SizedBox(height: 24),
          Text(
            word.definition,
            textAlign: TextAlign.center,
            style: GoogleFonts.lexend(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          if (word.wordClass != null) ...[
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                word.wordClass!,
                style: GoogleFonts.lexend(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Word Choice Mode (word → pick definition) ───────────────────────────────

class _WordChoiceMode extends StatefulWidget {
  final List<VocabularyModel> words;

  const _WordChoiceMode({super.key, required this.words});

  @override
  State<_WordChoiceMode> createState() => _WordChoiceModeState();
}

class _WordChoiceModeState extends State<_WordChoiceMode> {
  int _index = 0;
  int? _selected;
  int _correct = 0;
  late List<String> _options;

  bool get _answered => _selected != null;

  @override
  void initState() {
    super.initState();
    _generateOptions();
  }

  void _generateOptions() {
    final correct = widget.words[_index].definition;
    final others = widget.words
        .where((w) => w.definition != correct)
        .map((w) => w.definition)
        .toList()
      ..shuffle(math.Random());
    _options = [correct, ...others.take(3)]..shuffle(math.Random());
    _selected = null;
  }

  void _pick(int i) {
    if (_answered) return;
    setState(() {
      _selected = i;
      if (_options[i] == widget.words[_index].definition) _correct++;
    });
  }

  void _next() {
    if (_index < widget.words.length - 1) {
      setState(() {
        _index++;
        _generateOptions();
      });
    } else {
      _showResult();
    }
  }

  void _showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultDialog(
        correct: _correct,
        total: widget.words.length,
        onRetry: () {
          Navigator.of(context).pop();
          setState(() {
            _index = 0;
            _correct = 0;
            _generateOptions();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.words[_index];
    final total = widget.words.length;

    return Column(
      children: [
        const SizedBox(height: 16),
        _QuizProgress(index: _index, total: total, correct: _correct),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text('Nghĩa của từ này là?',
                    style: GoogleFonts.lexend(
                        fontSize: 12, color: AppColors.textSlate400)),
                const SizedBox(height: 12),
                Text(word.word,
                    style: GoogleFonts.lexend(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSlate800)),
                if (word.phonetic != null && word.phonetic!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(word.phonetic!,
                      style: GoogleFonts.lexend(
                          fontSize: 14,
                          color: AppColors.textSlate400,
                          fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: ListView.separated(
              itemCount: _options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _OptionTile(
                label: _options[i],
                isAnswered: _answered,
                isCorrect: _options[i] == word.definition,
                isSelected: _selected == i,
                onTap: () => _pick(i),
              ),
            ),
          ),
        ),
        if (_answered)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            child: ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _index < total - 1 ? 'Tiếp theo →' : 'Xem kết quả',
                style: GoogleFonts.lexend(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          )
        else
          const SizedBox(height: 28),
      ],
    );
  }
}

// ─── Definition Quiz Mode (definition → pick word) ───────────────────────────

class _DefinitionQuizMode extends StatefulWidget {
  final List<VocabularyModel> words;

  const _DefinitionQuizMode({super.key, required this.words});

  @override
  State<_DefinitionQuizMode> createState() => _DefinitionQuizModeState();
}

class _DefinitionQuizModeState extends State<_DefinitionQuizMode> {
  int _index = 0;
  int? _selected;
  int _correct = 0;
  late List<String> _options;

  bool get _answered => _selected != null;

  @override
  void initState() {
    super.initState();
    _generateOptions();
  }

  void _generateOptions() {
    final correct = widget.words[_index].word;
    final others = widget.words
        .where((w) => w.word != correct)
        .map((w) => w.word)
        .toList()
      ..shuffle(math.Random());
    _options = [correct, ...others.take(3)]..shuffle(math.Random());
    _selected = null;
  }

  void _pick(int i) {
    if (_answered) return;
    setState(() {
      _selected = i;
      if (_options[i] == widget.words[_index].word) _correct++;
    });
  }

  void _next() {
    if (_index < widget.words.length - 1) {
      setState(() {
        _index++;
        _generateOptions();
      });
    } else {
      _showResult();
    }
  }

  void _showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultDialog(
        correct: _correct,
        total: widget.words.length,
        onRetry: () {
          Navigator.of(context).pop();
          setState(() {
            _index = 0;
            _correct = 0;
            _generateOptions();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.words[_index];
    final total = widget.words.length;

    return Column(
      children: [
        const SizedBox(height: 16),
        _QuizProgress(index: _index, total: total, correct: _correct),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text('Từ nào có nghĩa là?',
                    style: GoogleFonts.lexend(
                        fontSize: 12, color: AppColors.textSlate400)),
                const SizedBox(height: 12),
                Text(
                  word.definition,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lexend(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSlate800,
                      height: 1.4),
                ),
                if (word.wordClass != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.teal100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(word.wordClass!,
                        style: GoogleFonts.lexend(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: ListView.separated(
              itemCount: _options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _OptionTile(
                label: _options[i],
                isAnswered: _answered,
                isCorrect: _options[i] == word.word,
                isSelected: _selected == i,
                onTap: () => _pick(i),
              ),
            ),
          ),
        ),
        if (_answered)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            child: ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _index < total - 1 ? 'Tiếp theo →' : 'Xem kết quả',
                style: GoogleFonts.lexend(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          )
        else
          const SizedBox(height: 28),
      ],
    );
  }
}

// ─── Speaking Mode ────────────────────────────────────────────────────────────

class _SpeakingMode extends StatefulWidget {
  final List<VocabularyModel> words;

  const _SpeakingMode({super.key, required this.words});

  @override
  State<_SpeakingMode> createState() => _SpeakingModeState();
}

class _SpeakingModeState extends State<_SpeakingMode> {
  int _index = 0;
  bool _isRecording = false;

  @override
  Widget build(BuildContext context) {
    final word = widget.words[_index];
    final total = widget.words.length;

    return Column(
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_index + 1} / $total',
                  style: GoogleFonts.lexend(
                      fontSize: 13, color: AppColors.textSlate500)),
              Text('Nghe và luyện phát âm',
                  style: GoogleFonts.lexend(
                      fontSize: 12, color: AppColors.textSlate400)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(word.word,
                    style: GoogleFonts.lexend(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSlate800)),
                if (word.phonetic != null && word.phonetic!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(word.phonetic!,
                      style: GoogleFonts.lexend(
                          fontSize: 16,
                          color: AppColors.textSlate400,
                          fontStyle: FontStyle.italic)),
                ],
                const SizedBox(height: 14),
                Text(word.definition,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lexend(
                        fontSize: 14, color: AppColors.textSlate600)),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.volume_up_rounded,
                        color: Colors.white, size: 26),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => setState(() => _isRecording = !_isRecording),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _isRecording
                  ? const Color(0xFFEF5350)
                  : AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_isRecording
                          ? const Color(0xFFEF5350)
                          : AppColors.primary)
                      .withValues(alpha: 0.35),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(
              _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isRecording ? 'Đang ghi âm...' : 'Nhấn để nói',
          style: GoogleFonts.lexend(
              fontSize: 13, color: AppColors.textSlate500),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _index > 0
                      ? () => setState(() {
                            _index--;
                            _isRecording = false;
                          })
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Trước',
                      style: GoogleFonts.lexend(
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _index < total - 1
                      ? () => setState(() {
                            _index++;
                            _isRecording = false;
                          })
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Tiếp',
                      style: GoogleFonts.lexend(
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Shared Quiz Widgets ──────────────────────────────────────────────────────

class _QuizProgress extends StatelessWidget {
  final int index;
  final int total;
  final int correct;

  const _QuizProgress(
      {required this.index, required this.total, required this.correct});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${index + 1} / $total',
                  style: GoogleFonts.lexend(
                      fontSize: 13, color: AppColors.textSlate500)),
              Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text('$correct đúng',
                      style: GoogleFonts.lexend(
                          fontSize: 12, color: AppColors.primary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (index + 1) / total,
              backgroundColor: AppColors.borderSlate100,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final bool isAnswered;
  final bool isCorrect;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.isAnswered,
    required this.isCorrect,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.white;
    Color borderColor = AppColors.borderSlate200;
    if (isAnswered && isCorrect) {
      bgColor = const Color(0xFFE8F5E9);
      borderColor = const Color(0xFF4CAF50);
    } else if (isAnswered && isSelected) {
      bgColor = const Color(0xFFFFEBEE);
      borderColor = const Color(0xFFEF5350);
    }
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: GoogleFonts.lexend(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSlate800)),
            ),
            if (isAnswered && isCorrect)
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF4CAF50), size: 20),
            if (isAnswered && isSelected && !isCorrect)
              const Icon(Icons.cancel_rounded,
                  color: Color(0xFFEF5350), size: 20),
          ],
        ),
      ),
    );
  }
}

class _ResultDialog extends StatelessWidget {
  final int correct;
  final int total;
  final VoidCallback onRetry;

  const _ResultDialog(
      {required this.correct,
      required this.total,
      required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (correct * 100 ~/ total) : 0;
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Kết quả',
          style: GoogleFonts.lexend(fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$pct%',
            style: GoogleFonts.lexend(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: pct >= 70
                    ? AppColors.primary
                    : const Color(0xFFEF5350)),
          ),
          Text('$correct / $total câu đúng',
              style: GoogleFonts.lexend(
                  fontSize: 14, color: AppColors.textSlate600)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onRetry,
          child: Text('Làm lại',
              style: GoogleFonts.lexend(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary)),
        ),
      ],
    );
  }
}

class _ComingSoonTab extends StatelessWidget {
  final String label;

  const _ComingSoonTab({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.construction_rounded,
              size: 48, color: AppColors.textSlate300),
          const SizedBox(height: 16),
          Text('$label đang được phát triển',
              style: GoogleFonts.lexend(
                  fontSize: 14, color: AppColors.textSlate500)),
        ],
      ),
    );
  }
}
