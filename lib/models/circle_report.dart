import 'package:flutter/foundation.dart';

import 'student.dart';
import 'user.dart';

enum AttendStatus { attended, excusedAbsence, unexcusedAbsence }

extension AttendStatusLabel on AttendStatus {
  String get label {
    switch (this) {
      case AttendStatus.attended:
        return 'Attended';
      case AttendStatus.excusedAbsence:
        return 'Excused absence';
      case AttendStatus.unexcusedAbsence:
        return 'Unexcused absence';
    }
  }
}

@immutable
class CircleReport {
  const CircleReport({
    required this.id,
    required this.creationTime,
    required this.teacherId,
    required this.circleId,
    required this.studentId,
    required this.attendStatueId,
    this.managerId,
    this.minutes,
    this.newId,
    this.newFrom,
    this.newTo,
    this.newRate,
    this.recentPast,
    this.recentPastRate,
    this.distantPast,
    this.distantPastRate,
    this.farthestPast,
    this.farthestPastRate,
    this.theWordsQuranStranger,
    this.intonation,
    this.other,
  });

  final String id;
  final DateTime creationTime;
  final String teacherId;
  final String circleId;
  final String studentId;
  final AttendStatus attendStatueId;
  final String? managerId;
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
  final String? theWordsQuranStranger;
  final String? intonation;
  final String? other;

  CircleReport copyWith({
    String? id,
    DateTime? creationTime,
    String? teacherId,
    String? circleId,
    String? studentId,
    AttendStatus? attendStatueId,
    String? managerId,
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
    String? theWordsQuranStranger,
    String? intonation,
    String? other,
  }) {
    return CircleReport(
      id: id ?? this.id,
      creationTime: creationTime ?? this.creationTime,
      teacherId: teacherId ?? this.teacherId,
      circleId: circleId ?? this.circleId,
      studentId: studentId ?? this.studentId,
      attendStatueId: attendStatueId ?? this.attendStatueId,
      managerId: managerId ?? this.managerId,
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
      theWordsQuranStranger:
          theWordsQuranStranger ?? this.theWordsQuranStranger,
      intonation: intonation ?? this.intonation,
      other: other ?? this.other,
    );
  }
}

class ReportFilter {
  const ReportFilter({this.teacherId, this.circleId, this.studentId, this.searchTerm});

  final String? teacherId;
  final String? circleId;
  final String? studentId;
  final String? searchTerm;
}

class ReportDisplayRow {
  const ReportDisplayRow({
    required this.report,
    required this.teacher,
    required this.student,
    required this.circleName,
  });

  final CircleReport report;
  final UserProfile teacher;
  final Student student;
  final String circleName;
}
