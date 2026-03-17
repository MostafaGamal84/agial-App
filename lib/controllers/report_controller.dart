import 'package:flutter/material.dart';

import '../models/report_stats.dart';
import '../models/user.dart';
import '../services/report_service.dart';

class ReportController extends ChangeNotifier {
  ReportController(this.reportService);

  final ReportService reportService;

  final List<ReportDisplayRow> reports = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  String? errorMessage;
  int totalCount = 0;
  ReportStats stats = const ReportStats();
  int pageIndex = 0;
  static const int pageSize = 10;

  String search = '';
  String? teacherId;
  String? circleId;
  int? studentId;
  int? residentGroup;
  DateTime? month;

  bool get hasMore => reports.length < totalCount;
  bool get canManageReports => _user?.isStudent != true;
  UserProfile? _user;

  Future<void> refresh(UserProfile currentUser) async {
    _user = currentUser;
    pageIndex = 0;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final pageFuture = reportService.fetchReports(
        currentUser: currentUser,
        pageIndex: 0,
        pageSize: pageSize,
        search: search,
        teacherId: teacherId,
        circleId: circleId,
        studentId: studentId,
        residentGroup: residentGroup,
        month: month,
      );
      final statsFuture = reportService.fetchReportStats(
        currentUser: currentUser,
        teacherId: teacherId,
        studentId: studentId,
        month: month,
      );
      final page = await pageFuture;
      stats = await statsFuture;
      reports
        ..clear()
        ..addAll(page.items);
      totalCount = page.totalCount;
    } catch (e) {
      errorMessage = e.toString();
      reports.clear();
      totalCount = 0;
      stats = const ReportStats();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_user == null || isLoading || isLoadingMore || !hasMore) return;
    isLoadingMore = true;
    notifyListeners();
    try {
      pageIndex += 1;
      final page = await reportService.fetchReports(
        currentUser: _user!,
        pageIndex: pageIndex,
        pageSize: pageSize,
        search: search,
        teacherId: teacherId,
        circleId: circleId,
        studentId: studentId,
        residentGroup: residentGroup,
        month: month,
      );
      reports.addAll(page.items);
      totalCount = page.totalCount;
    } catch (e) {
      errorMessage = e.toString();
    }
    isLoadingMore = false;
    notifyListeners();
  }
}
