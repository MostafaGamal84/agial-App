import 'package:flutter/material.dart';

import '../models/circle_report.dart';
import '../services/report_service.dart';

class ReportDetailsScreen extends StatelessWidget {
  const ReportDetailsScreen({super.key, required this.row});

  final ReportDisplayRow row;

  Color _statusColor(AttendStatus status) {
    switch (status) {
      case AttendStatus.attended:
        return Colors.green.shade600;
      case AttendStatus.ExcusedAbsence:
        return Colors.orange.shade700;
      case AttendStatus.UnexcusedAbsence:
        return Colors.red.shade700;
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final twoDigits = (int value) => value.toString().padLeft(2, '0');
    return '${local.year}/${twoDigits(local.month)}/${twoDigits(local.day)}';
  }

  Widget _metaTile(String label, String? value, {IconData? icon}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    return ListTile(
      dense: true,
      leading: icon != null ? Icon(icon) : null,
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = row.report;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل التقرير'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              row.studentName.isEmpty
                                  ? 'طالب غير معروف'
                                  : row.studentName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(row.circleName.isEmpty ? 'حلقة غير معروفة' : row.circleName),
                            Text(row.teacherName.isEmpty ? 'معلم غير معروف' : row.teacherName),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: _statusColor(report.attendStatueId).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: Text(
                              report.attendStatueId.label,
                              style: TextStyle(
                                color: _statusColor(report.attendStatueId),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDate(report.creationTime),
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      if (report.minutes != null)
                        Chip(
                          avatar: const Icon(Icons.timer_outlined, size: 18),
                          label: Text('${report.minutes} دقيقة'),
                          backgroundColor: Colors.grey.shade100,
                        ),
                      if (report.newId != null)
                        Chip(
                          avatar: const Icon(Icons.bookmark_border, size: 18),
                          label: Text('الجزء الجديد رقم ${report.newId}'),
                          backgroundColor: Colors.grey.shade100,
                        ),
                    ],
                  ),
                  const Divider(height: 28),
                  _metaTile(
                    'الجديد',
                    '${report.newFrom ?? ''}${report.newFrom != null && report.newTo != null ? ' → ' : ''}${report.newTo ?? ''}',
                    icon: Icons.menu_book_outlined,
                  ),
                  _metaTile(
                    'القريب',
                    _combineText(report.recentPast, report.recentPastRate),
                    icon: Icons.history_toggle_off,
                  ),
                  _metaTile(
                    'البعيد',
                    _combineText(report.distantPast, report.distantPastRate),
                    icon: Icons.auto_stories_outlined,
                  ),
                  _metaTile(
                    'الأبعد',
                    _combineText(report.farthestPast, report.farthestPastRate),
                    icon: Icons.menu_book,
                  ),
                  _metaTile(
                    'غريب القرآن',
                    report.theWordsQuranStranger,
                    icon: Icons.translate,
                  ),
                  _metaTile(
                    'التجويد',
                    report.intonation,
                    icon: Icons.graphic_eq,
                  ),
                  _metaTile(
                    'ملاحظات',
                    report.other,
                    icon: Icons.notes,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _combineText(String? value, String? rate) {
    final parts = [value, rate]
        .where((element) => element != null && element!.trim().isNotEmpty)
        .map((e) => e!.trim())
        .toList();
    return parts.join(' — ');
  }
}
