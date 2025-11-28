import '../models/circle.dart';
import '../models/circle_report.dart';
import '../models/student.dart';
import '../models/user.dart';

class MockDataStore {
  MockDataStore() {
    _seed();
  }

  final List<UserProfile> users = [];
  final List<Circle> circles = [];
  final List<Student> students = [];
  final List<CircleReport> reports = [];
  final Map<String, String> loginDirectory = {
    'admin@example.com': 'u-admin',
    'branch@example.com': 'u-branch',
    'manager@example.com': 'u-manager',
    'teacher@example.com': 'u-teacher',
  };

  void _seed() {
    users
      ..add(const UserProfile(
        id: 'u-admin',
        fullName: 'System Admin',
        userType: UserType.admin,
        branchId: 'central',
      ))
      ..add(const UserProfile(
        id: 'u-branch',
        fullName: 'Branch Leader',
        userType: UserType.branchLeader,
        branchId: 'north',
      ))
      ..add(const UserProfile(
        id: 'u-manager',
        fullName: 'Supervisor Noura',
        userType: UserType.manager,
        branchId: 'north',
      ))
      ..add(const UserProfile(
        id: 'u-teacher',
        fullName: 'Teacher Aisha',
        userType: UserType.teacher,
        branchId: 'north',
        managerId: 'u-manager',
      ))
      ..add(const UserProfile(
        id: 'u-teacher-2',
        fullName: 'Teacher Mariam',
        userType: UserType.teacher,
        branchId: 'north',
        managerId: 'u-manager',
      ));

    circles
      ..add(Circle(
        id: 'c-1',
        name: 'Circle An-Noor',
        teacherId: 'u-teacher',
        branchId: 'north',
      ))
      ..add(Circle(
        id: 'c-2',
        name: 'Circle Al-Fajr',
        teacherId: 'u-teacher-2',
        branchId: 'north',
      ));

    students
      ..add(const Student(
        id: 's-1',
        fullName: 'Student Sara',
        circleId: 'c-1',
        teacherId: 'u-teacher',
        branchId: 'north',
      ))
      ..add(const Student(
        id: 's-2',
        fullName: 'Student Layla',
        circleId: 'c-1',
        teacherId: 'u-teacher',
        branchId: 'north',
      ))
      ..add(const Student(
        id: 's-3',
        fullName: 'Student Huda',
        circleId: 'c-2',
        teacherId: 'u-teacher-2',
        branchId: 'north',
      ));

    final now = DateTime.now();
    reports
      ..add(CircleReport(
        id: 'r-1',
        creationTime: now.subtract(const Duration(days: 1)),
        teacherId: 'u-teacher',
        managerId: 'u-manager',
        circleId: 'c-1',
        studentId: 's-1',
        attendStatueId: AttendStatus.attended,
        minutes: 35,
        newId: 1,
        newFrom: '1',
        newTo: '10',
        newRate: 'جيد جدًا',
        recentPast: 'سورة الملك',
        recentPastRate: 'جيد',
        intonation: 'ممتاز',
      ))
      ..add(CircleReport(
        id: 'r-2',
        creationTime: now.subtract(const Duration(days: 2)),
        teacherId: 'u-teacher-2',
        managerId: 'u-manager',
        circleId: 'c-2',
        studentId: 's-3',
        attendStatueId: AttendStatus.excusedAbsence,
      ));
  }
}
