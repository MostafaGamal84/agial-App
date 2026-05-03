import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/auth_controller.dart';
import '../models/salary.dart';
import '../services/app_service.dart';
import '../theme/app_colors.dart';
import '../widgets/page_transition_wrapper.dart';
import '../widgets/toast.dart';

class TeacherSalaryScreen extends StatefulWidget {
  const TeacherSalaryScreen({super.key});

  @override
  State<TeacherSalaryScreen> createState() => _TeacherSalaryScreenState();
}

class _TeacherSalaryScreenState extends State<TeacherSalaryScreen> {
  final _scrollController = ScrollController();
  
  List<SalaryRecord> _salaries = [];
  SalarySummary? _summary;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _pageIndex = 0;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  AppService _getAppService() {
    return context.read<AppService>();
  }

  Future<void> _loadData({bool reset = false}) async {
    if (reset) {
      setState(() {
        _pageIndex = 0;
        _salaries = [];
        _hasMore = true;
        _isLoading = true;
      });
    } else if (_isLoading && _salaries.isEmpty) {
      // Continue loading
    } else if (_salaries.isNotEmpty && !reset) {
      return; // Already loaded
    }

    try {
      final user = context.read<AuthController>().currentUser;
      final appService = _getAppService();
      
      List<SalaryRecord> newSalaries;
      SalarySummary? summaryData;

      if (user != null) {
        if (user.isTeacher) {
          newSalaries = await appService.fetchSalaries(
            teacherId: user.id,
            month: _selectedMonth,
            year: _selectedYear,
            status: _selectedStatus,
            pageIndex: _pageIndex,
          );
          summaryData = await appService.fetchSalarySummary(
            teacherId: user.id,
            month: _selectedMonth,
            year: _selectedYear,
          );
        } else {
          newSalaries = await appService.fetchSalaries(
            month: _selectedMonth,
            year: _selectedYear,
            status: _selectedStatus,
            pageIndex: _pageIndex,
          );
          summaryData = await appService.fetchSalarySummary(
            month: _selectedMonth,
            year: _selectedYear,
          );
        }
      } else {
        newSalaries = await appService.fetchSalaries(
          month: _selectedMonth,
          year: _selectedYear,
          status: _selectedStatus,
          pageIndex: _pageIndex,
        );
        summaryData = await appService.fetchSalarySummary(
          month: _selectedMonth,
          year: _selectedYear,
        );
      }

      if (mounted) {
        setState(() {
          if (reset) {
            _salaries = newSalaries;
          } else {
            _salaries.addAll(newSalaries);
          }
          _summary = summaryData;
          _hasMore = newSalaries.length >= 50;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showToast(context, 'حدث خطأ في تحميل البيانات', isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
      _pageIndex++;
    });
    await _loadData();
  }

  void _filterByMonth(int month, int year) {
    setState(() {
      _selectedMonth = month;
      _selectedYear = year;
    });
    _loadData(reset: true);
  }

  void _filterByStatus(String? status) {
    setState(() {
      _selectedStatus = status;
    });
    _loadData(reset: true);
  }

  Future<void> _refresh() async {
    await _loadData(reset: true);
  }

  Future<void> _callTeacher(String? phone) async {
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

  void _showMonthPicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_selectedYear, _selectedMonth),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );

    if (picked != null) {
      _filterByMonth(picked.month, picked.year);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageTransitionWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('رواتب المعلمين'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: _showMonthPicker,
              tooltip: 'اختر الشهر',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              onSelected: _filterByStatus,
              itemBuilder: (context) => [
                const PopupMenuItem(value: null, child: Text('الكل')),
                const PopupMenuItem(value: '1', child: Text('معلق')),
                const PopupMenuItem(value: '2', child: Text('موافق عليه')),
                const PopupMenuItem(value: '3', child: Text('مدفوع')),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            _MonthSelector(
              month: _selectedMonth,
              year: _selectedYear,
              onTap: _showMonthPicker,
            ),
            if (_summary != null) _SummarySection(summary: _summary!),
            Expanded(
              child: _isLoading && _salaries.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _salaries.isEmpty
                      ? _EmptyState(onRefresh: _refresh)
                      : RefreshIndicator(
                          onRefresh: _refresh,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _salaries.length + (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= _salaries.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }

                              final salary = _salaries[index];
                              return _SalaryCard(
                                salary: salary,
                                onTap: () => _showSalaryDetails(salary),
                                onCall: () => _callTeacher(salary.teacherMobile),
                                onWhatsApp: () => _sendWhatsApp(salary.teacherMobile),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSalaryDetails(SalaryRecord salary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SalaryDetailsSheet(
        salary: salary,
        onCall: () => _callTeacher(salary.teacherMobile),
        onWhatsApp: () => _sendWhatsApp(salary.teacherMobile),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.month,
    required this.year,
    required this.onTap,
  });

  final int month;
  final int year;
  final VoidCallback onTap;

  String get _monthName {
    const months = [
      '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${months[month]} $year';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              _monthName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_drop_down, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.summary});

  final SalarySummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              icon: Icons.people,
              label: 'عدد المعلمين',
              value: '${summary.totalTeachers}',
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCard(
              icon: Icons.paid,
              label: 'إجمالي الرواتب',
              value: '${summary.totalSalaries.toStringAsFixed(0)} ج.م',
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCard(
              icon: Icons.check_circle,
              label: 'المدفوع',
              value: '${summary.totalPaid.toStringAsFixed(0)} ج.م',
              color: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SalaryCard extends StatelessWidget {
  const _SalaryCard({
    required this.salary,
    required this.onTap,
    required this.onCall,
    required this.onWhatsApp,
  });

  final SalaryRecord salary;
  final VoidCallback onTap;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _getStatusColor(salary.status).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        salary.teacherName.isNotEmpty 
                            ? salary.teacherName[0].toUpperCase() 
                            : 'T',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(salary.status),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          salary.teacherName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          salary.branchName ?? 'غير محدد',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.text2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      _StatusBadge(status: salary.status),
                      const SizedBox(height: 8),
                      Text(
                        '${salary.netSalary.toStringAsFixed(0)} ج.م',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(salary.status),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.people,
                      value: '${salary.studentCount} طالب',
                    ),
                  ),
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.check_circle,
                      value: '${salary.attendanceCount} حضور',
                      color: Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.description,
                      value: '${salary.reportsCount} تقرير',
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              if (salary.teacherMobile != null && salary.teacherMobile!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.phone, color: Colors.green),
                      onPressed: onCall,
                      tooltip: 'اتصال',
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat, color: Colors.teal),
                      onPressed: onWhatsApp,
                      tooltip: 'واتساب',
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(SalaryStatus status) {
    switch (status) {
      case SalaryStatus.pending:
        return Colors.orange;
      case SalaryStatus.approved:
        return Colors.blue;
      case SalaryStatus.paid:
        return Colors.green;
      case SalaryStatus.rejected:
        return Colors.red;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final SalaryStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case SalaryStatus.pending:
        color = Colors.orange;
        label = 'معلق';
        break;
      case SalaryStatus.approved:
        color = Colors.blue;
        label = 'موافق عليه';
        break;
      case SalaryStatus.paid:
        color = Colors.green;
        label = 'مدفوع';
        break;
      case SalaryStatus.rejected:
        color = Colors.red;
        label = 'مرفوض';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color ?? AppColors.text2),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color ?? AppColors.text2,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.money_off_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد رواتب',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لم يتم تسجيل رواتب لهذا الشهر',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة تحميل'),
          ),
        ],
      ),
    );
  }
}

class _SalaryDetailsSheet extends StatelessWidget {
  const _SalaryDetailsSheet({
    required this.salary,
    required this.onCall,
    required this.onWhatsApp,
  });

  final SalaryRecord salary;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: _getStatusColor(salary.status).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    salary.teacherName.isNotEmpty 
                        ? salary.teacherName[0].toUpperCase() 
                        : 'T',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(salary.status),
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
                      salary.teacherName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      salary.monthName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.text2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (salary.teacherMobile != null && salary.teacherMobile!.isNotEmpty)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onCall,
                    icon: const Icon(Icons.phone),
                    label: const Text('اتصال'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onWhatsApp,
                    icon: const Icon(Icons.chat),
                    label: const Text('واتساب'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
          _SalaryBreakdownSection(salary: salary),
          const SizedBox(height: 16),
          _DetailsSection(
            title: 'التفاصيل',
            children: [
              _DetailRow('عدد الطلاب', '${salary.studentCount}'),
              _DetailRow('عدد الحضور', '${salary.attendanceCount}'),
              _DetailRow('عدد التقارير', '${salary.reportsCount}'),
              if (salary.branchName != null)
                _DetailRow('الفرع', salary.branchName!),
              if (salary.managerName != null)
                _DetailRow('المشرف', salary.managerName!),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(SalaryStatus status) {
    switch (status) {
      case SalaryStatus.pending:
        return Colors.orange;
      case SalaryStatus.approved:
        return Colors.blue;
      case SalaryStatus.paid:
        return Colors.green;
      case SalaryStatus.rejected:
        return Colors.red;
    }
  }
}

class _SalaryBreakdownSection extends StatelessWidget {
  const _SalaryBreakdownSection({required this.salary});

  final SalaryRecord salary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Text(
            'صافي الراتب',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.text2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${salary.netSalary.toStringAsFixed(2)} ج.م',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _AmountItem(label: 'الراتب الأساسي', amount: salary.baseSalary),
              _AmountItem(label: 'البدلات', amount: salary.allowances, isPositive: true),
              _AmountItem(label: 'الخصومات', amount: salary.deductions, isNegative: true),
              _AmountItem(label: 'المكافآت', amount: salary.bonuses, isPositive: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountItem extends StatelessWidget {
  const _AmountItem({
    required this.label,
    required this.amount,
    this.isPositive = false,
    this.isNegative = false,
  });

  final String label;
  final double amount;
  final bool isPositive;
  final bool isNegative;

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.text2;
    String prefix = '';

    if (isPositive) {
      color = Colors.green;
      prefix = '+';
    } else if (isNegative) {
      color = Colors.red;
      prefix = '-';
    }

    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.text2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$prefix${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.text2),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
