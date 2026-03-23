import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/subscription/subscription_providers.dart';
import 'package:lexii/core/theme/app_colors.dart';

class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(userTransactionsProvider);
    await ref.read(userTransactionsProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(userTransactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          Container(
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
                        'Lịch sử giao dịch',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lexend(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => _refresh(ref),
              child: txAsync.when(
                loading: () => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 220),
                    Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                error: (_, __) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Không tải được lịch sử giao dịch.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        color: AppColors.textSlate500,
                      ),
                    ),
                  ],
                ),
                data: (items) {
                  final totalSpent = items
                      .where((t) => t.status.toLowerCase() == 'paid')
                      .fold<int>(0, (sum, t) => sum + t.amount);

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (items.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryDark,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tổng chi tiêu',
                                      style: GoogleFonts.lexend(
                                        fontSize: 13,
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatMoney(totalSpent, 'VND'),
                                      style: GoogleFonts.lexend(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Icon(
                                  Icons.credit_card,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.indigo100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 1),
                              child: Icon(
                                Icons.info_outline,
                                color: AppColors.indigo600,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Nếu có vấn đề về giao dịch, vui lòng liên hệ admin để được hỗ trợ.',
                                style: GoogleFonts.lexend(
                                  fontSize: 13,
                                  color: AppColors.indigo600,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (items.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderSlate100),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AppColors.slate100,
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                child: const Icon(
                                  Icons.credit_card,
                                  color: AppColors.textSlate400,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Chưa có giao dịch nào',
                                style: GoogleFonts.lexend(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSlate800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Các giao dịch của bạn sẽ hiển thị ở đây',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.lexend(
                                  fontSize: 13,
                                  color: AppColors.textSlate500,
                                ),
                              ),
                              const SizedBox(height: 14),
                              FilledButton(
                                onPressed: () => context.push('/upgrade'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  textStyle: GoogleFonts.lexend(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                child: const Text('Nâng cấp gói Premium'),
                              ),
                            ],
                          ),
                        )
                      else
                        ...items.map(
                          (tx) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _TransactionCard(item: tx),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final SubscriptionTransactionItem item;

  const _TransactionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final status = _statusInfo(item.status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSlate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.amber100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: AppColors.amber600,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.planName,
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSlate900,
                      ),
                    ),
                    Text(
                      _planDuration(item.planId),
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: AppColors.textSlate500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: status.bg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(status.icon, color: status.color, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      status.label,
                      style: GoogleFonts.lexend(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: status.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            runSpacing: 10,
            spacing: 12,
            children: [
              _DetailBlock(
                label: 'Số tiền',
                value: _formatMoney(item.amount, item.currency),
              ),
              _DetailBlock(
                label: 'Phương thức',
                value: _providerLabel(item.provider),
              ),
              _DetailBlock(label: 'Mã đơn hàng', value: '#${item.orderCode}'),
              _DetailBlock(
                label: 'Ngày tạo',
                value: _formatDateTime(item.createdAt),
              ),
              if (item.paidAt != null)
                _DetailBlock(
                  label: 'Ngày thanh toán',
                  value: _formatDateTime(item.paidAt),
                ),
              _DetailBlock(
                label: 'Hết hạn',
                value: item.isLifetime
                    ? 'Trọn đời'
                    : item.grantedUntil != null
                    ? _formatDateTime(item.grantedUntil)
                    : '—',
                valueColor: item.isLifetime ? AppColors.green600 : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailBlock({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: 11,
              color: AppColors.textSlate500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.lexend(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textSlate800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TxStatusInfo {
  final IconData icon;
  final String label;
  final Color bg;
  final Color color;

  const _TxStatusInfo({
    required this.icon,
    required this.label,
    required this.bg,
    required this.color,
  });
}

_TxStatusInfo _statusInfo(String status) {
  final value = status.toLowerCase().trim();
  if (value == 'paid') {
    return const _TxStatusInfo(
      icon: Icons.check_circle,
      label: 'Thành công',
      bg: AppColors.green100,
      color: AppColors.green600,
    );
  }
  if (value == 'pending') {
    return const _TxStatusInfo(
      icon: Icons.schedule,
      label: 'Đang xử lý',
      bg: AppColors.amber100,
      color: AppColors.amber600,
    );
  }
  if (value == 'cancelled') {
    return const _TxStatusInfo(
      icon: Icons.cancel,
      label: 'Đã hủy',
      bg: AppColors.orange50,
      color: AppColors.orange500,
    );
  }
  if (value == 'failed') {
    return const _TxStatusInfo(
      icon: Icons.highlight_off,
      label: 'Thất bại',
      bg: AppColors.red100,
      color: AppColors.red600,
    );
  }
  return _TxStatusInfo(
    icon: Icons.schedule,
    label: status,
    bg: AppColors.slate100,
    color: AppColors.textSlate600,
  );
}

String _providerLabel(String provider) {
  final key = provider.toLowerCase().trim();
  const providers = <String, String>{
    'payos': 'PayOS',
    'vnpay': 'VNPay',
    'momo': 'MoMo',
    'zalopay': 'ZaloPay',
    'stripe': 'Stripe',
    'bank_transfer': 'Chuyển khoản',
  };
  return providers[key] ?? provider;
}

String _planDuration(String planId) {
  final value = planId.toLowerCase();
  if (value.contains('lifetime')) return 'Trọn đời';
  if (value.contains('6')) return '6 tháng';
  if (value.contains('1_year')) return '1 năm';
  if (value.contains('1month')) return '1 tháng';
  return '';
}

String _formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return '—';
  final d = dateTime.toLocal();
  final day = d.day.toString().padLeft(2, '0');
  final month = d.month.toString().padLeft(2, '0');
  final year = d.year;
  final hour = d.hour.toString().padLeft(2, '0');
  final minute = d.minute.toString().padLeft(2, '0');
  return '$day/$month/$year • $hour:$minute';
}

String _formatMoney(int amount, String currency) {
  final normalized = currency.toUpperCase().trim();
  final absValue = amount.abs().toString();
  final out = StringBuffer();

  for (var i = 0; i < absValue.length; i++) {
    out.write(absValue[i]);
    final remain = absValue.length - i - 1;
    if (remain > 0 && remain % 3 == 0) {
      out.write('.');
    }
  }

  final prefix = amount < 0 ? '-' : '';
  final value = '$prefix$out';
  if (normalized == 'VND') return '$value ₫';
  return '$value $normalized';
}
