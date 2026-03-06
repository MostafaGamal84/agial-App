import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/circle.dart';
import '../models/circle_report.dart';
import '../models/student.dart';
import '../models/user.dart';
import '../models/quran_surah.dart';
import '../services/report_service.dart';
import '../widgets/page_transition_wrapper.dart';
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
  late TextEditingController _generalRateController;
  late TextEditingController _nextCircleOrderController;
  late TextEditingController _recentPastController;
  late TextEditingController _recentPastRateController;
  late TextEditingController _distantPastController;
  late TextEditingController _distantPastRateController;
  late TextEditingController _farthestPastController;
  late TextEditingController _farthestPastRateController;
  late TextEditingController intonation;
  late TextEditingController theWordsQuranStranger;
  late TextEditingController _otherController;
  late TextEditingController _creationTimeController;

  int? _selectedSurahNumber;
  String? _selectedSupervisorId;
  String? _selectedTeacherId;
  Circle? _selectedCircle;
  Student? _selectedStudent;
  bool? _isVisual;

  List<UserProfile> supervisors = [];
  List<UserProfile> teachers = [];
  List<Circle> circles = [];
  List<Student> students = [];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLoadingManagers = false;
  bool _isLoadingTeachers = false;
  bool _isLoadingCircles = false;
  bool _isLoadingStudents = false;
  String? _error;

  bool _lockManagerSelection = false;
  bool _lockTeacherSelection = false;

  bool get isEditing => widget.existingReport != null;

  bool get showSupervisorSelector =>
      widget.currentUser.isAdmin || widget.currentUser.isBranchLeader;

  bool get showTeacherSelector =>
      widget.currentUser.isAdmin ||
      widget.currentUser.isBranchLeader ||
      widget.currentUser.isManager;

  final List<Map<String, String>> _generalRateOptions = [
    {'label': 'ممتاز', 'value': 'ممتاز'},
    {'label': 'جيد جداً', 'value': 'جيد جداً'},
    {'label': 'جيد', 'value': 'جيد'},
    {'label': 'إعادة', 'value': 'إعادة'},
  ];

  InputDecoration _inputDecoration(String label, {String? hint}) {
    final theme = Theme.of(context);
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.4)),
    );

    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: theme.colorScheme.surface.withOpacity(0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: baseBorder,
      enabledBorder: baseBorder,
      focusedBorder: baseBorder.copyWith(
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _status = widget.existingReport?.attendStatueId ?? AttendStatus.attended;

    _minutesController = TextEditingController();
    _newFromController = TextEditingController();
    _newToController = TextEditingController();
    _generalRateController = TextEditingController();
    _nextCircleOrderController = TextEditingController();
    _recentPastController = TextEditingController();
    _recentPastRateController = TextEditingController();
    _distantPastController = TextEditingController();
    _distantPastRateController = TextEditingController();
    _farthestPastController = TextEditingController();
    _farthestPastRateController = TextEditingController();
    intonation = TextEditingController();
    theWordsQuranStranger = TextEditingController();
    _otherController = TextEditingController();
    _creationTimeController = TextEditingController();
    _isVisual = true;

    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _newFromController.dispose();
    _newToController.dispose();
    _generalRateController.dispose();
    _nextCircleOrderController.dispose();
    _recentPastController.dispose();
    _recentPastRateController.dispose();
    _distantPastController.dispose();
    _distantPastRateController.dispose();
    _farthestPastController.dispose();
    _farthestPastRateController.dispose();
    intonation.dispose();
    theWordsQuranStranger.dispose();
    _otherController.dispose();
    _creationTimeController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.existingReport != null) {
        _hydrateFromReport(widget.existingReport!);
        await _loadForEdit(widget.existingReport!);
      } else {
        await _initRoleFlow();
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
    _generalRateController.text = existing.generalRate ?? '';
    _nextCircleOrderController.text = existing.nextCircleOrder ?? '';
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
    _isVisual = existing.isVisual ?? true;

    _selectedSupervisorId = existing.managerId;
    _selectedTeacherId = existing.teacherId;
    _selectedCircle = circles.isNotEmpty
        ? circles.firstWhere(
            (c) => c.id == existing.circleId,
            orElse: () => circles.first,
          )
        : null;
  }

  Future<void> _initRoleFlow() async {
    final user = widget.currentUser;
    final myId = user.id;

    if (user.isTeacher) {
      _lockManagerSelection = true;
      _lockTeacherSelection = true;

      _selectedTeacherId = myId;
      _selectedSupervisorId = null;

      await _loadCirclesForTeacher(myId);
      return;
    }

    if (user.isManager) {
      _lockManagerSelection = true;
      _selectedSupervisorId = myId;

      await _loadTeachersForManager(myId);
      return;
    }

    if (user.isAdmin || user.isBranchLeader) {
      await _loadManagers();
      return;
    }
  }

  Future<void> _loadManagers() async {
    setState(() => _isLoadingManagers = true);
    final rs = context.read<ReportService>();

    try {
      supervisors = await rs.fetchSupervisors(
        branchId: widget.currentUser.isBranchLeader ? widget.currentUser.branchId : null,
      );
    } catch (e) {
      supervisors = [];
    }

    setState(() => _isLoadingManagers = false);
  }

  Future<void> _loadTeachersForManager(String managerId) async {
    setState(() => _isLoadingTeachers = true);
    final rs = context.read<ReportService>();

    try {
      teachers = await rs.fetchTeachers(
        managerId: managerId,
        branchId: widget.currentUser.branchId.isNotEmpty ? widget.currentUser.branchId : null,
      );

      if (teachers.length == 1 && _selectedTeacherId == null) {
        _selectedTeacherId = teachers.first.id;
        await _loadCirclesForTeacher(_selectedTeacherId!);
      }
    } catch (e) {
      teachers = [];
    }

    setState(() => _isLoadingTeachers = false);
  }

  Future<void> _loadCirclesForTeacher(String teacherId) async {
    setState(() => _isLoadingCircles = true);
    final rs = context.read<ReportService>();

    try {
      circles = await rs.fetchCircles(teacherId: teacherId);

      if (circles.isNotEmpty && _selectedCircle == null) {
        _selectedCircle = circles.first;
        await _loadStudentsForCircle(_selectedCircle!.id);
      }
    } catch (e) {
      circles = [];
    }

    setState(() => _isLoadingCircles = false);
  }

  Future<void> _loadStudentsForCircle(String circleId) async {
    setState(() => _isLoadingStudents = true);
    final rs = context.read<ReportService>();

    try {
      final circle = await rs.fetchCircle(circleId);
      students = circle.students;

      if (students.isNotEmpty && _selectedStudent == null) {
        _selectedStudent = students.first;
      }
    } catch (e) {
      students = [];
    }

    setState(() => _isLoadingStudents = false);
  }

  Future<void> _loadForEdit(CircleReport existing) async {
    final user = widget.currentUser;
    final rs = context.read<ReportService>();

    if (user.isAdmin || user.isBranchLeader) {
      supervisors = await rs.fetchSupervisors(
        branchId: user.isBranchLeader ? user.branchId : null,
      );
      _selectedSupervisorId = existing.managerId;

      if (existing.teacherId != null) {
        teachers = await rs.fetchTeachers(
          managerId: existing.managerId ?? '',
          branchId: user.branchId.isNotEmpty ? user.branchId : null,
        );
        _selectedTeacherId = existing.teacherId;
      }
    } else if (user.isManager) {
      _selectedSupervisorId = user.id;
      teachers = await rs.fetchTeachers(
        managerId: user.id,
        branchId: user.branchId.isNotEmpty ? user.branchId : null,
      );
      _selectedTeacherId = existing.teacherId;
    } else if (user.isTeacher) {
      _selectedTeacherId = user.id;
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

  void _onSupervisorChanged(String? supervisorId) {
    setState(() {
      _selectedSupervisorId = supervisorId;
      teachers = [];
      circles = [];
      students = [];
      _selectedTeacherId = null;
      _selectedCircle = null;
      _selectedStudent = null;
    });

    if (supervisorId != null) {
      _loadTeachersForManager(supervisorId);
    }
  }

  void _onTeacherChanged(String? teacherId) {
    setState(() {
      _selectedTeacherId = teacherId;
      circles = [];
      students = [];
      _selectedCircle = null;
      _selectedStudent = null;
    });

    if (teacherId != null) {
      _loadCirclesForTeacher(teacherId);
    }
  }

  void _onCircleChanged(String? circleId) {
    if (circleId == null) return;

    _selectedCircle = circles.firstWhere((c) => c.id == circleId);
    students = [];
    _selectedStudent = null;
    setState(() {});

    _loadStudentsForSelectedCircle();
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

  void _onStudentChanged(int? studentId) {
    if (studentId == null) return;
    _selectedStudent = students.firstWhere((s) => s.id == studentId);
    setState(() {});
  }

  void _applyStatusRules({bool preserveValues = false}) {
    setState(() {
      if (_status != AttendStatus.attended) {
        if (!preserveValues) {
          _newFromController.clear();
          _newToController.clear();
          _generalRateController.clear();
          _nextCircleOrderController.clear();
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
        _isVisual = true;
      }

      if (_status == AttendStatus.ExcusedAbsence && !preserveValues) {
        _minutesController.clear();
      }
    });
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName مطلوب';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PageTransitionWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'تعديل تقرير' : 'إنشاء تقرير جديد'),
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
                  : _buildForm(theme),
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isEditing) _buildStatusPill(theme),
            const SizedBox(height: 16),
            
            if (showSupervisorSelector && !isEditing) _buildSupervisorDropdown(theme),
            const SizedBox(height: 12),
            
            if (showTeacherSelector && !isEditing) _buildTeacherDropdown(theme),
            const SizedBox(height: 12),
            
            if (!isEditing) ...[
              _buildCircleDropdown(theme),
              const SizedBox(height: 12),
              _buildStudentDropdown(theme),
              const SizedBox(height: 12),
            ] else ...[
              _buildReadOnlyField('الحلقة', _selectedCircle?.name ?? '-'),
              const SizedBox(height: 12),
              _buildReadOnlyField('الطالب', _selectedStudent?.fullName ?? '-'),
              const SizedBox(height: 12),
            ],
            
            _buildStatusDropdown(theme),
            const SizedBox(height: 12),
            
            if (_status == AttendStatus.attended || _status == AttendStatus.UnexcusedAbsence)
              _buildMinutesField(),
            
            if (_status == AttendStatus.attended) ...[
              const SizedBox(height: 16),
              _buildSectionTitle(theme, 'تفاصيل الحفظ'),
              const SizedBox(height: 12),
              _buildSurahDropdown(theme),
              const SizedBox(height: 12),
              _buildTextField(_newFromController, 'من', theme),
              const SizedBox(height: 12),
              _buildTextField(_newToController, 'إلى', theme),
              const SizedBox(height: 12),
              _buildGeneralRateDropdown(theme),
              const SizedBox(height: 12),
              _buildIsVisualDropdown(theme),
              const SizedBox(height: 12),
              _buildTextField(_nextCircleOrderController, 'مقرر الحصة القادمة', theme, maxLines: 2),
              const SizedBox(height: 12),
              _buildTextField(_recentPastController, 'المراجعة القريبة', theme),
              const SizedBox(height: 12),
              _buildTextField(_distantPastController, 'المراجعة البعيدة', theme),
              const SizedBox(height: 12),
              _buildTextField(_farthestPastController, 'المراجعة الأبعد', theme),
              const SizedBox(height: 12),
              _buildTextField(theWordsQuranStranger, 'كلمات غريب القرآن', theme),
              const SizedBox(height: 12),
              _buildTextField(intonation, 'التجويد', theme),
              const SizedBox(height: 12),
              _buildTextField(_otherController, 'ملاحظات أخرى', theme, maxLines: 3),
            ],
            
            const SizedBox(height: 24),
            _buildSubmitButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Text(
        'وضع التعديل',
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
              style: BorderStyle.solid,
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupervisorDropdown(ThemeData theme) {
    final validIds = supervisors.map((s) => s.id).toSet();
    final value = (_selectedSupervisorId != null && validIds.contains(_selectedSupervisorId))
        ? _selectedSupervisorId
        : null;

    return AbsorbPointer(
      absorbing: isEditing || _lockManagerSelection,
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: _inputDecoration('المشرف'),
        items: supervisors
            .map((s) => DropdownMenuItem<String>(
                  value: s.id,
                  child: Text(s.fullName),
                ))
            .toList(),
        onChanged: isEditing || supervisors.isEmpty
            ? null
            : (v) => _onSupervisorChanged(v),
        validator: (v) => _validateRequired(v, 'المشرف'),
      ),
    );
  }

  Widget _buildTeacherDropdown(ThemeData theme) {
    final validIds = teachers.map((t) => t.id).toSet();
    final value = (_selectedTeacherId != null && validIds.contains(_selectedTeacherId))
        ? _selectedTeacherId
        : null;

    return AbsorbPointer(
      absorbing: isEditing || _lockTeacherSelection,
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: _inputDecoration('المعلم'),
        items: teachers
            .map((t) => DropdownMenuItem<String>(
                  value: t.id,
                  child: Text(t.fullName),
                ))
            .toList(),
        onChanged: isEditing || teachers.isEmpty
            ? null
            : (v) => _onTeacherChanged(v),
        validator: (v) => _validateRequired(v, 'المعلم'),
      ),
    );
  }

  Widget _buildCircleDropdown(ThemeData theme) {
    final validIds = circles.map((c) => c.id).toSet();
    final value = (_selectedCircle != null && validIds.contains(_selectedCircle!.id))
        ? _selectedCircle!.id
        : null;

    return AbsorbPointer(
      absorbing: isEditing,
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: _inputDecoration('الحلقة'),
        items: circles
            .map((c) => DropdownMenuItem<String>(
                  value: c.id,
                  child: Text(c.name),
                ))
            .toList(),
        onChanged: isEditing || circles.isEmpty
            ? null
            : (v) => _onCircleChanged(v),
        validator: (v) => _validateRequired(v, 'الحلقة'),
      ),
    );
  }

  Widget _buildStudentDropdown(ThemeData theme) {
    final uniqueStudents = <int, Student>{};
    for (final s in students) {
      if (s.id.toString().isEmpty) continue;
      uniqueStudents[s.id] = s;
    }
    final uniqueList = uniqueStudents.values.toList();

    final validIds = uniqueList.map((s) => s.id).toSet();
    final value = (_selectedStudent != null && validIds.contains(_selectedStudent!.id))
        ? _selectedStudent!.id
        : null;

    return AbsorbPointer(
      absorbing: isEditing,
      child: DropdownButtonFormField<int>(
        value: value,
        isExpanded: true,
        decoration: _inputDecoration('الطالب'),
        items: uniqueList
            .map((s) => DropdownMenuItem<int>(
                  value: s.id,
                  child: Text(s.fullName),
                ))
            .toList(),
        onChanged: isEditing || uniqueList.isEmpty
            ? null
            : (v) => _onStudentChanged(v),
        validator: (v) => _validateRequired(v?.toString(), 'الطالب'),
      ),
    );
  }

  Widget _buildStatusDropdown(ThemeData theme) {
    return DropdownButtonFormField<AttendStatus>(
      value: _status,
      decoration: _inputDecoration('حالة الحضور'),
      items: AttendStatus.values
          .map((st) => DropdownMenuItem<AttendStatus>(
                value: st,
                child: Text(st.label),
              ))
          .toList(),
      onChanged: isEditing
          ? null
          : (value) {
              if (value == null) return;
              setState(() {
                _status = value;
                _applyStatusRules();
              });
            },
      validator: (v) => v == null ? 'حالة الحضور مطلوبة' : null,
    );
  }

  Widget _buildMinutesField() {
    return TextFormField(
      controller: _minutesController,
      keyboardType: TextInputType.number,
      decoration: _inputDecoration('عدد الدقائق'),
      validator: _status == AttendStatus.UnexcusedAbsence
          ? (v) => _validateRequired(v, 'عدد الدقائق')
          : null,
    );
  }

  Widget _buildSurahDropdown(ThemeData theme) {
    return DropdownButtonFormField<int>(
      value: _selectedSurahNumber,
      isExpanded: true,
      decoration: _inputDecoration('السورة الجديدة'),
      items: QuranSurah.values
          .map((s) => DropdownMenuItem<int>(
                value: s.number,
                child: Text('${s.number}. ${s.arabicName}'),
              ))
          .toList(),
      onChanged: (value) => setState(() => _selectedSurahNumber = value),
    );
  }

  Widget _buildGeneralRateDropdown(ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: _generalRateController.text.isNotEmpty ? _generalRateController.text : null,
      isExpanded: true,
      decoration: _inputDecoration('التقييم العام'),
      items: _generalRateOptions
          .map((opt) => DropdownMenuItem<String>(
                value: opt['value'],
                child: Text(opt['label']!),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _generalRateController.text = value ?? '';
        });
      },
      validator: _status == AttendStatus.attended
          ? (v) => _validateRequired(v, 'التقييم العام')
          : null,
    );
  }

  Widget _buildIsVisualDropdown(ThemeData theme) {
    return DropdownButtonFormField<bool>(
      value: _isVisual,
      isExpanded: true,
      decoration: _inputDecoration('الحصة مرئية؟'),
      items: const [
        DropdownMenuItem<bool>(value: true, child: Text('نعم')),
        DropdownMenuItem<bool>(value: false, child: Text('لا')),
      ],
      onChanged: (value) => setState(() => _isVisual = value),
      validator: _status == AttendStatus.attended
          ? (v) => v == null ? 'الحصة المرئية مطلوبة' : null
          : null,
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    ThemeData theme, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: _inputDecoration(label),
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _submit,
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                isEditing ? 'تحديث' : 'إنشاء',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCircle == null || _selectedStudent == null) {
      showToast(context, 'الرجاء إكمال جميع الحقول المطلوبة', isError: true);
      return;
    }

    final service = context.read<ReportService>();

    final draft = CircleReport(
      id: widget.existingReport?.id ?? '',
      creationTime: widget.existingReport?.creationTime ?? DateTime.now(),
      teacherId: _selectedTeacherId ?? widget.currentUser.id,
      managerId: _selectedSupervisorId,
      circleId: _selectedCircle!.id,
      studentId: _selectedStudent!.id,
      attendStatueId: _status,
      minutes: _status == AttendStatus.UnexcusedAbsence || _status == AttendStatus.attended
          ? int.tryParse(_minutesController.text)
          : null,
      newId: _status == AttendStatus.attended ? _selectedSurahNumber : null,
      newFrom: _status == AttendStatus.attended ? _newFromController.text : null,
      newTo: _status == AttendStatus.attended ? _newToController.text : null,
      newRate: null,
      generalRate: _status == AttendStatus.attended ? _generalRateController.text : null,
      isVisual: _status == AttendStatus.attended ? _isVisual : null,
      nextCircleOrder: _status == AttendStatus.attended ? _nextCircleOrderController.text : null,
      recentPast: _status == AttendStatus.attended ? _recentPastController.text : null,
      recentPastRate: _status == AttendStatus.attended ? _recentPastRateController.text : null,
      distantPast: _status == AttendStatus.attended ? _distantPastController.text : null,
      distantPastRate: _status == AttendStatus.attended ? _distantPastRateController.text : null,
      farthestPast: _status == AttendStatus.attended ? _farthestPastController.text : null,
      farthestPastRate: _status == AttendStatus.attended ? _farthestPastRateController.text : null,
      intonation: _status == AttendStatus.attended ? intonation.text : null,
      theWordsQuranStranger: _status == AttendStatus.attended ? theWordsQuranStranger.text : null,
      other: _status == AttendStatus.attended ? _otherController.text : null,
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
