import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/circle.dart';
import '../models/circle_report.dart';
import '../models/student.dart';
import '../models/user.dart';
import '../services/report_service.dart';
import '../widgets/toast.dart';

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

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  bool _hydratedFromExisting = false;

  bool get isEditing => widget.existingReport != null;

  @override
  void initState() {
    super.initState();
    _status = AttendStatus.attended;
    _minutesController = TextEditingController();
    _newFromController = TextEditingController();
    _newToController = TextEditingController();
    _newRateController = TextEditingController();
    _recentPastController = TextEditingController();
    _recentPastRateController = TextEditingController();
    _distantPastController = TextEditingController();
    _distantPastRateController = TextEditingController();
    _farthestPastController = TextEditingController();
    _farthestPastRateController = TextEditingController();
    _otherController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
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

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final reportService = context.read<ReportService>();
      CircleReport? existing = widget.existingReport;
      if (existing != null) {
        existing = await reportService.fetchReport(existing.id);
      }
      _status = existing?.attendStatueId ?? AttendStatus.attended;
      _minutesController.text = existing?.minutes?.toString() ?? '';
      _newFromController.text = existing?.newFrom ?? '';
      _newToController.text = existing?.newTo ?? '';
      _newRateController.text = existing?.newRate ?? '';
      _recentPastController.text = existing?.recentPast ?? '';
      _recentPastRateController.text = existing?.recentPastRate ?? '';
      _distantPastController.text = existing?.distantPast ?? '';
      _distantPastRateController.text = existing?.distantPastRate ?? '';
      _farthestPastController.text = existing?.farthestPast ?? '';
      _farthestPastRateController.text = existing?.farthestPastRate ?? '';
      _otherController.text = existing?.other ?? '';
      _selectedSurah = existing?.newId;
      await _loadDropdowns(existing: existing);
    } catch (e) {
      _error = e.toString();
      if (mounted) {
        showToast(context, _error!, isError: true);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDropdowns({CircleReport? existing}) async {
    final reportService = context.read<ReportService>();
    final currentUser = widget.currentUser;

    if (currentUser.isAdmin || currentUser.isBranchLeader) {
      supervisors = await reportService.fetchSupervisors(
        branchId: currentUser.isBranchLeader ? currentUser.branchId : null,
      );
      _selectedSupervisorId = existing?.managerId ?? (supervisors.isNotEmpty ? supervisors.first.id : null);
    } else if (currentUser.isManager) {
      _selectedSupervisorId = currentUser.id;
    }

    if (currentUser.isTeacher) {
      _selectedTeacherId = currentUser.id;
    } else {
      teachers = await reportService.fetchTeachers(
        managerId: currentUser.isAdmin || currentUser.isBranchLeader ? _selectedSupervisorId : currentUser.id,
        branchId: currentUser.isBranchLeader ? currentUser.branchId : null,
      );
      if (teachers.isNotEmpty) {
        _selectedTeacherId = !_hydratedFromExisting && existing?.teacherId != null
            ? existing!.teacherId
            : _selectedTeacherId ?? teachers.first.id;
      }
    }

    if (_selectedTeacherId != null) {
      circles = await reportService.fetchCircles(
        teacherId: _selectedTeacherId!,
      );
      Circle? match;
      if (!_hydratedFromExisting && existing != null) {
        for (final circle in circles) {
          if (circle.id == existing.circleId) {
            match = circle;
            break;
          }
        }
      }
      _selectedCircle = match ?? _selectedCircle ?? (circles.isNotEmpty ? circles.first : null);
    } else {
      circles = [];
      _selectedCircle = null;
    }

    await _loadStudents(initial: true, existing: existing);
    _hydratedFromExisting = true;
    setState(() {});
  }

  Future<void> _loadStudents({bool initial = false, CircleReport? existing}) async {
    if (_selectedCircle == null || _selectedCircle!.id.isEmpty) {
      students = [];
      _selectedStudent = null;
      return;
    }
    final reportService = context.read<ReportService>();
    final circle = await reportService.fetchCircle(_selectedCircle!.id);
    students = circle.students;
    if (students.isNotEmpty) {
      if (initial && !_hydratedFromExisting && existing != null) {
        _selectedStudent = students.firstWhere(
          (s) => s.id == existing.studentId,
          orElse: () => students.first,
        );
      } else if (_selectedStudent == null ||
          !students.any((student) => student.id == _selectedStudent!.id)) {
        _selectedStudent = students.first;
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final reportService = context.read<ReportService>();
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'تعديل التقرير' : 'إضافة تقرير')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator.adaptive())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.currentUser.isAdmin || widget.currentUser.isBranchLeader)
                            DropdownButtonFormField<String>(
                              value: _selectedSupervisorId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'المشرف',
                                border: OutlineInputBorder(),
                              ),
                              hint: const Text('اختر المشرف'),
                              items: supervisors
                                  .map(
                                    (sup) => DropdownMenuItem(
                                      value: sup.id,
                                      child: Text(sup.fullName),
                                    ),
                                  )
                                  .toList(),
                              onTap: () {
                                if (supervisors.isEmpty) {
                                  _loadDropdowns(existing: widget.existingReport);
                                }
                              },
                              onChanged: (value) {
                                _selectedSupervisorId = value;
                                _selectedTeacherId = null;
                                _selectedCircle = null;
                                _selectedStudent = null;
                                _loadDropdowns(existing: widget.existingReport);
                              },
                            ),
                          if (widget.currentUser.isAdmin ||
                              widget.currentUser.isBranchLeader ||
                              widget.currentUser.isManager)
                            const SizedBox(height: 12),
                          if (!widget.currentUser.isTeacher)
                            DropdownButtonFormField<String>(
                              value: _selectedTeacherId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'المعلم',
                                border: OutlineInputBorder(),
                              ),
                              hint: const Text('اختر المعلم'),
                              items: teachers
                                  .map(
                                    (teacher) => DropdownMenuItem(
                                      value: teacher.id,
                                      child: Text(teacher.fullName),
                                    ),
                                  )
                                  .toList(),
                              onTap: () {
                                if (teachers.isEmpty) {
                                  _loadDropdowns(existing: widget.existingReport);
                                }
                              },
                              onChanged: (value) async {
                                _selectedTeacherId = value;
                                _selectedCircle = null;
                                _selectedStudent = null;
                                await _loadDropdowns(existing: widget.existingReport);
                              },
                            ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedCircle?.id,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'الحلقة',
                              border: OutlineInputBorder(),
                            ),
                            hint: const Text('اختر الحلقة'),
                            items: circles
                                .map(
                                  (circle) => DropdownMenuItem(
                                    value: circle.id,
                                    child: Text(circle.name),
                                  ),
                                )
                                .toList(),
                            onTap: () {
                              if (circles.isEmpty) {
                                _loadDropdowns(existing: widget.existingReport);
                              }
                            },
                            onChanged: (value) async {
                              _selectedCircle = circles.firstWhere((c) => c.id == value);
                              await _loadStudents();
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedStudent?.id,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'الطالب',
                              border: OutlineInputBorder(),
                            ),
                            hint: const Text('اختر الطالب'),
                            items: students
                                .map(
                                  (student) => DropdownMenuItem(
                                    value: student.id,
                                    child: Text(student.fullName),
                                  ),
                                )
                                .toList(),
                            onTap: () async {
                              if (students.isEmpty && _selectedCircle != null) {
                                await _loadStudents();
                              }
                            },
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
                                if (_status != AttendStatus.attended) {
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
                                if (_status == AttendStatus.excusedAbsence) {
                                  _minutesController.clear();
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
                              onPressed: _isSaving ? null : () => _submit(reportService),
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                                    )
                                  : Text(isEditing ? 'حفظ التعديلات' : 'إضافة التقرير'),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildText(String label, TextEditingController controller, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Future<void> _submit(ReportService reportService) async {
    if (_selectedCircle == null || _selectedStudent == null) return;
    if (!_formKey.currentState!.validate()) return;

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
      recentPast: _status == AttendStatus.attended ? _recentPastController.text : null,
      recentPastRate:
          _status == AttendStatus.attended ? _recentPastRateController.text : null,
      distantPast: _status == AttendStatus.attended ? _distantPastController.text : null,
      distantPastRate:
          _status == AttendStatus.attended ? _distantPastRateController.text : null,
      farthestPast: _status == AttendStatus.attended ? _farthestPastController.text : null,
      farthestPastRate:
          _status == AttendStatus.attended ? _farthestPastRateController.text : null,
      other: _status == AttendStatus.attended ? _otherController.text : null,
    );

    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      if (isEditing) {
        await reportService.updateReport(draft);
      } else {
        await reportService.createReport(draft: draft, currentUser: widget.currentUser);
      }
      if (mounted) {
        final message = isEditing ? 'تم تحديث التقرير بنجاح' : 'تم إنشاء التقرير بنجاح';
        Navigator.of(context).pop(message);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      if (mounted) {
        showToast(context, _error!, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
