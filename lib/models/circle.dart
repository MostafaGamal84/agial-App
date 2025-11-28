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

  factory Circle.fromApi(Map<String, dynamic> json) {
    final studentsList = (json['students'] as List<dynamic>?)
            ?.map((e) => Student.fromApi(e as Map<String, dynamic>, circleId: json['id'].toString(), teacherId: json['teacherId']?.toString()))
            .toList() ??
        [];
    return Circle(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      teacherId: json['teacherId']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      students: studentsList,
    );
  }
}
