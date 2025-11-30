import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'controllers/report_controller.dart';
import 'screens/splash_screen.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/report_service.dart';

void main() {
  final apiClient = ApiClient();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>(
          create: (_) => AuthController(AuthService(apiClient)),
        ),
        Provider<ReportService>(create: (_) => ReportService(apiClient)),
        ChangeNotifierProvider<ReportController>(
          create: (context) => ReportController(context.read<ReportService>()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    const seedColor = Color(0xFF7C3AED);
    const secondaryColor = Color(0xFFC3A56A);
    const tertiaryColor = Color(0xFF22C55E);
    const backgroundColor = Color(0xFF0F1622);
    const surfaceColor = Color(0xFF172233);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    ).copyWith(
      secondary: secondaryColor,
      onSecondary: Colors.black87,
      tertiary: tertiaryColor,
      onPrimary: Colors.white,
      onTertiary: Colors.white,
      background: backgroundColor,
      onBackground: Colors.white,
      surface: surfaceColor,
      onSurface: Colors.white,
    );

    return MaterialApp(
      title: 'Ajyal Al-Quran Reports',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: backgroundColor,
        useMaterial3: true,
        textTheme: GoogleFonts.cairoTextTheme()
            .apply(bodyColor: Colors.white, displayColor: Colors.white),
        fontFamily: GoogleFonts.cairo().fontFamily,
        appBarTheme: AppBarTheme(
          backgroundColor: surfaceColor,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: surfaceColor,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.06)),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: secondaryColor,
          foregroundColor: Colors.black87,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: seedColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.onSurface,
            side: BorderSide(color: Colors.white.withOpacity(0.2)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1F2937),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: seedColor, width: 1.6),
          ),
          labelStyle: const TextStyle(color: Colors.white70),
        ),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashScreen(),
    );
  }
}
