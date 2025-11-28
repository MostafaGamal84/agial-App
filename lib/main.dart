import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'controllers/report_controller.dart';
import 'screens/login_screen.dart';
import 'screens/reports_screen.dart';
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
    return MaterialApp(
      title: 'Ajyal Al-Quran Reports',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00695C)),
        useMaterial3: true,
        textTheme: GoogleFonts.tajawalTextTheme(),
        fontFamily: GoogleFonts.tajawal().fontFamily,
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(),
        ),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: auth.currentUser == null ? const LoginScreen() : const ReportsScreen(),
    );
  }
}
