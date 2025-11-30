import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../widgets/page_transition_wrapper.dart';
import 'otp_screen.dart';
import '../widgets/toast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController(text: 'admin@test.com');
  final _passwordController = TextEditingController();

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
        backgroundColor: Theme.of(context).colorScheme.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(48),
                        child: Image.asset(
                          'assets/images/favicon.ico',
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const [
                          Text(
                            'أهلاً بعودتك',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'أدخل بياناتك لتسجيل الدخول إلى حسابك',
                            style: TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    _StyledField(
                      controller: _loginController,
                      label: 'البريد الإلكتروني',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'هذا الحقل مطلوب';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _StyledField(
                      controller: _passwordController,
                      label: 'كلمة المرور',
                      obscureText: true,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.tertiary,
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text('نسيت كلمة المرور'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: auth.isLoading
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              await auth.login(
                                _loginController.text,
                                password: _passwordController.text,
                              );
                              if (!mounted) return;
                              if (auth.errorMessage != null) {
                                showToast(
                                  context,
                                  auth.errorMessage!,
                                  isError: true,
                                );
                                return;
                              }
                              if (auth.codeSent) {
                                showToast(
                                  context,
                                  'تم إرسال رمز التحقق بنجاح',
                                );
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => OTPScreen(
                                      loginValue: _loginController.text,
                                      initialCode: auth.pendingOtpCode,
                                    ),
                                  ),
                                );
                              }
                            },
                      child: auth.isLoading
                          ? const CircularProgressIndicator.adaptive(
                              backgroundColor: Colors.white,
                            )
                          : const Text(
                              'تسجيل الدخول',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ],
                ),
              ),
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
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.child, required this.backgroundColor});

  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: child,
    );
  }
}
