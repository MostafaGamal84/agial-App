import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/report_controller.dart';
import '../models/circle_report.dart';
import '../models/user.dart';
import '../services/report_service.dart';
import '../widgets/report_filters.dart';
import '../widgets/toast.dart';
import 'login_screen.dart';
import 'report_details_screen.dart';
import 'report_form_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String? _lastErrorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthController>();
      final controller = context.read<ReportController>();
      final user = auth.currentUser;
      if (user != null) {
        await controller.restoreFilter(user);
        if (!mounted) return;
        await controller.refresh(user);
      }
    });
  }

  void _maybeShowError(String? message) {
    if (message == null) {
      _lastErrorMessage = null;
      return;
    }
    if (_lastErrorMessage == message) return;
    _lastErrorMessage = message;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showToast(context, message, isError: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final controller = context.watch<ReportController>();
    final user = auth.currentUser;

    _maybeShowError(controller.errorMessage);

    if (user == null) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقارير الحلقات'),
        actions: [
          IconButton(
            onPressed: () => _logout(auth),
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
          )
        ],
      ),
      drawer: _ReportsDrawer(
        currentUser: user,
        onLogout: () => _logout(auth),
        onAddReport: () => _openReportForm(user),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openReportForm(user),
        icon: const Icon(Icons.add),
        label: const Text('إضافة تقرير'),
      ),
      body: Column(
        children: [
          ReportFilters(
            currentUser: user,
            reportService: context.read<ReportService>(),
            initialFilter: controller.filter,
            onChanged: (newFilter) {
              controller.updateFilter(newFilter, user);
            },
          ),
          Expanded(
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator.adaptive())
                : controller.reports.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.insert_chart_outlined, size: 64, color: Colors.black38),
                          SizedBox(height: 12),
                          Text('لا توجد تقارير بعد', style: TextStyle(fontSize: 16)),
                          SizedBox(height: 4),
                          Text('جرّب تعديل المرشحات أو إضافة تقرير جديد',
                              style: TextStyle(color: Colors.black54)),
                        ],
                      )
                    : RefreshIndicator(
                        onRefresh: () => controller.refresh(user),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          itemBuilder: (context, index) {
                            final row = controller.reports[index];
                            return _ReportCard(
                              row: row,
                              onEdit: () async {
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ReportFormScreen(
                                      currentUser: user,
                                      existingReport: row.report,
                                    ),
                                  ),
                                );
                                if (!mounted) return;
                                if (result is String && result.isNotEmpty) {
                                  showToast(context, result);
                                }
                                controller.refresh(user);
                              },
                              onView: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ReportDetailsScreen(row: row),
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemCount: controller.reports.length,
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(AuthController auth) async {
    await auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _openReportForm(UserProfile user) async {
    final controller = context.read<ReportController>();
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportFormScreen(currentUser: user),
      ),
    );
    if (!mounted) return;
    if (result is String && result.isNotEmpty) {
      showToast(context, result);
    }
    controller.refresh(user);
  }
}

class _ReportsDrawer extends StatelessWidget {
  const _ReportsDrawer({
    required this.currentUser,
    required this.onAddReport,
    required this.onLogout,
  });

  final UserProfile currentUser;
  final VoidCallback onAddReport;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'تطبيق تقارير الحلقات',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const CircleAvatar(
                        child: Icon(Icons.person_outline),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUser.fullName.isEmpty
                                  ? 'مستخدم غير معروف'
                                  : currentUser.fullName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              currentUser.userType.label,
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('عرض التقارير'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('إضافة تقرير'),
              onTap: () async {
                Navigator.of(context).pop();
                await Future<void>.delayed(const Duration(milliseconds: 200));
                onAddReport();
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('تسجيل الخروج'),
              onTap: () async {
                Navigator.of(context).pop();
                await Future<void>.delayed(const Duration(milliseconds: 200));
                onLogout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.row, required this.onEdit, required this.onView});

  final ReportDisplayRow row;
  final VoidCallback onEdit;
  final VoidCallback onView;

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final twoDigits = (int value) => value.toString().padLeft(2, '0');
    return '${local.year}/${twoDigits(local.month)}/${twoDigits(local.day)}';
  }

  Color _statusColor(AttendStatus status) {
    switch (status) {
      case AttendStatus.attended:
        return Colors.green.shade600;
      case AttendStatus.ExcusedAbsence:
        return Colors.orange.shade700;
      case AttendStatus.UnexcusedAbsence:
        return Colors.red.shade700;
    }
  }

  Widget _buildMetaRow(IconData icon, String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, height: 1.4),
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(text: value),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 1,
      color: Colors.grey.shade200,
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentName = row.studentName.isEmpty ? 'طالب غير معروف' : row.studentName;
    final teacherName = row.teacherName.isEmpty ? 'معلم غير معروف' : row.teacherName;
    final circleName = row.circleName.isEmpty ? 'حلقة غير معروفة' : row.circleName;
    final report = row.report;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(studentName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(circleName, style: TextStyle(color: Colors.grey.shade700)),
                      Text(teacherName, style: TextStyle(color: Colors.grey.shade700)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: _statusColor(report.attendStatueId).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Text(
                        report.attendStatueId.label,
                        style: TextStyle(
                          color: _statusColor(report.attendStatueId),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_formatDate(report.creationTime), style: TextStyle(color: Colors.grey.shade600)),
                  ],
                )
              ],
            ),
            _buildDivider(),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                if (report.minutes != null)
                  Chip(
                    avatar: const Icon(Icons.timer_outlined, size: 18),
                    label: Text('${report.minutes} دقيقة'),
                    backgroundColor: Colors.grey.shade100,
                  ),
                if (report.newId != null)
                  Chip(
                    avatar: const Icon(Icons.bookmark_border, size: 18),
                    label: Text('الجزء الجديد رقم ${report.newId}'),
                    backgroundColor: Colors.grey.shade100,
                  ),
              ],
            ),
            if ((report.newFrom ?? '').isNotEmpty || (report.newTo ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildMetaRow(
                  Icons.menu_book_outlined,
                  'الجديد',
                  '${report.newFrom ?? ''}${report.newFrom != null && report.newTo != null ? ' → ' : ''}${report.newTo ?? ''}',
                ),
              ),
            if ((report.recentPast ?? '').isNotEmpty || (report.recentPastRate ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _buildMetaRow(
                  Icons.history_toggle_off,
                  'القريب',
                  _combineText(report.recentPast, report.recentPastRate),
                ),
              ),
            if ((report.distantPast ?? '').isNotEmpty || (report.distantPastRate ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _buildMetaRow(
                  Icons.auto_stories_outlined,
                  'البعيد',
                  _combineText(report.distantPast, report.distantPastRate),
                ),
              ),
            if ((report.farthestPast ?? '').isNotEmpty || (report.farthestPastRate ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _buildMetaRow(
                  Icons.menu_book,
                  'الأبعد',
                  _combineText(report.farthestPast, report.farthestPastRate),
                ),
              ),
            if ((report.theWordsQuranStranger ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _buildMetaRow(
                  Icons.translate,
                  'غريب القرآن',
                  report.theWordsQuranStranger ?? '',
                ),
              ),
            if ((report.intonation ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _buildMetaRow(
                  Icons.graphic_eq,
                  'التجويد',
                  report.intonation ?? '',
                ),
              ),
            if ((report.other ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _buildMetaRow(
                  Icons.notes,
                  'ملاحظات',
                  report.other ?? '',
                ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('تعديل التقرير'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onView,
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('عرض التفاصيل'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _combineText(String? value, String? rate) {
    final parts = [value, rate].where((element) => element != null && element!.trim().isNotEmpty).map((e) => e!.trim()).toList();
    return parts.join(' — ');
  }
}
