import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lexii/core/theme/app_theme.dart';
import 'package:lexii/config/routes/app_router.dart';
import 'package:lexii/config/supabase_config.dart';

void _authLog(String message) {
  debugPrint('[AUTH] $message');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  if (kIsWeb) {
    _authLog('Initial Uri.base = ${Uri.base}');
    if ((Uri.base.queryParameters['code'] ?? '').isNotEmpty) {
      _authLog('OAuth code detected in URL. Waiting for supabase_flutter deeplink handler.');
    }
  }

  // Initialize router
  await AppRouter.init();

  runApp(const ProviderScope(child: LexiiApp()));
}

class LexiiApp extends StatefulWidget {
  const LexiiApp({super.key});

  @override
  State<LexiiApp> createState() => _LexiiAppState();
}

class _LexiiAppState extends State<LexiiApp> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;
  StreamSubscription<AuthState>? _authStateSub;

  @override
  void initState() {
    super.initState();
    _authStateSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final userId = data.session?.user.id ?? 'null';
      _authLog('Auth event: ${data.event.name}, userId: $userId');
    });

    _handleInitialLink();
    _linkSub = _appLinks.uriLinkStream.listen(_handleIncomingUri);
  }

  Future<void> _handleInitialLink() async {
    final uri = await _appLinks.getInitialLink();
    if (uri != null) {
      _handleIncomingUri(uri);
    }
  }

  void _handleIncomingUri(Uri uri) {
    final path = uri.path.toLowerCase();
    final host = uri.host.toLowerCase();

    final isAuthDeepLink =
        path.endsWith('/login-callback') ||
        host == 'login-callback' ||
        path.endsWith('/home') ||
        host == 'home';
    if (isAuthDeepLink) {
      final hasSession = Supabase.instance.client.auth.currentSession != null;
      AppRouter.router.go(hasSession ? '/home' : '/auth/signup');
      return;
    }

    final isPaymentDeepLink =
        path.endsWith('/payment-result') || host == 'payment-result';
    if (!isPaymentDeepLink) return;

    final statusRaw =
        (uri.queryParameters['status'] ?? uri.queryParameters['code'] ?? '')
            .toLowerCase();

    final status = switch (statusRaw) {
      'success' || 'paid' || '00' => 'success',
      'cancel' || 'cancelled' || 'canceled' => 'cancel',
      _ => 'failed',
    };

    final orderCode =
        uri.queryParameters['orderCode'] ?? uri.queryParameters['order_code'];

    final query = orderCode == null || orderCode.isEmpty
        ? 'status=$status'
        : 'status=$status&orderCode=$orderCode';

    AppRouter.router.go('/payment/result?$query');
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    _authStateSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Lexii TOEIC®',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
