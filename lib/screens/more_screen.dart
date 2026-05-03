import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/page_transition_wrapper.dart';
import 'membership_screen.dart';
import 'invoice_screen.dart';
import 'teacher_salary_screen.dart';
import 'profile_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;

    return PageTransitionWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المزيد'),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _UserInfoCard(user: user),
            const SizedBox(height: 24),
            const Text(
              'إدارة',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.text2,
              ),
            ),
            const SizedBox(height: 12),
            if (user?.canViewUsers ?? false) ...[
              _MenuItem(
                icon: Icons.people,
                title: 'المعلمون',
                subtitle: 'عرض قائمة المعلمين',
                color: Colors.blue,
                onTap: () => Navigator.of(context).pushNamed('/teachers'),
              ),
              _MenuItem(
                icon: Icons.school,
                title: 'الطلاب',
                subtitle: 'عرض قائمة الطلاب',
                color: Colors.orange,
                onTap: () => Navigator.of(context).pushNamed('/students'),
              ),
            ],
            if (user?.isTeacher == true || user?.isAdmin == true || user?.isBranchLeader == true || user?.isManager == true) ...[
              _MenuItem(
                icon: Icons.attach_money,
                title: 'الرواتب',
                subtitle: 'إدارة رواتب المعلمين',
                color: Colors.green,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TeacherSalaryScreen()),
                  );
                },
              ),
            ],
            _MenuItem(
              icon: Icons.card_membership,
              title: 'العضويات',
              subtitle: 'إدارة العضويات والاشتراكات',
              color: Colors.purple,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MembershipScreen()),
                );
              },
            ),
            _MenuItem(
              icon: Icons.receipt_long,
              title: 'الفواتير',
              subtitle: 'عرض وإدارة الفواتير',
              color: Colors.teal,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const InvoiceScreen()),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'الحساب',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.text2,
              ),
            ),
            const SizedBox(height: 12),
            _MenuItem(
              icon: Icons.person,
              title: 'الملف الشخصي',
              subtitle: 'عرض وتعديل بياناتك الشخصية',
              color: AppColors.primary,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            _MenuItem(
              icon: Icons.settings,
              title: 'الإعدادات',
              subtitle: 'إعدادات التطبيق',
              color: Colors.grey,
              onTap: () => _showSettingsDialog(context),
            ),
            _MenuItem(
              icon: Icons.help_outline,
              title: 'المساعدة',
              subtitle: 'تواصل معنا للدعم الفني',
              color: Colors.indigo,
              onTap: () => _showHelpDialog(context),
            ),
            const SizedBox(height: 24),
            _MenuItem(
              icon: Icons.info_outline,
              title: 'عن التطبيق',
              subtitle: 'معلومات عن التطبيق',
              color: Colors.blueGrey,
              onTap: () => _showAboutDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الإعدادات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('الإشعارات'),
              trailing: Switch(value: true, onChanged: (v) {}),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('اللغة'),
              trailing: const Text('العربية'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('الوضع الليلي'),
              trailing: Switch(value: false, onChanged: (v) {}),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('المساعدة'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.support_agent, size: 64, color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'تواصل معنا للدعم الفني',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'support@ajyalalquran.com',
              style: TextStyle(color: AppColors.primary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('عن التطبيق'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.menu_book,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'أجيال القرآن',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'نسخة الموبايل',
              style: TextStyle(color: AppColors.text2),
            ),
            const SizedBox(height: 4),
            const Text(
              'الإصدار 11.0.5',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'تطبيق لإدارة حلقات ومتابعة تحفيظ القرآن الكريم',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.text2,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}

class _UserInfoCard extends StatelessWidget {
  const _UserInfoCard({required this.user});

  final dynamic user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  user?.fullName?.isNotEmpty == true
                      ? user.fullName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.fullName ?? 'مستخدم',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.userType?.label ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.text2,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.text2,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.text2,
        ),
      ),
    );
  }
}
