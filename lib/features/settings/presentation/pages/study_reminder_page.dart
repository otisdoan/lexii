import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/settings/data/services/study_reminder_service.dart';

class StudyReminderPage extends StatefulWidget {
  const StudyReminderPage({super.key});

  @override
  State<StudyReminderPage> createState() => _StudyReminderPageState();
}

class _StudyReminderPageState extends State<StudyReminderPage> {
  final StudyReminderService _service = StudyReminderService.instance;

  bool _loading = true;
  bool _enabled = false;
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0);
  DateTime? _nextReminderAt;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _service.loadSettings();
    if (!mounted) return;

    setState(() {
      _enabled = settings.enabled;
      _time = settings.time;
      _loading = false;
    });

    if (settings.enabled) {
      await _refreshNextReminder();
    }
  }

  Future<void> _refreshNextReminder() async {
    final next = await _service.getNextReminderTime(_time);
    if (!mounted) return;
    setState(() => _nextReminderAt = next);
  }

  Future<void> _toggleReminder(bool value) async {
    if (value) {
      final granted = await _service.requestPermission();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bạn cần cấp quyền thông báo để bật nhắc học. Nếu dùng MIUI, hãy bật cả Tự khởi chạy và cho phép chạy nền.',
              style: GoogleFonts.lexend(fontSize: 13, color: Colors.white),
            ),
            backgroundColor: AppColors.orange500,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      try {
        await _service.scheduleDailyReminder(_time);
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không thể bật nhắc tự động: $error',
              style: GoogleFonts.lexend(fontSize: 13, color: Colors.white),
            ),
            backgroundColor: AppColors.orange500,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      await _service.saveSettings(
        StudyReminderSettings(
          enabled: true,
          hour: _time.hour,
          minute: _time.minute,
        ),
      );
      await _refreshNextReminder();
    } else {
      await _service.disableReminder();
      await _service.saveSettings(
        StudyReminderSettings(
          enabled: false,
          hour: _time.hour,
          minute: _time.minute,
        ),
      );
      _nextReminderAt = null;
    }

    if (!mounted) return;
    setState(() => _enabled = value);
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(context: context, initialTime: _time);
    if (selected == null) return;

    setState(() => _time = selected);

    final settings = StudyReminderSettings(
      enabled: _enabled,
      hour: selected.hour,
      minute: selected.minute,
    );
    await _service.saveSettings(settings);

    if (_enabled) {
      try {
        await _service.scheduleDailyReminder(selected);
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không thể cập nhật lịch nhắc: $error',
              style: GoogleFonts.lexend(fontSize: 13, color: Colors.white),
            ),
            backgroundColor: AppColors.orange500,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
      await _refreshNextReminder();
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã cập nhật giờ nhắc học ${_formatTime(selected)}.',
          style: GoogleFonts.lexend(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    await _service.showTestNotification();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã gửi thông báo thử. Vui lòng kiểm tra thông báo trên máy.',
          style: GoogleFonts.lexend(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _sendScheduledAutoTest() async {
    try {
      final scheduled = await _service.scheduleOneMinuteTestReminder();
      if (!mounted) return;
      final hh = scheduled.hour.toString().padLeft(2, '0');
      final mm = scheduled.minute.toString().padLeft(2, '0');
      final ss = scheduled.second.toString().padLeft(2, '0');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã lên lịch test tự động lúc $hh:$mm:$ss. Hãy thoát app và chờ thông báo.',
            style: GoogleFonts.lexend(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không thể lên lịch test tự động: $error',
            style: GoogleFonts.lexend(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: AppColors.orange500,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.slate100,
      body: Column(
        children: [
          Container(
            color: AppColors.primary,
            padding: EdgeInsets.fromLTRB(16, topPadding + 16, 16, 16),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () => context.pop(),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Nhắc nhở học tập',
                      style: GoogleFonts.lexend(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.notifications_active_outlined,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bật nhắc nhở mỗi ngày',
                                    style: GoogleFonts.lexend(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSlate800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _enabled
                                        ? 'Đang nhắc học lúc ${_formatTime(_time)}'
                                        : 'Bạn sẽ nhận thông báo nhắc học hằng ngày',
                                    style: GoogleFonts.lexend(
                                      fontSize: 12,
                                      color: AppColors.textSlate500,
                                    ),
                                  ),
                                  if (_enabled && _nextReminderAt != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Lần nhắc kế tiếp: ${_nextReminderAt!.day.toString().padLeft(2, '0')}/${_nextReminderAt!.month.toString().padLeft(2, '0')} ${_nextReminderAt!.hour.toString().padLeft(2, '0')}:${_nextReminderAt!.minute.toString().padLeft(2, '0')}',
                                      style: GoogleFonts.lexend(
                                        fontSize: 11,
                                        color: AppColors.textSlate500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Switch(
                              value: _enabled,
                              activeThumbColor: AppColors.primary,
                              activeTrackColor: AppColors.primary.withValues(
                                alpha: 0.4,
                              ),
                              onChanged: _toggleReminder,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.schedule_outlined,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Giờ nhắc học',
                                  style: GoogleFonts.lexend(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSlate800,
                                  ),
                                ),
                              ),
                              Text(
                                _formatTime(_time),
                                style: GoogleFonts.lexend(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: _sendTestNotification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.slate200,
                          foregroundColor: AppColors.textSlate800,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Gửi thông báo thử',
                          style: GoogleFonts.lexend(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _sendScheduledAutoTest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                        child: Text(
                          'Test tự gửi sau 1 phút',
                          style: GoogleFonts.lexend(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Lưu ý: Android cần quyền thông báo + báo thức chính xác. Nếu thiếu, app sẽ báo lỗi khi bật nhắc học.',
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          color: AppColors.textSlate500,
                          height: 1.5,
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
