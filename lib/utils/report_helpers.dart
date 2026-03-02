import 'package:flutter/material.dart';

import '../models/circle_report.dart';
import '../models/quran_surah.dart';
import '../services/report_service.dart';

String displayValue(dynamic value) {
  if (value == null) return '—';
  final text = value.toString().trim();
  return text.isEmpty ? '—' : text;
}

String formatDate(dynamic value) {
  if (value == null) return '—';
  final dt = value is DateTime ? value : DateTime.tryParse(value.toString());
  if (dt == null) return '—';
  final local = dt.toLocal();
  return '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String getStatusLabel(AttendStatus? status) => status?.label ?? '—';

({String label, Color color}) getStatusConfig(AttendStatus? status) {
  switch (status) {
    case AttendStatus.attended:
      return (label: 'حضر', color: const Color(0xFF22C55E));
    case AttendStatus.ExcusedAbsence:
      return (label: 'غياب بعذر', color: const Color(0xFFf59e0b));
    case AttendStatus.UnexcusedAbsence:
      return (label: 'غياب بدون عذر', color: const Color(0xFFef4444));
    default:
      return (label: '—', color: Colors.grey);
  }
}

String getVisualLabel(bool? isVisual) => isVisual == null ? '—' : (isVisual ? 'نعم' : 'لا');
String getStudentName(ReportDisplayRow row) => row.studentName.trim().isNotEmpty ? row.studentName : (row.report.studentId != null ? 'Student #${row.report.studentId}' : '—');
String getCircleName(ReportDisplayRow row) => row.circleName.trim().isNotEmpty ? row.circleName : (row.report.circleId.isNotEmpty ? 'Circle #${row.report.circleId}' : '—');
String getTeacherName(ReportDisplayRow row) => row.teacherName.trim().isNotEmpty ? row.teacherName : (row.report.teacherId != null ? 'Teacher #${row.report.teacherId}' : '—');

String resolveSurahName(int? newId) {
  if (newId == null) return '—';
  for (final s in QuranSurah.values) {
    if (s.number == newId) return s.arabicName;
  }
  return '$newId';
}

String buildWhatsAppPayload(ReportDisplayRow row) {
  final r = row.report;
  final lines = <String>[
    'تقرير الطالب ${getStudentName(row)}',
    'الحلقة: ${getCircleName(row)}',
    'المعلم: ${getTeacherName(row)}',
    'الحالة: ${getStatusLabel(r.attendStatueId)}',
    'الدقائق: ${displayValue(r.minutes)}',
  ];
  if (r.attendStatueId == AttendStatus.attended) {
    lines.addAll([
      'السورة الجديدة: ${resolveSurahName(r.newId)}',
      'الجديد من: ${displayValue(r.newFrom)}',
      'الجديد إلى: ${displayValue(r.newTo)}',
      'التقييم العام: ${displayValue(r.newRate)}',
      'الماضي القريب: ${displayValue(r.recentPast)}',
      'الماضي البعيد: ${displayValue(r.distantPast)}',
      'الأبعد: ${displayValue(r.farthestPast)}',
      'غريب القرآن: ${displayValue(r.theWordsQuranStranger)}',
      'التجويد: ${displayValue(r.intonation)}',
    ]);
  }
  return lines.join('\n');
}
