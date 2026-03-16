import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  @override
  Widget build(BuildContext context) {
    final userId = _currentUserId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Thông báo',
          style: GoogleFonts.lexend(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: userId == null
                ? null
                : () async {
                    await Supabase.instance.client
                        .from('notifications')
                        .update({'is_read': true})
                        .eq('recipient_user_id', userId)
                        .eq('is_read', false);
                  },
            child: Text(
              'Đọc hết',
              style: GoogleFonts.lexend(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: userId == null
          ? Center(
              child: Text(
                'Vui lòng đăng nhập để xem thông báo.',
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  color: AppColors.textSlate500,
                ),
              ),
            )
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('notifications')
                  .stream(primaryKey: ['id'])
                  .eq('recipient_user_id', userId)
                  .order('created_at'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rows = List<Map<String, dynamic>>.from(snapshot.data ?? const []);
                rows.sort((a, b) {
                  final aTime = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
                  final bTime = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
                  return bTime.compareTo(aTime);
                });

                if (rows.isEmpty) {
                  return Center(
                    child: Text(
                      'Chưa có thông báo nào.',
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        color: AppColors.textSlate500,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  itemCount: rows.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = rows[index];
                    final title = item['title']?.toString() ?? 'Thông báo';
                    final body = item['body']?.toString() ?? '';
                    final createdAt = item['created_at']?.toString();
                    final isRead = item['is_read'] == true;

                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        if (!isRead) {
                          await Supabase.instance.client
                              .from('notifications')
                              .update({'is_read': true})
                              .eq('id', item['id'])
                              .eq('recipient_user_id', userId);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isRead ? AppColors.slate50 : AppColors.teal50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isRead ? AppColors.borderSlate200 : AppColors.teal200,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 6, right: 10),
                              decoration: BoxDecoration(
                                color: isRead ? AppColors.textSlate300 : AppColors.red500,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: GoogleFonts.lexend(
                                      fontSize: 14,
                                      fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                                      color: AppColors.textSlate900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    body,
                                    style: GoogleFonts.lexend(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSlate600,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _formatTime(createdAt),
                                    style: GoogleFonts.lexend(
                                      fontSize: 11,
                                      color: AppColors.textSlate400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  String _formatTime(String? iso) {
    if (iso == null || iso.isEmpty) return 'Vừa xong';

    final dt = DateTime.tryParse(iso);
    if (dt == null) return 'Vừa xong';

    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';

    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
