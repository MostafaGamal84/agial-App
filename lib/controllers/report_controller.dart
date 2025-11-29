import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/circle_report.dart';
import '../models/user.dart';
import '../services/report_service.dart';

/// =======================================================
/// FILTER MODEL
/// =======================================================
class ReportFilter {
  final String? supervisorId;
  final String? teacherId;
  final String? circleId;
  final String? studentId;
  final String? searchTerm;

  const ReportFilter({
    this.supervisorId,
    this.teacherId,
    this.circleId,
    this.studentId,
    this.searchTerm,
  });

  /// Factory for decoding from JSON (to restore saved filter)
  factory ReportFilter.fromJson(Map<String, dynamic> json) {
    return ReportFilter(
      supervisorId: json['supervisorId'] as String?,
      teacherId: json['teacherId'] as String?,
      circleId: json['circleId'] as String?,
      studentId: json['studentId'] as String?,
      searchTerm: json['searchTerm'] as String?,
    );
  }

  /// Converts to JSON for saving locally
  Map<String, dynamic> toJson() {
    return {
      'supervisorId': supervisorId,
      'teacherId': teacherId,
      'circleId': circleId,
      'studentId': studentId,
      'searchTerm': searchTerm,
    };
  }

  /// Clone with updated fields
  ReportFilter copyWith({
    String? supervisorId,
    String? teacherId,
    String? circleId,
    String? studentId,
    String? searchTerm,
  }) {
    return ReportFilter(
      supervisorId: supervisorId ?? this.supervisorId,
      teacherId: teacherId ?? this.teacherId,
      circleId: circleId ?? this.circleId,
      studentId: studentId ?? this.studentId,
      searchTerm: searchTerm ?? this.searchTerm,
    );
  }
}

/// =======================================================
/// REPORT CONTROLLER
/// =======================================================
class ReportController extends ChangeNotifier {
  ReportController(this.reportService);

  final ReportService reportService;

  ReportFilter filter = const ReportFilter();
  List<ReportDisplayRow> reports = [];
  bool isLoading = false;
  String? errorMessage;

  static const _filterStorageKey = 'report_filter';

  /// Restore saved filter (from SharedPreferences)
  Future<void> restoreFilter(UserProfile currentUser) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKeyForUser(currentUser));

    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        filter = ReportFilter.fromJson(decoded);
      } catch (e) {
        debugPrint('Failed to restore filter: $e');
      }
    }
  }

  /// Save filter state
  Future<void> _persistFilter(UserProfile currentUser) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKeyForUser(currentUser),
      jsonEncode(filter.toJson()),
    );
  }

  /// Compose key per user
  String _storageKeyForUser(UserProfile currentUser) =>
      '$_filterStorageKey-${currentUser.id}';

  /// Refresh reports based on filter
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

  /// Update filter & refresh
  Future<void> updateFilter(
    ReportFilter newFilter,
    UserProfile currentUser,
  ) async {
    filter = newFilter;
    await _persistFilter(currentUser);
    await refresh(currentUser);
  }
}
