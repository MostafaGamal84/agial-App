import 'package:flutter/foundation.dart';

@immutable
class ReportStats {
  final int totalReports;
  final int attendedCount;
  final int excusedAbsenceCount;
  final int unexcusedAbsenceCount;

  const ReportStats({
    this.totalReports = 0,
    this.attendedCount = 0,
    this.excusedAbsenceCount = 0,
    this.unexcusedAbsenceCount = 0,
  });

  factory ReportStats.fromApi(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return ReportStats(
      totalReports: parseInt(json['totalReports']),
      attendedCount: parseInt(json['attendedCount']),
      excusedAbsenceCount: parseInt(json['excusedAbsenceCount']),
      unexcusedAbsenceCount: parseInt(json['unexcusedAbsenceCount']),
    );
  }
}
