import 'package:flutter/foundation.dart';

enum UserType {
  admin('1', 'System Admin'),
  branchLeader('2', 'Branch Manager'),
  manager('3', 'Supervisor'),
  teacher('4', 'Teacher');

  const UserType(this.id, this.label);

  final String id;
  final String label;

  static UserType fromId(String id) {
    return UserType.values.firstWhere((role) => role.id == id);
  }
}

@immutable
class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.userType,
    required this.branchId,
    this.managerId,
  });

  final String id;
  final String fullName;
  final UserType userType;
  final String branchId;
  final String? managerId;

  bool get isAdmin => userType == UserType.admin;
  bool get isBranchLeader => userType == UserType.branchLeader;
  bool get isManager => userType == UserType.manager;
  bool get isTeacher => userType == UserType.teacher;

  factory UserProfile.fromApi(Map<String, dynamic> json) {
    return UserProfile(
      id: json['userId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      userType: UserType.fromId(json['userTypeId']?.toString() ?? '4'),
      branchId: json['branchId']?.toString() ?? '',
      managerId: json['managerId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': id,
      'fullName': fullName,
      'userTypeId': userType.id,
      'branchId': branchId,
      'managerId': managerId,
    };
  }
}
