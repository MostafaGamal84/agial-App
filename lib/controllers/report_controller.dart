import 'package:flutter/material.dart';

import '../models/circle_report.dart';
import '../models/user.dart';
import '../services/report_service.dart';

/// =======================================================
/// REPORT CONTROLLER
/// =======================================================
class ReportController extends ChangeNotifier {
  ReportController(this.reportService);

  final ReportService reportService;

  List<ReportDisplayRow> reports = [];
  bool isLoading = false;
  String? errorMessage;

  /// Refresh reports for the current user
  Future<void> refresh(UserProfile currentUser) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      reports = await reportService.fetchReports(
        currentUser: currentUser,
      );
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }
}
