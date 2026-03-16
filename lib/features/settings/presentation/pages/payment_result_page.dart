import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/subscription/subscription_providers.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:lexii/features/settings/data/services/payment_verification_service.dart';

class PaymentResultPage extends ConsumerStatefulWidget {
  final String status;
  final String? orderCode;

  const PaymentResultPage({super.key, required this.status, this.orderCode});

  @override
  ConsumerState<PaymentResultPage> createState() => _PaymentResultPageState();
}

class _PaymentResultPageState extends ConsumerState<PaymentResultPage>
    with SingleTickerProviderStateMixin {
  final PaymentVerificationService _verificationService =
      PaymentVerificationService();

  bool _isVerifying = false;
  PaymentVerificationResult? _verificationResult;
  late String _resolvedStatus;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _resolvedStatus = widget.status;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (_resolvedStatus == 'success' &&
        widget.orderCode != null &&
        widget.orderCode!.isNotEmpty) {
      _verifyPayment();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _verifyPayment() async {
    if (_isVerifying) return;
    setState(() => _isVerifying = true);

    final result = await _verificationService.verifyPayment(widget.orderCode!);

    if (!mounted) return;

    setState(() {
      _verificationResult = result;
      _isVerifying = false;
      if (result.isPaid) {
        _resolvedStatus = 'success';
      } else if (result.isCancelled) {
        _resolvedStatus = 'cancel';
      } else if (result.status == 'error' || result.status == 'unknown') {
        // Keep original status from deep link
      }
    });

    // Refresh premium status across the entire app
    if (result.isPaid) {
      ref.invalidate(isPremiumProvider);
      ref.invalidate(subscriptionInfoProvider);
      ref.invalidate(userRoleProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    // While verifying, show loading state
    if (_isVerifying) {
      return Scaffold(
        backgroundColor: AppColors.slate100,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.12),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Đang xác nhận thanh toán...',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lexend(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSlate800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Vui lòng chờ trong giây lát',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      color: AppColors.textSlate500,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final isSuccess = _resolvedStatus == 'success';
    final isCancel = _resolvedStatus == 'cancel';

    final icon = isSuccess
        ? Icons.check_circle_rounded
        : isCancel
            ? Icons.info_rounded
            : Icons.error_rounded;

    final iconColor = isSuccess
        ? AppColors.green600
        : isCancel
            ? AppColors.amber600
            : AppColors.red600;

    final title = isSuccess
        ? 'Thanh toán thành công!'
        : isCancel
            ? 'Bạn đã hủy thanh toán'
            : 'Thanh toán thất bại';

    final subtitle = isSuccess
        ? 'Tài khoản đã được nâng cấp Premium. Chúc bạn học tập hiệu quả!'
        : isCancel
            ? 'Bạn có thể quay lại để thử lại bất kỳ lúc nào.'
            : 'Đã có lỗi xảy ra trong quá trình thanh toán. Vui lòng thử lại.';

    // Build premium info text for success
    String? premiumInfoText;
    if (isSuccess && _verificationResult != null) {
      if (_verificationResult!.isLifetime) {
        premiumInfoText = '🎉 Gói Premium trọn đời';
      } else if (_verificationResult!.premiumExpiresAt != null) {
        final expiresAt =
            DateTime.tryParse(_verificationResult!.premiumExpiresAt!);
        if (expiresAt != null) {
          final day = expiresAt.day.toString().padLeft(2, '0');
          final month = expiresAt.month.toString().padLeft(2, '0');
          final year = expiresAt.year;
          premiumInfoText = '⏰ Có hiệu lực đến $day/$month/$year';
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.slate100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(),
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor.withValues(alpha: 0.14),
                  ),
                  child: Icon(icon, size: 52, color: iconColor),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.lexend(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSlate900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  color: AppColors.textSlate600,
                  height: 1.45,
                ),
              ),
              if (premiumInfoText != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    premiumInfoText,
                    style: GoogleFonts.lexend(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
              if (widget.orderCode != null && widget.orderCode!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Mã đơn: ${widget.orderCode}',
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    color: AppColors.textSlate500,
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Về trang chủ',
                    style: GoogleFonts.lexend(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (!isSuccess) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => context.go('/upgrade'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Quay lại nâng cấp',
                      style: GoogleFonts.lexend(
                        color: AppColors.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
