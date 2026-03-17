import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/auth_controller.dart';
import '../controllers/report_controller.dart';
import '../models/circle_report.dart';
import '../models/report_stats.dart';
import '../models/student.dart';
import '../models/user.dart';
import '../services/report_service.dart';
import '../theme/app_colors.dart';
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
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  int _currentTab = 0;
  bool _isLoadingFilters = false;
  List<UserProfile> _teachers = const [];
  List<Student> _students = const [];
  String? _selectedTeacherId;
  int? _selectedStudentId;
  DateTime? _selectedMonth;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = context.read<AuthController>().currentUser;
      if (user != null) {
        await _initializeScreen(user);
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
        .push(MaterialPageRoute(builder: (_) => ReportFormScreen(currentUser: user)))
        .then((_) {
      if (mounted) _applyFilters(user);
    });
  }

  Future<void> _initializeScreen(UserProfile user) async {
    setState(() => _isLoadingFilters = true);
    try {
      await _loadTeachersForFilters(user);
      await _loadStudentsForFilters(user);
      await _applyFilters(user, updateState: false);
    } catch (e) {
      if (mounted) {
        showToast(context, e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingFilters = false);
      }
    }
  }

  Future<ReportDisplayRow> _resolveFullReportRow(ReportDisplayRow row) async {
    if (row.report.id.isEmpty) {
      return row;
    }

    try {
      final fullReport = await context.read<ReportService>().fetchReport(row.report.id);
      return row.copyWith(report: fullReport);
    } catch (_) {
      return row;
    }
  }

  Future<void> _loadTeachersForFilters(UserProfile user) async {
    final reportService = context.read<ReportService>();

    if (user.isTeacher) {
      _selectedTeacherId = user.id;
      _teachers = const [];
      return;
    }

    if (user.isStudent) {
      _teachers = const [];
      _selectedTeacherId = null;
      return;
    }

    if (user.isManager) {
      _teachers = await reportService.fetchTeachers(managerId: user.id);
    } else if (user.isBranchLeader) {
      _teachers = await reportService.fetchTeachers(branchId: user.branchId);
    } else if (user.isAdmin) {
      _teachers = await reportService.fetchTeachers();
    } else {
      _teachers = const [];
    }

    if (_selectedTeacherId != null && !_teachers.any((teacher) => teacher.id == _selectedTeacherId)) {
      _selectedTeacherId = null;
    }
  }

  Future<void> _loadStudentsForFilters(UserProfile user) async {
    final reportService = context.read<ReportService>();

    if (user.isStudent) {
      _students = const [];
      _selectedStudentId = null;
      return;
    }

    final teacherId = user.isTeacher ? user.id : _selectedTeacherId;
    final managerId = !user.isTeacher && teacherId == null && user.isManager ? user.id : null;
    final branchId = !user.isTeacher && !user.isManager && user.isBranchLeader ? user.branchId : null;

    _students = await reportService.fetchStudentsForSelects(
      teacherId: teacherId,
      managerId: managerId,
      branchId: branchId,
    );

    if (_selectedStudentId != null && !_students.any((student) => student.id == _selectedStudentId)) {
      _selectedStudentId = null;
    }
  }

  Future<void> _applyFilters(UserProfile user, {bool updateState = true}) async {
    final controller = context.read<ReportController>();
    controller.teacherId = user.isTeacher ? user.id : _selectedTeacherId;
    controller.studentId = _selectedStudentId;
    controller.month = _selectedMonth;
    await controller.refresh(user);
    if (mounted && updateState) {
      setState(() {});
    }
  }

  Future<void> _applyDrawerFilters(
    UserProfile user, {
    String? teacherId,
    int? studentId,
    DateTime? month,
  }) async {
    setState(() {
      if (!user.isTeacher && !user.isStudent) {
        _selectedTeacherId = teacherId;
      }
      _selectedStudentId = null;
      _selectedMonth = month;
      _isLoadingFilters = true;
    });

    try {
      await _loadStudentsForFilters(user);

      if (!user.isStudent &&
          studentId != null &&
          _students.any((student) => student.id == studentId)) {
        _selectedStudentId = studentId;
      }

      await _applyFilters(user, updateState: false);
    } catch (e) {
      if (mounted) {
        showToast(context, e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingFilters = false);
      }
    }
  }

  int _activeFilterCount(UserProfile user) {
    var count = 0;
    if (!user.isTeacher && !user.isStudent && _selectedTeacherId != null) {
      count++;
    }
    if (!user.isStudent && _selectedStudentId != null) {
      count++;
    }
    if (_selectedMonth != null) {
      count++;
    }
    return count;
  }

  void _openFilters() {
    FocusScope.of(context).unfocus();
    _scaffoldKey.currentState?.openEndDrawer();
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

    final activeFilterCount = _activeFilterCount(user);

    return PageTransitionWrapper(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(_currentTab == 0 ? 'الإحصائيات' : 'التقارير'),
          actions: [
            IconButton(
              onPressed: _openFilters,
              tooltip: activeFilterCount > 0
                  ? 'الفلاتر ($activeFilterCount)'
                  : 'الفلاتر',
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.tune_rounded, semanticLabel: 'الفلاتر'),
                  if (activeFilterCount > 0)
                    Positioned(
                      top: -4,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$activeFilterCount',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: _logout,
              tooltip: 'تسجيل الخروج',
              icon: const Icon(Icons.logout, semanticLabel: 'تسجيل الخروج'),
            ),
          ],
        ),
        endDrawer: _FiltersDrawer(
          user: user,
          teachers: _teachers,
          initialStudents: _students,
          initialSelectedTeacherId: _selectedTeacherId,
          initialSelectedStudentId: _selectedStudentId,
          initialMonth: _selectedMonth,
          onApply: (teacherId, studentId, month) =>
              _applyDrawerFilters(
            user,
            teacherId: teacherId,
            studentId: studentId,
            month: month,
          ),
        ),
        endDrawerEnableOpenDragGesture: false,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: user.isStudent
            ? null
            : FloatingActionButton(
                onPressed: _openAddReport,
                tooltip: 'إضافة تقرير',
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                elevation: 6,
                child: const Icon(Icons.add, size: 36, semanticLabel: 'إضافة تقرير'),
              ),
        bottomNavigationBar: _BottomNavBar(
          currentIndex: _currentTab,
          onChanged: (index) => setState(() => _currentTab = index),
        ),
        body: _currentTab == 0
            ? _DashboardView(
                stats: controller.stats,
                isLoading: controller.isLoading || _isLoadingFilters,
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
                    _applyFilters(user);
                  });
                },
                onClearSearch: () {
                  _searchController.clear();
                  controller.search = '';
                  _applyFilters(user);
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

    final resolvedRow = await _resolveFullReportRow(row);
    final reportText = buildWhatsAppPayload(resolvedRow);
    final whatsappUri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(reportText)}');

    final opened = await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    if (opened) return;

    await Clipboard.setData(ClipboardData(text: reportText));
    if (mounted) {
      showToast(
        context,
        'تعذر فتح واتساب مباشرة. تم نسخ نص التقرير ويمكنك لصقه يدويًا.',
        isError: true,
      );
    }
  }
}
class _DashboardView extends StatelessWidget {
  const _DashboardView({required this.stats, required this.isLoading});

  final ReportStats stats;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading && stats.totalReports == 0) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    final totalCount = stats.totalReports;
    final attended = stats.attendedCount;
    final excused = stats.excusedAbsenceCount;
    final unexcused = stats.unexcusedAbsenceCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatCard(label: 'إجمالي التقارير', value: '$totalCount', icon: Icons.copy_all_rounded),
              _StatCard(label: 'حضور', value: '$attended', icon: Icons.check_circle_outline, iconColor: AppColors.success),
              _StatCard(label: 'غياب بعذر', value: '$excused', icon: Icons.error_outline, iconColor: AppColors.info),
              _StatCard(label: 'غياب بدون عذر', value: '$unexcused', icon: Icons.cancel_outlined, iconColor: AppColors.danger),
            ].map((e) => SizedBox(width: (MediaQuery.sizeOf(context).width - 44) / 2, child: e)).toList(),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('إجمالي التقارير', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 16),
                  _AttendanceBarChart(attended: attended, excused: excused, unexcused: unexcused),
                  const SizedBox(height: 8),
                  Text('إجمالي الحالات الحالية: $totalCount', style: Theme.of(context).textTheme.labelMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _FiltersDrawer extends StatefulWidget {
  const _FiltersDrawer({
    required this.user,
    required this.teachers,
    required this.initialStudents,
    required this.initialSelectedTeacherId,
    required this.initialSelectedStudentId,
    required this.initialMonth,
    required this.onApply,
  });

  final UserProfile user;
  final List<UserProfile> teachers;
  final List<Student> initialStudents;
  final String? initialSelectedTeacherId;
  final int? initialSelectedStudentId;
  final DateTime? initialMonth;
  final Future<void> Function(String? teacherId, int? studentId, DateTime? month)
      onApply;

  @override
  State<_FiltersDrawer> createState() => _FiltersDrawerState();
}

class _FiltersDrawerState extends State<_FiltersDrawer> {
  late String? _selectedTeacherId;
  late int? _selectedStudentId;
  late DateTime? _selectedMonth;
  late List<Student> _students;
  bool _isLoadingStudents = false;
  bool _isApplying = false;

  bool get _showTeacherFilter =>
      !widget.user.isTeacher && !widget.user.isStudent;

  bool get _showStudentFilter => !widget.user.isStudent;

  String? get _selectedTeacherName {
    if (_selectedTeacherId == null) {
      return null;
    }

    for (final teacher in widget.teachers) {
      if (teacher.id == _selectedTeacherId) {
        return teacher.fullName;
      }
    }

    return 'المعلم المحدد';
  }

  String? get _selectedStudentName {
    if (_selectedStudentId == null) {
      return null;
    }

    for (final student in _students) {
      if (student.id == _selectedStudentId) {
        return student.fullName;
      }
    }

    return 'الطالب المحدد';
  }

  String get _monthLabel {
    if (_selectedMonth == null) {
      return 'كل الشهور';
    }
    return '${_selectedMonth!.month.toString().padLeft(2, '0')}/${_selectedMonth!.year}';
  }

  @override
  void initState() {
    super.initState();
    _selectedTeacherId = widget.initialSelectedTeacherId;
    _selectedStudentId = widget.initialSelectedStudentId;
    _selectedMonth = widget.initialMonth;
    _students = widget.initialStudents;

    if (_showStudentFilter && _students.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadStudents());
    }
  }

  Future<void> _loadStudents() async {
    if (!_showStudentFilter) {
      return;
    }

    setState(() => _isLoadingStudents = true);

    try {
      final teacherId = widget.user.isTeacher ? widget.user.id : _selectedTeacherId;
      final managerId = !widget.user.isTeacher &&
              teacherId == null &&
              widget.user.isManager
          ? widget.user.id
          : null;
      final branchId = !widget.user.isTeacher &&
              !widget.user.isManager &&
              widget.user.isBranchLeader
          ? widget.user.branchId
          : null;

      final students = await context.read<ReportService>().fetchStudentsForSelects(
            teacherId: teacherId,
            managerId: managerId,
            branchId: branchId,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _students = students;
        if (_selectedStudentId != null &&
            !_students.any((student) => student.id == _selectedStudentId)) {
          _selectedStudentId = null;
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingStudents = false);
      }
    }
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth ?? now,
      firstDate: DateTime(now.year - 3, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: 'اختر شهرًا',
      fieldHintText: 'يوم/شهر/سنة',
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _selectedMonth = DateTime(picked.year, picked.month, 1);
    });
  }

  Future<void> _apply() async {
    setState(() => _isApplying = true);
    try {
      await widget.onApply(_selectedTeacherId, _selectedStudentId, _selectedMonth);
      if (mounted) {
        Navigator.of(context).maybePop();
      }
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }

  Future<void> _resetLocalFilters() async {
    setState(() {
      if (_showTeacherFilter) {
        _selectedTeacherId = null;
      }
      if (_showStudentFilter) {
        _selectedStudentId = null;
      }
      _selectedMonth = null;
    });

    if (_showStudentFilter) {
      await _loadStudents();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeFilterCount =
        (_showTeacherFilter && _selectedTeacherId != null ? 1 : 0) +
        (_showStudentFilter && _selectedStudentId != null ? 1 : 0) +
        (_selectedMonth != null ? 1 : 0);

    InputDecoration decoration(String label, IconData icon, String hint) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: AppColors.primary,
          semanticLabel: label,
        ),
        filled: true,
        fillColor: AppColors.surface1,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      );
    }

    return Drawer(
      width: 360,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.primary,
                      semanticLabel: 'فلاتر التقارير',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'فلاتر التقارير',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          activeFilterCount > 0
                              ? '$activeFilterCount فلتر نشط'
                              : 'اختر الفلاتر ثم اضغط تطبيق',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.text2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'إغلاق الفلاتر',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      semanticLabel: 'إغلاق الفلاتر',
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_showTeacherFilter) ...[
                      DropdownButtonFormField<String?>(
                        value: _selectedTeacherId,
                        isExpanded: true,
                        menuMaxHeight: 360,
                        decoration: decoration(
                          'المعلم',
                          Icons.person_outline_rounded,
                          'اختر المعلم',
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('كل المعلمين'),
                          ),
                          ...widget.teachers.map(
                            (teacher) => DropdownMenuItem<String?>(
                              value: teacher.id,
                              child: Text(teacher.fullName),
                            ),
                          ),
                        ],
                        onChanged: _isApplying
                            ? null
                            : (value) async {
                                setState(() {
                                  _selectedTeacherId = value;
                                  _selectedStudentId = null;
                                });
                                await _loadStudents();
                              },
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_showStudentFilter) ...[
                      DropdownButtonFormField<int?>(
                        value: _selectedStudentId,
                        isExpanded: true,
                        menuMaxHeight: 360,
                        decoration: decoration(
                          'الطالب',
                          Icons.school_outlined,
                          'اختر الطالب',
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('كل الطلاب'),
                          ),
                          ..._students.map(
                            (student) => DropdownMenuItem<int?>(
                              value: student.id,
                              child: Text(student.fullName),
                            ),
                          ),
                        ],
                        onChanged: _isApplying || _isLoadingStudents
                            ? null
                            : (value) => setState(() => _selectedStudentId = value),
                      ),
                      if (_isLoadingStudents) ...[
                        const SizedBox(height: 10),
                        const LinearProgressIndicator(minHeight: 2),
                      ],
                      const SizedBox(height: 12),
                    ],
                    _FilterActionTile(
                      label: 'الشهر',
                      value: _monthLabel,
                      icon: Icons.calendar_month_outlined,
                      onTap: _isApplying ? null : _pickMonth,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_showTeacherFilter && _selectedTeacherId != null)
                          _ActiveFilterChip(
                            label: 'المعلم: ${_selectedTeacherName ?? 'المحدد'}',
                            icon: Icons.person_outline_rounded,
                            onDeleted: _isApplying
                                ? null
                                : () async {
                                    setState(() {
                                      _selectedTeacherId = null;
                                      _selectedStudentId = null;
                                    });
                                    await _loadStudents();
                                  },
                          ),
                        if (_showStudentFilter && _selectedStudentId != null)
                          _ActiveFilterChip(
                            label: 'الطالب: ${_selectedStudentName ?? 'المحدد'}',
                            icon: Icons.school_outlined,
                            onDeleted: _isApplying
                                ? null
                                : () => setState(() => _selectedStudentId = null),
                          ),
                        if (_selectedMonth != null)
                          _ActiveFilterChip(
                            label: 'الشهر: $_monthLabel',
                            icon: Icons.calendar_month_outlined,
                            onDeleted: _isApplying
                                ? null
                                : () => setState(() => _selectedMonth = null),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isApplying ? null : _resetLocalFilters,
                      child: const Text('مسح الكل'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isApplying ? null : _apply,
                      child: _isApplying
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('تطبيق الفلاتر'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterActionTile extends StatelessWidget {
  const _FilterActionTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label: $value',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: AppColors.primary,
                    semanticLabel: label,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: onTap == null ? AppColors.text3 : AppColors.primary,
                  semanticLabel: 'فتح اختيار $label',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({
    required this.label,
    required this.icon,
    required this.onDeleted,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      avatar: Icon(
        icon,
        size: 18,
        color: AppColors.primary,
        semanticLabel: label,
      ),
      label: Text(label),
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppColors.border),
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        color: AppColors.text1,
      ),
      deleteIcon: const Icon(
        Icons.close_rounded,
        size: 18,
        semanticLabel: 'إزالة الفلتر',
      ),
      onDeleted: onDeleted,
    );
  }
}

class _AttendanceBarChart extends StatelessWidget {
  const _AttendanceBarChart({required this.attended, required this.excused, required this.unexcused});

  final int attended;
  final int excused;
  final int unexcused;

  @override
  Widget build(BuildContext context) {
    final maxValue = [attended, excused, unexcused, 1].reduce(math.max).toDouble();

    return SizedBox(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BarItem(label: 'حضور', value: attended, maxValue: maxValue, color: const Color(0xFFBDE8B9)),
          _BarItem(label: 'بعذر', value: excused, maxValue: maxValue, color: const Color(0xFF9E8B56)),
          _BarItem(label: 'بدون عذر', value: unexcused, maxValue: maxValue, color: const Color(0xFF356D62)),
        ],
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({required this.label, required this.value, required this.maxValue, required this.color});

  final String label;
  final int value;
  final double maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final normalized = value / maxValue;
    final h = math.max(18.0, normalized * 150);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('$value', style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Container(
          width: 48,
          height: h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
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
              prefixIcon: const Icon(Icons.search, semanticLabel: 'بحث'),
              suffixIcon: IconButton(
                tooltip: 'مسح البحث',
                icon: const Icon(Icons.clear, semanticLabel: 'مسح البحث'),
                onPressed: onClearSearch,
              ),
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
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurface.withOpacity(0.3),
                            semanticLabel: 'لا توجد تقارير',
                          ),
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
                          subtitle: Text('${getCircleName(row)} - ${formatDate(row.report.creationTime)}'),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                tooltip: 'عرض التقرير',
                                icon: const Icon(
                                  Icons.remove_red_eye_outlined,
                                  semanticLabel: 'عرض التقرير',
                                ),
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => ReportDetailsScreen(row: row, currentUser: user)),
                                ),
                              ),
                              IconButton(
                                tooltip: 'إرسال عبر واتساب',
                                icon: const Icon(
                                  Icons.share_outlined,
                                  semanticLabel: 'إرسال عبر واتساب',
                                ),
                                onPressed: () => onSendWhatsApp(row),
                              ),
                              if (controller.canManageReports) ...[
                                IconButton(
                                  tooltip: 'تعديل التقرير',
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    semanticLabel: 'تعديل التقرير',
                                  ),
                                  onPressed: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => ReportFormScreen(currentUser: user, existingReport: row.report)),
                                    );
                                    if (context.mounted) context.read<ReportController>().refresh(user);
                                  },
                                ),
                                IconButton(
                                  tooltip: 'حذف التقرير',
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    semanticLabel: 'حذف التقرير',
                                  ),
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
  const _StatCard({required this.label, required this.value, required this.icon, this.iconColor});

  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface3,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: iconColor ?? AppColors.primary,
              semanticLabel: label,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.text2)),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: AppColors.text1)),
              ],
            ),
          )
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
    final inactive = AppColors.primary.withOpacity(0.75);
    const active = AppColors.primary;

    return Material(
      color: Colors.white,
      elevation: 10,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              Expanded(
                child: Center(
                  child: IconButton(
                    onPressed: () => onChanged(0),
                    tooltip: 'الإحصائيات',
                    icon: Icon(
                      Icons.bar_chart_rounded,
                      color: currentIndex == 0 ? active : inactive,
                      size: 30,
                      semanticLabel: 'الإحصائيات',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 72),
              Expanded(
                child: Center(
                  child: IconButton(
                    onPressed: () => onChanged(1),
                    tooltip: 'التقارير',
                    icon: Icon(
                      Icons.description_outlined,
                      color: currentIndex == 1 ? active : inactive,
                      size: 30,
                      semanticLabel: 'التقارير',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
