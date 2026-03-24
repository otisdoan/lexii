import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lexii/core/subscription/subscription_providers.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/home/presentation/widgets/bottom_nav_bar.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPadding = MediaQuery.of(context).padding.top;
    final user = Supabase.instance.client.auth.currentUser;
    final subscriptionInfo = ref.watch(subscriptionInfoProvider).valueOrNull;
    final role = ref.watch(userRoleProvider).valueOrNull;
    final metadataRole = (user?.userMetadata?['role'] as String?)
        ?.toLowerCase()
        .trim();
    final isPremium =
        (subscriptionInfo?.isPremium ?? false) ||
        role == 'premium' ||
        metadataRole == 'premium';
    final premiumLabel = subscriptionInfo?.statusLabel ?? 'Premium';
    final displayName =
        user?.userMetadata?['full_name'] as String? ??
        user?.userMetadata?['name'] as String? ??
        user?.email?.split('@').first ??
        'Người dùng';
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;
    final isLoggedIn = user != null;

    return Scaffold(
      backgroundColor: AppColors.slate100,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Column(
          children: [
            // Header
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
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                          return;
                        }
                        context.go('/home');
                      },
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Cài đặt',
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
            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile section
                    _ProfileSection(
                      key: ValueKey(user?.id ?? 'guest'),
                      displayName: displayName,
                      avatarUrl: avatarUrl,
                      email: user?.email,
                      isPremium: isPremium,
                      premiumLabel: premiumLabel,
                      isLoggedIn: isLoggedIn,
                      onActionTap: () {
                        if (isLoggedIn) {
                          _handleLogout(context);
                          return;
                        }
                        context.go('/auth/signup');
                      },
                    ),
                    const SizedBox(height: 24),
                    // Group 1: Account & Usage
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _SettingsGroup(
                        items: [
                          _SettingsItem(
                            icon: Icons.edit_outlined,
                            label: 'Chỉnh sửa hồ sơ',
                            onTap: () => _showComingSoon(context),
                          ),
                          _SettingsItem(
                            icon: Icons.menu_book_outlined,
                            label: 'Hướng dẫn sử dụng hiệu quả',
                            onTap: () => _showComingSoon(context),
                          ),
                          _SettingsItem(
                            icon: Icons.history_edu_outlined,
                            label: 'Lịch sử bài làm đề thi',
                            onTap: () => context.push('/settings/test-history'),
                          ),
                          _SettingsItem(
                            icon: Icons.receipt_long_outlined,
                            label: 'Lịch sử giao dịch',
                            onTap: () => context.push('/settings/transactions'),
                          ),
                          _SettingsItem(
                            icon: Icons.language_outlined,
                            label: 'Ngôn ngữ ứng dụng',
                            trailing: Text(
                              'Tiếng Việt',
                              style: GoogleFonts.lexend(
                                fontSize: 13,
                                color: AppColors.textSlate500,
                              ),
                            ),
                            onTap: () => _showComingSoon(context),
                          ),
                          _SettingsItem(
                            icon: Icons.dark_mode_outlined,
                            label: 'Giao diện tối',
                            trailing: _ToggleSwitch(
                              value: false,
                              onChanged: (_) {},
                            ),
                            showChevron: false,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Group 2: App Customization
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _SettingsGroup(
                        items: [
                          _SettingsItem(
                            icon: Icons.touch_app_outlined,
                            label: 'Giao diện đáp án',
                            onTap: () => _showComingSoon(context),
                          ),
                          _SettingsItem(
                            icon: Icons.monitor_outlined,
                            label: 'Hiển thị',
                            onTap: () => _showComingSoon(context),
                          ),
                          _SettingsItem(
                            icon: Icons.download_outlined,
                            label: 'Quản lý tải xuống',
                            onTap: () => _showComingSoon(context),
                          ),
                          _SettingsItem(
                            icon: Icons.refresh_outlined,
                            label: 'Làm mới trạng thái Premium',
                            onTap: () => _refreshSubscriptionStatus(ref, context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Group 3: Community & Feedback
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _SettingsGroup(
                        items: [
                          _SettingsItem(
                            icon: Icons.group_outlined,
                            label: 'Tham gia cộng đồng Lexii TOEIC',
                            onTap: () => _showComingSoon(context),
                          ),
                          _SettingsItem(
                            icon: Icons.share_outlined,
                            label: 'Chia sẻ ứng dụng',
                            onTap: () => _showComingSoon(context),
                          ),
                          _SettingsItem(
                            icon: Icons.feedback_outlined,
                            label: 'Phản hồi & hỗ trợ',
                            onTap: () => context.push('/settings/support'),
                          ),
                          _SettingsItem(
                            icon: Icons.star_border_outlined,
                            label: 'Đánh giá 5 sao',
                            onTap: () => context.push('/settings/reviews'),
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Version
                    Center(
                      child: Text(
                        'Phiên bản 1.0.0',
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          color: AppColors.textSlate400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 4,
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
        context.go('/exam/mock-test');
        return;
      case 3:
        context.go('/upgrade');
        return;
      case 4:
        return;
    }
  }

  void _showComingSoon(BuildContext context) {
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

  void _refreshSubscriptionStatus(WidgetRef ref, BuildContext context) {
    ref.invalidate(isPremiumProvider);
    ref.invalidate(userRoleProvider);
    ref.invalidate(subscriptionInfoProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã làm mới trạng thái Premium',
          style: GoogleFonts.lexend(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: AppColors.green600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Đăng xuất',
          style: GoogleFonts.lexend(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất không?',
          style: GoogleFonts.lexend(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Huỷ',
              style: GoogleFonts.lexend(color: AppColors.textSlate500),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Đăng xuất',
              style: GoogleFonts.lexend(
                color: AppColors.orange500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        context.go('/auth/signup');
      }
    }
  }
}

// ─── Profile Section ──────────────────────────────────────────────────────────

class _ProfileSection extends StatelessWidget {
  final String displayName;
  final String? avatarUrl;
  final String? email;
  final bool isPremium;
  final String? premiumLabel;
  final bool isLoggedIn;
  final VoidCallback onActionTap;

  const _ProfileSection({
    super.key,
    required this.displayName,
    required this.avatarUrl,
    required this.email,
    required this.isPremium,
    required this.premiumLabel,
    required this.isLoggedIn,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final premiumGradient = const LinearGradient(
      colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A), Color(0xFFF59E0B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: isPremium ? null : Colors.white,
        gradient: isPremium ? premiumGradient : null,
        borderRadius: BorderRadius.circular(16),
        border: isPremium
            ? Border.all(color: const Color(0xFFFFFBEB), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: isPremium
                ? const Color(0xFFF59E0B).withValues(alpha: 0.28)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: isPremium ? 18 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isPremium ? 0.9 : 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _ProfileAvatar(
              displayName: displayName,
              avatarUrl: avatarUrl,
              isPremium: isPremium,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isPremium)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB45309),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Premium',
                        style: GoogleFonts.lexend(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  Text(
                    displayName,
                    style: GoogleFonts.lexend(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSlate800,
                    ),
                  ),
                  if (email != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      email!,
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: AppColors.textSlate500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onActionTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: isLoggedIn
                    ? AppColors.orange500
                    : AppColors.primary,
                side: BorderSide(
                  color: (isLoggedIn ? AppColors.orange500 : AppColors.primary)
                      .withValues(alpha: 0.4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                textStyle: GoogleFonts.lexend(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(isLoggedIn ? 'Đăng xuất' : 'Đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatefulWidget {
  final String displayName;
  final String? avatarUrl;
  final bool isPremium;

  const _ProfileAvatar({
    required this.displayName,
    required this.avatarUrl,
    required this.isPremium,
  });

  @override
  State<_ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<_ProfileAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ringController;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: 34,
      backgroundColor: widget.isPremium
          ? const Color(0xFFFFF7D6)
          : AppColors.teal100,
      backgroundImage: widget.avatarUrl != null
          ? NetworkImage(widget.avatarUrl!)
          : null,
      child: widget.avatarUrl == null
          ? Text(
              widget.displayName.isNotEmpty
                  ? widget.displayName[0].toUpperCase()
                  : 'U',
              style: GoogleFonts.lexend(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: widget.isPremium
                    ? const Color(0xFFB45309)
                    : AppColors.primary,
              ),
            )
          : null,
    );

    if (!widget.isPremium) {
      return avatar;
    }

    return AnimatedBuilder(
      animation: _ringController,
      builder: (context, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: const [
                    Color(0xFFFF3B30),
                    Color(0xFFFF9500),
                    Color(0xFFFFCC00),
                    Color(0xFF34C759),
                    Color(0xFF007AFF),
                    Color(0xFF5856D6),
                    Color(0xFFAF52DE),
                    Color(0xFFFF3B30),
                  ],
                  transform: GradientRotation(
                    _ringController.value * 6.283185307,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFAF52DE).withValues(alpha: 0.32),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: child,
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFFB45309),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  size: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
      child: avatar,
    );
  }
}

// ─── Settings Group ───────────────────────────────────────────────────────────

class _SettingsGroup extends StatelessWidget {
  final List<_SettingsItem> items;

  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: items),
      ),
    );
  }
}

// ─── Settings Item ────────────────────────────────────────────────────────────

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final bool showChevron;
  final bool isLast;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    this.trailing,
    this.showChevron = true,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 22, color: AppColors.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSlate600,
                    ),
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
                if (showChevron && trailing == null)
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.textSlate400,
                  ),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Divider(height: 1, indent: 54, color: AppColors.borderSlate100),
      ],
    );
  }
}

// ─── Toggle Switch ────────────────────────────────────────────────────────────

class _ToggleSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleSwitch({required this.value, required this.onChanged});

  @override
  State<_ToggleSwitch> createState() => _ToggleSwitchState();
}

class _ToggleSwitchState extends State<_ToggleSwitch> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: _value,
      activeThumbColor: AppColors.primary,
      activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
      onChanged: (v) {
        setState(() => _value = v);
        widget.onChanged(v);
      },
    );
  }
}
