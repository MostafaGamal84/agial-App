import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const _filterStorageKey = 'report_filter';

  Future<void> restoreFilter(UserProfile currentUser) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('${_storageKeyForUser(currentUser)}');
    if (raw != null) {
      filter = ReportFilter.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }
  }

  Future<void> _persistFilter(UserProfile currentUser) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKeyForUser(currentUser),
      jsonEncode(filter.toJson()),
    );
  }

  String _storageKeyForUser(UserProfile currentUser) => '$_filterStorageKey-${currentUser.id}';

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
    await _persistFilter(currentUser);
    await refresh(currentUser);
  }
}
