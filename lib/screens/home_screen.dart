import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/report_controller.dart';
import '../models/circle_report.dart';
import '../models/report_stats.dart';
import '../models/user.dart';
import '../models/student.dart';
import '../services/api_client.dart';
import '../services/report_service.dart';
import '../services/app_service.dart';
import '../theme/app_colors.dart';
import '../widgets/page_transition_wrapper.dart';
import '../widgets/toast.dart';
import 'login_screen.dart';
import 'report_details_screen.dart';
import 'report_form_screen.dart';
import 'teachers_list_screen.dart';
import 'students_list_screen.dart';
import 'courses_list_screen.dart';
import 'more_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  
  late ReportController _reportController;
  late ReportService _reportService;
  
  List<ReportDisplayRow> _reports = [];
  ReportStats _stats = ReportStats(attendedCount: 0, excusedAbsenceCount: 0, unexcusedAbsenceCount: 0, totalReports: 0);
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _pageIndex = 0;
  String? _selectedTeacherId;
  int? _selectedStudentId;
  DateTime? _selectedMonth;
  List<UserProfile> _teachers = [];
  List<Student> _students = [];

  @override
  void initState() {
    super.initState();
    _reportService = ReportService(context.read<ApiClient>());
    _reportController = ReportController(_reportService);
    _scrollController.addListener(_onScroll);
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = context.read<AuthController>().currentUser;
      if (user != null) {
        await _initializeScreen(user);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _initializeScreen(UserProfile user) async {
    setState(() => _isLoading = true);
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
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadTeachersForFilters(UserProfile user) async {
    if (user.isTeacher) {
      _selectedTeacherId = user.id;
      _teachers = [];
      return;
    }

    if (user.isStudent) {
      _teachers = [];
      _selectedTeacherId = null;
      return;
    }

    try {
      if (user.isManager) {
        _teachers = await _reportService.fetchTeachers(managerId: user.id);
      } else if (user.isBranchLeader) {
        _teachers = await _reportService.fetchTeachers(branchId: user.branchId);
      } else if (user.isAdmin) {
        _teachers = await _reportService.fetchTeachers();
      }
    } catch (_) {
      _teachers = [];
    }
  }

  Future<void> _loadStudentsForFilters(UserProfile user) async {
    if (user.isStudent) {
      _students = [];
      _selectedStudentId = null;
      return;
    }

    try {
      final teacherId = user.isTeacher ? user.id : _selectedTeacherId;
      final managerId = !user.isTeacher && teacherId == null && user.isManager ? user.id : null;
      final branchId = !user.isTeacher && !user.isManager && user.isBranchLeader ? user.branchId : null;

      _students = await _reportService.fetchStudentsForSelects(
        teacherId: teacherId,
        managerId: managerId,
        branchId: branchId,
      );
    } catch (_) {
      _students = [];
    }
  }

  Future<void> _applyFilters(UserProfile user, {bool updateState = true}) async {
    _reportController.teacherId = user.isTeacher ? user.id : _selectedTeacherId;
    _reportController.studentId = _selectedStudentId;
    _reportController.month = _selectedMonth;
    await _reportController.refresh(user);
    
    if (mounted && updateState) {
      setState(() {});
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
      _pageIndex++;
    });

    try {
      final user = context.read<AuthController>().currentUser;
      if (user == null) return;

      final result = await _reportService.fetchReports(
        currentUser: user,
        pageIndex: _pageIndex,
        search: _searchController.text,
        teacherId: user.isTeacher ? user.id : _selectedTeacherId,
        studentId: _selectedStudentId,
        month: _selectedMonth,
      );

      if (mounted) {
        setState(() {
          _reports.addAll(result.items);
          _hasMore = result.items.length >= 10;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final user = context.read<AuthController>().currentUser;
      if (user != null) {
        setState(() => _pageIndex = 0);
        try {
          final result = await _reportService.fetchReports(
            currentUser: user,
            pageIndex: 0,
            search: value,
            teacherId: user.isTeacher ? user.id : _selectedTeacherId,
            studentId: _selectedStudentId,
            month: _selectedMonth,
          );
          if (mounted) {
            setState(() {
              _reports = result.items;
              _hasMore = result.items.length >= 10;
            });
          }
        } catch (_) {}
      }
    });
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
      if (mounted) _refreshReports(user);
    });
  }

  Future<void> _refreshReports(UserProfile user) async {
    setState(() => _pageIndex = 0);
    try {
      final result = await _reportService.fetchReports(
        currentUser: user,
        pageIndex: 0,
        search: _searchController.text,
        teacherId: user.isTeacher ? user.id : _selectedTeacherId,
        studentId: _selectedStudentId,
        month: _selectedMonth,
      );
      if (mounted) {
        setState(() {
          _reports = result.items;
          _hasMore = result.items.length >= 10;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    _stats = _reportController.stats;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PageTransitionWrapper(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(_getTitle()),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              tooltip: 'الفلاتر',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'تسجيل الخروج',
            ),
          ],
        ),
        endDrawer: _FiltersDrawer(
          user: user,
          teachers: _teachers,
          students: _students,
          selectedTeacherId: _selectedTeacherId,
          selectedStudentId: _selectedStudentId,
          selectedMonth: _selectedMonth,
          onApply: (teacherId, studentId, month) async {
            setState(() {
              _selectedTeacherId = teacherId;
              _selectedStudentId = studentId;
              _selectedMonth = month;
              _pageIndex = 0;
            });
            await _loadStudentsForFilters(user);
            await _applyFilters(user);
            await _refreshReports(user);
          },
        ),
        floatingActionButton: user.isStudent
            ? null
            : FloatingActionButton(
                onPressed: _openAddReport,
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.add),
              ),
        bottomNavigationBar: _BottomNavBar(
          currentIndex: _currentIndex,
          onChanged: (index) => setState(() => _currentIndex = index),
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _DashboardView(
              stats: _stats,
              isLoading: _isLoading,
            ),
            _ReportsListView(
              reports: _reports,
              user: user,
              isLoading: _isLoading,
              isLoadingMore: _isLoadingMore,
              searchController: _searchController,
              scrollController: _scrollController,
              onSearchChanged: _onSearchChanged,
              onClearSearch: () {
                _searchController.clear();
                _onSearchChanged('');
              },
              onDelete: (id) => _delete(id, user),
            ),
            _UsersView(user: user),
            _MoreView(),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'الرئيسية';
      case 1:
        return 'التقارير';
      case 2:
        return 'المستخدمين';
      case 3:
        return 'المزيد';
      default:
        return 'أجيال القرآن';
    }
  }

  Future<void> _delete(String id, UserProfile user) async {
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
      await _reportService.deleteReport(id);
      if (mounted) {
        showToast(context, 'تم حذف التقرير');
        await _refreshReports(user);
      }
    } catch (e) {
      if (mounted) showToast(context, e.toString(), isError: true);
    }
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({required this.stats, required this.isLoading});

  final ReportStats stats;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalCount = stats.totalReports;
    final attended = stats.attendedCount;
    final excused = stats.excusedAbsenceCount;
    final unexcused = stats.unexcusedAbsenceCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatCard(label: 'إجمالي التقارير', value: '$totalCount', icon: Icons.copy_all, color: Colors.blue),
              _StatCard(label: 'حضور', value: '$attended', icon: Icons.check_circle, color: Colors.green),
              _StatCard(label: 'غياب بعذر', value: '$excused', icon: Icons.error, color: Colors.orange),
              _StatCard(label: 'غياب بدون عذر', value: '$unexcused', icon: Icons.cancel, color: Colors.red),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'نسبة الحضور',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  if (totalCount > 0)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: attended / totalCount,
                        minHeight: 20,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation(Colors.green),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    totalCount > 0
                        ? '${((attended / totalCount) * 100).toStringAsFixed(1)}%'
                        : '0%',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 44) / 2,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.text2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportsListView extends StatelessWidget {
  const _ReportsListView({
    required this.reports,
    required this.user,
    required this.isLoading,
    required this.isLoadingMore,
    required this.searchController,
    required this.scrollController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onDelete,
  });

  final List<ReportDisplayRow> reports;
  final UserProfile user;
  final bool isLoading;
  final bool isLoadingMore;
  final TextEditingController searchController;
  final ScrollController scrollController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final void Function(String) onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'بحث عن طالب...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: onClearSearch,
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: onSearchChanged,
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : reports.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text('لا توجد تقارير'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: reports.length + (isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= reports.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final row = reports[index];
                        return ListTile(
                          title: Text(row.studentName),
                          subtitle: Text('${row.circleName} - ${_formatDate(row.report.creationTime)}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ReportDetailsScreen(row: row, currentUser: user),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}

class _UsersView extends StatelessWidget {
  const _UsersView({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    if (!user.canViewUsers) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('ليس لديك صلاحية لعرض المستخدمين'),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MenuCard(
          icon: Icons.people,
          title: 'المعلمون',
          subtitle: 'عرض قائمة المعلمين',
          color: Colors.blue,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TeachersListScreen()),
            );
          },
        ),
        const SizedBox(height: 12),
        _MenuCard(
          icon: Icons.school,
          title: 'الطلاب',
          subtitle: 'عرض قائمة الطلاب',
          color: Colors.orange,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StudentsListScreen()),
            );
          },
        ),
        const SizedBox(height: 12),
        _MenuCard(
          icon: Icons.circle_outlined,
          title: 'الحلقات والدورات',
          subtitle: 'عرض الحلقات والدورات',
          color: Colors.purple,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CoursesListScreen()),
            );
          },
        ),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
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
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}

class _MoreView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MoreScreen();
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.currentIndex, required this.onChanged});

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onChanged,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.text2,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
        BottomNavigationBarItem(icon: Icon(Icons.description), label: 'التقارير'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'المستخدمين'),
        BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'المزيد'),
      ],
    );
  }
}

class _FiltersDrawer extends StatefulWidget {
  const _FiltersDrawer({
    required this.user,
    required this.teachers,
    required this.students,
    required this.selectedTeacherId,
    required this.selectedStudentId,
    required this.selectedMonth,
    required this.onApply,
  });

  final UserProfile user;
  final List<UserProfile> teachers;
  final List<Student> students;
  final String? selectedTeacherId;
  final int? selectedStudentId;
  final DateTime? selectedMonth;
  final Future<void> Function(String?, int?, DateTime?) onApply;

  @override
  State<_FiltersDrawer> createState() => _FiltersDrawerState();
}

class _FiltersDrawerState extends State<_FiltersDrawer> {
  late String? _selectedTeacherId;
  late int? _selectedStudentId;
  late DateTime? _selectedMonth;
  List<Student> _students = [];

  @override
  void initState() {
    super.initState();
    _selectedTeacherId = widget.selectedTeacherId;
    _selectedStudentId = widget.selectedStudentId;
    _selectedMonth = widget.selectedMonth;
    _students = widget.students;
  }

  String get _monthLabel {
    if (_selectedMonth == null) return 'اختر الشهر';
    return '${_selectedMonth!.month}/${_selectedMonth!.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'فلاتر التقارير',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (!widget.user.isTeacher && !widget.user.isStudent) ...[
                    DropdownButtonFormField<String?>(
                      value: _selectedTeacherId,
                      decoration: const InputDecoration(
                        labelText: 'المعلم',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('الكل')),
                        ...widget.teachers.map((t) => DropdownMenuItem(value: t.id, child: Text(t.fullName))),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedTeacherId = value;
                          _selectedStudentId = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (!widget.user.isStudent) ...[
                    DropdownButtonFormField<int?>(
                      value: _selectedStudentId,
                      decoration: const InputDecoration(
                        labelText: 'الطالب',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('الكل')),
                        ..._students.map((s) => DropdownMenuItem(value: s.id, child: Text(s.fullName))),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedStudentId = value);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  ListTile(
                    title: const Text('الشهر'),
                    subtitle: Text(_monthLabel),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _pickMonth,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedTeacherId = null;
                          _selectedStudentId = null;
                          _selectedMonth = null;
                        });
                      },
                      child: const Text('مسح'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await widget.onApply(_selectedTeacherId, _selectedStudentId, _selectedMonth);
                        if (mounted) Navigator.pop(context);
                      },
                      child: const Text('تطبيق'),
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

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month, 1);
      });
    }
  }
}
