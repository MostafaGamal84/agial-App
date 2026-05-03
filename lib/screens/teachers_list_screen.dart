import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/auth_controller.dart';
import '../models/user.dart';
import '../services/app_service.dart';
import '../theme/app_colors.dart';
import '../widgets/page_transition_wrapper.dart';
import '../widgets/toast.dart';
import 'teacher_details_screen.dart';

class TeachersListScreen extends StatefulWidget {
  const TeachersListScreen({super.key});

  @override
  State<TeachersListScreen> createState() => _TeachersListScreenState();
}

class _TeachersListScreenState extends State<TeachersListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  
  List<UserProfile> _teachers = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _pageIndex = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTeachers());
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

  Future<void> _loadTeachers({bool reset = false}) async {
    if (reset) {
      setState(() {
        _pageIndex = 0;
        _teachers = [];
        _hasMore = true;
        _isLoading = true;
      });
    } else if (_isLoading && _teachers.isEmpty) {
      // Continue loading
    } else if (_teachers.isNotEmpty && !reset) {
      return; // Already loaded
    }

    try {
      final user = context.read<AuthController>().currentUser;
      final search = _searchController.text.trim();

      List<UserProfile> newTeachers;
      final appService = _getAppService();
      
      if (user != null) {
        if (user.isTeacher) {
          newTeachers = await appService.fetchTeachers(
            managerId: user.isManager ? user.id : null,
            branchId: user.isBranchLeader ? user.branchId : null,
            search: search.isNotEmpty ? search : null,
            pageIndex: _pageIndex,
          );
        } else {
          newTeachers = await appService.fetchTeachers(
            search: search.isNotEmpty ? search : null,
            pageIndex: _pageIndex,
          );
        }
      } else {
        newTeachers = await appService.fetchTeachers(
          search: search.isNotEmpty ? search : null,
          pageIndex: _pageIndex,
        );
      }

      if (mounted) {
        setState(() {
          if (reset) {
            _teachers = newTeachers;
          } else {
            _teachers.addAll(newTeachers);
          }
          _hasMore = newTeachers.length >= 50;
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
    await _loadTeachers();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadTeachers(reset: true);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _loadTeachers(reset: true);
  }

  Future<void> _refresh() async {
    await _loadTeachers(reset: true);
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

  @override
  Widget build(BuildContext context) {
    return PageTransitionWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المعلمون'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'بحث عن معلم...',
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
              child: _isLoading && _teachers.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _teachers.isEmpty
                      ? _EmptyState(onRefresh: _refresh)
                      : RefreshIndicator(
                          onRefresh: _refresh,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _teachers.length + (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= _teachers.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }

                              final teacher = _teachers[index];
                              return _TeacherCard(
                                teacher: teacher,
                                onTap: () => _openTeacherDetails(teacher),
                                onCall: () => _callTeacher(teacher.mobile),
                                onWhatsApp: () => _sendWhatsApp(teacher.mobile),
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

  void _openTeacherDetails(UserProfile teacher) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TeacherDetailsScreen(teacher: teacher),
      ),
    );
  }
}

class _TeacherCard extends StatelessWidget {
  const _TeacherCard({
    required this.teacher,
    required this.onTap,
    required this.onCall,
    required this.onWhatsApp,
  });

  final UserProfile teacher;
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
              _TeacherAvatar(name: teacher.fullName),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teacher.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (teacher.branchName != null && teacher.branchName!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.business_outlined,
                            size: 14,
                            color: AppColors.text2,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            teacher.branchName!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.text2,
                            ),
                          ),
                        ],
                      ),
                    if (teacher.mobile.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: AppColors.text2,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            teacher.mobile,
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

class _TeacherAvatar extends StatelessWidget {
  const _TeacherAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'T',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
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
            Icons.person_search_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'لا يوجد معلمون',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لم يتم العثور على معلمين',
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
