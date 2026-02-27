import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexii/core/theme/app_theme.dart';
import 'package:lexii/config/routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize router
  await AppRouter.init();

  runApp(const ProviderScope(child: LexiiApp()));
}

class LexiiApp extends StatelessWidget {
  const LexiiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Lexii IELTS®',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
