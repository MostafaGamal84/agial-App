import 'package:flutter/material.dart';

import '../models/circle_report.dart';
import '../models/quran_surah.dart';
import '../services/report_service.dart';

String displayValue(dynamic value) {
  if (value == null) return '-';
  final text = value.toString().trim();
  return text.isEmpty ? '-' : text;
}

String formatDate(dynamic value) {
  if (value == null) return '-';
  final dt = value is DateTime ? value : DateTime.tryParse(value.toString());
  if (dt == null) return '-';
  final local = dt.toLocal();
  return '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String getStatusLabel(AttendStatus? status) => status?.label ?? '-';

({String label, Color color}) getStatusConfig(AttendStatus? status) {
  switch (status) {
    case AttendStatus.attended:
      return (label: 'حضور', color: const Color(0xFF22C55E));
    case AttendStatus.ExcusedAbsence:
      return (label: 'غياب بعذر', color: const Color(0xFFf59e0b));
    case AttendStatus.UnexcusedAbsence:
      return (label: 'غياب بدون عذر', color: const Color(0xFFef4444));
    default:
      return (label: '-', color: Colors.grey);
  }
}

String getVisualLabel(bool? isVisual) => isVisual == null ? '-' : (isVisual ? 'نعم' : 'لا');

String getStudentName(ReportDisplayRow row) {
  if (row.studentName.trim().isNotEmpty) {
    return row.studentName;
  }
  return row.report.studentId != null ? 'الطالب رقم ${row.report.studentId}' : '-';
}

String getCircleName(ReportDisplayRow row) {
  if (row.circleName.trim().isNotEmpty) {
    return row.circleName;
  }
  return row.report.circleId.isNotEmpty ? 'الحلقة رقم ${row.report.circleId}' : '-';
}

String getTeacherName(ReportDisplayRow row) {
  if (row.teacherName.trim().isNotEmpty) {
    return row.teacherName;
  }
  return row.report.teacherId != null ? 'المعلم رقم ${row.report.teacherId}' : '-';
}

String getManagerName(CircleReport report) {
  final managerId = report.managerId?.trim();
  if (managerId == null || managerId.isEmpty) {
    return '-';
  }
  return 'المشرف رقم $managerId';
}

String resolveSurahName(int? newId) {
  if (newId == null) return '-';
  for (final s in QuranSurah.values) {
    if (s.number == newId) return s.arabicName;
  }
  return '$newId';
}

String buildWhatsAppPayload(ReportDisplayRow row) {
  final report = row.report;
  final lines = <String>[
    'تقرير الطالب ${getStudentName(row)}',
    'الحلقة: ${getCircleName(row)}',
    'المعلم: ${getTeacherName(row)}',
    if ((report.managerId ?? '').trim().isNotEmpty) 'المشرف: ${getManagerName(report)}',
    'الحالة: ${getStatusLabel(report.attendStatueId)}',
    'عدد الدقائق: ${displayValue(report.minutes)}',
    'تاريخ التقرير: ${formatDate(report.creationTime)}',
  ];

  if (report.attendStatueId == AttendStatus.attended) {
    lines.addAll([
      'السورة الجديدة: ${resolveSurahName(report.newId)}',
      'من: ${displayValue(report.newFrom)}',
      'إلى: ${displayValue(report.newTo)}',
      'تقييم الدرس الجديد: ${displayValue(report.newRate)}',
      'المراجعة القريبة: ${displayValue(report.recentPast)}',
      'تقييم المراجعة القريبة: ${displayValue(report.recentPastRate)}',
      'المراجعة البعيدة: ${displayValue(report.distantPast)}',
      'تقييم المراجعة البعيدة: ${displayValue(report.distantPastRate)}',
      'المراجعة الأبعد: ${displayValue(report.farthestPast)}',
      'تقييم المراجعة الأبعد: ${displayValue(report.farthestPastRate)}',
      'التقييم العام: ${displayValue(report.generalRate)}',
      'كلمات غريب القرآن: ${displayValue(report.theWordsQuranStranger)}',
      'التجويد: ${displayValue(report.intonation)}',
      'الحصة مرئية: ${getVisualLabel(report.isVisual)}',
      'مقرر الحصة القادمة: ${displayValue(report.nextCircleOrder)}',
    ]);
  }

  if ((report.other ?? '').trim().isNotEmpty) {
    lines.add('ملاحظات أخرى: ${displayValue(report.other)}');
  }

  return lines.join('\n');
}
