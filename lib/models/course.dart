import 'user.dart';
import 'student.dart';

class Course {
  final String id;
  final String title;
  final String? description;
  final String teacherId;
  final String teacherName;
  final String? managerId;
  final String? managerName;
  final String? branchId;
  final String? branchName;
  final int studentCount;
  final String? status;
  final DateTime? createdDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? pricing;
  final List<Student> students;
  final String? level;
  final String? timeSlot;
  final String? days;

  Course({
    required this.id,
    required this.title,
    this.description,
    required this.teacherId,
    required this.teacherName,
    this.managerId,
    this.managerName,
    this.branchId,
    this.branchName,
    required this.studentCount,
    this.status,
    this.createdDate,
    this.startDate,
    this.endDate,
    this.pricing,
    this.students = const [],
    this.level,
    this.timeSlot,
    this.days,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id']?.toString() ?? json['courseId']?.toString() ?? '',
      title: json['title']?.toString() ?? 
             json['courseName']?.toString() ?? 
             json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      teacherId: json['teacherId']?.toString() ?? '',
      teacherName: json['teacherName']?.toString() ?? 
                   json['teacher']?['fullName']?.toString() ?? 
                   '',
      managerId: json['managerId']?.toString(),
      managerName: json['managerName']?.toString(),
      branchId: json['branchId']?.toString(),
      branchName: json['branchName']?.toString(),
      studentCount: json['studentCount'] as int? ?? 
                    json['studentsCount'] as int? ?? 
                    0,
      status: json['status']?.toString(),
      createdDate: json['createdDate'] != null
          ? DateTime.tryParse(json['createdDate'].toString())
          : null,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString())
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString())
          : null,
      pricing: json['pricing']?.toString() ?? json['price']?.toString(),
      level: json['level']?.toString(),
      timeSlot: json['timeSlot']?.toString(),
      days: json['days']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'managerId': managerId,
        'managerName': managerName,
        'branchId': branchId,
        'branchName': branchName,
        'studentCount': studentCount,
        'status': status,
        'createdDate': createdDate?.toIso8601String(),
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'pricing': pricing,
        'level': level,
        'timeSlot': timeSlot,
        'days': days,
      };
}

class Circle {
  final String id;
  final String name;
  final String? description;
  final String teacherId;
  final String teacherName;
  final String? managerId;
  final String? managerName;
  final String? branchId;
  final String? branchName;
  final int studentCount;
  final List<Student> students;
  final String? status;
  final String? level;
  final String? timeSlot;
  final String? days;
  final String? location;

  Circle({
    required this.id,
    required this.name,
    this.description,
    required this.teacherId,
    required this.teacherName,
    this.managerId,
    this.managerName,
    this.branchId,
    this.branchName,
    required this.studentCount,
    this.students = const [],
    this.status,
    this.level,
    this.timeSlot,
    this.days,
    this.location,
  });

  factory Circle.fromApi(Map<String, dynamic> json) {
    List<Student> studentsList = [];
    if (json['students'] != null) {
      studentsList = (json['students'] as List)
          .map((s) => Student.fromJson(s))
          .toList();
    }

    return Circle(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      teacherId: json['teacherId']?.toString() ?? '',
      teacherName: json['teacherName']?.toString() ?? 
                   json['teacher']?['fullName']?.toString() ?? 
                   '',
      managerId: json['managerId']?.toString(),
      managerName: json['managerName']?.toString(),
      branchId: json['branchId']?.toString(),
      branchName: json['branchName']?.toString(),
      studentCount: json['studentCount'] as int? ?? 
                    studentsList.length,
      students: studentsList,
      status: json['status']?.toString(),
      level: json['level']?.toString(),
      timeSlot: json['timeSlot']?.toString(),
      days: json['days']?.toString(),
      location: json['location']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'managerId': managerId,
        'managerName': managerName,
        'branchId': branchId,
        'branchName': branchName,
        'studentCount': studentCount,
        'status': status,
        'level': level,
        'timeSlot': timeSlot,
        'days': days,
        'location': location,
      };
}
