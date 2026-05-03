import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/page_transition_wrapper.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
    _startTransition();
  }

  void _startTransition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();

      void listener() {
        if (!auth.isRestoring) {
          auth.removeListener(listener);
          _goToNext(auth);
        }
      }

      auth.addListener(listener);
      if (!auth.isRestoring) {
        auth.removeListener(listener);
        _goToNext(auth);
      }
    });
  }

  Future<void> _goToNext(AuthController auth) async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    final nextPage = auth.currentUser == null ? const LoginScreen() : const HomeScreen();

    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => nextPage));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageTransitionWrapper(
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Stack(
          children: [
            const Positioned.fill(child: _GridOverlay()),
            SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Image.asset('assets/images/app_icon.png', fit: BoxFit.contain),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'أجيال القرآن',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'نرتقي بالحلقات',
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridOverlay extends StatelessWidget {
  const _GridOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter());
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1;

    const space = 44.0;
    for (double x = 0; x <= size.width; x += space) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y <= size.height; y += space) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
