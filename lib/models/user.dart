import 'package:flutter/foundation.dart';

enum UserType {
  admin('1', 'System Admin'),
  branchLeader('2', 'Branch Manager'),
  manager('3', 'Supervisor'),
  teacher('4', 'Teacher');

  final String id;
  final String label;
  const UserType(this.id, this.label);

  /// نحول الـ role أو userTypeId القادم من الـ API إلى UserType
  static UserType fromRoleId(String? id) {
    switch (id) {
      case '1':
        return UserType.admin;
      case '2':
        return UserType.branchLeader;
      case '3':
        return UserType.manager;
      case '4':
        return UserType.teacher;
      default:
        return UserType.teacher;
    }
  }
}

@immutable
class UserProfile {
  final String id;
  final String fullName;
  final UserType userType;
  final String branchId;
  final String? managerId;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.userType,
    required this.branchId,
    this.managerId,
  });

  bool get isAdmin => userType == UserType.admin;
  bool get isBranchLeader => userType == UserType.branchLeader;
  bool get isManager => userType == UserType.manager;
  bool get isTeacher => userType == UserType.teacher;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // ⚠️ هنا التعديل المهم:
    // الـ API الحالي بيرجع "role"، وفي المستقبل ممكن يرجّع "userTypeId"
    final dynamic rawRole = json['userTypeId'] ?? json['role'];

    return UserProfile(
      id: json['userId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      userType: UserType.fromRoleId(rawRole?.toString()),
      branchId: json['branchId']?.toString() ?? '',
      managerId: json['managerId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': id,
        'fullName': fullName,
        'userTypeId': userType.id,
        'branchId': branchId,
        'managerId': managerId,
      };
}
