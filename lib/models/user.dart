import 'package:flutter/foundation.dart';

enum UserType {
  admin('1', 'مدير النظام'),
  branchLeader('2', 'مدير الفرع'),
  manager('3', 'مشرف'),
  teacher('4', 'معلم'),
  student('5', 'طالب');

  final String id;
  final String label;
  const UserType(this.id, this.label);

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
      case '5':
        return UserType.student;
      default:
        return UserType.teacher;
    }
  }
}

@immutable
class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String mobile;
  final UserType userType;
  final String branchId;
  final String? branchName;
  final String? managerId;
  final String? managerName;
  final DateTime? createdDate;
  final String? qualification;
  final String? department;
  final String? nationalId;
  final String? profileImage;

  const UserProfile({
    required this.id,
    required this.fullName,
    this.email = '',
    this.mobile = '',
    required this.userType,
    required this.branchId,
    this.branchName,
    this.managerId,
    this.managerName,
    this.createdDate,
    this.qualification,
    this.department,
    this.nationalId,
    this.profileImage,
  });

  bool get isAdmin => userType == UserType.admin;
  bool get isBranchLeader => userType == UserType.branchLeader;
  bool get isManager => userType == UserType.manager;
  bool get isTeacher => userType == UserType.teacher;
  bool get isStudent => userType == UserType.student;
  
  bool get canViewUsers =>
      isAdmin || isBranchLeader || isManager;
  
  bool get canManageUsers =>
      isAdmin || isBranchLeader;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final dynamic rawRole = json['userTypeId'] ?? json['role'];

    return UserProfile(
      id: json['userId']?.toString() ?? json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? json['phone']?.toString() ?? '',
      userType: UserType.fromRoleId(rawRole?.toString()),
      branchId: json['branchId']?.toString() ?? '',
      branchName: json['branchName']?.toString(),
      managerId: json['managerId']?.toString(),
      managerName: json['managerName']?.toString(),
      createdDate: json['createdDate'] != null
          ? DateTime.tryParse(json['createdDate'].toString())
          : null,
      qualification: json['qualification']?.toString(),
      department: json['department']?.toString(),
      nationalId: json['nationalId']?.toString(),
      profileImage: json['profileImage']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': id,
        'fullName': fullName,
        'email': email,
        'mobile': mobile,
        'userTypeId': userType.id,
        'branchId': branchId,
        'branchName': branchName,
        'managerId': managerId,
        'managerName': managerName,
      };

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? mobile,
    UserType? userType,
    String? branchId,
    String? branchName,
    String? managerId,
    String? managerName,
    DateTime? createdDate,
    String? qualification,
    String? department,
    String? nationalId,
    String? profileImage,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      userType: userType ?? this.userType,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
      createdDate: createdDate ?? this.createdDate,
      qualification: qualification ?? this.qualification,
      department: department ?? this.department,
      nationalId: nationalId ?? this.nationalId,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}
