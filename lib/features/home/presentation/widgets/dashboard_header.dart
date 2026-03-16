import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/core/constants/app_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardHeader extends StatefulWidget {
  const DashboardHeader({super.key});

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader> {
  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        border: Border(
          bottom: BorderSide(color: AppColors.primaryDark.withValues(alpha: 0.35)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40),
          Text(
            AppConstants.appName,
            style: GoogleFonts.lexend(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          _currentUserId == null
              ? const SizedBox(width: 40, height: 40)
              : StreamBuilder<List<Map<String, dynamic>>>(
                  stream: Supabase.instance.client
                      .from('notifications')
                      .stream(primaryKey: ['id'])
                      .eq('recipient_user_id', _currentUserId!)
                      .order('created_at'),
                  builder: (context, snapshot) {
                    final rows = snapshot.data ?? const <Map<String, dynamic>>[];
                    final unreadCount = rows.where((row) => row['is_read'] != true).length;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.push('/home/notifications'),
                        borderRadius: BorderRadius.circular(9999),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Center(
                                child: Icon(
                                  Icons.notifications_none,
                                  size: 24,
                                  color: Colors.white,
                                ),
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  top: 6,
                                  right: 4,
                                  child: Container(
                                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.red600,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(color: Colors.white, width: 1.5),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      unreadCount > 99 ? '99+' : '$unreadCount',
                                      style: GoogleFonts.lexend(
                                        fontSize: unreadCount > 99 ? 8 : 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
