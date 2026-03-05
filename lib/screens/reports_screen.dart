import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/report_controller.dart';
import '../models/user.dart';
import '../services/report_service.dart';
import '../utils/report_helpers.dart';
import '../widgets/page_transition_wrapper.dart';
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
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthController>();
      final user = auth.currentUser;
      if (user != null) {
        await context.read<ReportController>().refresh(user);
      }
    });
  }

  void _onScroll() {
    final c = context.read<ReportController>();
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      c.loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _openDrawer() {
    Scaffold.of(context).openDrawer();
  }

  void _onMenuSelected(int index) {
    Navigator.pop(context);
    switch (index) {
      case 0:
        break;
      case 1:
        _openAddReport();
        break;
      case 2:
        _logout();
        break;
    }
  }

  void _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('تسجيل الخروج')),
        ],
      ),
    );
    if (confirmed != true) return;
    
    await context.read<AuthController>().logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _openAddReport() {
    final auth = context.read<AuthController>();
    final user = auth.currentUser;
    if (user == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReportFormScreen(currentUser: user)),
    ).then((_) {
      if (mounted) context.read<ReportController>().refresh(user);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final controller = context.watch<ReportController>();
    final user = auth.currentUser;
    final theme = Theme.of(context);

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Builder(
      builder: (ctx) => Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('تقارير الحلقات'),
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ),
        drawer: _buildDrawer(ctx, user, theme),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: user.isStudent ? null : _openAddReport,
          icon: const Icon(Icons.add),
          label: const Text('تقرير جديد'),
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث عن طالب...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    controller.search = '';
                    controller.refresh(user);
                  },
                ),
              ),
              onChanged: (v) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () {
                  controller.search = v;
                  controller.refresh(user);
                });
              },
            ),
          ),
          Expanded(
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator.adaptive())
                : controller.reports.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text('لا توجد تقارير', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: controller.reports.length + (controller.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= controller.reports.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator.adaptive()),
                            );
                          }
                          final row = controller.reports[index];
                          return ListTile(
                            title: Text(getStudentName(row)),
                            subtitle: Text('${getCircleName(row)} • ${formatDate(row.report.creationTime)}'),
                            trailing: Wrap(spacing: 4, children: [
                              IconButton(
                                icon: const Icon(Icons.remove_red_eye_outlined),
                                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReportDetailsScreen(row: row, currentUser: user))),
                              ),
                              IconButton(
                                icon: const Icon(Icons.share_outlined),
                                onPressed: () => _sendWhatsApp(row),
                              ),
                              if (controller.canManageReports) ...[
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () async {
                                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReportFormScreen(currentUser: user, existingReport: row.report)));
                                    if (mounted) controller.refresh(user);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _delete(row.report.id, user),
                                ),
                              ]
                            ]),
                          );
                        },
                      ),
          )
        ]),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, UserProfile user, ThemeData theme) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.auto_stories_rounded, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'أجيال القرآن',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.fullName.isEmpty ? 'مستخدم' : user.fullName,
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500),
                  ),
                  Text(
                    user.userType.label,
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.list_alt, color: theme.colorScheme.primary),
              title: const Text('التقارير'),
              selected: true,
              onTap: () => _onMenuSelected(0),
            ),
            if (!user.isStudent)
              ListTile(
                leading: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
                title: const Text('إضافة تقرير'),
                onTap: () => _onMenuSelected(1),
              ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: theme.colorScheme.error),
              title: Text('تسجيل الخروج', style: TextStyle(color: theme.colorScheme.error)),
              onTap: () => _onMenuSelected(2),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(String id, UserProfile user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف التقرير'),
        content: const Text('هل انت متاكد من حذف التقرير؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    );
    if (ok != true) return;
    await context.read<ReportService>().deleteReport(id);
    if (mounted) {
      showToast(context, 'تم حذف التقرير');
      context.read<ReportController>().refresh(user);
    }
  }

  Future<void> _sendWhatsApp(ReportDisplayRow row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إرسال التقرير عبر واتساب'),
        content: const Text('تأكيد إنشاء نص الرسالة ومشاركته؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('إرسال')),
        ],
      ),
    );
    if (confirmed != true) return;
    await Clipboard.setData(ClipboardData(text: buildWhatsAppPayload(row)));
    if (mounted) showToast(context, 'تم نسخ نص التقرير للمشاركة عبر واتساب');
  }

  Future<void> _openForm(UserProfile user) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReportFormScreen(currentUser: user)));
    if (mounted) context.read<ReportController>().refresh(user);
  }
}
