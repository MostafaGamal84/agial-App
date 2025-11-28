import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/circle.dart';
import '../models/circle_report.dart';
import '../models/student.dart';
import '../models/user.dart';
import '../services/report_service.dart';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({
    super.key,
    required this.currentUser,
    this.existingReport,
  });

  final UserProfile currentUser;
  final CircleReport? existingReport;

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late AttendStatus _status;
  late TextEditingController _minutesController;
  late TextEditingController _newFromController;
  late TextEditingController _newToController;
  late TextEditingController _newRateController;
  late TextEditingController _recentPastController;
  late TextEditingController _recentPastRateController;
  late TextEditingController _distantPastController;
  late TextEditingController _distantPastRateController;
  late TextEditingController _farthestPastController;
  late TextEditingController _farthestPastRateController;
  late TextEditingController _otherController;
  int? _selectedSurah;
  String? _selectedSupervisorId;
  String? _selectedTeacherId;
  Circle? _selectedCircle;
  Student? _selectedStudent;

  List<UserProfile> supervisors = [];
  List<UserProfile> teachers = [];
  List<Circle> circles = [];
  List<Student> students = [];

  bool get isEditing => widget.existingReport != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingReport;
    _status = existing?.attendStatueId ?? AttendStatus.attended;
    _minutesController = TextEditingController(
      text: existing?.minutes != null ? existing!.minutes.toString() : '',
    );
    _newFromController = TextEditingController(text: existing?.newFrom ?? '');
    _newToController = TextEditingController(text: existing?.newTo ?? '');
    _newRateController = TextEditingController(text: existing?.newRate ?? '');
    _recentPastController = TextEditingController(text: existing?.recentPast ?? '');
    _recentPastRateController =
        TextEditingController(text: existing?.recentPastRate ?? '');
    _distantPastController = TextEditingController(text: existing?.distantPast ?? '');
    _distantPastRateController =
        TextEditingController(text: existing?.distantPastRate ?? '');
    _farthestPastController =
        TextEditingController(text: existing?.farthestPast ?? '');
    _farthestPastRateController =
        TextEditingController(text: existing?.farthestPastRate ?? '');
    _otherController = TextEditingController(text: existing?.other ?? '');
    _selectedSurah = existing?.newId;
    _loadDropdowns();
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _newFromController.dispose();
    _newToController.dispose();
    _newRateController.dispose();
    _recentPastController.dispose();
    _recentPastRateController.dispose();
    _distantPastController.dispose();
    _distantPastRateController.dispose();
    _farthestPastController.dispose();
    _farthestPastRateController.dispose();
    _otherController.dispose();
    super.dispose();
  }

  void _loadDropdowns() {
    final reportService = context.read<ReportService>();
    final currentUser = widget.currentUser;

    if (currentUser.isAdmin || currentUser.isBranchLeader) {
      supervisors = reportService.getSupervisors(
        branchId: currentUser.isBranchLeader ? currentUser.branchId : null,
      );
      _selectedSupervisorId = widget.existingReport?.managerId ??
          (supervisors.isNotEmpty ? supervisors.first.id : null);
    } else if (currentUser.isManager) {
      _selectedSupervisorId = currentUser.id;
    }

    teachers = reportService.getTeachers(
      managerId: currentUser.isTeacher
          ? currentUser.managerId
          : _selectedSupervisorId ?? currentUser.id,
      branchId: currentUser.isBranchLeader ? currentUser.branchId : null,
    );

    if (currentUser.isTeacher) {
      _selectedTeacherId = currentUser.id;
    } else {
      _selectedTeacherId = widget.existingReport?.teacherId ??
          (teachers.isNotEmpty ? teachers.first.id : null);
    }

    circles = reportService.getCircles(
      teacherId: currentUser.isTeacher ? currentUser.id : _selectedTeacherId,
    );
    if (widget.existingReport != null) {
      _selectedCircle =
          circles.firstWhere((c) => c.id == widget.existingReport!.circleId);
    } else if (circles.isNotEmpty) {
      _selectedCircle = circles.first;
    }

    _loadStudents(initial: true);
  }

  void _loadStudents({bool initial = false}) {
    if (_selectedCircle == null) {
      students = [];
      _selectedStudent = null;
      return;
    }
    final reportService = context.read<ReportService>();
    final circle = reportService.getCircle(_selectedCircle!.id);
    students = circle.students;
    if (initial && widget.existingReport != null) {
      _selectedStudent =
          students.firstWhere((s) => s.id == widget.existingReport!.studentId);
    } else if (students.isNotEmpty) {
      _selectedStudent = students.first;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final reportService = context.read<ReportService>();
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'تعديل التقرير' : 'إضافة تقرير')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.currentUser.isAdmin || widget.currentUser.isBranchLeader)
                  DropdownButtonFormField<String>(
                    value: _selectedSupervisorId,
                    decoration: const InputDecoration(
                      labelText: 'المشرف',
                      border: OutlineInputBorder(),
                    ),
                    items: supervisors
                        .map(
                          (sup) => DropdownMenuItem(
                            value: sup.id,
                            child: Text(sup.fullName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      _selectedSupervisorId = value;
                      _loadDropdowns();
                      setState(() {});
                    },
                  ),
                if (widget.currentUser.isAdmin ||
                    widget.currentUser.isBranchLeader ||
                    widget.currentUser.isManager)
                  const SizedBox(height: 12),
                if (!widget.currentUser.isTeacher)
                  DropdownButtonFormField<String>(
                    value: _selectedTeacherId,
                    decoration: const InputDecoration(
                      labelText: 'المعلم',
                      border: OutlineInputBorder(),
                    ),
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
                      circles = reportService.getCircles(teacherId: value);
                      _selectedCircle = circles.isNotEmpty ? circles.first : null;
                      _loadStudents();
                    },
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedCircle?.id,
                  decoration: const InputDecoration(
                    labelText: 'الحلقة',
                    border: OutlineInputBorder(),
                  ),
                  items: circles
                      .map(
                        (circle) => DropdownMenuItem(
                          value: circle.id,
                          child: Text(circle.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    _selectedCircle = circles.firstWhere((c) => c.id == value);
                    _loadStudents();
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedStudent?.id,
                  decoration: const InputDecoration(
                    labelText: 'الطالب',
                    border: OutlineInputBorder(),
                  ),
                  items: students
                      .map(
                        (student) => DropdownMenuItem(
                          value: student.id,
                          child: Text(student.fullName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    _selectedStudent = students.firstWhere((s) => s.id == value);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<AttendStatus>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'الحالة',
                    border: OutlineInputBorder(),
                  ),
                  items: AttendStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _status = value;
                      if (_status == AttendStatus.excusedAbsence) {
                        _minutesController.clear();
                        _newFromController.clear();
                        _newToController.clear();
                        _newRateController.clear();
                        _recentPastController.clear();
                        _recentPastRateController.clear();
                        _distantPastController.clear();
                        _distantPastRateController.clear();
                        _farthestPastController.clear();
                        _farthestPastRateController.clear();
                        _otherController.clear();
                        _selectedSurah = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (_status != AttendStatus.excusedAbsence)
                  TextFormField(
                    controller: _minutesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'عدد الدقائق',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (_status == AttendStatus.excusedAbsence) return null;
                      if (value == null || value.isEmpty) {
                        return 'هذا الحقل مطلوب عند الحضور أو الغياب بدون عذر';
                      }
                      return null;
                    },
                  ),
                if (_status != AttendStatus.excusedAbsence) const SizedBox(height: 12),
                if (_status == AttendStatus.attended) ...[
                  DropdownButtonFormField<int>(
                    value: _selectedSurah,
                    decoration: const InputDecoration(
                      labelText: 'السورة الجديدة',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(
                      10,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('سورة رقم ${index + 1}'),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedSurah = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildText('من', _newFromController),
                  const SizedBox(height: 12),
                  _buildText('إلى', _newToController),
                  const SizedBox(height: 12),
                  _buildText('تقدير الجديد', _newRateController),
                  const SizedBox(height: 12),
                  _buildText('الماضي القريب', _recentPastController),
                  const SizedBox(height: 12),
                  _buildText('تقدير الماضي القريب', _recentPastRateController),
                  const SizedBox(height: 12),
                  _buildText('الماضي المتوسط', _distantPastController),
                  const SizedBox(height: 12),
                  _buildText('تقدير الماضي المتوسط', _distantPastRateController),
                  const SizedBox(height: 12),
                  _buildText('الماضي البعيد', _farthestPastController),
                  const SizedBox(height: 12),
                  _buildText('تقدير الماضي البعيد', _farthestPastRateController),
                  const SizedBox(height: 12),
                  _buildText('ملاحظات أخرى', _otherController, maxLines: 3),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: Text(isEditing ? 'حفظ التعديلات' : 'إضافة التقرير'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildText(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  void _submit() {
    if (_selectedCircle == null || _selectedStudent == null) return;
    if (!_formKey.currentState!.validate()) return;
    final reportService = context.read<ReportService>();

    final draft = CircleReport(
      id: widget.existingReport?.id ?? '',
      creationTime: widget.existingReport?.creationTime ?? DateTime.now(),
      teacherId: _selectedTeacherId ?? widget.currentUser.id,
      managerId: _selectedSupervisorId,
      circleId: _selectedCircle!.id,
      studentId: _selectedStudent!.id,
      attendStatueId: _status,
      minutes: _status == AttendStatus.excusedAbsence
          ? null
          : int.tryParse(_minutesController.text),
      newId: _status == AttendStatus.attended ? _selectedSurah : null,
      newFrom: _status == AttendStatus.attended ? _newFromController.text : null,
      newTo: _status == AttendStatus.attended ? _newToController.text : null,
      newRate: _status == AttendStatus.attended ? _newRateController.text : null,
      recentPast:
          _status == AttendStatus.attended ? _recentPastController.text : null,
      recentPastRate: _status == AttendStatus.attended
          ? _recentPastRateController.text
          : null,
      distantPast:
          _status == AttendStatus.attended ? _distantPastController.text : null,
      distantPastRate: _status == AttendStatus.attended
          ? _distantPastRateController.text
          : null,
      farthestPast:
          _status == AttendStatus.attended ? _farthestPastController.text : null,
      farthestPastRate: _status == AttendStatus.attended
          ? _farthestPastRateController.text
          : null,
      other: _status == AttendStatus.attended ? _otherController.text : null,
    );

    if (isEditing) {
      reportService.updateReport(draft);
    } else {
      reportService.createReport(draft: draft, currentUser: widget.currentUser);
    }
    Navigator.of(context).pop();
  }
}
