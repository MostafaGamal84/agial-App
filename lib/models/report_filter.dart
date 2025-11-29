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

  factory ReportFilter.fromJson(Map<String, dynamic> json) {
    return ReportFilter(
      supervisorId: json['supervisorId'] as String?,
      teacherId: json['teacherId'] as String?,
      circleId: json['circleId'] as String?,
      studentId: json['studentId'] as String?,
      searchTerm: json['searchTerm'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'supervisorId': supervisorId,
      'teacherId': teacherId,
      'circleId': circleId,
      'studentId': studentId,
      'searchTerm': searchTerm,
    };
  }

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
