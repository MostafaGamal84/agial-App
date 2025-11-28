class Student {
  const Student({
    required this.id,
    required this.fullName,
    required this.circleId,
    required this.teacherId,
    required this.branchId,
  });

  final String id;
  final String fullName;
  final String circleId;
  final String teacherId;
  final String branchId;

  factory Student.fromApi(Map<String, dynamic> json, {String? circleId, String? teacherId}) {
    final studentMap = json['student'] as Map<String, dynamic>?;
    return Student(
      id: (json['studentId'] ?? studentMap?['id']).toString(),
      fullName: (studentMap?['fullName'] ?? json['fullName'] ?? '').toString(),
      circleId: circleId ?? json['circleId']?.toString() ?? '',
      teacherId: teacherId ?? json['teacherId']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
    );
  }
}
