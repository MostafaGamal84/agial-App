import '../models/circle.dart';
import '../models/circle_report.dart';
import '../models/report_stats.dart';
import '../models/user.dart';
import '../models/student.dart';
import 'api_client.dart';

class ReportService {
  ReportService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<UserProfile>> fetchSupervisors({String? branchId}) async {
    final query = <String, dynamic>{'userTypeId': UserType.manager.id};
    if (branchId != null && branchId.isNotEmpty) query['branchId'] = branchId;
    final response = await _apiClient.get('/UsersForGroups/GetUsersForSelects', query: query);
    final container = (response['data'] ?? response['result'] ?? response) as Map<String, dynamic>;
    final rawItems = container['items'] as List<dynamic>? ?? const [];
    return rawItems.map((item) {
      final map = _normalize(item);
      return UserProfile(
        id: map['id']?.toString() ?? '',
        fullName: map['fullName']?.toString() ?? '',
        userType: UserType.manager,
        branchId: map['branchId']?.toString() ?? '',
        managerId: null,
      );
    }).where((u) => u.id.isNotEmpty).toList();
  }

  Future<List<UserProfile>> fetchTeachers({String? managerId, String? branchId}) async {
    final query = <String, dynamic>{'userTypeId': UserType.teacher.id};
    if (managerId != null && managerId.isNotEmpty) query['managerId'] = managerId;
    if (branchId != null && branchId.isNotEmpty) query['branchId'] = branchId;
    final response = await _apiClient.get('/UsersForGroups/GetUsersForSelects', query: query);
    final container = (response['data'] ?? response['result'] ?? response) as Map<String, dynamic>;
    final rawItems = container['items'] as List<dynamic>? ?? const [];
    return rawItems.map((item) {
      final map = _normalize(item);
      return UserProfile(
        id: map['id']?.toString() ?? '',
        fullName: map['fullName']?.toString() ?? '',
        userType: UserType.teacher,
        branchId: map['branchId']?.toString() ?? '',
        managerId: map['managerId']?.toString(),
      );
    }).where((u) => u.id.isNotEmpty).toList();
  }

  Future<List<Student>> fetchStudentsForSelects({
    String? managerId,
    String? teacherId,
    String? branchId,
  }) async {
    final query = <String, dynamic>{
      'userTypeId': UserType.student.id,
      if (managerId != null && managerId.isNotEmpty) 'managerId': managerId,
      if (teacherId != null && teacherId.isNotEmpty) 'teacherId': teacherId,
      if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
      'Filter': 'lookupOnly=true',
    };
    final response = await _apiClient.get('/UsersForGroups/GetUsersForSelects', query: query);
    final container = (response['data'] ?? response['result'] ?? response) as Map<String, dynamic>;
    final rawItems = container['items'] as List<dynamic>? ?? const [];
    return rawItems.map((item) {
      final map = _normalize(item);
      return Student(id: int.tryParse(map['id']?.toString() ?? '') ?? 0, fullName: map['fullName']?.toString() ?? '');
    }).where((s) => s.id != 0).toList();
  }

  Future<List<Circle>> fetchCircles({required String teacherId}) async {
    final response = await _apiClient.get('/Circle/GetResultsByFilter', query: {'teacherId': teacherId, 'SkipCount': 0, 'MaxResultCount': 200});
    final result = response['result'] ?? response['data'] ?? response;
    final items = (result['items'] as List<dynamic>? ?? const []);
    return items.map((item) => Circle.fromApi(_normalize(item))).toList();
  }

  Future<Circle> fetchCircle(String id) async {
    final response = await _apiClient.get('/Circle/Get', query: {'id': id});
    final map = response['result'] ?? response['data'] ?? response;
    return Circle.fromApi(_normalize(map));
  }

  Future<ReportsPage> fetchReports({
    required UserProfile currentUser,
    int pageIndex = 0,
    int pageSize = 10,
    String? search,
    String? circleId,
    int? studentId,
    String? teacherId,
    int? residentGroup,
    String? residentId,
    DateTime? month,
  }) async {
    final monthQuery = _buildMonthQuery(month);
    final query = <String, dynamic>{
      'SkipCount': pageIndex * pageSize,
      'MaxResultCount': pageSize,
      if ((search ?? '').trim().isNotEmpty) ...{
        'SearchTerm': search!.trim(),
        'SearchWord': search.trim(),
      },
      if (circleId != null) 'circleId': circleId,
      if (studentId != null) 'studentId': studentId,
      if (residentGroup != null) 'residentGroup': residentGroup,
      if (residentId != null) 'residentId': residentId,
      if ((currentUser.isTeacher ? currentUser.id : teacherId) != null)
        'teacherId': currentUser.isTeacher ? currentUser.id : teacherId,
      ...monthQuery,
    };

    final response = await _apiClient.get('/CircleReport/GetMobileResultsByFilter', query: query);
    final result = response['result'] ?? response['data'] ?? response;
    final totalCount = (result['totalCount'] as num?)?.toInt() ?? 0;
    final items = (result['items'] as List<dynamic>? ?? const []);

    final rows = items.map((item) {
      final map = _normalize(item);
      final report = CircleReport.fromApi(map);
      return ReportDisplayRow(
        report: report,
        teacherName: map['teacherName']?.toString() ?? map['teacher']?['fullName']?.toString() ?? map['teacherFullName']?.toString() ?? '',
        studentName: map['studentName']?.toString() ?? map['student']?.toString() ?? map['studentFullName']?.toString() ?? '',
        circleName: map['circleName']?.toString() ?? map['circle']?.toString() ?? map['circleTitle']?.toString() ?? '',
      );
    }).toList();

    return ReportsPage(items: rows, totalCount: totalCount);
  }

  Future<ReportStats> fetchReportStats({
    required UserProfile currentUser,
    String? teacherId,
    int? studentId,
    DateTime? month,
  }) async {
    final query = <String, dynamic>{
      if ((currentUser.isTeacher ? currentUser.id : teacherId) != null)
        'teacherId': currentUser.isTeacher ? currentUser.id : teacherId,
      if (studentId != null) 'studentId': studentId,
      if (month != null) 'month': DateTime(month.year, month.month, 1).toIso8601String(),
    };

    final response = await _apiClient.get('/CircleReport/GetMobileStats', query: query);
    final map = response['result'] ?? response['data'] ?? response;
    return ReportStats.fromApi(_normalize(map));
  }

  Future<CircleReport> fetchReport(String id) async {
    final response = await _apiClient.get('/CircleReport/Get', query: {'id': id});
    final map = response['result'] ?? response['data'] ?? response;
    return CircleReport.fromApi(_normalize(map));
  }

  Future<CircleReport> createReport({required CircleReport draft, required UserProfile currentUser}) async {
    final payloadReport = draft.copyWith(
      teacherId: currentUser.isTeacher ? currentUser.id : draft.teacherId,
      managerId: currentUser.isManager ? currentUser.id : draft.managerId,
    );
    final response = await _apiClient.post('/CircleReport/Create', body: payloadReport.toApiPayload());
    final newId = response['result']?.toString() ?? response['data']?.toString() ?? payloadReport.id;
    return payloadReport.copyWith(id: newId, creationTime: payloadReport.creationTime);
  }

  Future<void> updateReport(CircleReport report) async {
    await _apiClient.post('/CircleReport/Update', body: report.toApiPayload(includeId: true));
  }

  Future<void> deleteReport(String id) async {
    final reportId = id.trim();
    if (reportId.isEmpty) {
      throw Exception('معرّف التقرير غير صالح');
    }

    try {
      await _apiClient.delete('/CircleReport/Delete', query: {'id': reportId});
      return;
    } catch (_) {
      // بعض البيئات لا تمرّر DELETE بشكل صحيح، لذلك نوفّر بديل POST.
    }

    try {
      await _apiClient.post('/CircleReport/Delete', body: {'id': reportId});
      return;
    } catch (_) {
      await _apiClient.post('/CircleReport/Delete?id=$reportId');
    }
  }

  Map<String, dynamic> _normalize(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((key, val) => MapEntry(key.toString(), val));
    return <String, dynamic>{};
  }

  Map<String, dynamic> _buildMonthQuery(DateTime? month) {
    if (month == null) {
      return const <String, dynamic>{};
    }

    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0);
    return <String, dynamic>{
      'FromDate': monthStart.toIso8601String(),
      'ToDate': monthEnd.toIso8601String(),
    };
  }
}

class ReportsPage {
  final List<ReportDisplayRow> items;
  final int totalCount;

  ReportsPage({required this.items, required this.totalCount});
}

class ReportDisplayRow {
  final CircleReport report;
  final String teacherName;
  final String studentName;
  final String circleName;

  ReportDisplayRow({required this.report, required this.teacherName, required this.studentName, required this.circleName});

  ReportDisplayRow copyWith({
    CircleReport? report,
    String? teacherName,
    String? studentName,
    String? circleName,
  }) {
    return ReportDisplayRow(
      report: report ?? this.report,
      teacherName: teacherName ?? this.teacherName,
      studentName: studentName ?? this.studentName,
      circleName: circleName ?? this.circleName,
    );
  }
}
