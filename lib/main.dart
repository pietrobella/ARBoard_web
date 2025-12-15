import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'router/app_router.dart';

void main() {
  // Remove the # from URLs on web
  usePathUrlStrategy();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ARBoard',
      theme: ThemeData(
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF012035),
          onPrimary: Colors.white,
          primaryContainer: Color(0xFF022840),
          onPrimaryContainer: Colors.white,
          secondary: Color(0xFFFFFFFF),
          onSecondary: Color(0xFF012035),
          tertiary: Color(0xFF8FBABF),
          onTertiary: Color(0xFF012035),
          surface: Color(0xFFFFFFFF),
          onSurface: Color(0xFF012035),
          outline: Color(0xFF666C73),
          error: Colors.red,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF012035),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF012035),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      routerConfig: AppRouter.router,
    );
  }
}
