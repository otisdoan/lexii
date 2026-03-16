import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/subscription/subscription_providers.dart';
import 'package:lexii/features/settings/presentation/pages/payment_result_page.dart';
import 'package:lexii/features/settings/presentation/pages/upgrade_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _InMemoryAsyncStorage extends GotrueAsyncStorage {
  final Map<String, String> _store = {};

  @override
  Future<String?> getItem({required String key}) async => _store[key];

  @override
  Future<void> removeItem({required String key}) async {
    _store.remove(key);
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    _store[key] = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;

    await Supabase.initialize(
      url: 'https://bkkpaaacxftqlidaxnml.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJra3BhYWFjeGZ0cWxpZGF4bm1sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxODQzMzQsImV4cCI6MjA4Nzc2MDMzNH0.NJ23R9N-1cn3OtpZgacoy28K_bbNZUXkE9AZ31I2HqI',
      authOptions: FlutterAuthClientOptions(
        detectSessionInUri: false,
        localStorage: const EmptyLocalStorage(),
        pkceAsyncStorage: _InMemoryAsyncStorage(),
      ),
    );
  });

  testWidgets('Upgrade page renders key UI blocks', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isPremiumProvider.overrideWith((ref) async => false),
        ],
        child: const MaterialApp(home: UpgradePage()),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Nâng cấp Premium'), findsOneWidget);
    expect(find.text('Chọn gói phù hợp với bạn'), findsOneWidget);
    expect(find.text('Nâng cấp gói đã chọn'), findsOneWidget);
  });

  testWidgets('Payment result success UI renders', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PaymentResultPage(status: 'success'),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Thanh toán thành công!'), findsOneWidget);
    expect(find.text('Về trang chủ'), findsOneWidget);
  });

  testWidgets('Payment result failed UI renders retry action', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PaymentResultPage(status: 'failed'),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Thanh toán thất bại'), findsOneWidget);
    expect(find.text('Quay lại nâng cấp'), findsOneWidget);
  });
}
