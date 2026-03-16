import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentVerificationResult {
  final String status;
  final bool alreadyProcessed;
  final String? premiumExpiresAt;
  final bool isLifetime;
  final String? message;

  const PaymentVerificationResult({
    required this.status,
    this.alreadyProcessed = false,
    this.premiumExpiresAt,
    this.isLifetime = false,
    this.message,
  });

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';
  bool get isCancelled => status == 'cancelled' || status == 'cancel';

  factory PaymentVerificationResult.fromJson(Map<String, dynamic> json) {
    return PaymentVerificationResult(
      status: json['status'] as String? ?? 'unknown',
      alreadyProcessed: json['alreadyProcessed'] as bool? ?? false,
      premiumExpiresAt: json['premiumExpiresAt'] as String?,
      isLifetime: json['isLifetime'] as bool? ?? false,
      message: json['message'] as String?,
    );
  }
}

class PaymentVerificationService {
  final SupabaseClient _client;

  PaymentVerificationService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// Calls the `confirm-payment` Edge Function to verify
  /// the payment status and grant premium if paid.
  Future<PaymentVerificationResult> verifyPayment(String orderCode) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return const PaymentVerificationResult(
        status: 'error',
        message: 'User not authenticated',
      );
    }

    // Always proactively refresh the session to ensure the access token
    // is fresh – the session object can exist but carry an expired JWT.
    try {
      await _client.auth.refreshSession();
    } catch (_) {}

    final session = _client.auth.currentSession;

    if (session == null) {
      return const PaymentVerificationResult(
        status: 'error',
        message: 'Session expired',
      );
    }

    try {
      final response = await _client.functions.invoke(
        'confirm-payment',
        body: {
          'orderCode': orderCode,
          'userId': user.id,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('error')) {
          return PaymentVerificationResult(
            status: 'error',
            message: data['error'] as String?,
          );
        }
        return PaymentVerificationResult.fromJson(data);
      }

      return const PaymentVerificationResult(
        status: 'error',
        message: 'Invalid response from server',
      );
    } catch (e) {
      return PaymentVerificationResult(
        status: 'error',
        message: e.toString(),
      );
    }
  }
}
