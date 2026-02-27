import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';

class ListeningQuestionPage extends StatefulWidget {
  final String testId;
  final String testTitle;

  const ListeningQuestionPage({
    super.key,
    required this.testId,
    required this.testTitle,
  });

  @override
  State<ListeningQuestionPage> createState() => _ListeningQuestionPageState();
}

class _ListeningQuestionPageState extends State<ListeningQuestionPage> {
  int _selectedAnswer = -1;
  final int _currentQuestion = 1;
  final int _totalQuestions = 200;

  // Timer
  int _hours = 1;
  int _minutes = 59;
  int _seconds = 57;
  Timer? _timer;

  // Audio
  double _audioProgress = 0.04;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_seconds > 0) {
          _seconds--;
        } else if (_minutes > 0) {
          _minutes--;
          _seconds = 59;
        } else if (_hours > 0) {
          _hours--;
          _minutes = 59;
          _seconds = 59;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // App bar
          _buildAppBar(),
          // Timer & tools
          _buildTimerSection(),
          // Content
          Expanded(
            child: Stack(
              children: [
                // Scrollable question area
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 180),
                    child: Column(
                      children: [
                        // Question card
                        _buildQuestionCard(),
                        const SizedBox(height: 20),
                        // Answer options
                        _buildAnswerOption(0, 'A', 'They are sitting in a circle.'),
                        const SizedBox(height: 12),
                        _buildAnswerOption(1, 'B', 'They are working on computers.'),
                        const SizedBox(height: 12),
                        _buildAnswerOption(2, 'C', 'One woman is standing up.'),
                        const SizedBox(height: 12),
                        _buildAnswerOption(3, 'D', 'The room is empty.'),
                      ],
                    ),
                  ),
                ),
                // Audio bar
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildAudioBar(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSlate100),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.pop(),
                  borderRadius: BorderRadius.circular(9999),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.arrow_back, color: AppColors.textSlate800),
                  ),
                ),
              ),
              Text(
                'Câu $_currentQuestion/$_totalQuestions',
                style: GoogleFonts.lexend(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSlate800,
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(9999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      'Nộp bài',
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        children: [
          // Timer display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimerBox(_hours.toString().padLeft(2, '0'), 'Hours', false),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  ':',
                  style: GoogleFonts.lexend(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSlate300,
                  ),
                ),
              ),
              _buildTimerBox(_minutes.toString().padLeft(2, '0'), 'Minutes', false),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  ':',
                  style: GoogleFonts.lexend(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSlate300,
                  ),
                ),
              ),
              _buildTimerBox(_seconds.toString().padLeft(2, '0'), 'Seconds', true),
            ],
          ),
          const SizedBox(height: 16),
          // Toolbar
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSlate100),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildToolButton(Icons.flag, 'Báo lỗi'),
                _buildToolButton(Icons.settings, 'Cài đặt'),
                _buildToolButton(Icons.favorite_border, 'Yêu thích'),
                _buildToolButton(Icons.visibility, 'Xem đáp án'),
                _buildToolButton(Icons.pause_circle_outline, 'Tạm dừng'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBox(String value, String label, bool isAccent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                value,
                style: GoogleFonts.lexend(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isAccent ? AppColors.primary : AppColors.textSlate800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSlate400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(IconData icon, String tooltip) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, size: 22, color: AppColors.textSlate500),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF9C3).withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFFEAB308).withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.image, color: Color(0xFFCA8A04), size: 18),
                const SizedBox(width: 8),
                Text(
                  'SELECT THE ANSWER',
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFCA8A04),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Image
          Padding(
            padding: const EdgeInsets.all(20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Container(
                  color: AppColors.slate100,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const Center(
                        child: Icon(
                          Icons.photo,
                          size: 64,
                          color: AppColors.textSlate300,
                        ),
                      ),
                      // Gradient overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0),
                                Colors.black.withValues(alpha: 0.1),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOption(int index, String letter, String text) {
    final isSelected = _selectedAnswer == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedAnswer = index),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.05)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Letter circle
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.slate100,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: GoogleFonts.lexend(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.textSlate600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Text
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.lexend(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.textSlate900
                        : AppColors.textSlate800,
                  ),
                ),
              ),
              // Radio indicator
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.borderSlate200,
                    width: isSelected ? 5 : 2,
                  ),
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question $_currentQuestion Audio',
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'TOEIC Listening Part 1',
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.more_vert,
                    color: Color(0xFF94A3B8),
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Slider row
            Row(
              children: [
                Text(
                  '00:01',
                  style: GoogleFonts.lexend(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: const Color(0xFFF97316),
                      inactiveTrackColor: const Color(0xFF374151),
                      thumbColor: const Color(0xFFF97316),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 7,
                      ),
                      trackHeight: 3,
                      overlayColor: const Color(0xFFF97316).withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: _audioProgress,
                      onChanged: (v) => setState(() => _audioProgress = v),
                    ),
                  ),
                ),
                Text(
                  '00:25',
                  style: GoogleFonts.lexend(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.replay_5, color: Color(0xFF94A3B8), size: 28),
                ),
                const SizedBox(width: 24),
                // Play button
                Material(
                  color: AppColors.primary,
                  shape: const CircleBorder(),
                  elevation: 4,
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                  child: InkWell(
                    onTap: () => setState(() => _isPlaying = !_isPlaying),
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.forward_5, color: Color(0xFF94A3B8), size: 28),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
