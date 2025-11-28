import '../models/circle.dart';
import '../models/circle_report.dart';
import '../models/student.dart';
import '../models/user.dart';
import 'mock_data_store.dart';

class ReportService {
  ReportService(this.dataStore);

  final MockDataStore dataStore;
  int _reportCounter = 10;

  List<UserProfile> getSupervisors({String? branchId}) {
    return dataStore.users.where((user) {
      final matchesBranch = branchId == null || user.branchId == branchId;
      return user.userType == UserType.manager && matchesBranch;
    }).toList();
  }

  List<UserProfile> getTeachers({String? managerId, String? branchId}) {
    return dataStore.users.where((user) {
      final matchesManager = managerId == null || user.managerId == managerId;
      final matchesBranch = branchId == null || user.branchId == branchId;
      return user.userType == UserType.teacher && matchesManager && matchesBranch;
    }).toList();
  }

  List<Circle> getCircles({String? teacherId}) {
    return dataStore.circles
        .where((circle) => teacherId == null || circle.teacherId == teacherId)
        .toList();
  }

  Circle getCircle(String id) {
    final circle = dataStore.circles.firstWhere((item) => item.id == id);
    final relatedStudents = dataStore.students
        .where((student) => student.circleId == circle.id)
        .toList();
    return Circle(
      id: circle.id,
      name: circle.name,
      teacherId: circle.teacherId,
      branchId: circle.branchId,
      students: relatedStudents,
    );
  }

  Student? getStudent(String id) {
    try {
      return dataStore.students.firstWhere((student) => student.id == id);
    } catch (_) {
      return null;
    }
  }

  UserProfile? getTeacher(String id) {
    try {
      return dataStore.users.firstWhere((user) => user.id == id);
    } catch (_) {
      return null;
    }
  }

  String getCircleName(String id) {
    return dataStore.circles.firstWhere((circle) => circle.id == id).name;
  }

  List<ReportDisplayRow> getReports({
    required ReportFilter filter,
    required UserProfile currentUser,
  }) {
    var filtered = dataStore.reports.toList();

    // Role-based scoping
    if (currentUser.isTeacher) {
      filtered = filtered
          .where((report) => report.teacherId == currentUser.id)
          .toList();
    } else if (currentUser.isManager) {
      final managedTeachers = getTeachers(managerId: currentUser.id)
          .map((teacher) => teacher.id)
          .toSet();
      filtered = filtered
          .where((report) => managedTeachers.contains(report.teacherId))
          .toList();
    } else if (currentUser.isBranchLeader) {
      final branchTeachers = getTeachers(branchId: currentUser.branchId)
          .map((teacher) => teacher.id)
          .toSet();
      filtered = filtered
          .where((report) => branchTeachers.contains(report.teacherId))
          .toList();
    }

    // User-selected filters
    if (filter.teacherId != null) {
      filtered =
          filtered.where((report) => report.teacherId == filter.teacherId).toList();
    }
    if (filter.circleId != null) {
      filtered = filtered.where((report) => report.circleId == filter.circleId).toList();
    }
    if (filter.studentId != null) {
      filtered =
          filtered.where((report) => report.studentId == filter.studentId).toList();
    }
    if (filter.searchTerm != null && filter.searchTerm!.isNotEmpty) {
      final term = filter.searchTerm!.toLowerCase();
      filtered = filtered.where((report) {
        final student = getStudent(report.studentId);
        return student?.fullName.toLowerCase().contains(term) ?? false;
      }).toList();
    }

    return filtered.map((report) {
      final student = getStudent(report.studentId)!;
      final teacher = getTeacher(report.teacherId)!;
      return ReportDisplayRow(
        report: report,
        teacher: teacher,
        student: student,
        circleName: getCircleName(report.circleId),
      );
    }).toList();
  }

  CircleReport createReport({
    required CircleReport draft,
    required UserProfile currentUser,
  }) {
    if (currentUser.isTeacher) {
      draft = draft.copyWith(teacherId: currentUser.id);
    }
    if (currentUser.isManager) {
      draft = draft.copyWith(managerId: currentUser.id);
    }
    final report = draft.copyWith(
      id: 'r-${_reportCounter++}',
      creationTime: DateTime.now(),
    );
    dataStore.reports.insert(0, report);
    return report;
  }

  CircleReport updateReport(CircleReport updated) {
    final index = dataStore.reports.indexWhere((r) => r.id == updated.id);
    if (index == -1) {
      throw Exception('Report not found');
    }
    dataStore.reports[index] = updated;
    return updated;
  }
}
