import 'package:flutter/material.dart';

import '../models/circle_report.dart';
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
  late List<DropdownMenuItem<String>> supervisorItems;
  late List<DropdownMenuItem<String>> teacherItems;
  late List<DropdownMenuItem<String>> circleItems;
  late List<DropdownMenuItem<String>> studentItems;

  @override
  void initState() {
    super.initState();
    supervisorItems = [];
    teacherItems = [];
    circleItems = [];
    studentItems = [];
    _configureFiltersFromUser();
  }

  void _configureFiltersFromUser() {
    final user = widget.currentUser;
    if (user.isAdmin || user.isBranchLeader) {
      final supervisors = widget.reportService
          .getSupervisors(branchId: user.isBranchLeader ? user.branchId : null);
      supervisorItems = supervisors
          .map((sup) => DropdownMenuItem(value: sup.id, child: Text(sup.fullName)))
          .toList();
      if (widget.initialFilter.teacherId != null && supervisors.isNotEmpty) {
        final matched = supervisors.firstWhere(
          (sup) => widget.reportService
              .getTeachers(managerId: sup.id)
              .any((t) => t.id == widget.initialFilter.teacherId),
          orElse: () => supervisors.first,
        );
        _selectedSupervisorId = matched.id;
      } else {
        _selectedSupervisorId = supervisors.isNotEmpty ? supervisors.first.id : null;
      }
      _loadTeachers();
    } else if (user.isManager) {
      _selectedSupervisorId = user.id;
      _loadTeachers();
    } else if (user.isTeacher) {
      _selectedTeacherId = user.id;
      _loadCircles();
    }
  }

  void _loadTeachers() {
    final user = widget.currentUser;
    final teachers = widget.reportService.getTeachers(
      managerId: user.isAdmin || user.isBranchLeader ? _selectedSupervisorId : user.id,
      branchId: user.isBranchLeader ? user.branchId : null,
    );
    teacherItems = teachers
        .map((teacher) => DropdownMenuItem(
              value: teacher.id,
              child: Text(teacher.fullName),
            ))
        .toList();
    if (teachers.isNotEmpty) {
      _selectedTeacherId = widget.initialFilter.teacherId ?? teachers.first.id;
    }
    _loadCircles();
  }

  void _loadCircles() {
    final circles = widget.reportService.getCircles(
      teacherId: widget.currentUser.isTeacher ? widget.currentUser.id : _selectedTeacherId,
    );
    circleItems = circles
        .map((circle) => DropdownMenuItem(value: circle.id, child: Text(circle.name)))
        .toList();
    if (circles.isNotEmpty) {
      _selectedCircleId = widget.initialFilter.circleId ?? circles.first.id;
    }
    _loadStudents();
  }

  void _loadStudents() {
    studentItems = [];
    if (_selectedCircleId != null) {
      final circle = widget.reportService.getCircle(_selectedCircleId!);
      studentItems = circle.students
          .map(
            (student) => DropdownMenuItem(
              value: student.id,
              child: Text(student.fullName),
            ),
          )
          .toList();
      if (circle.students.isNotEmpty) {
        _selectedStudentId = widget.initialFilter.studentId ?? circle.students.first.id;
      }
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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.currentUser;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          if (user.isAdmin || user.isBranchLeader) ...[
            DropdownButtonFormField<String>(
              value: _selectedSupervisorId,
              decoration: const InputDecoration(labelText: 'المشرف', border: OutlineInputBorder()),
              items: supervisorItems,
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
              items: teacherItems,
              onChanged: (value) {
                _selectedTeacherId = value;
                _loadCircles();
              },
            ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedCircleId,
            decoration: const InputDecoration(labelText: 'الحلقة', border: OutlineInputBorder()),
            items: circleItems,
            onChanged: (value) {
              _selectedCircleId = value;
              _loadStudents();
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedStudentId,
            decoration: const InputDecoration(labelText: 'الطالب', border: OutlineInputBorder()),
            items: studentItems,
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
