import 'student.dart';

class Circle {
  Circle({
    required this.id,
    required this.name,
    required this.teacherId,
    required this.branchId,
    List<Student>? students,
  }) : students = students ?? [];

  final String id;
  final String name;
  final String teacherId;
  final String branchId;
  final List<Student> students;
}
