import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/exam/data/models/question_model.dart';
import 'package:lexii/features/exam/presentation/providers/test_providers.dart';

class AnswerDetailPage extends ConsumerStatefulWidget {
  final String testId;
  final String testTitle;
  final int questionIndex;
  final Map<int, int> userAnswers;
  /// When set, loads only this part's questions (practice mode).
  final String? partId;

  const AnswerDetailPage({
    super.key,
    required this.testId,
    required this.testTitle,
    required this.questionIndex,
    this.userAnswers = const {},
    this.partId,
  });

  @override
  ConsumerState<AnswerDetailPage> createState() => _AnswerDetailPageState();
}

class _AnswerDetailPageState extends ConsumerState<AnswerDetailPage> {
  late int _currentIndex;
  late final AudioPlayer _audioPlayer;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _showSubtitle = true;
  int _subtitleTab = 0; // 0=subtitle, 1=translation, 2=keywords

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.questionIndex;
    _audioPlayer = AudioPlayer();
    _audioPlayer.durationStream.listen((d) {
      if (d != null && mounted) setState(() => _duration = d);
    });
    _audioPlayer.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _loadAudio(String url) async {
    try {
      await _audioPlayer.setUrl(url);
    } catch (_) {}
  }

  String _fmt(Duration d) {
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = widget.partId != null
        ? ref.watch(questionsByPartIdProvider(widget.partId!))
        : ref.watch(questionsByTestIdProvider(widget.testId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: questionsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (questions) {
          if (questions.isEmpty || _currentIndex >= questions.length) {
            return const Center(child: Text('Không có dữ liệu'));
          }

          final q = questions[_currentIndex];
          final selectedIdx = widget.userAnswers[_currentIndex];
          final totalQ = questions.length;

          // Auto-load audio
          if (q.audioUrl != null && _duration == Duration.zero) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadAudio(q.audioUrl!);
            });
          }

          return Column(
            children: [
              _buildHeader(context, q.orderIndex, totalQ),
              _buildAudioBar(q),
              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                          16, 16, 16, _showSubtitle ? 260 : 16),
                      child: Column(
                        children: [
                          _buildQuestionCard(q),
                          const SizedBox(height: 16),
                          ...q.options.asMap().entries.map((entry) {
                            final i = entry.key;
                            final opt = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildOption(
                                  i, opt, selectedIdx, q.options),
                            );
                          }),
                        ],
                      ),
                    ),
                    // Subtitle sheet
                    if (_showSubtitle)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _buildSubtitleSheet(q),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int orderIndex, int totalQ) {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.pop(),
                  borderRadius: BorderRadius.circular(9999),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Câu $orderIndex/$totalQ',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lexend(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() => _showSubtitle = !_showSubtitle);
                  },
                  borderRadius: BorderRadius.circular(9999),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Giải thích',
                      style: GoogleFonts.lexend(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
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

  Widget _buildAudioBar(QuestionModel q) {
    final hasAudio = q.audioUrl != null;
    final isPlaying = _audioPlayer.playing;
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Container(
      color: const Color(0xFF0F172A).withValues(alpha: 0.95),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: hasAudio
                ? () {
                    final newPos =
                        _position - const Duration(seconds: 10);
                    _audioPlayer.seek(Duration(
                      milliseconds:
                          newPos.inMilliseconds.clamp(0, _duration.inMilliseconds),
                    ));
                  }
                : null,
            child: Icon(Icons.replay_10,
                color: Colors.white.withValues(alpha: 0.7), size: 24),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: hasAudio
                ? () {
                    if (isPlaying) {
                      _audioPlayer.pause();
                    } else {
                      _audioPlayer.play();
                    }
                  }
                : null,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _fmt(_position),
            style: GoogleFonts.lexend(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: const Color(0xFFF59E0B),
                  inactiveTrackColor:
                      Colors.white.withValues(alpha: 0.15),
                  thumbColor: Colors.white,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 5),
                  trackHeight: 3,
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 12),
                ),
                child: Slider(
                  value: progress.clamp(0.0, 1.0),
                  onChanged: hasAudio
                      ? (v) {
                          _audioPlayer.seek(Duration(
                            milliseconds:
                                (v * _duration.inMilliseconds).round(),
                          ));
                        }
                      : null,
                ),
              ),
            ),
          ),
          Text(
            _fmt(_duration),
            style: GoogleFonts.lexend(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuestionModel q) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Text(
              'SELECT THE ANSWER',
              style: GoogleFonts.lexend(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFCA8A04),
                letterSpacing: 0.5,
              ),
            ),
          ),
          // Image
          if (q.imageUrl != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: q.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      color: AppColors.slate100,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (_, _, _) => Container(
                      color: AppColors.slate100,
                      child: const Icon(Icons.broken_image,
                          size: 40, color: AppColors.textSlate300),
                    ),
                  ),
                ),
              ),
            ),
          if (q.questionText != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                q.questionText!,
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  color: AppColors.textSlate500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOption(int index, OptionModel opt, int? selectedIdx,
      List<OptionModel> allOptions) {
    final letter = String.fromCharCode(65 + index);
    final isSelected = selectedIdx == index;
    final isCorrect = opt.isCorrect;

    Color borderColor;
    Color bgColor;
    Color letterBg;
    Color letterFg;
    Widget? trailing;

    if (isSelected && isCorrect) {
      // Correct selection
      borderColor = AppColors.primary;
      bgColor = AppColors.primary.withValues(alpha: 0.05);
      letterBg = AppColors.primary;
      letterFg = Colors.white;
      trailing = const Icon(Icons.check_circle, color: AppColors.primary);
    } else if (isSelected && !isCorrect) {
      // Wrong selection
      borderColor = AppColors.red500.withValues(alpha: 0.3);
      bgColor = AppColors.red100.withValues(alpha: 0.5);
      letterBg = AppColors.red100;
      letterFg = AppColors.red500;
      trailing = const Icon(Icons.cancel, color: AppColors.red500);
    } else if (isCorrect) {
      // The correct one (not selected)
      borderColor = AppColors.primary;
      bgColor = AppColors.primary.withValues(alpha: 0.05);
      letterBg = AppColors.primary;
      letterFg = Colors.white;
      trailing = const Icon(Icons.check_circle, color: AppColors.primary);
    } else {
      borderColor = AppColors.borderSlate200;
      bgColor = Colors.white;
      letterBg = AppColors.slate100;
      letterFg = AppColors.textSlate500;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: letterBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                letter,
                style: GoogleFonts.lexend(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: letterFg,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              opt.content,
              style: GoogleFonts.lexend(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSlate800,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildSubtitleSheet(QuestionModel q) {
    final tabLabels = ['Phụ đề', 'Lời dịch', 'Từ khóa'];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
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
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            // Tabs + close
            Row(
              children: [
                ...tabLabels.asMap().entries.map((entry) {
                  final i = entry.key;
                  final label = entry.value;
                  final isActive = _subtitleTab == i;
                  return GestureDetector(
                    onTap: () => setState(() => _subtitleTab = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isActive
                                ? const Color(0xFFF59E0B)
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        label,
                        style: GoogleFonts.lexend(
                          fontSize: 13,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  );
                }),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => _showSubtitle = false),
                  icon: Icon(
                    Icons.close,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 20,
                  ),
                ),
              ],
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: q.options.asMap().entries.map((entry) {
                  final i = entry.key;
                  final opt = entry.value;
                  final letter = String.fromCharCode(65 + i);
                  final isCorrect = opt.isCorrect;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '($letter)',
                            style: GoogleFonts.lexend(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              opt.content,
                              style: GoogleFonts.lexend(
                                fontSize: 14,
                                fontWeight: isCorrect
                                    ? FontWeight.w600
                                    : FontWeight.w300,
                                color: isCorrect
                                    ? Colors.white
                                    : Colors.white
                                        .withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
