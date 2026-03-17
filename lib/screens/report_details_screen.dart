import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/circle_report.dart';
import '../models/user.dart';
import '../services/report_service.dart';
import '../utils/report_helpers.dart';
import '../widgets/page_transition_wrapper.dart';
import '../widgets/toast.dart';
import 'report_form_screen.dart';

class ReportDetailsScreen extends StatefulWidget {
  const ReportDetailsScreen({
    super.key,
    required this.row,
    required this.currentUser,
  });

  final ReportDisplayRow row;
  final UserProfile currentUser;

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  bool _isDeleting = false;
  bool _isRefreshing = false;
  CircleReport? _fullReport;

  ReportDisplayRow get _resolvedRow =>
      widget.row.copyWith(report: _fullReport ?? widget.row.report);

  CircleReport get _report => _resolvedRow.report;

  bool get _canEdit =>
      !widget.currentUser.isStudent && _resolvedRow.report.id.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _fullReport = widget.row.report;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReportDetails());
  }

  Future<void> _loadReportDetails({bool showFailureToast = false}) async {
    final reportId = widget.row.report.id.trim();
    if (reportId.isEmpty) {
      return;
    }

    setState(() => _isRefreshing = true);

    try {
      final report = await context.read<ReportService>().fetchReport(reportId);
      if (!mounted) {
        return;
      }
      setState(() => _fullReport = report);
    } catch (_) {
      if (showFailureToast && mounted) {
        showToast(
          context,
          'تعذر تحديث تفاصيل التقرير بالكامل، وتم عرض البيانات المتاحة.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageTransitionWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل التقرير'),
          actions: [
            if (_canEdit) ...[
              IconButton(
                tooltip: 'تعديل التقرير',
                icon: const Icon(
                  Icons.edit_outlined,
                  semanticLabel: 'تعديل التقرير',
                ),
                onPressed: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReportFormScreen(
                        currentUser: widget.currentUser,
                        existingReport: _report,
                      ),
                    ),
                  );

                  if (result != null && mounted) {
                    await _loadReportDetails(showFailureToast: true);
                  }
                },
              ),
              IconButton(
                tooltip: 'حذف التقرير',
                icon: const Icon(
                  Icons.delete_outline,
                  semanticLabel: 'حذف التقرير',
                ),
                onPressed: _isDeleting ? null : _delete,
              ),
            ],
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isRefreshing) ...[
              const LinearProgressIndicator(minHeight: 2),
              const SizedBox(height: 16),
            ],
            _DetailsSection(
              title: 'البيانات العامة',
              children: [
                _DetailItem(label: 'المشرف', value: getManagerName(_report)),
                _DetailItem(label: 'المعلم', value: getTeacherName(_resolvedRow)),
                _DetailItem(label: 'الحلقة', value: getCircleName(_resolvedRow)),
                _DetailItem(label: 'الطالب', value: getStudentName(_resolvedRow)),
                _DetailItem(
                  label: 'حالة الحضور',
                  value: getStatusLabel(_report.attendStatueId),
                ),
                _DetailItem(
                  label: 'عدد الدقائق',
                  value: displayValue(_report.minutes),
                ),
                _DetailItem(
                  label: 'تاريخ التقرير',
                  value: formatDate(_report.creationTime),
                ),
                _DetailItem(
                  label: 'الحصة مرئية',
                  value: getVisualLabel(_report.isVisual),
                ),
                _DetailItem(
                  label: 'مقرر الحصة القادمة',
                  value: displayValue(_report.nextCircleOrder),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DetailsSection(
              title: 'الدرس الجديد',
              children: [
                _DetailItem(
                  label: 'السورة الجديدة',
                  value: resolveSurahName(_report.newId),
                ),
                _DetailItem(label: 'من', value: displayValue(_report.newFrom)),
                _DetailItem(label: 'إلى', value: displayValue(_report.newTo)),
                _DetailItem(
                  label: 'تقييم الدرس الجديد',
                  value: displayValue(_report.newRate),
                ),
                _DetailItem(
                  label: 'التقييم العام',
                  value: displayValue(_report.generalRate),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DetailsSection(
              title: 'المراجعة',
              children: [
                _DetailItem(
                  label: 'المراجعة القريبة',
                  value: displayValue(_report.recentPast),
                ),
                _DetailItem(
                  label: 'تقييم المراجعة القريبة',
                  value: displayValue(_report.recentPastRate),
                ),
                _DetailItem(
                  label: 'المراجعة البعيدة',
                  value: displayValue(_report.distantPast),
                ),
                _DetailItem(
                  label: 'تقييم المراجعة البعيدة',
                  value: displayValue(_report.distantPastRate),
                ),
                _DetailItem(
                  label: 'المراجعة الأبعد',
                  value: displayValue(_report.farthestPast),
                ),
                _DetailItem(
                  label: 'تقييم المراجعة الأبعد',
                  value: displayValue(_report.farthestPastRate),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DetailsSection(
              title: 'ملاحظات إضافية',
              children: [
                _DetailItem(
                  label: 'كلمات غريب القرآن',
                  value: displayValue(_report.theWordsQuranStranger),
                ),
                _DetailItem(
                  label: 'التجويد',
                  value: displayValue(_report.intonation),
                ),
                _DetailItem(
                  label: 'ملاحظات أخرى',
                  value: displayValue(_report.other),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف التقرير'),
        content: const Text('هل أنت متأكد من حذف التقرير؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _isDeleting = true);

    try {
      await context.read<ReportService>().deleteReport(_report.id);
      if (mounted) {
        showToast(context, 'تم حذف التقرير');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        showToast(context, e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
