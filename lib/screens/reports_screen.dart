import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/report_controller.dart';
import '../models/circle_report.dart';
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
  Timer? _debounce;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = context.read<AuthController>().currentUser;
      if (user != null) {
        await context.read<ReportController>().refresh(user);
      }
    });
  }

  void _onScroll() {
    final c = context.read<ReportController>();
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
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

    await context.read<AuthController>().logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _openAddReport() {
    final user = context.read<AuthController>().currentUser;
    if (user == null) return;
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => ReportFormScreen(currentUser: user),
    ))
        .then((_) {
      if (mounted) context.read<ReportController>().refresh(user);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final controller = context.watch<ReportController>();
    final user = auth.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PageTransitionWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentTab == 0 ? 'الإحصائيات' : 'التقارير'),
          actions: [
            IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              tooltip: 'تسجيل الخروج',
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: user.isStudent
            ? null
            : FloatingActionButton(
                onPressed: _openAddReport,
                backgroundColor: const Color(0xFF8E825B),
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                elevation: 8,
                child: const Icon(Icons.add, size: 34),
              ),
        bottomNavigationBar: _BottomNavBar(
          currentIndex: _currentTab,
          onChanged: (index) => setState(() => _currentTab = index),
        ),
        body: _currentTab == 0
            ? _DashboardView(
                totalCount: controller.totalCount,
                reports: controller.reports,
                isLoading: controller.isLoading,
              )
            : _ReportsListView(
                controller: controller,
                user: user,
                searchController: _searchController,
                scrollController: _scrollController,
                onSearchChanged: (v) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300), () {
                    controller.search = v;
                    controller.refresh(user);
                  });
                },
                onClearSearch: () {
                  _searchController.clear();
                  controller.search = '';
                  controller.refresh(user);
                },
                onDelete: (id) => _delete(id, user),
                onSendWhatsApp: _sendWhatsApp,
              ),
      ),
    );
  }

  Future<void> _delete(String id, UserProfile user) async {
    if (id.isEmpty) {
      showToast(context, 'لا يمكن حذف تقرير بدون معرّف', isError: true);
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف التقرير'),
        content: const Text('هل أنت متأكد من حذف التقرير؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await context.read<ReportService>().deleteReport(id);
      if (mounted) {
        showToast(context, 'تم حذف التقرير');
        await context.read<ReportController>().refresh(user);
      }
    } catch (e) {
      if (mounted) showToast(context, e.toString(), isError: true);
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
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({
    required this.totalCount,
    required this.reports,
    required this.isLoading,
  });

  final int totalCount;
  final List<ReportDisplayRow> reports;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading && reports.isEmpty) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    final attended = reports.where((r) => r.report.attendStatueId == AttendStatus.attended).length;
    final excused = reports.where((r) => r.report.attendStatueId == AttendStatus.ExcusedAbsence).length;
    final unexcused = reports.where((r) => r.report.attendStatueId == AttendStatus.UnexcusedAbsence).length;
    final loadedTotal = math.max(1, reports.length);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatCard(label: 'إجمالي التقارير', value: '$totalCount', icon: Icons.description_outlined),
              _StatCard(label: 'حضر', value: '$attended', icon: Icons.check_circle_outline, iconColor: const Color(0xFF4CAF50)),
              _StatCard(label: 'تغيب بعذر', value: '$excused', icon: Icons.info_outline, iconColor: const Color(0xFF03A9F4)),
              _StatCard(label: 'تغيب بدون عذر', value: '$unexcused', icon: Icons.cancel_outlined, iconColor: const Color(0xFFE53935)),
            ].map((e) => SizedBox(width: (MediaQuery.sizeOf(context).width - 44) / 2, child: e)).toList(),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('توزيع حالات الحضور', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 16),
                  _MiniBar(title: 'حضر', count: attended, color: const Color(0xFF4CAF50), maxValue: loadedTotal),
                  _MiniBar(title: 'غياب بعذر', count: excused, color: const Color(0xFF03A9F4), maxValue: loadedTotal),
                  _MiniBar(title: 'غياب بدون عذر', count: unexcused, color: const Color(0xFFE53935), maxValue: loadedTotal),
                  const SizedBox(height: 8),
                  Text(
                    'ملحوظة: الشارت مبني على التقارير المحمّلة حالياً (${reports.length}) من أصل ($totalCount).',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportsListView extends StatelessWidget {
  const _ReportsListView({
    required this.controller,
    required this.user,
    required this.searchController,
    required this.scrollController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onDelete,
    required this.onSendWhatsApp,
  });

  final ReportController controller;
  final UserProfile user;
  final TextEditingController searchController;
  final ScrollController scrollController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onDelete;
  final ValueChanged<ReportDisplayRow> onSendWhatsApp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'بحث عن طالب...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(icon: const Icon(Icons.clear), onPressed: onClearSearch),
            ),
            onChanged: onSearchChanged,
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
                      controller: scrollController,
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
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_red_eye_outlined),
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ReportDetailsScreen(row: row, currentUser: user),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.share_outlined),
                                onPressed: () => onSendWhatsApp(row),
                              ),
                              if (controller.canManageReports) ...[
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ReportFormScreen(currentUser: user, existingReport: row.report),
                                      ),
                                    );
                                    if (context.mounted) {
                                      context.read<ReportController>().refresh(user);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => onDelete(row.report.id),
                                ),
                              ]
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  const _MiniBar({
    required this.title,
    required this.count,
    required this.color,
    required this.maxValue,
  });

  final String title;
  final int count;
  final Color color;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    final progress = (count / maxValue).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              Text(title),
              const Spacer(),
              Text('$count'),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.currentIndex, required this.onChanged});

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final inactive = Colors.white70;
    final active = const Color(0xFF8E825B);

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: () => onChanged(0),
              icon: Icon(Icons.bar_chart_rounded, color: currentIndex == 0 ? active : inactive),
            ),
            IconButton(
              onPressed: () => onChanged(1),
              icon: Icon(Icons.list_alt_rounded, color: currentIndex == 1 ? active : inactive),
            ),
            const SizedBox(width: 36),
            IconButton(
              onPressed: () => onChanged(1),
              icon: Icon(Icons.description_outlined, color: currentIndex == 1 ? active : inactive),
            ),
            IconButton(
              onPressed: () => onChanged(0),
              icon: Icon(Icons.person_outline_rounded, color: currentIndex == 0 ? active : inactive),
            ),
          ],
        ),
      ),
    );
  }
}
