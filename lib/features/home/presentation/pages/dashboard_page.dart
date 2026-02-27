import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
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
        onTap: (index) {
          setState(() => _currentNavIndex = index);
        },
      ),
    );
  }
}
