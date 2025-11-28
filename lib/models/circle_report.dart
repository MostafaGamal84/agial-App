import 'package:flutter/foundation.dart';

enum AttendStatus { attended, excusedAbsence, unexcusedAbsence }

extension AttendStatusLabel on AttendStatus {
  String get label {
    switch (this) {
      case AttendStatus.attended:
        return 'حضر';
      case AttendStatus.excusedAbsence:
        return 'غاب بعذر';
      case AttendStatus.unexcusedAbsence:
        return 'غاب بدون عذر';
    }
  }

  int get apiValue {
    switch (this) {
      case AttendStatus.attended:
        return 1;
      case AttendStatus.excusedAbsence:
        return 2;
      case AttendStatus.unexcusedAbsence:
        return 3;
    }
  }

  static AttendStatus fromApi(dynamic value) {
    switch (value) {
      case 1:
        return AttendStatus.attended;
      case 2:
        return AttendStatus.excusedAbsence;
      case 3:
      default:
        return AttendStatus.unexcusedAbsence;
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

  factory CircleReport.fromApi(Map<String, dynamic> json) {
    return CircleReport(
      id: json['id']?.toString() ?? '',
      creationTime: DateTime.tryParse(json['creationTime']?.toString() ?? '') ?? DateTime.now(),
      teacherId: json['teacherId']?.toString() ?? '',
      circleId: json['circleId']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      attendStatueId: AttendStatusHelper.fromApiValue(json['attendStatueId']) ?? AttendStatus.unexcusedAbsence,
      managerId: json['managerId']?.toString(),
      minutes: json['minutes'] is int ? json['minutes'] as int? : int.tryParse(json['minutes']?.toString() ?? ''),
      newId: json['newId'] is int ? json['newId'] as int? : int.tryParse(json['newId']?.toString() ?? ''),
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

  Map<String, dynamic> toApiPayload({bool includeId = false}) {
    return {
      if (includeId) 'id': id,
      'teacherId': teacherId,
      'circleId': circleId,
      'studentId': studentId,
      'attendStatueId': attendStatueId.apiValue,
      'managerId': managerId,
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
      'theWordsQuranStranger': theWordsQuranStranger,
      'intonation': intonation,
      'other': other,
      'creationTime': creationTime.toIso8601String(),
    };
  }
}

class AttendStatusHelper {
  static AttendStatus? fromApiValue(dynamic value) {
    if (value == null) return null;
    final intValue = value is int ? value : int.tryParse(value.toString());
    return switch (intValue) {
      1 => AttendStatus.attended,
      2 => AttendStatus.excusedAbsence,
      _ => AttendStatus.unexcusedAbsence,
    };
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
    required this.teacherName,
    required this.studentName,
    required this.circleName,
  });

  final CircleReport report;
  final String teacherName;
  final String studentName;
  final String circleName;
}
