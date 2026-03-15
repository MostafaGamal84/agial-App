import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/page_transition_wrapper.dart';
import '../widgets/toast.dart';
import 'reports_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController(text: 'admin@test.com');
  final _passwordController = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return PageTransitionWrapper(
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 360,
                      color: AppColors.primary,
                      child: const _TopGridOverlay(),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 360,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/app_icon.png',
                            width: 180,
                            height: 110,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'أجيال القرآن',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 46,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'برجاء إدخال البريد الإلكتروني وكلمة السر',
                            style: TextStyle(color: Colors.white70, fontSize: 20),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _StyledField(
                                controller: _loginController,
                                label: 'البريد الإلكتروني',
                                hintText: 'أدخل اسم المستخدم الخاص بك',
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: const Icon(Icons.mail, color: Color(0xFFAAAAAA)),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'هذا الحقل مطلوب';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              _StyledField(
                                controller: _passwordController,
                                label: 'كلمة السر',
                                hintText: 'أدخل كلمة السر الخاصة بك',
                                obscureText: _hidePassword,
                                prefixIcon: IconButton(
                                  onPressed: () => setState(() => _hidePassword = !_hidePassword),
                                  icon: Icon(_hidePassword ? Icons.visibility : Icons.visibility_off, color: const Color(0xFFAAAAAA)),
                                ),
                              ),
                              const SizedBox(height: 34),
                              ElevatedButton(
                                onPressed: auth.isLoading
                                    ? null
                                    : () async {
                                        if (!_formKey.currentState!.validate()) return;
                                        final user = await auth.login(
                                          _loginController.text,
                                          password: _passwordController.text,
                                        );
                                        if (!mounted) return;
                                        if (auth.errorMessage != null) {
                                          showToast(context, auth.errorMessage!, isError: true);
                                          return;
                                        }
                                        if (user != null) {
                                          showToast(context, 'تم تسجيل الدخول بنجاح');
                                          Navigator.of(context).pushAndRemoveUntil(
                                            MaterialPageRoute(builder: (_) => const ReportsScreen()),
                                            (route) => false,
                                          );
                                        }
                                      },
                                child: auth.isLoading
                                    ? const CircularProgressIndicator.adaptive(backgroundColor: Colors.white)
                                    : const Text('تسجيل الدخول'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text('v 11.0.5', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StyledField extends StatelessWidget {
  const _StyledField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.prefixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      textAlign: TextAlign.right,
      style: const TextStyle(fontSize: 19, color: AppColors.text1),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 18, color: AppColors.text3),
        prefixIcon: prefixIcon,
      ),
    );
  }
}

class _TopGridOverlay extends StatelessWidget {
  const _TopGridOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _TopGridPainter());
  }
}

class _TopGridPainter extends CustomPainter {
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
