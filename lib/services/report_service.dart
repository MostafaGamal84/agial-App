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
  // SUPERVISORS (userTypeId = 3) - Managers
  // ============================================================
  Future<List<UserProfile>> fetchSupervisors({
    String? branchId,
  }) async {
    // نجهز الـ query parameters
    final query = <String, dynamic>{
      'userTypeId': UserType.manager.id, // 3
    };

    // لو فيه branchId نضيفه، لو null مانبعتوش
    if (branchId != null && branchId.isNotEmpty) {
      query['branchId'] = branchId;
    }

    final response = await _apiClient.get(
      '/UsersForGroups/GetUsersForSelects',
      query: query,
    );

    // الريسبونس اللي بعتّه:
    // { isSuccess, errors, data: { totalCount, items: [ {...}, ... ] } }
    final container = (response['data'] ??
            response['result'] ??
            response) as Map<String, dynamic>;

    final rawItems = container['items'] as List<dynamic>? ?? const [];

    // هنا ما نستخدمش UserProfile.fromJson مباشرة،
    // لأن الـ JSON هنا مختلف عن JSON حق تسجيل الدخول
    final supervisors = rawItems.map((item) {
      final map = _normalize(item);

      return UserProfile(
        id: map['id']?.toString() ?? '',
        fullName: map['fullName']?.toString() ?? '',
        // دول مشرفين → UserType.manager
        userType: UserType.manager,
        branchId: map['branchId']?.toString() ?? '',
        managerId: null,
      );
    }).where((u) => u.id.isNotEmpty).toList();

    return supervisors;
  }

  // ============================================================
  // TEACHERS (userTypeId = 4)
  // ============================================================
  Future<List<UserProfile>> fetchTeachers({
    String? managerId,
    String? branchId,
  }) async {
    final query = <String, dynamic>{
      'userTypeId': UserType.teacher.id, // 4
    };

    if (managerId != null && managerId.isNotEmpty) {
      query['managerId'] = managerId;
    }
    if (branchId != null && branchId.isNotEmpty) {
      query['branchId'] = branchId;
    }

    final response = await _apiClient.get(
      '/UsersForGroups/GetUsersForSelects',
      query: query,
    );

    final container = (response['data'] ??
            response['result'] ??
            response) as Map<String, dynamic>;

    final rawItems = container['items'] as List<dynamic>? ?? const [];

    final teachers = rawItems.map((item) {
      final map = _normalize(item);

      return UserProfile(
        id: map['id']?.toString() ?? '',
        fullName: map['fullName']?.toString() ?? '',
        userType: UserType.teacher,
        branchId: map['branchId']?.toString() ?? '',
        managerId: map['managerId']?.toString(),
      );
    }).where((u) => u.id.isNotEmpty).toList();

    return teachers;
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

    // ABP-style: { result: { totalCount, items: [...] } }
    final result = response['result'] ?? response['data'] ?? response;
    final items = (result['items'] as List<dynamic>? ?? const []);

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

    final map = response['result'] ?? response['data'] ?? response;
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

    // دعم أكثر من شكل للريسبونس (result / data / مباشر)
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

    final map = response['result'] ?? response['data'] ?? response;
    return CircleReport.fromApi(_normalize(map));
  }

  // ============================================================
  // CREATE REPORT
  // ============================================================
  Future<CircleReport> createReport({
    required CircleReport draft,
    required UserProfile currentUser,
  }) async {
    // في حالة أن المعلم هو اللي داخل: نثبت teacherId = currentUser.id
    // في حالة أن المشرف هو اللي داخل: نثبت managerId = currentUser.id
    final payloadReport = draft.copyWith(
      teacherId: currentUser.isTeacher ? currentUser.id : draft.teacherId,
      managerId: currentUser.isManager ? currentUser.id : draft.managerId,
    );

    final response = await _apiClient.post(
      '/CircleReport/Create',
      body: payloadReport.toApiPayload(),
    );

    final newId = response['result']?.toString() ??
        response['data']?.toString() ??
        payloadReport.id;

    return payloadReport.copyWith(
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
    return <String, dynamic>{};
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
