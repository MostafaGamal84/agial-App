import 'package:flutter/material.dart';

import '../models/circle_report.dart';
import '../models/user.dart';
import '../services/report_service.dart';

class ReportController extends ChangeNotifier {
  ReportController(this.reportService);

  final ReportService reportService;
  ReportFilter filter = const ReportFilter();
  List<ReportDisplayRow> reports = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> refresh(UserProfile currentUser) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      reports = await reportService.fetchReports(
        filter: filter,
        currentUser: currentUser,
      );
    } catch (e) {
      errorMessage = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> updateFilter(ReportFilter newFilter, UserProfile currentUser) async {
    filter = newFilter;
    await refresh(currentUser);
  }
}
