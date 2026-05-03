import 'user.dart';

class Student {
  final int id;
  final String fullName;
  final String? email;
  final String? mobile;
  final String? parentMobile;
  final String? nationalId;
  final String? birthDate;
  final String? address;
  final String? grade;
  final String? school;
  final String? teacherId;
  final String? teacherName;
  final String? circleId;
  final String? circleName;
  final String? managerId;
  final String? managerName;
  final String? branchId;
  final String? branchName;
  final DateTime? enrollmentDate;
  final String? status;
  final String? notes;

  Student({
    required this.id,
    required this.fullName,
    this.email,
    this.mobile,
    this.parentMobile,
    this.nationalId,
    this.birthDate,
    this.address,
    this.grade,
    this.school,
    this.teacherId,
    this.teacherName,
    this.circleId,
    this.circleName,
    this.managerId,
    this.managerName,
    this.branchId,
    this.branchName,
    this.enrollmentDate,
    this.status,
    this.notes,
  });

  bool get isActive => status?.toLowerCase() != 'inactive';

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      fullName: json['fullName']?.toString() ?? 
                json['name']?.toString() ?? 
                '',
      email: json['email']?.toString(),
      mobile: json['mobile']?.toString() ?? json['phone']?.toString(),
      parentMobile: json['parentMobile']?.toString() ?? json['guardianPhone']?.toString(),
      nationalId: json['nationalId']?.toString(),
      birthDate: json['birthDate']?.toString(),
      address: json['address']?.toString(),
      grade: json['grade']?.toString(),
      school: json['school']?.toString(),
      teacherId: json['teacherId']?.toString(),
      teacherName: json['teacherName']?.toString() ?? 
                   json['teacher']?['fullName']?.toString(),
      circleId: json['circleId']?.toString(),
      circleName: json['circleName']?.toString() ?? 
                  json['circle']?['name']?.toString(),
      managerId: json['managerId']?.toString(),
      managerName: json['managerName']?.toString(),
      branchId: json['branchId']?.toString(),
      branchName: json['branchName']?.toString(),
      enrollmentDate: json['enrollmentDate'] != null
          ? DateTime.tryParse(json['enrollmentDate'].toString())
          : null,
      status: json['status']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  factory Student.fromApi(Map<String, dynamic> json) => Student.fromJson(json);

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'mobile': mobile,
        'parentMobile': parentMobile,
        'nationalId': nationalId,
        'birthDate': birthDate,
        'address': address,
        'grade': grade,
        'school': school,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'circleId': circleId,
        'circleName': circleName,
        'managerId': managerId,
        'managerName': managerName,
        'branchId': branchId,
        'branchName': branchName,
        'enrollmentDate': enrollmentDate?.toIso8601String(),
        'status': status,
        'notes': notes,
      };
}

class StudentDetails {
  final Student student;
  final List<String> enrolledCourses;
  final int totalAttendance;
  final int totalAbsence;
  final int totalExcused;
  final double averageGrade;
  final List<CircleReportSummary> recentReports;

  StudentDetails({
    required this.student,
    this.enrolledCourses = const [],
    this.totalAttendance = 0,
    this.totalAbsence = 0,
    this.totalExcused = 0,
    this.averageGrade = 0.0,
    this.recentReports = const [],
  });

  factory StudentDetails.fromJson(Map<String, dynamic> json) {
    List<CircleReportSummary> reports = [];
    if (json['recentReports'] != null) {
      reports = (json['recentReports'] as List)
          .map((r) => CircleReportSummary.fromJson(r))
          .toList();
    }

    return StudentDetails(
      student: Student.fromJson(json),
      enrolledCourses: (json['enrolledCourses'] as List?)?.cast<String>() ?? [],
      totalAttendance: json['totalAttendance'] as int? ?? 0,
      totalAbsence: json['totalAbsence'] as int? ?? 0,
      totalExcused: json['totalExcused'] as int? ?? 0,
      averageGrade: (json['averageGrade'] as num?)?.toDouble() ?? 0.0,
      recentReports: reports,
    );
  }
}

class CircleReportSummary {
  final String id;
  final DateTime date;
  final String status;
  final String? grade;

  CircleReportSummary({
    required this.id,
    required this.date,
    required this.status,
    this.grade,
  });

  factory CircleReportSummary.fromJson(Map<String, dynamic> json) {
    return CircleReportSummary(
      id: json['id']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      status: json['status']?.toString() ?? '',
      grade: json['grade']?.toString(),
    );
  }
}
