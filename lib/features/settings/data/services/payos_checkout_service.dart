import 'package:supabase_flutter/supabase_flutter.dart';

class PayosCheckoutService {
  final SupabaseClient _client;
  static const String _paymentResultDeepLink = 'lexii://payment-result';

  PayosCheckoutService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  static const List<_UpgradePlan> _plans = [
    _UpgradePlan(
      id: 'premium_6_months',
      name: 'Premium 6 thang',
      amount: 299000,
      description: 'Lexii Premium 6 thang',
    ),
    _UpgradePlan(
      id: 'premium_lifetime',
      name: 'Premium tron doi',
      amount: 1499000,
      description: 'Lexii Premium tron doi',
    ),
    _UpgradePlan(
      id: 'premium_1_year',
      name: 'Premium 1 nam',
      amount: 599000,
      description: 'Lexii Premium 1 nam',
    ),
  ];

  Future<PayosCheckoutSession> createCheckoutSession({
    required int planIndex,
  }) async {
    if (planIndex < 0 || planIndex >= _plans.length) {
      throw Exception('Goi nang cap khong hop le');
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Vui long dang nhap de nang cap Premium');
    }

    final plan = _plans[planIndex];

    late final FunctionResponse response;
    try {
      response = await _invokeCreatePayment(plan, user.id);
    } on FunctionException catch (error) {
      if (error.status == 401) {
        try {
          response = await _invokeCreatePayment(plan, user.id);
        } on FunctionException catch (retryError) {
          throw Exception(_extractFunctionError(retryError));
        }
      } else {
        throw Exception(_extractFunctionError(error));
      }
    }

    final data = response.data;
    if (data is! Map) {
      throw Exception('Phan hoi khong hop le tu server thanh toan');
    }

    final checkoutUrl = data['checkoutUrl'] as String?;
    if (checkoutUrl == null || checkoutUrl.isEmpty) {
      final errorMessage = data['error'] as String?;
      throw Exception(errorMessage ?? 'Khong tao duoc link thanh toan');
    }

    final qrContent =
        (data['qrCode'] as String?) ??
        (data['qr_code'] as String?) ??
        (data['vietQrData'] as String?) ??
        (data['viet_qr_data'] as String?);

    final orderCodeRaw = data['orderCode'];
    final orderCode = orderCodeRaw == null ? '' : orderCodeRaw.toString();

    return PayosCheckoutSession(
      checkoutUrl: checkoutUrl,
      qrContent: qrContent,
      orderCode: orderCode,
    );
  }

  Future<String> createCheckoutUrl({required int planIndex}) async {
    final session = await createCheckoutSession(planIndex: planIndex);
    return session.checkoutUrl;
  }

  Future<FunctionResponse> _invokeCreatePayment(
    _UpgradePlan plan,
    String userId,
  ) {
    return _client.functions.invoke(
      'create-payos-payment',
      body: {
        'userId': userId,
        'planId': plan.id,
        'planName': plan.name,
        'amount': plan.amount,
        'description': plan.description,
        'returnUrl': _paymentResultDeepLink,
        'cancelUrl': _paymentResultDeepLink,
      },
    );
  }

  String _extractFunctionError(FunctionException error) {
    final details = error.details;
    if (details is Map) {
      final backendMessage =
          details['error'] ?? details['message'] ?? details['msg'];
      if (backendMessage is String && backendMessage.trim().isNotEmpty) {
        return '[${error.status}] ${backendMessage.trim()}';
      }
    }

    final reason = error.reasonPhrase?.trim();
    if (reason != null && reason.isNotEmpty) {
      return '[${error.status}] $reason';
    }

    return '[${error.status}] Loi goi dich vu thanh toan';
  }
}

class PayosCheckoutSession {
  final String checkoutUrl;
  final String? qrContent;
  final String orderCode;

  const PayosCheckoutSession({
    required this.checkoutUrl,
    this.qrContent,
    required this.orderCode,
  });
}

class _UpgradePlan {
  final String id;
  final String name;
  final int amount;
  final String description;

  const _UpgradePlan({
    required this.id,
    required this.name,
    required this.amount,
    required this.description,
  });
}
