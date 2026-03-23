import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/subscription/subscription_providers.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/home/presentation/widgets/bottom_nav_bar.dart';
import 'package:lexii/features/settings/data/services/payos_checkout_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class UpgradePage extends ConsumerStatefulWidget {
  const UpgradePage({super.key});

  @override
  ConsumerState<UpgradePage> createState() => _UpgradePageState();
}

class _UpgradePageState extends ConsumerState<UpgradePage> {
  final PageController _pageController = PageController();
  final PayosCheckoutService _checkoutService = PayosCheckoutService();
  Timer? _autoSlideTimer;

  int _selectedPlan = 1;
  int _currentSlide = 0;
  bool _isCreatingCheckout = false;

  @override
  void initState() {
    super.initState();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_currentSlide + 1) % _slides.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPremiumUser = ref.watch(isPremiumProvider).valueOrNull ?? false;

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
            _UpgradeHeader(onBack: _handleBack),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FeatureCarousel(
                      pageController: _pageController,
                      currentSlide: _currentSlide,
                      onPageChanged: (index) {
                        setState(() => _currentSlide = index);
                      },
                      onDotTap: (index) {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOut,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const _SocialProofRow(),
                    const SizedBox(height: 24),
                    _PlanSelector(
                      selectedPlan: _selectedPlan,
                      onSelect: (value) =>
                          setState(() => _selectedPlan = value),
                    ),
                    const SizedBox(height: 20),
                    _UpgradeButton(
                      selectedPlan: _selectedPlan,
                      isLoading: _isCreatingCheckout,
                      onPressed: () => _handleUpgradePress(isPremiumUser),
                    ),
                    const SizedBox(height: 16),
                    const _AccountStatusSection(),
                    const SizedBox(height: 16),
                    const _FeatureComparisonTable(),
                    const SizedBox(height: 16),
                    const _UserReviewsSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 3, onTap: _onNavTap),
    );
  }

  void _onNavTap(int index) {
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
        return;
      case 4:
        context.go('/settings');
        return;
    }
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/home');
  }

  Future<void> _handleUpgradePress(bool isPremiumUser) async {
    if (_isCreatingCheckout) return;

    if (isPremiumUser) {
      _showSnackBar('Tài khoản của bạn đã là Premium');
      return;
    }

    setState(() => _isCreatingCheckout = true);
    try {
      final checkoutSession = await _checkoutService.createCheckoutSession(
        planIndex: _selectedPlan,
      );
      final checkoutUrl = checkoutSession.checkoutUrl;
      debugPrint('[PAYMENT] checkoutUrl=$checkoutUrl');

      final launched = await _openCheckoutUrl(checkoutUrl);
      debugPrint('[PAYMENT] launchResult=$launched, kIsWeb=$kIsWeb');

      if (!launched) {
        _showSnackBar('Không mở được trang thanh toán. Vui lòng thử lại.');
      }
    } catch (e) {
      final isAuthError = _isAuthError(e);

      _showSnackBar(_friendlyPaymentError(e));

      if (isAuthError &&
          Supabase.instance.client.auth.currentUser == null &&
          mounted) {
        context.go('/auth/signup');
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingCheckout = false);
      }
    }
  }

  Future<bool> _openCheckoutUrl(String checkoutUrl) async {
    final uri = Uri.parse(checkoutUrl);

    if (kIsWeb) {
      return launchUrl(uri, webOnlyWindowName: '_self');
    }

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.lexend(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool _isAuthError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('401') ||
        message.contains('unauthorized') ||
        message.contains('missing auth header') ||
        message.contains('invalid jwt') ||
        message.contains('dang nhap') ||
        message.contains('refresh token');
  }

  String _friendlyPaymentError(Object error) {
    final raw = error
        .toString()
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .trim();
    final normalized = raw.toLowerCase();
    final auth = Supabase.instance.client.auth;
    final hasAuthState =
        auth.currentUser != null || auth.currentSession != null;

    if (normalized.contains('socketexception') ||
        normalized.contains('failed host lookup') ||
        normalized.contains('network')) {
      return 'Không kết nối được mạng. Vui lòng kiểm tra Internet.';
    }

    if (_isAuthError(error)) {
      if (hasAuthState) {
        if (raw.isNotEmpty) {
          return 'Token thanh toán bị từ chối: $raw';
        }
        return 'Đăng nhập vẫn còn nhưng token thanh toán bị từ chối. Vui lòng đăng xuất rồi đăng nhập lại 1 lần.';
      }
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    }

    if (raw.isEmpty) {
      return 'Tạo thanh toán thất bại. Vui lòng thử lại.';
    }

    return 'Tạo thanh toán thất bại: $raw';
  }
}

class _UpgradeHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _UpgradeHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(8, topPadding + 10, 8, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            color: Colors.white,
          ),
          const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            'Nâng cấp Premium',
            style: GoogleFonts.lexend(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCarousel extends StatelessWidget {
  final PageController pageController;
  final int currentSlide;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onDotTap;

  const _FeatureCarousel({
    required this.pageController,
    required this.currentSlide,
    required this.onPageChanged,
    required this.onDotTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 230,
            child: PageView.builder(
              controller: pageController,
              onPageChanged: onPageChanged,
              itemCount: _slides.length,
              itemBuilder: (context, index) {
                final slide = _slides[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: slide.iconBackground,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          slide.icon,
                          size: 40,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        slide.title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lexend(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSlate800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        slide.description,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lexend(
                          fontSize: 13,
                          color: AppColors.textSlate500,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (index) {
                final isActive = currentSlide == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onDotTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      width: isActive ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        color: isActive
                            ? AppColors.primary
                            : AppColors.slate200,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialProofRow extends StatelessWidget {
  const _SocialProofRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: const [
        _ProofChip(icon: '⭐', text: '4.8/5 từ hơn 3.200 học viên'),
        _ProofChip(icon: '🔥', text: '12.000+ người đang học trên Lexii'),
      ],
    );
  }
}

class _ProofChip extends StatelessWidget {
  final String icon;
  final String text;

  const _ProofChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.lexend(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSlate600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanSelector extends StatelessWidget {
  final int selectedPlan;
  final ValueChanged<int> onSelect;

  const _PlanSelector({required this.selectedPlan, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Chọn gói phù hợp với bạn',
          textAlign: TextAlign.center,
          style: GoogleFonts.lexend(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textSlate800,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 198,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _plans.length,
            padding: const EdgeInsets.fromLTRB(2, 16, 2, 6),
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final plan = _plans[index];
              final isSelected = selectedPlan == plan.id;
              return _PlanCard(
                plan: plan,
                isSelected: isSelected,
                onTap: () => onSelect(plan.id),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_plans.length, (index) {
            final isActive = selectedPlan == _plans[index].id;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: isActive ? AppColors.primary : AppColors.textSlate300,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final _Plan plan;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFeatured = plan.featured;
    final double width = isFeatured ? 196 : 152;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isFeatured ? 16 : 14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: width,
        padding: EdgeInsets.fromLTRB(14, isFeatured ? 26 : 14, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isFeatured ? 16 : 14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderSlate200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isFeatured
                  ? AppColors.primary.withValues(alpha: 0.16)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: isFeatured ? 18 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (plan.badge != null)
              Positioned(
                top: -30,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      plan.badge!,
                      style: GoogleFonts.lexend(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 13, color: Colors.white),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.label,
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSlate400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  plan.price,
                  style: GoogleFonts.lexend(
                    fontSize: isFeatured ? 28 : 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    height: 1.1,
                  ),
                ),
                if (plan.discount != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      plan.discount!,
                      style: GoogleFonts.lexend(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFC84B11),
                      ),
                    ),
                  ),
                ],
                if (plan.subPrice != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    plan.subPrice!,
                    style: GoogleFonts.lexend(
                      fontSize: 11,
                      color: AppColors.textSlate400,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UpgradeButton extends StatelessWidget {
  final int selectedPlan;
  final bool isLoading;
  final VoidCallback onPressed;

  const _UpgradeButton({
    required this.selectedPlan,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1C9C8C), Color(0xFF14B8A6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1C9C8C).withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Nâng cấp gói đã chọn',
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

class _AccountStatusSection extends StatelessWidget {
  const _AccountStatusSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.teal50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      color: AppColors.textSlate600,
                    ),
                    children: const [
                      TextSpan(text: 'Tài khoản '),
                      TextSpan(
                        text: 'Phạm Thùy Trang',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: ' vừa nâng cấp'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              '9',
              '9',
              '5',
              '7',
            ].map((digit) => _ScoreBox(digit: digit)).toList(),
          ),
        ],
      ),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final String digit;

  const _ScoreBox({required this.digit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSlate200),
      ),
      alignment: Alignment.center,
      child: Text(
        digit,
        style: GoogleFonts.lexend(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _FeatureComparisonTable extends StatelessWidget {
  const _FeatureComparisonTable();

  static const _rows = [
    _ComparisonRow('Luyện tập part 1,2,5', true, true),
    _ComparisonRow('Học lý thuyết', true, true),
    _ComparisonRow('Phân tích điểm mạnh/yếu', false, true),
    _ComparisonRow('Đề thi TOEIC Premium', false, true),
    _ComparisonRow('Giải thích chi tiết mọi câu hỏi', false, true),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              color: AppColors.slate50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'TÍNH NĂNG',
                      style: GoogleFonts.lexend(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSlate500,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 72,
                    child: Center(
                      child: Text(
                        'Miễn phí',
                        style: GoogleFonts.lexend(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSlate500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 72,
                    child: Center(
                      child: Text(
                        'Premium',
                        style: GoogleFonts.lexend(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ..._rows.map(_buildRow),
            _buildCountRow('Mở khóa đề thi thử', '4', '30'),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(_ComparisonRow row) {
    return Column(
      children: [
        const Divider(height: 1, color: AppColors.borderSlate100),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  row.feature,
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSlate600,
                  ),
                ),
              ),
              SizedBox(
                width: 72,
                child: Center(
                  child: Icon(
                    row.free ? Icons.check : Icons.lock_outline,
                    size: 20,
                    color: row.free
                        ? AppColors.green600
                        : AppColors.textSlate300,
                  ),
                ),
              ),
              const SizedBox(
                width: 72,
                child: Center(
                  child: Icon(Icons.check, size: 20, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCountRow(String feature, String freeCount, String premiumCount) {
    return Column(
      children: [
        const Divider(height: 1, color: AppColors.borderSlate100),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  feature,
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSlate600,
                  ),
                ),
              ),
              SizedBox(
                width: 72,
                child: Center(
                  child: Text(
                    freeCount,
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSlate500,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 72,
                child: Center(
                  child: Text(
                    premiumCount,
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ComparisonRow {
  final String feature;
  final bool free;
  final bool premium;

  const _ComparisonRow(this.feature, this.free, this.premium);
}

class _UserReviewsSection extends StatefulWidget {
  const _UserReviewsSection();

  @override
  State<_UserReviewsSection> createState() => _UserReviewsSectionState();
}

class _UserReviewsSectionState extends State<_UserReviewsSection> {
  late final Future<List<_RemoteReview>> _futureReviews = _fetchTopReviews();

  Future<List<_RemoteReview>> _fetchTopReviews() async {
    try {
      final client = Supabase.instance.client;
      final data = await client
          .from('reviews')
          .select('id,rating,content,profiles:user_id(full_name,avatar_url)')
          .eq('rating', 5)
          .order('created_at', ascending: false)
          .limit(20);

      final rows = (data as List).cast<Map<String, dynamic>>();
      return rows.map((row) {
        final dynamic profileRaw = row['profiles'];
        Map<String, dynamic>? profile;
        if (profileRaw is Map<String, dynamic>) {
          profile = profileRaw;
        } else if (profileRaw is Map) {
          profile = profileRaw.map((k, v) => MapEntry('$k', v));
        }

        final String? rawName = (profile?['full_name'] as String?)?.trim();
        final String? rawAvatar = (profile?['avatar_url'] as String?)?.trim();
        final String rawContent = ('${row['content'] ?? ''}').trim();

        return _RemoteReview(
          id: '${row['id'] ?? ''}',
          name: (rawName == null || rawName.isEmpty) ? 'Người dùng' : rawName,
          stars: (row['rating'] as num?)?.toInt() ?? 5,
          text: rawContent,
          avatarUrl: (rawAvatar == null || rawAvatar.isEmpty)
              ? null
              : rawAvatar,
        );
      }).toList();
    } catch (_) {
      return const <_RemoteReview>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phản hồi của người dùng',
          style: GoogleFonts.lexend(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textSlate800,
          ),
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<_RemoteReview>>(
          future: _futureReviews,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Đang tải đánh giá...',
                      style: GoogleFonts.lexend(
                        fontSize: 13,
                        color: AppColors.textSlate500,
                      ),
                    ),
                  ],
                ),
              );
            }

            final reviews = snapshot.data ?? const <_RemoteReview>[];
            if (reviews.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Chưa có đánh giá nào. Hãy là người đầu tiên!',
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    color: AppColors.textSlate500,
                  ),
                ),
              );
            }

            final preview = reviews.take(5).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...preview.map(
                  (review) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ReviewCard(review: review),
                  ),
                ),
                FilledButton(
                  onPressed: () => context.push('/settings/reviews'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: GoogleFonts.lexend(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text('Xem thêm đánh giá (${reviews.length})'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final _RemoteReview review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.teal50,
                backgroundImage: review.avatarUrl != null
                    ? NetworkImage(review.avatarUrl!)
                    : null,
                child: review.avatarUrl == null
                    ? Text(
                        review.name.isNotEmpty ? review.name[0] : 'U',
                        style: GoogleFonts.lexend(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.name,
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSlate800,
                    ),
                  ),
                  Row(
                    children: List.generate(
                      review.stars,
                      (_) => const Icon(
                        Icons.star,
                        size: 14,
                        color: AppColors.yellow500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.text,
            style: GoogleFonts.lexend(
              fontSize: 12,
              color: AppColors.textSlate600,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final Color iconBackground;
  final String title;
  final String description;

  const _Slide({
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.description,
  });
}

class _Plan {
  final int id;
  final String label;
  final String price;
  final String? subPrice;
  final String? badge;
  final String? discount;
  final bool featured;

  const _Plan({
    required this.id,
    required this.label,
    required this.price,
    required this.subPrice,
    required this.badge,
    required this.discount,
    required this.featured,
  });
}

class _RemoteReview {
  final String id;
  final String name;
  final int stars;
  final String text;
  final String? avatarUrl;

  const _RemoteReview({
    required this.id,
    required this.name,
    required this.stars,
    required this.text,
    this.avatarUrl,
  });
}

const List<_Slide> _slides = [
  _Slide(
    icon: Icons.menu_book_rounded,
    iconBackground: Color(0xFFE6F7F5),
    title: '30 đề thi TOEIC ETS mới nhất',
    description: '12.000 câu hỏi có đáp án và giải thích chi tiết',
  ),
  _Slide(
    icon: Icons.headphones_rounded,
    iconBackground: Color(0xFFEEF2FF),
    title: 'Luyện nghe chuẩn ETS',
    description: '600+ audio giúp luyện nghe từ Part 1 đến Part 4',
  ),
  _Slide(
    icon: Icons.bar_chart_rounded,
    iconBackground: Color(0xFFFFF7ED),
    title: 'Phân tích điểm thi thông minh',
    description: 'Hệ thống tự động phân tích điểm yếu và gợi ý lộ trình học',
  ),
  _Slide(
    icon: Icons.bookmark_added_rounded,
    iconBackground: Color(0xFFF5F3FF),
    title: 'Học từ vựng theo chủ đề',
    description: '3000+ từ vựng TOEIC với flashcard và quiz',
  ),
];

const List<_Plan> _plans = [
  _Plan(
    id: 0,
    label: '6 tháng',
    price: '299.000đ',
    subPrice: '49.000đ / tháng',
    badge: null,
    discount: null,
    featured: false,
  ),
  _Plan(
    id: 1,
    label: 'Trọn đời',
    price: '1.499.000đ',
    subPrice: null,
    badge: 'Phổ biến nhất',
    discount: 'Giảm 50%',
    featured: true,
  ),
  _Plan(
    id: 2,
    label: '1 năm',
    price: '599.000đ',
    subPrice: '49.000đ / tháng',
    badge: null,
    discount: null,
    featured: false,
  ),
];
