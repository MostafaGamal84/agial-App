import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/report_controller.dart';
import '../models/circle_report.dart';
import '../models/user.dart';
import '../services/report_service.dart';
import '../widgets/report_filters.dart';
import 'login_screen.dart';
import 'report_form_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final controller = context.watch<ReportController>();
    final user = auth.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقارير الحلقات'),
        actions: [
          IconButton(
            onPressed: () async {
              await auth.logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReportFormScreen(currentUser: user),
            ),
          );
          if (mounted) {
            controller.refresh(user);
          }
        },
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
          if (controller.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                controller.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator.adaptive())
                : controller.reports.isEmpty
                    ? const Center(child: Text('لا توجد تقارير بعد'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemBuilder: (context, index) {
                          final row = controller.reports[index];
                          return Card(
                            child: ListTile(
                              title: Text(row.studentName.isEmpty ? 'طالب غير معروف' : row.studentName),
                              subtitle: Text(
                                '${row.circleName.isNotEmpty ? row.circleName : 'حلقة غير معروفة'} • ${row.teacherName.isEmpty ? 'معلم غير معروف' : row.teacherName}\n${row.report.attendStatueId.label}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ReportFormScreen(
                                        currentUser: user,
                                        existingReport: row.report,
                                      ),
                                    ),
                                  );
                                  if (mounted) {
                                    controller.refresh(user);
                                  }
                                },
                              ),
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemCount: controller.reports.length,
                      ),
          ),
        ],
      ),
    );
  }
}
