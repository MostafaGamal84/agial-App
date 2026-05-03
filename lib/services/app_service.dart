import '../models/user.dart';
import '../models/student.dart';
import '../models/course.dart';
import '../models/membership.dart';
import '../models/invoice.dart';
import '../models/salary.dart';
import 'api_client.dart';

class AppService {
  AppService(this._apiClient);

  final ApiClient _apiClient;

  Map<String, dynamic> _normalize(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((key, val) => MapEntry(key.toString(), val));
    return <String, dynamic>{};
  }

  // ==================== TEACHERS ====================
  
  Future<List<UserProfile>> fetchTeachers({
    String? managerId,
    String? branchId,
    String? search,
    int pageIndex = 0,
    int pageSize = 50,
  }) async {
    final query = <String, dynamic>{
      'userTypeId': '4',
      'SkipCount': pageIndex * pageSize,
      'MaxResultCount': pageSize,
      if (managerId != null && managerId.isNotEmpty) 'managerId': managerId,
      if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
      if (search != null && search.isNotEmpty) 'SearchTerm': search,
    };

    final response = await _apiClient.get('/UsersForGroups/GetUsersForSelects', query: query);
    final container = (response['data'] ?? response['result'] ?? response) as Map<String, dynamic>;
    final rawItems = container['items'] as List<dynamic>? ?? container['result'] as List<dynamic>? ?? [];

    return rawItems.map((item) {
      final map = _normalize(item);
      return UserProfile(
        id: map['id']?.toString() ?? '',
        fullName: map['fullName']?.toString() ?? '',
        email: map['email']?.toString() ?? '',
        mobile: map['mobile']?.toString() ?? '',
        userType: UserType.teacher,
        branchId: map['branchId']?.toString() ?? '',
        branchName: map['branchName']?.toString(),
        managerId: map['managerId']?.toString(),
        managerName: map['managerName']?.toString(),
        qualification: map['qualification']?.toString(),
        department: map['department']?.toString(),
        createdDate: map['createdDate'] != null
            ? DateTime.tryParse(map['createdDate'].toString())
            : null,
      );
    }).where((u) => u.id.isNotEmpty).toList();
  }

  Future<UserProfile> fetchTeacherDetails(String id) async {
    final response = await _apiClient.get('/Teacher/Get', query: {'id': id});
    final map = _normalize(response['result'] ?? response['data'] ?? response);
    return UserProfile.fromJson(map);
  }

  // ==================== STUDENTS ====================
  
  Future<List<Student>> fetchStudents({
    String? teacherId,
    String? managerId,
    String? branchId,
    String? search,
    int pageIndex = 0,
    int pageSize = 50,
  }) async {
    final query = <String, dynamic>{
      'userTypeId': '5',
      'SkipCount': pageIndex * pageSize,
      'MaxResultCount': pageSize,
      if (teacherId != null && teacherId.isNotEmpty) 'teacherId': teacherId,
      if (managerId != null && managerId.isNotEmpty) 'managerId': managerId,
      if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
      if (search != null && search.isNotEmpty) 'SearchTerm': search,
    };

    final response = await _apiClient.get('/UsersForGroups/GetUsersForSelects', query: query);
    final container = (response['data'] ?? response['result'] ?? response) as Map<String, dynamic>;
    final rawItems = container['items'] as List<dynamic>? ?? container['result'] as List<dynamic>? ?? [];

    return rawItems.map((item) {
      final map = _normalize(item);
      return Student.fromJson(map);
    }).where((s) => s.id != 0).toList();
  }

  Future<StudentDetails> fetchStudentDetails(String id) async {
    final response = await _apiClient.get('/Student/Get', query: {'id': id});
    final map = _normalize(response['result'] ?? response['data'] ?? response);
    return StudentDetails.fromJson(map);
  }

  // ==================== COURSES & CIRCLES ====================
  
  Future<List<Course>> fetchCourses({
    String? teacherId,
    String? managerId,
    String? branchId,
    String? search,
    int pageIndex = 0,
    int pageSize = 50,
  }) async {
    final query = <String, dynamic>{
      'SkipCount': pageIndex * pageSize,
      'MaxResultCount': pageSize,
      if (teacherId != null && teacherId.isNotEmpty) 'teacherId': teacherId,
      if (managerId != null && managerId.isNotEmpty) 'managerId': managerId,
      if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
      if (search != null && search.isNotEmpty) 'SearchTerm': search,
    };

    final response = await _apiClient.get('/Course/GetAll', query: query);
    final result = response['result'] ?? response['data'] ?? response;
    final items = (result['items'] as List<dynamic>? ?? result as List<dynamic>? ?? []);

    return items.map((item) => Course.fromJson(_normalize(item))).toList();
  }

  Future<Course> fetchCourseDetails(String id) async {
    final response = await _apiClient.get('/Course/Get', query: {'id': id});
    final map = _normalize(response['result'] ?? response['data'] ?? response);
    return Course.fromJson(map);
  }

  Future<List<Circle>> fetchCircles({
    String? teacherId,
    String? search,
    int pageIndex = 0,
    int pageSize = 50,
  }) async {
    final query = <String, dynamic>{
      'SkipCount': pageIndex * pageSize,
      'MaxResultCount': pageSize,
      if (teacherId != null && teacherId.isNotEmpty) 'teacherId': teacherId,
      if (search != null && search.isNotEmpty) 'SearchTerm': search,
    };

    final response = await _apiClient.get('/Circle/GetResultsByFilter', query: query);
    final result = response['result'] ?? response['data'] ?? response;
    final items = (result['items'] as List<dynamic>? ?? result as List<dynamic>? ?? []);

    return items.map((item) => Circle.fromApi(_normalize(item))).toList();
  }

  // ==================== MEMBERSHIP ====================
  
  Future<List<Membership>> fetchMemberships({
    String? userId,
    String? status,
    String? search,
    int pageIndex = 0,
    int pageSize = 50,
  }) async {
    final query = <String, dynamic>{
      'SkipCount': pageIndex * pageSize,
      'MaxResultCount': pageSize,
      if (userId != null && userId.isNotEmpty) 'userId': userId,
      if (status != null && status.isNotEmpty) 'status': status,
      if (search != null && search.isNotEmpty) 'SearchTerm': search,
    };

    final response = await _apiClient.get('/Membership/GetAll', query: query);
    final result = response['result'] ?? response['data'] ?? response;
    final items = (result['items'] as List<dynamic>? ?? result as List<dynamic>? ?? []);

    return items.map((item) => Membership.fromJson(_normalize(item))).toList();
  }

  Future<Membership> fetchMembershipDetails(String id) async {
    final response = await _apiClient.get('/Membership/Get', query: {'id': id});
    final map = _normalize(response['result'] ?? response['data'] ?? response);
    return Membership.fromJson(map);
  }

  Future<List<SubscriptionPlan>> fetchSubscriptionPlans() async {
    final response = await _apiClient.get('/SubscriptionPlan/GetAll');
    final result = response['result'] ?? response['data'] ?? response;
    final items = (result['items'] as List<dynamic>? ?? result as List<dynamic>? ?? []);

    return items.map((item) => SubscriptionPlan.fromJson(_normalize(item))).toList();
  }

  // ==================== INVOICES ====================
  
  Future<List<Invoice>> fetchInvoices({
    String? userId,
    String? status,
    String? search,
    int pageIndex = 0,
    int pageSize = 50,
  }) async {
    final query = <String, dynamic>{
      'SkipCount': pageIndex * pageSize,
      'MaxResultCount': pageSize,
      if (userId != null && userId.isNotEmpty) 'userId': userId,
      if (status != null && status.isNotEmpty) 'status': status,
      if (search != null && search.isNotEmpty) 'SearchTerm': search,
    };

    final response = await _apiClient.get('/Invoice/GetAll', query: query);
    final result = response['result'] ?? response['data'] ?? response;
    final items = (result['items'] as List<dynamic>? ?? result as List<dynamic>? ?? []);

    return items.map((item) => Invoice.fromJson(_normalize(item))).toList();
  }

  Future<Invoice> fetchInvoiceDetails(String id) async {
    final response = await _apiClient.get('/Invoice/Get', query: {'id': id});
    final map = _normalize(response['result'] ?? response['data'] ?? response);
    return Invoice.fromJson(map);
  }

  // ==================== SALARIES ====================
  
  Future<List<SalaryRecord>> fetchSalaries({
    String? teacherId,
    int? month,
    int? year,
    String? status,
    int pageIndex = 0,
    int pageSize = 50,
  }) async {
    final query = <String, dynamic>{
      'SkipCount': pageIndex * pageSize,
      'MaxResultCount': pageSize,
      if (teacherId != null && teacherId.isNotEmpty) 'teacherId': teacherId,
      if (month != null) 'month': month,
      if (year != null) 'year': year,
      if (status != null && status.isNotEmpty) 'status': status,
    };

    final response = await _apiClient.get('/TeacherSalary/GetAll', query: query);
    final result = response['result'] ?? response['data'] ?? response;
    final items = (result['items'] as List<dynamic>? ?? result as List<dynamic>? ?? []);

    return items.map((item) => SalaryRecord.fromJson(_normalize(item))).toList();
  }

  Future<SalaryRecord> fetchSalaryDetails(String id) async {
    final response = await _apiClient.get('/TeacherSalary/Get', query: {'id': id});
    final map = _normalize(response['result'] ?? response['data'] ?? response);
    return SalaryRecord.fromJson(map);
  }

  Future<SalarySummary> fetchSalarySummary({String? teacherId, int? month, int? year}) async {
    final query = <String, dynamic>{
      if (teacherId != null && teacherId.isNotEmpty) 'teacherId': teacherId,
      if (month != null) 'month': month,
      if (year != null) 'year': year,
    };

    final response = await _apiClient.get('/TeacherSalary/GetSummary', query: query);
    final map = _normalize(response['result'] ?? response['data'] ?? response);
    return SalarySummary.fromJson(map);
  }

  // ==================== BRANCHES ====================
  
  Future<List<Map<String, dynamic>>> fetchBranches() async {
    final response = await _apiClient.get('/Branch/GetAll');
    final result = response['result'] ?? response['data'] ?? response;
    final items = (result['items'] as List<dynamic>? ?? result as List<dynamic>? ?? []);
    return items.map((item) => _normalize(item)).toList();
  }

  // ==================== MANAGERS ====================
  
  Future<List<UserProfile>> fetchManagers({
    String? branchId,
    String? search,
    int pageIndex = 0,
    int pageSize = 50,
  }) async {
    final query = <String, dynamic>{
      'userTypeId': '3',
      'SkipCount': pageIndex * pageSize,
      'MaxResultCount': pageSize,
      if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
      if (search != null && search.isNotEmpty) 'SearchTerm': search,
    };

    final response = await _apiClient.get('/UsersForGroups/GetUsersForSelects', query: query);
    final container = (response['data'] ?? response['result'] ?? response) as Map<String, dynamic>;
    final rawItems = container['items'] as List<dynamic>? ?? [];

    return rawItems.map((item) {
      final map = _normalize(item);
      return UserProfile(
        id: map['id']?.toString() ?? '',
        fullName: map['fullName']?.toString() ?? '',
        email: map['email']?.toString() ?? '',
        mobile: map['mobile']?.toString() ?? '',
        userType: UserType.manager,
        branchId: map['branchId']?.toString() ?? '',
        branchName: map['branchName']?.toString(),
      );
    }).where((u) => u.id.isNotEmpty).toList();
  }
}
