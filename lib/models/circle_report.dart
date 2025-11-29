// models/circle_report.dart (بس الجزء المهم)

enum AttendStatus {
  attended,
  ExcusedAbsence,
  UnexcusedAbsence;

  String get label {
    switch (this) {
      case AttendStatus.attended:
        return 'حضر';
      case AttendStatus.ExcusedAbsence:
        return 'تغيب بعذر';
      case AttendStatus.UnexcusedAbsence:
        return 'تغيب بدون عذر';
    }
  }

  static AttendStatus fromApi(int value) {
    switch (value) {
      case 0:
        return AttendStatus.attended;
      case 1:
        return AttendStatus.ExcusedAbsence;
      case 2:
      default:
        return AttendStatus.UnexcusedAbsence;
    }
  }

  int get toApi {
    switch (this) {
      case AttendStatus.attended:
        return 0;
      case AttendStatus.ExcusedAbsence:
        return 1;
      case AttendStatus.UnexcusedAbsence:
        return 2;
    }
  }
}

class CircleReport {
  final String id;
  final DateTime creationTime;
  final String? teacherId;
  final String? managerId;
  final String circleId;
  final int? studentId;        // 👈 هنا التغيير المهم
  final AttendStatus attendStatueId;
  final int? minutes;
  final int? newId;
  final String? newFrom;
  final String? newTo;
  final String? newRate;
  final String? recentPast;
  final String? recentPastRate;
  final String? distantPast;
  final String? distantPastRate;
  final String? farthestPast;
  final String? farthestPastRate;
  final String? intonation;
  final String? theWordsQuranStranger;
  final String? other;

  CircleReport({
    required this.id,
    required this.creationTime,
    required this.teacherId,
    required this.managerId,
    required this.circleId,
    required this.studentId,
    required this.attendStatueId,
    required this.minutes,
    required this.newId,
    required this.newFrom,
    required this.newTo,
    required this.newRate,
    required this.recentPast,
    required this.recentPastRate,
    required this.distantPast,
    required this.distantPastRate,
    required this.farthestPast,
    required this.farthestPastRate,
    required this.theWordsQuranStranger,
    required this.intonation,
    required this.other,
  });

  factory CircleReport.fromApi(Map<String, dynamic> json) {
    final rawStudentId = json['studentId'];
    final intStudentId = rawStudentId == null
        ? null
        : (rawStudentId is int
            ? rawStudentId
            : int.tryParse(rawStudentId.toString()));

    return CircleReport(
      id: json['id']?.toString() ?? '',
      creationTime: DateTime.tryParse(json['creationTime']?.toString() ?? '') ??
          DateTime.now(),
      teacherId: json['teacherId']?.toString(),
      managerId: json['managerId']?.toString(),
      circleId: json['circleId']?.toString() ?? '',
      studentId: intStudentId,
      attendStatueId:
          AttendStatus.fromApi(json['attendStatueId'] as int? ?? 0),
      minutes: json['minutes'] as int?,
      newId: json['newId'] as int?,
      newFrom: json['newFrom']?.toString(),
      newTo: json['newTo']?.toString(),
      newRate: json['newRate']?.toString(),
      recentPast: json['recentPast']?.toString(),
      recentPastRate: json['recentPastRate']?.toString(),
      distantPast: json['distantPast']?.toString(),
      distantPastRate: json['distantPastRate']?.toString(),
      farthestPast: json['farthestPast']?.toString(),
      farthestPastRate: json['farthestPastRate']?.toString(),
      theWordsQuranStranger: json['theWordsQuranStranger']?.toString(),
      intonation: json['intonation']?.toString(),
      other: json['other']?.toString(),
    );
  }

  CircleReport copyWith({
    String? id,
    DateTime? creationTime,
    String? teacherId,
    String? managerId,
    String? circleId,
    int? studentId,
    AttendStatus? attendStatueId,
    int? minutes,
    int? newId,
    String? newFrom,
    String? newTo,
    String? newRate,
    String? recentPast,
    String? recentPastRate,
    String? distantPast,
    String? distantPastRate,
    String? farthestPast,
    String? farthestPastRate,
    String? intonation,
    String? theWordsQuranStranger,
    String? other,
  }) {
    return CircleReport(
      id: id ?? this.id,
      creationTime: creationTime ?? this.creationTime,
      teacherId: teacherId ?? this.teacherId,
      managerId: managerId ?? this.managerId,
      circleId: circleId ?? this.circleId,
      studentId: studentId ?? this.studentId,
      attendStatueId: attendStatueId ?? this.attendStatueId,
      minutes: minutes ?? this.minutes,
      newId: newId ?? this.newId,
      newFrom: newFrom ?? this.newFrom,
      newTo: newTo ?? this.newTo,
      newRate: newRate ?? this.newRate,
      recentPast: recentPast ?? this.recentPast,
      recentPastRate: recentPastRate ?? this.recentPastRate,
      distantPast: distantPast ?? this.distantPast,
      distantPastRate: distantPastRate ?? this.distantPastRate,
      farthestPast: farthestPast ?? this.farthestPast,
      farthestPastRate: farthestPastRate ?? this.farthestPastRate,
      intonation: intonation ?? this.intonation,
      theWordsQuranStranger: theWordsQuranStranger ?? this.theWordsQuranStranger,
      other: other ?? this.other,
    );
  }

  Map<String, dynamic> toApiPayload({bool includeId = false}) {
    final map = <String, dynamic>{
      'teacherId': teacherId,
      'managerId': managerId,
      'circleId': circleId,
      'studentId': studentId,            // 👈 يترسّل كـ int?
      'attendStatueId': attendStatueId.toApi,
      'minutes': minutes,
      'newId': newId,
      'newFrom': newFrom,
      'newTo': newTo,
      'newRate': newRate,
      'recentPast': recentPast,
      'recentPastRate': recentPastRate,
      'distantPast': distantPast,
      'distantPastRate': distantPastRate,
      'farthestPast': farthestPast,
      'farthestPastRate': farthestPastRate,
      'other': other,
    };

    if (includeId) {
      map['id'] = id;
    }
    return map;
  }
}
