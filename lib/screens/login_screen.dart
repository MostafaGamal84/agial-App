import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import 'otp_screen.dart';
import '../widgets/toast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController(text: 'admin@example.com');
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
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الدخول')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'Ajyal Al-Quran – Mobile Reports',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _loginController,
                    decoration: const InputDecoration(
                      labelText: 'رقم الجوال أو البريد الإلكتروني',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'هذا الحقل مطلوب';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'كلمة المرور',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
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
                                  ),
                                ),
                              );
                            }
                          },
                    child: auth.isLoading
                        ? const CircularProgressIndicator.adaptive()
                        : const Text('إرسال رمز التحقق'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
