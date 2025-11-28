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
      reports = reportService.getReports(filter: filter, currentUser: currentUser);
    } catch (e) {
      errorMessage = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  void updateFilter(ReportFilter newFilter, UserProfile currentUser) {
    filter = newFilter;
    refresh(currentUser);
  }
}
