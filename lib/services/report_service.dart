import '../models/circle.dart';
import '../models/circle_report.dart';
import '../models/report_filter.dart';
import '../models/user.dart';
import '../models/student.dart';
import 'api_client.dart';

class ReportService {
  ReportService(this._apiClient);

  final ApiClient _apiClient;

  // ============================================================
  // SUPERVISORS (userTypeId = 3)
  // ============================================================
  Future<List<UserProfile>> fetchSupervisors({
    String? branchId,
  }) async {
    final response = await _apiClient.get(
      '/UsersForGroups/GetUsersForSelects',
      query: {
        'userTypeId': UserType.manager.id,
        if (branchId != null) 'branchId': branchId,
      },
    );

    final items = response['result'] as List<dynamic>? ??
        response['items'] as List<dynamic>? ??
        [];

    return items
        .map((item) => UserProfile.fromJson(_normalize(item)))
        .toList();
  }

  // ============================================================
  // TEACHERS (userTypeId = 4)
  // ============================================================
  Future<List<UserProfile>> fetchTeachers({
    String? managerId,
    String? branchId,
  }) async {
    final query = <String, dynamic>{
      'userTypeId': UserType.teacher.id,
    };

    if (managerId != null) query['managerId'] = managerId;
    if (branchId != null) query['branchId'] = branchId;

    final response = await _apiClient.get(
      '/UsersForGroups/GetUsersForSelects',
      query: query,
    );

    final items = response['result'] as List<dynamic>? ??
        response['items'] as List<dynamic>? ??
        [];

    return items
        .map((item) => UserProfile.fromJson(_normalize(item)))
        .toList();
  }

  // ============================================================
  // GET CIRCLES FOR TEACHER
  // ============================================================
  Future<List<Circle>> fetchCircles({
    required String teacherId,
  }) async {
    final response = await _apiClient.get(
      '/Circle/GetResultsByFilter',
      query: {
        'teacherId': teacherId,
        'SkipCount': 0,
        'MaxResultCount': 200,
      },
    );

    final result = response['result'] ?? response;
    final items = result['items'] as List<dynamic>? ?? [];

    return items
        .map((item) => Circle.fromApi(_normalize(item)))
        .toList();
  }

  // ============================================================
  // GET CIRCLE WITH STUDENTS (used for selecting student)
  // ============================================================
  Future<Circle> fetchCircle(String id) async {
    final response = await _apiClient.get(
      '/Circle/Get',
      query: {'id': id},
    );

    final map = response['result'] ?? response;
    return Circle.fromApi(_normalize(map));
  }

  // ============================================================
  // GET ALL REPORTS (Teacher + Supervisor + Admin + BranchLeader)
  // ============================================================
  Future<List<ReportDisplayRow>> fetchReports({
    required ReportFilter filter,
    required UserProfile currentUser,
  }) async {
    final query = <String, dynamic>{
      'SkipCount': 0,
      'MaxResultCount': 200,
    };

    if (filter.searchTerm?.isNotEmpty == true) {
      query['SearchTerm'] = filter.searchTerm;
    }
    if (filter.circleId != null) {
      query['circleId'] = filter.circleId;
    }
    if (filter.studentId != null) {
      query['studentId'] = filter.studentId;
    }

    // Teacher restriction
    if (currentUser.isTeacher) {
      query['teacherId'] = currentUser.id;
    } else {
      if (filter.teacherId != null) {
        query['teacherId'] = filter.teacherId;
      }
    }

    final response =
        await _apiClient.get('/CircleReport/GetResultsByFilter', query: query);

    final result =
        response['result'] ?? response['data'] ?? response;
    final itemsDynamic = result['items'] ?? [];

    final items = itemsDynamic is List<dynamic> ? itemsDynamic : <dynamic>[];

    return items.map((item) {
      final map = _normalize(item);

      final report = CircleReport.fromApi(map);

      final studentName = map['studentName']?.toString() ??
          map['student']?['fullName']?.toString() ??
          '';

      final teacherName = map['teacherName']?.toString() ??
          map['teacher']?['fullName']?.toString() ??
          '';

      final circleName = map['circleName']?.toString() ?? '';

      return ReportDisplayRow(
        report: report,
        teacherName: teacherName,
        studentName: studentName,
        circleName: circleName,
      );
    }).toList();
  }

  // ============================================================
  // FETCH ONE REPORT
  // ============================================================
  Future<CircleReport> fetchReport(String id) async {
    final response = await _apiClient.get(
      '/CircleReport/Get',
      query: {'id': id},
    );

    final map = response['result'] ?? response;
    return CircleReport.fromApi(_normalize(map));
  }

  // ============================================================
  // CREATE REPORT
  // ============================================================
  Future<CircleReport> createReport({
    required CircleReport draft,
    required UserProfile currentUser,
  }) async {
    final payload = draft.copyWith(
      teacherId: currentUser.isTeacher ? currentUser.id : draft.teacherId,
      managerId: currentUser.isManager ? currentUser.id : draft.managerId,
    );

    final response = await _apiClient.post(
      '/CircleReport/Create',
      body: payload.toApiPayload(),
    );

    final newId = response['result']?.toString() ?? payload.id;

    return payload.copyWith(
      id: newId,
      creationTime: DateTime.now(),
    );
  }

  // ============================================================
  // UPDATE REPORT
  // ============================================================
  Future<void> updateReport(CircleReport report) async {
    await _apiClient.post(
      '/CircleReport/Update',
      body: report.toApiPayload(includeId: true),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================
  Map<String, dynamic> _normalize(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(key.toString(), val),
      );
    }
    return {};
  }
}

// ============================================================
// SUPPORT MODEL FOR DISPLAY
// ============================================================
class ReportDisplayRow {
  final CircleReport report;
  final String teacherName;
  final String studentName;
  final String circleName;

  ReportDisplayRow({
    required this.report,
    required this.teacherName,
    required this.studentName,
    required this.circleName,
  });
}

