import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/circle.dart';
import '../models/circle_report.dart';
import '../models/student.dart';
import '../models/user.dart';
import '../models/quran_surah.dart';
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

  // Controllers
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
  late TextEditingController intonation;
  late TextEditingController theWordsQuranStranger;
  late TextEditingController _otherController;

  // Selections
  int? _selectedSurahNumber;
  String? _selectedSupervisorId;
  String? _selectedTeacherId;
  Circle? _selectedCircle;
  Student? _selectedStudent;

  // Lists
  List<UserProfile> supervisors = [];
  List<UserProfile> teachers = [];
  List<Circle> circles = [];
  List<Student> students = [];

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  bool get isEditing => widget.existingReport != null;

  @override
  void initState() {
    super.initState();

    _status = widget.existingReport?.attendStatueId ?? AttendStatus.attended;

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
    intonation = TextEditingController();
    theWordsQuranStranger = TextEditingController();
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
    intonation.dispose();
    theWordsQuranStranger.dispose();
    _otherController.dispose();
    super.dispose();
  }

  // =====================================================
  // INITIALIZE
  // =====================================================
  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final existing = widget.existingReport;

      if (existing != null) {
        _hydrateFromReport(existing);
        await _loadForEdit(existing);
      } else {
        await _loadForAdd();
      }
    } catch (e) {
      _error = e.toString();
      if (mounted) {
        showToast(context, _error!, isError: true);
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _hydrateFromReport(CircleReport existing) {
    _status = existing.attendStatueId;
    _minutesController.text = existing.minutes?.toString() ?? '';
    _newFromController.text = existing.newFrom ?? '';
    _newToController.text = existing.newTo ?? '';
    _newRateController.text = existing.newRate ?? '';
    _recentPastController.text = existing.recentPast ?? '';
    _recentPastRateController.text = existing.recentPastRate ?? '';
    _distantPastController.text = existing.distantPast ?? '';
    _distantPastRateController.text = existing.distantPastRate ?? '';
    _farthestPastController.text = existing.farthestPast ?? '';
    _farthestPastRateController.text = existing.farthestPastRate ?? '';
    intonation.text = existing.intonation ?? '';
    theWordsQuranStranger.text = existing.theWordsQuranStranger ?? '';
    _otherController.text = existing.other ?? '';
    _selectedSurahNumber = existing.newId;
  }

  // ========================= ADD MODE =========================
  Future<void> _loadForAdd() async {
    final rs = context.read<ReportService>();
    final user = widget.currentUser;

    debugPrint(
        '[ReportFormScreen] currentUser: id=${user.id}, type=${user.userType}, isAdmin=${user.isAdmin}, isBranchLeader=${user.isBranchLeader}');

    if (user.isAdmin || user.isBranchLeader) {
      final branchFilter = _branchIdForSupervisorFilters(user);
      debugPrint('[_loadForAdd] branchFilter for supervisors: $branchFilter');

      supervisors = await rs.fetchSupervisors(branchId: branchFilter);

      debugPrint('[_loadForAdd] Loaded supervisors count: ${supervisors.length}');
      for (final s in supervisors) {
        debugPrint('Supervisor: ${s.id} - ${s.fullName}');
      }

      teachers = [];
      circles = [];
      students = [];
      _selectedSupervisorId = null;
      _selectedTeacherId = null;
      _selectedCircle = null;
      _selectedStudent = null;
    } else if (user.isManager) {
      _selectedSupervisorId = user.id;
      supervisors = [];

      teachers = await rs.fetchTeachers(
        managerId: user.id,
        branchId: user.branchId,
      );
      circles = [];
      students = [];
      _selectedTeacherId = null;
      _selectedCircle = null;
      _selectedStudent = null;
    } else if (user.isTeacher) {
      _selectedSupervisorId = null;
      _selectedTeacherId = user.id;

      circles = await rs.fetchCircles(teacherId: user.id);
      students = [];
      _selectedCircle = null;
      _selectedStudent = null;
    }

    setState(() {});
  }

  // ========================= EDIT MODE =========================
  Future<void> _loadForEdit(CircleReport existing) async {
    final rs = context.read<ReportService>();
    final user = widget.currentUser;

    if (user.isAdmin || user.isBranchLeader) {
      final branchFilter = _branchIdForSupervisorFilters(user);
      debugPrint('[_loadForEdit] branchFilter for supervisors: $branchFilter');

      supervisors = await rs.fetchSupervisors(
        branchId: branchFilter,
      );
      debugPrint('[_loadForEdit] Loaded supervisors count: ${supervisors.length}');

      _selectedSupervisorId = existing.managerId;

      teachers = await rs.fetchTeachers(
        managerId: existing.managerId,
        branchId: branchFilter,
      );
      _selectedTeacherId = existing.teacherId;
    } else if (user.isManager) {
      _selectedSupervisorId = user.id;
      teachers = await rs.fetchTeachers(
        managerId: user.id,
        branchId: user.branchId,
      );
      _selectedTeacherId = existing.teacherId;
    } else if (user.isTeacher) {
      _selectedTeacherId = user.id;
      supervisors = [];
      teachers = [];
    }

    if (_selectedTeacherId != null) {
      circles = await rs.fetchCircles(teacherId: _selectedTeacherId!);
      if (circles.isNotEmpty) {
        _selectedCircle = circles.firstWhere(
          (c) => c.id == existing.circleId,
          orElse: () => circles.first,
        );
        final circle = await rs.fetchCircle(_selectedCircle!.id);
        students = circle.students;
        if (students.isNotEmpty) {
          _selectedStudent = students.firstWhere(
            (s) => s.id == existing.studentId,
            orElse: () => students.first,
          );
        }
      }
    }

    setState(() {});
  }

  // ===================== HELPERS FOR CASCADE =====================
  Future<void> _onSupervisorChanged(String? supervisorId) async {
    final rs = context.read<ReportService>();
    final user = widget.currentUser;

    setState(() {
      _selectedSupervisorId = supervisorId;
      teachers = [];
      circles = [];
      students = [];
      _selectedTeacherId = null;
      _selectedCircle = null;
      _selectedStudent = null;
    });

    if (supervisorId == null) return;

    final branchFilter = _branchIdForSupervisorFilters(user);
    debugPrint('[_onSupervisorChanged] branchFilter: $branchFilter');

    teachers = await rs.fetchTeachers(
      managerId: supervisorId,
      branchId: branchFilter,
    );

    setState(() {});
  }

  Future<void> _onTeacherChanged(String? teacherId) async {
    final rs = context.read<ReportService>();

    setState(() {
      _selectedTeacherId = teacherId;
      circles = [];
      students = [];
      _selectedCircle = null;
      _selectedStudent = null;
    });

    if (teacherId == null) return;

    circles = await rs.fetchCircles(teacherId: teacherId);

    if (circles.length == 1) {
      _selectedCircle = circles.first;
      await _loadStudentsForSelectedCircle();
    }

    setState(() {});
  }

  Future<void> _onCircleChanged(String? circleId) async {
    if (circleId == null) return;

    _selectedCircle =
        circles.firstWhere((c) => c.id == circleId, orElse: () => circles.first);
    students = [];
    _selectedStudent = null;
    setState(() {});

    await _loadStudentsForSelectedCircle();
  }

  Future<void> _loadStudentsForSelectedCircle() async {
    if (_selectedCircle == null) return;
    final rs = context.read<ReportService>();

    final circle = await rs.fetchCircle(_selectedCircle!.id);
    students = circle.students;

    if (students.length == 1) {
      _selectedStudent = students.first;
    }

    setState(() {});
  }

  String? _branchIdForSupervisorFilters(UserProfile user) {
    // Admin: رجّع null عشان يجيب كل المشرفين بدون فلتر فرع
    if (user.isAdmin) return null;

    // مدير فرع: فلتر حسب الفرع
    if (user.isBranchLeader) return user.branchId;

    // لو في branchId معروف للمستخدم استخدمه
    if (user.branchId.isNotEmpty) return user.branchId;

    return null;
  }

  // =====================================================
  // BUILD UI
  // =====================================================
  @override
  Widget build(BuildContext context) {
    final reportService = context.read<ReportService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'تعديل التقرير' : 'إضافة تقرير'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator.adaptive())
            : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : _buildForm(reportService),
      ),
    );
  }

  Widget _buildForm(ReportService reportService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildSupervisorDropdown(),
            const SizedBox(height: 12),
            _buildTeacherDropdown(),
            const SizedBox(height: 12),
            _buildCircleDropdown(),
            const SizedBox(height: 12),
            _buildStudentDropdown(),
            const SizedBox(height: 12),
            _buildStatusDropdown(),
            const SizedBox(height: 12),
            _buildMinutesField(),
            if (_status == AttendStatus.attended) const SizedBox(height: 12),
            if (_status == AttendStatus.attended) _buildSurahDropdown(),
            if (_status == AttendStatus.attended) const SizedBox(height: 12),
            if (_status == AttendStatus.attended) _buildAttendedFields(),
            const SizedBox(height: 20),
            _buildSubmit(reportService),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // DROPDOWNS
  // =====================================================
  Widget _buildSupervisorDropdown() {
    final user = widget.currentUser;

    if (!(user.isAdmin || user.isBranchLeader)) {
      return const SizedBox.shrink();
    }

    final validIds = supervisors.map((s) => s.id).toSet();
    final value =
        (_selectedSupervisorId != null && validIds.contains(_selectedSupervisorId))
            ? _selectedSupervisorId
            : null;

    return AbsorbPointer(
      absorbing: isEditing,
      child: DropdownButtonFormField<String>(
        key: ValueKey('supervisor-${user.id}-${supervisors.length}'),
        value: value,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'المشرف',
          border: OutlineInputBorder(),
        ),
        items: supervisors
            .map(
              (s) => DropdownMenuItem<String>(
                value: s.id,
                child: Text(s.fullName),
              ),
            )
            .toList(),
        onChanged:
            isEditing || supervisors.isEmpty ? null : (v) => _onSupervisorChanged(v),
      ),
    );
  }

  Widget _buildTeacherDropdown() {
    final user = widget.currentUser;

    if (user.isTeacher) {
      return const SizedBox.shrink();
    }

    final validIds = teachers.map((t) => t.id).toSet();
    final value =
        (_selectedTeacherId != null && validIds.contains(_selectedTeacherId))
            ? _selectedTeacherId
            : null;

    return AbsorbPointer(
      absorbing: isEditing,
      child: DropdownButtonFormField<String>(
        key: ValueKey('teacher-${_selectedSupervisorId ?? 'none'}-${teachers.length}'),
        value: value,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'المعلم',
          border: OutlineInputBorder(),
        ),
        items: teachers
            .map(
              (t) => DropdownMenuItem<String>(
                value: t.id,
                child: Text(t.fullName),
              ),
            )
            .toList(),
        onChanged:
            isEditing || teachers.isEmpty ? null : (v) => _onTeacherChanged(v),
      ),
    );
  }

  Widget _buildCircleDropdown() {
    final validIds = circles.map((c) => c.id).toSet();
    final value =
        (_selectedCircle != null && validIds.contains(_selectedCircle!.id))
            ? _selectedCircle!.id
            : null;

    return AbsorbPointer(
      absorbing: isEditing,
      child: DropdownButtonFormField<String>(
        key: ValueKey('circle-${_selectedTeacherId ?? 'none'}-${circles.length}'),
        value: value,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'الحلقة',
          border: OutlineInputBorder(),
        ),
        items: circles
            .map(
              (c) => DropdownMenuItem<String>(
                value: c.id,
                child: Text(c.name),
              ),
            )
            .toList(),
        onChanged:
            isEditing || circles.isEmpty ? null : (v) => _onCircleChanged(v),
      ),
    );
  }

  Widget _buildStudentDropdown() {
    // إزالة الطلبة المكررة والتأكد أن الـ id مش فاضي
    final uniqueStudentsMap = <int, Student>{};
    for (final s in students) {
      final id = s.id;
      if (id.toString().isEmpty) continue;
      uniqueStudentsMap[id] = s;
    }
    final uniqueStudents = uniqueStudentsMap.values.toList();

    final validIds = uniqueStudents.map((s) => s.id).toSet();
    final value =
        (_selectedStudent != null && validIds.contains(_selectedStudent!.id))
            ? _selectedStudent!.id
            : null;

    if (_selectedStudent != null && !validIds.contains(_selectedStudent!.id)) {
      _selectedStudent = null;
    }

    return AbsorbPointer(
      absorbing: isEditing,
      child: DropdownButtonFormField<int>(
        key: ValueKey(
            'student-${_selectedCircle?.id ?? 'none'}-${uniqueStudents.length}'),
        value: value,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'الطالب',
          border: OutlineInputBorder(),
        ),
        items: uniqueStudents
            .map(
              (s) => DropdownMenuItem<int>(
                value: s.id,
                child: Text(s.fullName),
              ),
            )
            .toList(),
        onChanged: isEditing || uniqueStudents.isEmpty
            ? null
            : (v) {
                if (v == null) return;
                _selectedStudent = uniqueStudents.firstWhere(
                  (s) => s.id == v,
                  orElse: () => uniqueStudents.first,
                );
                setState(() {});
              },
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<AttendStatus>(
      value: _status,
      decoration: const InputDecoration(
        labelText: 'الحالة',
        border: OutlineInputBorder(),
      ),
      items: AttendStatus.values
          .map(
            (st) => DropdownMenuItem<AttendStatus>(
              value: st,
              child: Text(st.label),
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
            intonation.clear();
            theWordsQuranStranger.clear();
            _otherController.clear();
            _selectedSurahNumber = null;
          }

          if (_status == AttendStatus.ExcusedAbsence) {
            _minutesController.clear();
          }
        });
      },
    );
  }

  Widget _buildMinutesField() {
    return TextFormField(
      controller: _minutesController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'عدد الدقائق',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (_status == AttendStatus.ExcusedAbsence) return null;
        if (value == null || value.isEmpty) {
          return 'هذا الحقل مطلوب عند الحضور أو الغياب بدون عذر';
        }
        return null;
      },
    );
  }

  Widget _buildSurahDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedSurahNumber,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'السورة الجديدة',
        border: OutlineInputBorder(),
      ),
      items: QuranSurah.values
          .map(
            (s) => DropdownMenuItem<int>(
              value: s.number,
              child: Text('${s.number}. ${s.arabicName}'),
            ),
          )
          .toList(),
      onChanged: (value) => setState(() => _selectedSurahNumber = value),
    );
  }

  Widget _buildAttendedFields() {
    return Column(
      children: [
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
        _buildText('أحكام التجويد / ملاحظات على التلاوة', intonation,
            maxLines: 2),
        const SizedBox(height: 12),
        _buildText('كلمات غريبة أو صعبة في القرآن', theWordsQuranStranger,
            maxLines: 2),
        const SizedBox(height: 12),
        _buildText('ملاحظات أخرى', _otherController, maxLines: 3),
      ],
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

  // =====================================================
  // SUBMIT
  // =====================================================
  Widget _buildSubmit(ReportService reportService) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : () => _submit(reportService),
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator.adaptive(
                  strokeWidth: 2,
                ),
              )
            : Text(isEditing ? 'حفظ التعديلات' : 'إضافة التقرير'),
      ),
    );
  }

  Future<void> _submit(ReportService service) async {
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
      minutes: _status == AttendStatus.ExcusedAbsence
          ? null
          : int.tryParse(_minutesController.text),
      newId: _status == AttendStatus.attended ? _selectedSurahNumber : null,
      newFrom:
          _status == AttendStatus.attended ? _newFromController.text : null,
      newTo: _status == AttendStatus.attended ? _newToController.text : null,
      newRate:
          _status == AttendStatus.attended ? _newRateController.text : null,
      recentPast:
          _status == AttendStatus.attended ? _recentPastController.text : null,
      recentPastRate: _status == AttendStatus.attended
          ? _recentPastRateController.text
          : null,
      distantPast: _status == AttendStatus.attended
          ? _distantPastController.text
          : null,
      distantPastRate: _status == AttendStatus.attended
          ? _distantPastRateController.text
          : null,
      farthestPast: _status == AttendStatus.attended
          ? _farthestPastController.text
          : null,
      farthestPastRate: _status == AttendStatus.attended
          ? _farthestPastRateController.text
          : null,
      intonation:
          _status == AttendStatus.attended ? intonation.text : null,
      theWordsQuranStranger: _status == AttendStatus.attended
          ? theWordsQuranStranger.text
          : null,
      other:
          _status == AttendStatus.attended ? _otherController.text : null,
    );

    setState(() => _isSaving = true);

    try {
      if (isEditing) {
        await service.updateReport(draft);
      } else {
        await service.createReport(
          draft: draft,
          currentUser: widget.currentUser,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(
          isEditing ? 'تم تحديث التقرير بنجاح' : 'تم إنشاء التقرير بنجاح',
        );
      }
    } catch (e) {
      if (mounted) {
        showToast(context, e.toString(), isError: true);
      }
    }

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }
}
