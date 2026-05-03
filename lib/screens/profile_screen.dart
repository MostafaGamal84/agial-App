import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/auth_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/page_transition_wrapper.dart';
import '../widgets/toast.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggingOut = false;

  void _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoggingOut = true);

    try {
      await context.read<AuthController>().logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        showToast(context, 'حدث خطأ أثناء تسجيل الخروج', isError: true);
        setState(() => _isLoggingOut = false);
      }
    }
  }

  Future<void> _callPhone(String? phone) async {
    if (phone == null || phone.isEmpty) {
      showToast(context, 'رقم الهاتف غير متوفر', isError: true);
      return;
    }

    final uri = Uri(scheme: 'tel', path: phone);
    try {
      await launchUrl(uri);
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: phone));
      if (mounted) {
        showToast(context, 'تم نسخ رقم الهاتف');
      }
    }
  }

  Future<void> _sendWhatsApp(String? phone) async {
    if (phone == null || phone.isEmpty) {
      showToast(context, 'رقم الهاتف غير متوفر', isError: true);
      return;
    }

    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('whatsapp://send?phone=$cleanPhone');
    
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      showToast(context, 'تعذر فتح واتساب', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PageTransitionWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الملف الشخصي'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _ProfileHeader(user: user),
              const SizedBox(height: 24),
              _ProfileInfoCard(user: user),
              const SizedBox(height: 16),
              _QuickActionsCard(
                user: user,
                onCall: () => _callPhone(user.mobile),
                onWhatsApp: () => _sendWhatsApp(user.mobile),
              ),
              const SizedBox(height: 16),
              _AppInfoCard(),
              const SizedBox(height: 24),
              _LogoutButton(
                isLoading: _isLoggingOut,
                onPressed: _logout,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final dynamic user;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary,
              width: 3,
            ),
          ),
          child: Center(
            child: Text(
              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user.fullName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _getRoleColor(user.userType.label).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getRoleColor(user.userType.label),
              width: 1,
            ),
          ),
          child: Text(
            user.userType.label,
            style: TextStyle(
              color: _getRoleColor(user.userType.label),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'مدير النظام':
        return Colors.purple;
      case 'مدير الفرع':
        return Colors.indigo;
      case 'مشرف':
        return Colors.blue;
      case 'معلم':
        return Colors.green;
      case 'طالب':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }
}

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({required this.user});

  final dynamic user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person_outline, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'معلومات الحساب',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _InfoRow(
              icon: Icons.badge_outlined,
              label: 'الاسم',
              value: user.fullName,
            ),
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'البريد الإلكتروني',
              value: user.email.isNotEmpty ? user.email : 'غير متوفر',
            ),
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'رقم الجوال',
              value: user.mobile.isNotEmpty ? user.mobile : 'غير متوفر',
            ),
            if (user.branchName != null && user.branchName!.isNotEmpty)
              _InfoRow(
                icon: Icons.business_outlined,
                label: 'الفرع',
                value: user.branchName!,
              ),
            if (user.managerName != null && user.managerName!.isNotEmpty)
              _InfoRow(
                icon: Icons.supervisor_account_outlined,
                label: 'المشرف',
                value: user.managerName!,
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.text2),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.text2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({
    required this.user,
    required this.onCall,
    required this.onWhatsApp,
  });

  final dynamic user;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.quick_contacts_mail_outlined, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'اتصل بنا',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.phone,
                    label: 'اتصال',
                    color: Colors.green,
                    onPressed: onCall,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.chat,
                    label: 'واتساب',
                    color: Colors.teal,
                    onPressed: onWhatsApp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}

class _AppInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'عن التطبيق',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _InfoRow(
              icon: Icons.apps,
              label: 'اسم التطبيق',
              value: 'أجيال القرآن',
            ),
            _InfoRow(
              icon: Icons.numbers,
              label: 'الإصدار',
              value: '11.0.5',
            ),
            _InfoRow(
              icon: Icons.language,
              label: 'اللغة',
              value: 'العربية',
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.logout),
        label: Text(isLoading ? 'جاري تسجيل الخروج...' : 'تسجيل الخروج'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
