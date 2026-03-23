import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Duration _kSubscriptionRefreshInterval = Duration(seconds: 30);

final _authStateTickProvider = StreamProvider<int>((ref) async* {
  final auth = Supabase.instance.client.auth;
  var tick = 0;
  yield tick;
  await for (final _ in auth.onAuthStateChange) {
    tick++;
    yield tick;
  }
});

final _subscriptionRefreshTickProvider = StreamProvider<int>((ref) async* {
  var tick = 0;
  while (true) {
    yield tick++;
    await Future<void>.delayed(_kSubscriptionRefreshInterval);
  }
});

Future<void> _normalizeExpiredSubscriptionState(
  SupabaseClient client,
  String userId,
) async {
  final nowIso = DateTime.now().toUtc().toIso8601String();

  // 1) Mark expired paid orders as expired.
  try {
    await client
        .from('subscription_orders')
        .update({'status': 'expired'})
        .eq('user_id', userId)
        .eq('status', 'paid')
        .eq('is_lifetime', false)
        .lte('granted_until', nowIso);
  } catch (_) {
    // Best-effort sync only; continue reading subscription state.
  }

  // 2) Downgrade profile role when premium expiry has passed.
  Map<String, dynamic>? profile;
  try {
    profile = await client
        .from('profiles')
        .select('role,premium_expires_at')
        .eq('id', userId)
        .maybeSingle();
  } catch (_) {
    return;
  }

  final role = (profile?['role'] as String?)?.toLowerCase().trim();
  final expiresAtRaw = profile?['premium_expires_at'] as String?;

  if (role == 'premium' && expiresAtRaw != null && expiresAtRaw.isNotEmpty) {
    final expiresAt = DateTime.tryParse(expiresAtRaw)?.toUtc();
    final isExpired =
        expiresAt == null || !expiresAt.isAfter(DateTime.now().toUtc());
    if (isExpired) {
      try {
        await client
            .from('profiles')
            .update({'role': 'user', 'premium_expires_at': null})
            .eq('id', userId);
      } catch (_) {
        // Best-effort sync only; keep UI based on server-read state.
      }
    }
  }
}

Future<bool> _hasActivePremiumOrder(
  SupabaseClient client,
  String userId,
) async {
  final orders = await client
      .from('subscription_orders')
      .select('is_lifetime,granted_until,status')
      .eq('user_id', userId)
      .eq('status', 'paid');

  if (orders.isEmpty) return false;

  final now = DateTime.now().toUtc();
  for (final row in orders) {
    final isLifetime = row['is_lifetime'] == true;
    if (isLifetime) return true;

    final grantedUntilRaw = row['granted_until'] as String?;
    if (grantedUntilRaw == null || grantedUntilRaw.isEmpty) continue;

    final grantedUntil = DateTime.tryParse(grantedUntilRaw)?.toUtc();
    if (grantedUntil != null && grantedUntil.isAfter(now)) {
      return true;
    }
  }

  return false;
}

Future<SubscriptionInfo> _subscriptionInfoFromOrders(
  SupabaseClient client,
  String userId,
) async {
  final rows = await client
      .from('subscription_orders')
      .select('is_lifetime,granted_until,status')
      .eq('user_id', userId)
      .eq('status', 'paid');

  if (rows.isEmpty) {
    return const SubscriptionInfo(isPremium: false);
  }

  final now = DateTime.now().toUtc();
  DateTime? latestExpiry;

  for (final row in rows) {
    if (row['is_lifetime'] == true) {
      return const SubscriptionInfo(isPremium: true, isLifetime: true);
    }

    final grantedUntilRaw = row['granted_until'] as String?;
    if (grantedUntilRaw == null || grantedUntilRaw.isEmpty) continue;

    final grantedUntil = DateTime.tryParse(grantedUntilRaw)?.toUtc();
    if (grantedUntil == null) continue;
    if (latestExpiry == null || grantedUntil.isAfter(latestExpiry)) {
      latestExpiry = grantedUntil;
    }
  }

  if (latestExpiry != null && latestExpiry.isAfter(now)) {
    return SubscriptionInfo(
      isPremium: true,
      isLifetime: false,
      expiresAt: latestExpiry,
    );
  }

  return const SubscriptionInfo(isPremium: false);
}

final userRoleProvider = FutureProvider<String>((ref) async {
  ref.watch(_authStateTickProvider);
  ref.watch(_subscriptionRefreshTickProvider);

  final client = Supabase.instance.client;
  final user = client.auth.currentUser;

  if (user == null) return 'guest';

  try {
    await _normalizeExpiredSubscriptionState(client, user.id);

    final response = await client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();

    final role = (response['role'] as String?)?.toLowerCase().trim();
    if (role == null || role.isEmpty) return 'user';
    return role;
  } catch (_) {
    final metadataRole = (user.userMetadata?['role'] as String?)
        ?.toLowerCase()
        .trim();
    if (metadataRole == null || metadataRole.isEmpty) return 'user';
    return metadataRole;
  }
});

final isPremiumProvider = FutureProvider<bool>((ref) async {
  ref.watch(_authStateTickProvider);
  ref.watch(_subscriptionRefreshTickProvider);

  final client = Supabase.instance.client;
  final user = client.auth.currentUser;

  if (user == null) return false;

  try {
    await _normalizeExpiredSubscriptionState(client, user.id);

    final response = await client
        .from('profiles')
        .select('role,premium_expires_at')
        .eq('id', user.id)
        .single();

    final role = (response['role'] as String?)?.toLowerCase().trim();
    if (role == 'premium') return true;
    return _hasActivePremiumOrder(client, user.id);
  } catch (_) {
    return _hasActivePremiumOrder(client, user.id);
  }
});

/// Detailed subscription info for display in the UI.
class SubscriptionInfo {
  final bool isPremium;
  final bool isLifetime;
  final DateTime? expiresAt;

  const SubscriptionInfo({
    required this.isPremium,
    this.isLifetime = false,
    this.expiresAt,
  });

  String get statusLabel {
    if (!isPremium) return 'Miễn phí';
    if (isLifetime) return 'Premium trọn đời';
    if (expiresAt != null) {
      final day = expiresAt!.day.toString().padLeft(2, '0');
      final month = expiresAt!.month.toString().padLeft(2, '0');
      final year = expiresAt!.year;
      return 'Premium đến $day/$month/$year';
    }
    return 'Premium';
  }
}

class SubscriptionTransactionItem {
  final String id;
  final String userId;
  final String planId;
  final String planName;
  final int amount;
  final String currency;
  final int orderCode;
  final String status;
  final String provider;
  final bool isLifetime;
  final DateTime? paidAt;
  final DateTime createdAt;
  final DateTime? grantedUntil;

  const SubscriptionTransactionItem({
    required this.id,
    required this.userId,
    required this.planId,
    required this.planName,
    required this.amount,
    required this.currency,
    required this.orderCode,
    required this.status,
    required this.provider,
    required this.isLifetime,
    required this.paidAt,
    required this.createdAt,
    required this.grantedUntil,
  });

  factory SubscriptionTransactionItem.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? 0;
    }

    DateTime? parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value)?.toLocal();
      }
      return null;
    }

    return SubscriptionTransactionItem(
      id: '${json['id'] ?? ''}',
      userId: '${json['user_id'] ?? ''}',
      planId: '${json['plan_id'] ?? ''}',
      planName: '${json['plan_name'] ?? ''}',
      amount: parseInt(json['amount']),
      currency: '${json['currency'] ?? 'VND'}',
      orderCode: parseInt(json['order_code']),
      status: '${json['status'] ?? ''}',
      provider: '${json['provider'] ?? ''}',
      isLifetime: json['is_lifetime'] == true,
      paidAt: parseDate(json['paid_at']),
      createdAt: parseDate(json['created_at']) ?? DateTime.now(),
      grantedUntil: parseDate(json['granted_until']),
    );
  }
}

final userTransactionsProvider = FutureProvider<List<SubscriptionTransactionItem>>((
  ref,
) async {
  ref.watch(_authStateTickProvider);
  ref.watch(_subscriptionRefreshTickProvider);

  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return const [];

  final rows = await client
      .from('subscription_orders')
      .select(
        'id,user_id,plan_id,plan_name,amount,currency,order_code,status,provider,is_lifetime,paid_at,created_at,granted_until',
      )
      .eq('user_id', user.id)
      .order('created_at', ascending: false);

  return rows
      .map<SubscriptionTransactionItem>(
        (row) => SubscriptionTransactionItem.fromJson(row),
      )
      .toList();
});

final subscriptionInfoProvider = FutureProvider<SubscriptionInfo>((ref) async {
  ref.watch(_authStateTickProvider);
  ref.watch(_subscriptionRefreshTickProvider);

  final client = Supabase.instance.client;
  final user = client.auth.currentUser;

  if (user == null) {
    return const SubscriptionInfo(isPremium: false);
  }

  try {
    await _normalizeExpiredSubscriptionState(client, user.id);

    final response = await client
        .from('profiles')
        .select('role,premium_expires_at')
        .eq('id', user.id)
        .single();

    final role = (response['role'] as String?)?.toLowerCase().trim();
    if (role != 'premium') {
      return _subscriptionInfoFromOrders(client, user.id);
    }

    final expiresAtRaw = response['premium_expires_at'] as String?;

    // If no expiry date -> could be lifetime
    if (expiresAtRaw == null || expiresAtRaw.isEmpty) {
      final hasActive = await _hasActivePremiumOrder(client, user.id);
      if (!hasActive) return const SubscriptionInfo(isPremium: false);

      // Check if it's a lifetime order
      final orders = await client
          .from('subscription_orders')
          .select('is_lifetime')
          .eq('user_id', user.id)
          .eq('status', 'paid')
          .eq('is_lifetime', true)
          .limit(1);

      return SubscriptionInfo(isPremium: true, isLifetime: orders.isNotEmpty);
    }

    final expiresAt = DateTime.tryParse(expiresAtRaw)?.toUtc();
    if (expiresAt == null) return const SubscriptionInfo(isPremium: false);

    final isActive = expiresAt.isAfter(DateTime.now().toUtc());
    if (!isActive) return const SubscriptionInfo(isPremium: false);

    return SubscriptionInfo(
      isPremium: true,
      isLifetime: false,
      expiresAt: expiresAt,
    );
  } catch (_) {
    return _subscriptionInfoFromOrders(client, user.id);
  }
});
