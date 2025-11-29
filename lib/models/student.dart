// models/student.dart
import 'package:flutter/foundation.dart';

@immutable
class Student {
  final int id;
  final String fullName;

  const Student({
    required this.id,
    required this.fullName,
  });

  factory Student.fromApi(Map<String, dynamic> json) {
    final rawId = json['id'];
    final intId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;

    return Student(
      id: intId,
      fullName: json['fullName']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
    };
  }
}
