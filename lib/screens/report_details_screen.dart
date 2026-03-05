import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../services/report_service.dart';
import '../utils/report_helpers.dart';
import '../widgets/page_transition_wrapper.dart';
import '../widgets/toast.dart';
import 'report_form_screen.dart';

class ReportDetailsScreen extends StatefulWidget {
  const ReportDetailsScreen({super.key, required this.row, required this.currentUser});

  final ReportDisplayRow row;
  final UserProfile currentUser;

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  bool isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final report = row.report;
    final canEdit = !widget.currentUser.isStudent && report.id.isNotEmpty;

    return PageTransitionWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل التقرير'),
          actions: [
            if (canEdit) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReportFormScreen(currentUser: widget.currentUser, existingReport: report))),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: isDeleting ? null : _delete,
              )
            ]
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(title: const Text('البيانات العامة', style: TextStyle(fontWeight: FontWeight.bold))),
            _item('الطالب', getStudentName(row)),
            _item('الحلقة', getCircleName(row)),
            _item('المعلم', getTeacherName(row)),
            _item('الحالة', getStatusLabel(report.attendStatueId)),
            _item('الدقائق', displayValue(report.minutes)),
            _item('وقت الإنشاء', formatDate(report.creationTime)),
            const Divider(),
            ListTile(title: const Text('الدرس الجديد', style: TextStyle(fontWeight: FontWeight.bold))),
            _item('السورة الجديدة', resolveSurahName(report.newId)),
            _item('الجديد من', displayValue(report.newFrom)),
            _item('الجديد إلى', displayValue(report.newTo)),
            _item('تقييم الحفظ الجديد', displayValue(report.newRate)),
            _item('التقييم العام', displayValue(report.generalRate)),
            const Divider(),
            ListTile(title: const Text('المراجعة', style: TextStyle(fontWeight: FontWeight.bold))),
            _item('الماضي القريب', displayValue(report.recentPast)),
            _item('تقييم الماضي القريب', displayValue(report.recentPastRate)),
            _item('الماضي البعيد', displayValue(report.distantPast)),
            _item('تقييم الماضي البعيد', displayValue(report.distantPastRate)),
            _item('الأبعد', displayValue(report.farthestPast)),
            _item('تقييم الأبعد', displayValue(report.farthestPastRate)),
            const Divider(),
            ListTile(title: const Text('متابعة إضافية', style: TextStyle(fontWeight: FontWeight.bold))),
            _item('غريب القرآن', displayValue(report.theWordsQuranStranger)),
            _item('التجويد', displayValue(report.intonation)),
            _item('مرئي', report.isVisual == null ? '-' : (report.isVisual! ? 'نعم' : 'لا')),
            _item('الواجب القادم', displayValue(report.nextCircleOrder)),
            _item('ملاحظات أخرى', displayValue(report.other)),
          ],
        ),
      ),
    );
  }

  Widget _item(String k, String v) => ListTile(title: Text(k), subtitle: Text(v));

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف التقرير'),
        content: const Text('هل انت متاكد من حذف التقرير؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => isDeleting = true);
    try {
      await context.read<ReportService>().deleteReport(widget.row.report.id);
      if (mounted) {
        showToast(context, 'تم حذف التقرير');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showToast(context, e.toString(), isError: true);
    }
    if (mounted) setState(() => isDeleting = false);
  }
}
