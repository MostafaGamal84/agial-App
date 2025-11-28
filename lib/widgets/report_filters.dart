import 'package:flutter/material.dart';

import '../models/circle.dart';
import '../models/circle_report.dart';
import '../models/student.dart';
import '../models/user.dart';
import '../services/report_service.dart';

class ReportFilters extends StatefulWidget {
  const ReportFilters({
    super.key,
    required this.currentUser,
    required this.reportService,
    required this.initialFilter,
    required this.onChanged,
  });

  final UserProfile currentUser;
  final ReportService reportService;
  final ReportFilter initialFilter;
  final ValueChanged<ReportFilter> onChanged;

  @override
  State<ReportFilters> createState() => _ReportFiltersState();
}

class _ReportFiltersState extends State<ReportFilters> {
  String? _selectedSupervisorId;
  String? _selectedTeacherId;
  String? _selectedCircleId;
  String? _selectedStudentId;
  bool _isLoading = true;
  String? _error;
  bool _hydratedFromInitial = false;

  List<UserProfile> supervisors = [];
  List<UserProfile> teachers = [];
  List<Circle> circles = [];
  List<Student> students = [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _configureFiltersFromUser();
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _configureFiltersFromUser() async {
    final user = widget.currentUser;
    if (user.isAdmin || user.isBranchLeader) {
      supervisors = await widget.reportService
          .fetchSupervisors(branchId: user.isBranchLeader ? user.branchId : null);
      _selectedSupervisorId = supervisors.isNotEmpty ? supervisors.first.id : null;
    } else if (user.isManager) {
      _selectedSupervisorId = user.id;
    } else if (user.isTeacher) {
      _selectedTeacherId = user.id;
    }
    await _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    final user = widget.currentUser;
    if (user.isTeacher) {
      await _loadCircles();
      return;
    }

    teachers = await widget.reportService.fetchTeachers(
      managerId: user.isAdmin || user.isBranchLeader ? _selectedSupervisorId : user.id,
      branchId: user.isBranchLeader ? user.branchId : null,
    );

    if (teachers.isNotEmpty) {
      _selectedTeacherId =
          (!_hydratedFromInitial && widget.initialFilter.teacherId != null)
              ? widget.initialFilter.teacherId
              : _selectedTeacherId ?? teachers.first.id;
    }
    await _loadCircles();
  }

  Future<void> _loadCircles() async {
    if (_selectedTeacherId == null && !widget.currentUser.isTeacher) {
      circles = [];
      students = [];
      _notify();
      return;
    }

    final teacherId = widget.currentUser.isTeacher ? widget.currentUser.id : _selectedTeacherId!;
    circles = await widget.reportService.fetchCircles(teacherId: teacherId);
    if (circles.isNotEmpty) {
      _selectedCircleId = (!_hydratedFromInitial && widget.initialFilter.circleId != null)
          ? widget.initialFilter.circleId
          : _selectedCircleId ?? circles.first.id;
    }
    await _loadStudents();
  }

  Future<void> _loadStudents() async {
    if (_selectedCircleId == null) {
      students = [];
      _selectedStudentId = null;
      _notify();
      return;
    }
    final circle = await widget.reportService.fetchCircle(_selectedCircleId!);
    students = circle.students;
    if (students.isNotEmpty) {
      _selectedStudentId = (!_hydratedFromInitial && widget.initialFilter.studentId != null)
          ? widget.initialFilter.studentId
          : _selectedStudentId ?? students.first.id;
    }
    _notify();
  }

  void _notify() {
    widget.onChanged(
      ReportFilter(
        teacherId: widget.currentUser.isTeacher ? widget.currentUser.id : _selectedTeacherId,
        circleId: _selectedCircleId,
        studentId: _selectedStudentId,
      ),
    );
    _hydratedFromInitial = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.currentUser;
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          if (user.isAdmin || user.isBranchLeader) ...[
            DropdownButtonFormField<String>(
              value: _selectedSupervisorId,
              decoration: const InputDecoration(labelText: 'المشرف', border: OutlineInputBorder()),
              items: supervisors
                  .map((sup) => DropdownMenuItem(value: sup.id, child: Text(sup.fullName)))
                  .toList(),
              onChanged: (value) {
                _selectedSupervisorId = value;
                _loadTeachers();
              },
            ),
            const SizedBox(height: 12),
          ],
          if (!user.isTeacher)
            DropdownButtonFormField<String>(
              value: _selectedTeacherId,
              decoration: const InputDecoration(labelText: 'المعلم', border: OutlineInputBorder()),
              items: teachers
                  .map(
                    (teacher) => DropdownMenuItem(
                      value: teacher.id,
                      child: Text(teacher.fullName),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                _selectedTeacherId = value;
                _loadCircles();
              },
            ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedCircleId,
            decoration: const InputDecoration(labelText: 'الحلقة', border: OutlineInputBorder()),
            items: circles
                .map(
                  (circle) => DropdownMenuItem(
                    value: circle.id,
                    child: Text(circle.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              _selectedCircleId = value;
              _loadStudents();
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedStudentId,
            decoration: const InputDecoration(labelText: 'الطالب', border: OutlineInputBorder()),
            items: students
                .map(
                  (student) => DropdownMenuItem(
                    value: student.id,
                    child: Text(student.fullName),
                  ),
                )
                .toList(),
            onChanged: (value) {
              _selectedStudentId = value;
              _notify();
            },
          ),
        ],
      ),
    );
  }
}
