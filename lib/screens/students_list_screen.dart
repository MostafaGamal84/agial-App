import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/auth_controller.dart';
import '../models/student.dart';
import '../services/app_service.dart';
import '../theme/app_colors.dart';
import '../widgets/page_transition_wrapper.dart';
import '../widgets/toast.dart';
import 'student_details_screen.dart';

class StudentsListScreen extends StatefulWidget {
  const StudentsListScreen({super.key});

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  
  List<Student> _students = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _pageIndex = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStudents());
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

  AppService _getAppService() {
    return context.read<AppService>();
  }

  Future<void> _loadStudents({bool reset = false}) async {
    if (reset) {
      setState(() {
        _pageIndex = 0;
        _students = [];
        _hasMore = true;
        _isLoading = true;
      });
    } else if (_isLoading && _students.isEmpty) {
      // Continue loading
    } else if (_students.isNotEmpty && !reset) {
      return; // Already loaded
    }

    try {
      final user = context.read<AuthController>().currentUser;
      final search = _searchController.text.trim();
      final appService = _getAppService();

      List<Student> newStudents;
      
      if (user != null) {
        if (user.isTeacher) {
          newStudents = await appService.fetchStudents(
            teacherId: user.id,
            search: search.isNotEmpty ? search : null,
            pageIndex: _pageIndex,
          );
        } else if (user.isManager) {
          newStudents = await appService.fetchStudents(
            managerId: user.id,
            search: search.isNotEmpty ? search : null,
            pageIndex: _pageIndex,
          );
        } else {
          newStudents = await appService.fetchStudents(
            branchId: user.branchId.isNotEmpty ? user.branchId : null,
            search: search.isNotEmpty ? search : null,
            pageIndex: _pageIndex,
          );
        }
      } else {
        newStudents = await appService.fetchStudents(
          search: search.isNotEmpty ? search : null,
          pageIndex: _pageIndex,
        );
      }

      if (mounted) {
        setState(() {
          if (reset) {
            _students = newStudents;
          } else {
            _students.addAll(newStudents);
          }
          _hasMore = newStudents.length >= 50;
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
    await _loadStudents();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadStudents(reset: true);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _loadStudents(reset: true);
  }

  Future<void> _refresh() async {
    await _loadStudents(reset: true);
  }

  Future<void> _callParent(String? phone) async {
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
    return PageTransitionWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الطلاب'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'بحث عن طالب...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            Expanded(
              child: _isLoading && _students.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _students.isEmpty
                      ? _EmptyState(onRefresh: _refresh)
                      : RefreshIndicator(
                          onRefresh: _refresh,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _students.length + (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= _students.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }

                              final student = _students[index];
                              return _StudentCard(
                                student: student,
                                onTap: () => _openStudentDetails(student),
                                onCall: () => _callParent(student.parentMobile ?? student.mobile),
                                onWhatsApp: () => _sendWhatsApp(student.parentMobile ?? student.mobile),
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

  void _openStudentDetails(Student student) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentDetailsScreen(student: student),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.student,
    required this.onTap,
    required this.onCall,
    required this.onWhatsApp,
  });

  final Student student;
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
          child: Row(
            children: [
              _StudentAvatar(name: student.fullName),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (student.circleName != null && student.circleName!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.circle_outlined,
                            size: 14,
                            color: AppColors.text2,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            student.circleName!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.text2,
                            ),
                          ),
                        ],
                      ),
                    if (student.teacherName != null && student.teacherName!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 14,
                            color: AppColors.text2,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            student.teacherName!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.text2,
                            ),
                          ),
                        ],
                      ),
                    if (student.grade != null && student.grade!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.school_outlined,
                            size: 14,
                            color: AppColors.text2,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            student.grade!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.text2,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Column(
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
          ),
        ),
      ),
    );
  }
}

class _StudentAvatar extends StatelessWidget {
  const _StudentAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'S',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
      ),
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
            Icons.school_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'لا يوجد طلاب',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لم يتم العثور على طلاب',
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
