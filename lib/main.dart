import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'controllers/report_controller.dart';
import 'screens/splash_screen.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/report_service.dart';
import 'services/app_service.dart';
import 'theme/app_theme.dart';

void main() {
  final apiClient = ApiClient();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>(
          create: (_) => AuthController(AuthService(apiClient)),
        ),
        Provider<ApiClient>(create: (_) => apiClient),
        Provider<ReportService>(create: (_) => ReportService(apiClient)),
        Provider<AppService>(create: (_) => AppService(apiClient)),
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
    return MaterialApp(
      title: 'أجيال القرآن',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      darkTheme: darkTheme,
      theme: darkTheme,
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
