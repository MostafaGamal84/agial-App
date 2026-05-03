import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/user.dart';
import '../theme/app_colors.dart';
import '../widgets/page_transition_wrapper.dart';
import '../widgets/toast.dart';

class TeacherDetailsScreen extends StatelessWidget {
  const TeacherDetailsScreen({
    super.key,
    required this.teacher,
  });

  final UserProfile teacher;

  Future<void> _callPhone(BuildContext context) async {
    if (teacher.mobile.isEmpty) {
      showToast(context, 'رقم الهاتف غير متوفر', isError: true);
      return;
    }

    final uri = Uri(scheme: 'tel', path: teacher.mobile);
    try {
      await launchUrl(uri);
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: teacher.mobile));
      if (context.mounted) {
        showToast(context, 'تم نسخ رقم الهاتف');
      }
    }
  }

  Future<void> _sendWhatsApp(BuildContext context) async {
    if (teacher.mobile.isEmpty) {
      showToast(context, 'رقم الهاتف غير متوفر', isError: true);
      return;
    }

    final cleanPhone = teacher.mobile.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('whatsapp://send?phone=$cleanPhone');
    
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        showToast(context, 'تعذر فتح واتساب', isError: true);
      }
    }
  }

  Future<void> _sendEmail(BuildContext context) async {
    if (teacher.email.isEmpty) {
      showToast(context, 'البريد الإلكتروني غير متوفر', isError: true);
      return;
    }

    final uri = Uri(scheme: 'mailto', path: teacher.email);
    try {
      await launchUrl(uri);
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: teacher.email));
      if (context.mounted) {
        showToast(context, 'تم نسخ البريد الإلكتروني');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageTransitionWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل المعلم'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _TeacherHeader(teacher: teacher),
              const SizedBox(height: 24),
              _ContactActions(
                onCall: () => _callPhone(context),
                onWhatsApp: () => _sendWhatsApp(context),
                onEmail: () => _sendEmail(context),
              ),
              const SizedBox(height: 16),
              _DetailsCard(teacher: teacher),
              const SizedBox(height: 16),
              _QuickStatsCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeacherHeader extends StatelessWidget {
  const _TeacherHeader({required this.teacher});

  final UserProfile teacher;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
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
              teacher.fullName.isNotEmpty ? teacher.fullName[0].toUpperCase() : 'T',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          teacher.fullName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green),
          ),
          child: const Text(
            'معلم',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ContactActions extends StatelessWidget {
  const _ContactActions({
    required this.onCall,
    required this.onWhatsApp,
    required this.onEmail,
  });

  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onEmail;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ActionItem(
              icon: Icons.phone,
              label: 'اتصال',
              color: Colors.green,
              onTap: onCall,
            ),
            _ActionItem(
              icon: Icons.chat,
              label: 'واتساب',
              color: Colors.teal,
              onTap: onWhatsApp,
            ),
            _ActionItem(
              icon: Icons.email,
              label: 'بريد',
              color: Colors.blue,
              onTap: onEmail,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.teacher});

  final UserProfile teacher;

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
                Icon(Icons.info_outline, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'معلومات المعلم',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _DetailRow(
              icon: Icons.badge_outlined,
              label: 'الاسم',
              value: teacher.fullName,
            ),
            _DetailRow(
              icon: Icons.email_outlined,
              label: 'البريد الإلكتروني',
              value: teacher.email.isNotEmpty ? teacher.email : 'غير متوفر',
            ),
            _DetailRow(
              icon: Icons.phone_outlined,
              label: 'رقم الجوال',
              value: teacher.mobile.isNotEmpty ? teacher.mobile : 'غير متوفر',
            ),
            if (teacher.branchName != null && teacher.branchName!.isNotEmpty)
              _DetailRow(
                icon: Icons.business_outlined,
                label: 'الفرع',
                value: teacher.branchName!,
              ),
            if (teacher.managerName != null && teacher.managerName!.isNotEmpty)
              _DetailRow(
                icon: Icons.supervisor_account_outlined,
                label: 'المشرف',
                value: teacher.managerName!,
              ),
            if (teacher.qualification != null && teacher.qualification!.isNotEmpty)
              _DetailRow(
                icon: Icons.school_outlined,
                label: 'المؤهل',
                value: teacher.qualification!,
              ),
            if (teacher.department != null && teacher.department!.isNotEmpty)
              _DetailRow(
                icon: Icons.category_outlined,
                label: 'القسم',
                value: teacher.department!,
              ),
            if (teacher.createdDate != null)
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'تاريخ التسجيل',
                value: _formatDate(teacher.createdDate!),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
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

class _QuickStatsCard extends StatelessWidget {
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
                Icon(Icons.analytics_outlined, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'إحصائيات سريعة',
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
                  child: _StatItem(
                    icon: Icons.people_outline,
                    value: '0',
                    label: 'الطلاب',
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.description_outlined,
                    value: '0',
                    label: 'التقارير',
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.check_circle_outline,
                    value: '0%',
                    label: 'الحضور',
                    color: Colors.orange,
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

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.text2,
            ),
          ),
        ],
      ),
    );
  }
}
