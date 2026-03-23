import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/exam/data/models/test_model.dart';
import 'package:lexii/features/exam/presentation/providers/test_providers.dart';
import 'package:lexii/features/exam/presentation/widgets/fulltest_grid.dart';
import 'package:lexii/features/exam/presentation/widgets/minitest_grid.dart';
import 'package:lexii/features/exam/presentation/widgets/sw_section.dart';
import 'package:lexii/features/home/presentation/widgets/bottom_nav_bar.dart';

class MockTestPage extends ConsumerStatefulWidget {
  const MockTestPage({super.key});

  @override
  ConsumerState<MockTestPage> createState() => _MockTestPageState();
}

class _MockTestPageState extends ConsumerState<MockTestPage> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  String _typeFilter = 'all'; // all | full | mini
  String _yearFilter = 'all';

  static const List<(String value, String label)> _typeOptions = [
    ('all', 'Chọn tất cả'),
    ('full', 'Full Test'),
    ('mini', 'Mini Test'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fullTestsAsync = ref.watch(fullTestsProvider);
    final miniTestsAsync = ref.watch(miniTestsProvider);

    final isLoading = fullTestsAsync.isLoading || miniTestsAsync.isLoading;
    final fullTests = fullTestsAsync.valueOrNull ?? const <TestModel>[];
    final miniTests = miniTestsAsync.valueOrNull ?? const <TestModel>[];

    final normalized = _search.trim().toLowerCase();

    List<TestModel> filteredFull = fullTests.where((t) {
      if (normalized.isEmpty) return true;
      return t.title.toLowerCase().contains(normalized);
    }).toList();

    List<TestModel> filteredMini = miniTests.where((t) {
      if (normalized.isEmpty) return true;
      return t.title.toLowerCase().contains(normalized);
    }).toList();

    final availableYears = <String>{
      for (final t in fullTests)
        if (_extractYear(t) != null) _extractYear(t)!,
    }.toList()..sort((a, b) => b.compareTo(a));

    if (_yearFilter != 'all') {
      filteredFull = filteredFull
          .where((t) => _extractYear(t) == _yearFilter)
          .toList();
      filteredMini = filteredMini
          .where((t) => _extractYear(t) == _yearFilter)
          .toList();
    }

    final showFull = _typeFilter == 'all' || _typeFilter == 'full';
    final showMini = _typeFilter == 'all' || _typeFilter == 'mini';
    final hasAny =
        (showFull && filteredFull.isNotEmpty) ||
        (showMini && filteredMini.isNotEmpty);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          _buildAppBar(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.borderSlate200,
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (v) => setState(() => _search = v),
                              style: GoogleFonts.lexend(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Tìm kiếm đề thi...',
                                hintStyle: GoogleFonts.lexend(
                                  fontSize: 13,
                                  color: AppColors.textSlate400,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: AppColors.textSlate400,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => _openFilterModal(availableYears),
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
                  ),
                  const SizedBox(height: 10),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  else ...[
                    if (showFull) ...[
                      const SizedBox(height: 10),
                      FulltestGrid(testsOverride: filteredFull),
                    ],
                    if (showMini) ...[
                      const SizedBox(height: 12),
                      MinitestGrid(testsOverride: filteredMini),
                    ],
                    const SizedBox(height: 28),
                    const SpeakingWritingSection(),
                    const SizedBox(height: 24),
                    if (!hasAny)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 28,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderSlate100),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.search_off,
                                color: AppColors.textSlate400,
                                size: 40,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Không tìm thấy đề thi',
                                style: GoogleFonts.lexend(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.slate700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Thử thay đổi từ khóa hoặc bộ lọc năm',
                                style: GoogleFonts.lexend(
                                  fontSize: 12,
                                  color: AppColors.textSlate500,
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
          ),
        ],
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
        context.go('/theory');
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

  Widget _buildAppBar(BuildContext context) {
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
              // Title
              Text(
                'Đề thi TOEIC',
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

  String? _extractYear(TestModel test) {
    final match = RegExp(r'\b(20\d{2})\b').firstMatch(test.title);
    if (match != null) return match.group(1);
    final dt = test.createdAt;
    if (dt != null) return dt.year.toString();
    return null;
  }

  Future<void> _openFilterModal(List<String> availableYears) async {
    String selectedType = _typeFilter;
    String selectedYear = _yearFilter;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
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
                      'Bộ lọc đề thi',
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSlate900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Loại đề',
                      style: GoogleFonts.lexend(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._typeOptions.map(
                      (opt) => RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(
                          opt.$2,
                          style: GoogleFonts.lexend(
                            fontSize: 13,
                            color: AppColors.slate700,
                          ),
                        ),
                        value: opt.$1,
                        groupValue: selectedType,
                        activeColor: AppColors.primary,
                        onChanged: (value) {
                          if (value == null) return;
                          setModalState(() => selectedType = value);
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Năm',
                      style: GoogleFonts.lexend(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderSlate200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedYear,
                          isExpanded: true,
                          style: GoogleFonts.lexend(
                            fontSize: 13,
                            color: AppColors.slate700,
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: 'all',
                              child: Text('Tất cả năm'),
                            ),
                            ...availableYears.map(
                              (y) => DropdownMenuItem<String>(
                                value: y,
                                child: Text(y),
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setModalState(() => selectedYear = v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _typeFilter = selectedType;
                            _yearFilter = selectedYear;
                          });
                          Navigator.of(ctx).pop();
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
                          'Tìm kiếm',
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
