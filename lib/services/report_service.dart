import '../models/circle.dart';
import '../models/circle_report.dart';
import '../models/user.dart';
import 'api_client.dart';

class ReportService {
  ReportService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<UserProfile>> fetchSupervisors({String? branchId}) async {
    final response = await _apiClient.get('/UsersForGroups/GetUsersForSelects', query: {
      'userTypeId': UserType.manager.id,
      if (branchId != null) 'branchId': branchId,
    });
    final items = response['result'] as List<dynamic>? ?? response['items'] as List<dynamic>? ?? [];
    return items.map((item) => UserProfile.fromApi(item as Map<String, dynamic>)).toList();
  }

  Future<List<UserProfile>> fetchTeachers({String? managerId, String? branchId}) async {
    final query = <String, dynamic>{'userTypeId': UserType.teacher.id};
    if (managerId != null) query['managerId'] = managerId;
    if (branchId != null) query['branchId'] = branchId;
    final response = await _apiClient.get('/UsersForGroups/GetUsersForSelects', query: query);
    final items = response['result'] as List<dynamic>? ?? response['items'] as List<dynamic>? ?? [];
    return items.map((item) => UserProfile.fromApi(item as Map<String, dynamic>)).toList();
  }

  Future<List<Circle>> fetchCircles({required String teacherId, int maxResultCount = 200}) async {
    final response = await _apiClient.get('/Circle/GetResultsByFilter', query: {
      'teacherId': teacherId,
      'SkipCount': 0,
      'MaxResultCount': maxResultCount,
    });
    final result = response['result'] ?? response;
    final items = (result['items'] ?? []) as List<dynamic>;
    return items.map((item) => Circle.fromApi(item as Map<String, dynamic>)).toList();
  }

  Future<Circle> fetchCircle(String id) async {
    final response = await _apiClient.get('/Circle/Get', query: {'id': id});
    final result = response['result'] ?? response;
    return Circle.fromApi(result as Map<String, dynamic>);
  }

  Future<List<ReportDisplayRow>> fetchReports({
    required ReportFilter filter,
    required UserProfile currentUser,
  }) async {
    final query = <String, dynamic>{
      'SkipCount': 0,
      'MaxResultCount': 200,
      if (filter.searchTerm?.isNotEmpty == true) 'SearchTerm': filter.searchTerm,
      if (filter.circleId != null) 'circleId': filter.circleId,
      if (filter.studentId != null) 'studentId': filter.studentId,
    };

    if (currentUser.isTeacher) {
      query['teacherId'] = currentUser.id;
    } else if (filter.teacherId != null) {
      query['teacherId'] = filter.teacherId;
    }

    final response = await _apiClient.get('/CircleReport/GetResultsByFilter', query: query);
    final result = response['result'] ?? response['data'] ?? response;
    final itemsDynamic = result is Map<String, dynamic>
        ? result['items'] ?? result['data'] ?? result['result'] ?? []
        : [];
    final items = itemsDynamic is List<dynamic> ? itemsDynamic : <dynamic>[];

    return items.map((item) {
      final reportMap = item as Map<String, dynamic>;
      final report = CircleReport.fromApi(reportMap);
      final studentName = reportMap['studentName']?.toString() ??
          (reportMap['student'] is Map<String, dynamic>
              ? (reportMap['student'] as Map<String, dynamic>)['fullName']?.toString()
              : '');
      final teacherName = reportMap['teacherName']?.toString() ??
          (reportMap['teacher'] is Map<String, dynamic>
              ? (reportMap['teacher'] as Map<String, dynamic>)['fullName']?.toString()
              : '');
      return ReportDisplayRow(
        report: report,
        teacherName: teacherName ?? '',
        studentName: studentName ?? '',
        circleName: reportMap['circleName']?.toString() ?? '',
      );
    }).toList();
  }

  Future<CircleReport> fetchReport(String id) async {
    final response = await _apiClient.get('/CircleReport/Get', query: {'id': id});
    final result = response['result'] ?? response;
    return CircleReport.fromApi(result as Map<String, dynamic>);
  }

  Future<CircleReport> createReport({
    required CircleReport draft,
    required UserProfile currentUser,
  }) async {
    final payload = draft.copyWith(
      teacherId: currentUser.isTeacher ? currentUser.id : draft.teacherId,
      managerId: currentUser.isManager ? currentUser.id : draft.managerId,
    );
    final response = await _apiClient.post('/CircleReport/Create', body: payload.toApiPayload());
    final newId = response['result']?.toString() ?? payload.id;
    return payload.copyWith(id: newId, creationTime: DateTime.now());
  }

  Future<void> updateReport(CircleReport report) async {
    await _apiClient.post('/CircleReport/Update', body: report.toApiPayload(includeId: true));
  }
}
