import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../models/course.dart';
import '../services/app_service.dart';
import '../theme/app_colors.dart';
import '../widgets/page_transition_wrapper.dart';
import '../widgets/toast.dart';

class CoursesListScreen extends StatefulWidget {
  const CoursesListScreen({super.key});

  @override
  State<CoursesListScreen> createState() => _CoursesListScreenState();
}

class _CoursesListScreenState extends State<CoursesListScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  late TabController _tabController;
  
  List<Circle> _circles = [];
  List<Course> _courses = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreCircles = true;
  bool _hasMoreCourses = true;
  int _pageIndexCircles = 0;
  int _pageIndexCourses = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_tabController.index == 0) {
        _loadMoreCircles();
      } else {
        _loadMoreCourses();
      }
    }
  }

  AppService _getAppService() {
    return context.read<AppService>();
  }

  Future<void> _loadData({bool reset = false}) async {
    if (reset) {
      setState(() {
        _pageIndexCircles = 0;
        _pageIndexCourses = 0;
        _circles = [];
        _courses = [];
        _hasMoreCircles = true;
        _hasMoreCourses = true;
        _isLoading = true;
      });
    } else if (_isLoading && _circles.isEmpty && _courses.isEmpty) {
      // Continue loading
    } else if (_circles.isNotEmpty && _courses.isNotEmpty && !reset) {
      return; // Already loaded
    }

    try {
      final user = context.read<AuthController>().currentUser;
      final search = _searchController.text.trim();
      final appService = _getAppService();

      List<Circle> circlesData;
      List<Course> coursesData;

      if (user != null && user.isTeacher) {
        circlesData = await appService.fetchCircles(
          teacherId: user.id,
          search: search.isNotEmpty ? search : null,
          pageIndex: _pageIndexCircles,
        );
        coursesData = await appService.fetchCourses(
          teacherId: user.id,
          search: search.isNotEmpty ? search : null,
          pageIndex: _pageIndexCourses,
        );
      } else {
        circlesData = await appService.fetchCircles(
          search: search.isNotEmpty ? search : null,
          pageIndex: _pageIndexCircles,
        );
        coursesData = await appService.fetchCourses(
          search: search.isNotEmpty ? search : null,
          pageIndex: _pageIndexCourses,
        );
      }

      if (mounted) {
        setState(() {
          if (reset) {
            _circles = circlesData;
            _courses = coursesData;
          } else {
            _circles.addAll(circlesData);
            _courses.addAll(coursesData);
          }
          _hasMoreCircles = circlesData.length >= 50;
          _hasMoreCourses = coursesData.length >= 50;
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

  Future<void> _loadMoreCircles() async {
    if (_isLoadingMore || !_hasMoreCircles) return;
    setState(() {
      _isLoadingMore = true;
      _pageIndexCircles++;
    });
    await _loadData();
  }

  Future<void> _loadMoreCourses() async {
    if (_isLoadingMore || !_hasMoreCourses) return;
    setState(() {
      _isLoadingMore = true;
      _pageIndexCourses++;
    });
    await _loadData();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadData(reset: true);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _loadData(reset: true);
  }

  Future<void> _refresh() async {
    await _loadData(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return PageTransitionWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الحلقات والدورات'),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'الحلقات'),
              Tab(text: 'الدورات'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'بحث...',
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
              child: TabBarView(
                controller: _tabController,
                children: [
                  _CirclesTab(
                    circles: _circles,
                    isLoading: _isLoading,
                    isLoadingMore: _isLoadingMore,
                    scrollController: _scrollController,
                    onRefresh: _refresh,
                  ),
                  _CoursesTab(
                    courses: _courses,
                    isLoading: _isLoading,
                    isLoadingMore: _isLoadingMore,
                    scrollController: _scrollController,
                    onRefresh: _refresh,
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

class _CirclesTab extends StatelessWidget {
  const _CirclesTab({
    required this.circles,
    required this.isLoading,
    required this.isLoadingMore,
    required this.scrollController,
    required this.onRefresh,
  });

  final List<Circle> circles;
  final bool isLoading;
  final bool isLoadingMore;
  final ScrollController scrollController;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    if (isLoading && circles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (circles.isEmpty) {
      return _EmptyState(
        icon: Icons.circle_outlined,
        message: 'لا توجد حلقات',
        onRefresh: onRefresh,
      );
    }

    return RefreshIndicator(
      onRefresh: () async { onRefresh(); },
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: circles.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= circles.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final circle = circles[index];
          return _CircleCard(circle: circle);
        },
      ),
    );
  }
}

class _CoursesTab extends StatelessWidget {
  const _CoursesTab({
    required this.courses,
    required this.isLoading,
    required this.isLoadingMore,
    required this.scrollController,
    required this.onRefresh,
  });

  final List<Course> courses;
  final bool isLoading;
  final bool isLoadingMore;
  final ScrollController scrollController;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    if (isLoading && courses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (courses.isEmpty) {
      return _EmptyState(
        icon: Icons.school_outlined,
        message: 'لا توجد دورات',
        onRefresh: onRefresh,
      );
    }

    return RefreshIndicator(
      onRefresh: () async { onRefresh(); },
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: courses.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= courses.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final course = courses[index];
          return _CourseCard(course: course);
        },
      ),
    );
  }
}

class _CircleCard extends StatelessWidget {
  const _CircleCard({required this.circle});

  final Circle circle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showCircleDetails(context, circle);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.circle_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          circle.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          circle.teacherName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.text2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          '${circle.studentCount}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (circle.location != null || circle.timeSlot != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (circle.location != null) ...[
                      const Icon(Icons.location_on_outlined, size: 16, color: AppColors.text2),
                      const SizedBox(width: 4),
                      Text(
                        circle.location!,
                        style: const TextStyle(fontSize: 13, color: AppColors.text2),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (circle.timeSlot != null) ...[
                      const Icon(Icons.access_time, size: 16, color: AppColors.text2),
                      const SizedBox(width: 4),
                      Text(
                        circle.timeSlot!,
                        style: const TextStyle(fontSize: 13, color: AppColors.text2),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showCircleDetails(BuildContext context, Circle circle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _CircleDetailsSheet(
          circle: circle,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showCourseDetails(context, course);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.school_outlined,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course.teacherName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.text2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people, size: 16, color: Colors.purple),
                        const SizedBox(width: 4),
                        Text(
                          '${course.studentCount}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (course.description != null && course.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  course.description!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.text2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (course.pricing != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.attach_money, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      course.pricing!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
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

  void _showCourseDetails(BuildContext context, Course course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _CourseDetailsSheet(
          course: course,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

class _CircleDetailsSheet extends StatelessWidget {
  const _CircleDetailsSheet({
    required this.circle,
    required this.scrollController,
  });

  final Circle circle;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView(
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
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.circle_outlined,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    circle.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الحلقة',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _DetailItem(icon: Icons.person, label: 'المعلم', value: circle.teacherName),
        if (circle.location != null)
          _DetailItem(icon: Icons.location_on, label: 'الموقع', value: circle.location!),
        if (circle.timeSlot != null)
          _DetailItem(icon: Icons.access_time, label: 'الوقت', value: circle.timeSlot!),
        if (circle.days != null)
          _DetailItem(icon: Icons.calendar_today, label: 'الأيام', value: circle.days!),
        _DetailItem(
          icon: Icons.people,
          label: 'عدد الطلاب',
          value: '${circle.studentCount} طالب',
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.visibility),
            label: const Text('عرض الطلاب'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _CourseDetailsSheet extends StatelessWidget {
  const _CourseDetailsSheet({
    required this.course,
    required this.scrollController,
  });

  final Course course;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView(
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
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.school_outlined,
                color: Colors.purple,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الدورة',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (course.description != null && course.description!.isNotEmpty) ...[
          Text(
            course.description!,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
        ],
        _DetailItem(icon: Icons.person, label: 'المعلم', value: course.teacherName),
        if (course.pricing != null)
          _DetailItem(icon: Icons.attach_money, label: 'السعر', value: course.pricing!),
        _DetailItem(
          icon: Icons.people,
          label: 'عدد الطلاب',
          value: '${course.studentCount} طالب',
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.visibility),
            label: const Text('عرض التفاصيل'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
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
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.text2,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.onRefresh,
  });

  final IconData icon;
  final String message;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
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
