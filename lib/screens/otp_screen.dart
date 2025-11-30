import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import 'reports_screen.dart';
import '../widgets/toast.dart';

class OTPScreen extends StatefulWidget {
  const OTPScreen({super.key, required this.loginValue});

  final String loginValue;

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _formKey = GlobalKey<FormState>();
  late final List<TextEditingController> _otpControllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _otpControllers = List.generate(4, (_) => TextEditingController());
    _focusNodes = List.generate(4, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _otpControllers.map((controller) => controller.text).join();

  void _onOtpChanged(int index, String value, FormFieldState<String> field) {
    if (value.length > 1) {
      _otpControllers[index]
        ..text = value.substring(value.length - 1)
        ..selection = const TextSelection.collapsed(offset: 1);
    }

    if (value.isNotEmpty && index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    field.didChange(_otpCode);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 30),
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/favicon.ico',
                        height: 72,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'AJYAL AL-QURAN',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onBackground,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    'كود التحقق',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onBackground,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    'تم إرسال الرمز إلى ${widget.loginValue}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.75),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                FormField<String>(
                  validator: (value) {
                    if (_otpCode.length != 4) {
                      return 'أدخل الرمز المكون من 4 أرقام';
                    }
                    return null;
                  },
                  builder: (field) => Column(
                    children: [
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _otpControllers.length,
                            (index) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: SizedBox(
                                width: 60,
                                child: TextField(
                                  controller: _otpControllers[index],
                                  focusNode: _focusNodes[index],
                                  autofocus: index == 0,
                                  textAlign: TextAlign.center,
                                  textDirection: TextDirection.ltr,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.surface,
                                    contentPadding:
                                        const EdgeInsets.symmetric(vertical: 14),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.2),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Theme.of(context).colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(1),
                                  ],
                                  onChanged: (value) =>
                                      _onOtpChanged(index, value, field),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (field.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            field.errorText!,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    'لم تتسلم كود؟ إعادة إرساله',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          final user = await auth.verify(_otpCode);
                          if (!mounted) return;
                          if (auth.errorMessage != null) {
                            showToast(
                              context,
                              auth.errorMessage!,
                              isError: true,
                            );
                            return;
                          }
                          if (user != null) {
                            showToast(
                              context,
                              'تم تسجيل الدخول بنجاح',
                            );
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const ReportsScreen(),
                              ),
                              (_) => false,
                            );
                          }
                        },
                  child: auth.isLoading
                      ? const CircularProgressIndicator.adaptive()
                      : const Text(
                          'تحقق',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
