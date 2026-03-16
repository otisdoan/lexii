import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lexii/features/home/presentation/widgets/dashboard_header.dart';
import 'package:lexii/features/home/presentation/widgets/promo_banner.dart';
import 'package:lexii/features/home/presentation/widgets/practice_grid.dart';
import 'package:lexii/features/home/presentation/widgets/exam_grid.dart';
import 'package:lexii/features/home/presentation/widgets/new_exam_banner.dart';
import 'package:lexii/features/home/presentation/widgets/history_section.dart';
import 'package:lexii/features/home/presentation/widgets/notebook_section.dart';
import 'package:lexii/features/home/presentation/widgets/bottom_nav_bar.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentNavIndex = 0;

  void _onNavTap(int index) {
    if (index == 1) {
      context.go('/exam/mock-test');
      return;
    }
    if (index == 2) {
      context.go('/theory');
      return;
    }
    if (index == 3) {
      context.go('/upgrade');
      return;
    }
    if (index == 4) {
      context.go('/settings');
      return;
    }
    setState(() => _currentNavIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Column(
          children: [
            const DashboardHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: const [
                    PromoBanner(),
                    SizedBox(height: 24),
                    PracticeGrid(),
                    SizedBox(height: 24),
                    ExamGrid(),
                    SizedBox(height: 24),
                    NewExamBanner(),
                    SizedBox(height: 24),
                    HistorySection(),
                    SizedBox(height: 24),
                    NotebookSection(),
                    SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

