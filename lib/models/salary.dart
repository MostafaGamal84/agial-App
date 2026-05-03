enum SalaryStatus {
  pending('1', 'معلق'),
  approved('2', 'موافق عليه'),
  paid('3', 'مدفوع'),
  rejected('4', 'مرفوض');

  final String id;
  final String label;
  const SalaryStatus(this.id, this.label);

  static SalaryStatus fromString(String? value) {
    switch (value) {
      case '1':
      case 'pending':
        return SalaryStatus.pending;
      case '2':
      case 'approved':
        return SalaryStatus.approved;
      case '3':
      case 'paid':
        return SalaryStatus.paid;
      case '4':
      case 'rejected':
        return SalaryStatus.rejected;
      default:
        return SalaryStatus.pending;
    }
  }
}

class SalaryRecord {
  final String id;
  final String teacherId;
  final String teacherName;
  final String? teacherMobile;
  final String? managerId;
  final String? managerName;
  final String? branchId;
  final String? branchName;
  final int month;
  final int year;
  final double baseSalary;
  final double allowances;
  final double deductions;
  final double bonuses;
  final double netSalary;
  final SalaryStatus status;
  final DateTime? paymentDate;
  final String? paymentMethod;
  final String? transactionId;
  final DateTime createdDate;
  final String? notes;
  final int studentCount;
  final int attendanceCount;
  final int reportsCount;
  final bool isMonthLocked; // if true, reports for this month cannot be modified

  SalaryRecord({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    this.teacherMobile,
    this.managerId,
    this.managerName,
    this.branchId,
    this.branchName,
    required this.month,
    required this.year,
    required this.baseSalary,
    required this.allowances,
    required this.deductions,
    required this.bonuses,
    required this.netSalary,
    required this.status,
    this.paymentDate,
    this.paymentMethod,
    this.transactionId,
    required this.createdDate,
    this.notes,
    this.studentCount = 0,
    this.attendanceCount = 0,
    this.reportsCount = 0,
    this.isMonthLocked = false,
  });

  String get monthYear => '$month/$year';
  
  String get monthName {
    const months = [
      '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return months[month];
  }

  bool get isPaid => status == SalaryStatus.paid;
  bool get isPending => status == SalaryStatus.pending;

  factory SalaryRecord.fromJson(Map<String, dynamic> json) {
    return SalaryRecord(
      id: json['id']?.toString() ?? '',
      teacherId: json['teacherId']?.toString() ?? '',
      teacherName: json['teacherName']?.toString() ?? 
                   json['teacher']?['fullName']?.toString() ?? 
                   '',
      teacherMobile: json['teacherMobile']?.toString() ?? 
                     json['teacher']?['mobile']?.toString(),
      managerId: json['managerId']?.toString(),
      managerName: json['managerName']?.toString(),
      branchId: json['branchId']?.toString(),
      branchName: json['branchName']?.toString(),
      month: json['month'] as int? ?? DateTime.now().month,
      year: json['year'] as int? ?? DateTime.now().year,
      baseSalary: (json['baseSalary'] as num?)?.toDouble() ?? 0.0,
      allowances: (json['allowances'] as num?)?.toDouble() ?? 0.0,
      deductions: (json['deductions'] as num?)?.toDouble() ?? 0.0,
      bonuses: (json['bonuses'] as num?)?.toDouble() ?? 0.0,
      netSalary: (json['netSalary'] as num?)?.toDouble() ?? 
                 (json['totalSalary'] as num?)?.toDouble() ?? 
                 0.0,
      status: SalaryStatus.fromString(json['status']?.toString()),
      paymentDate: json['paymentDate'] != null
          ? DateTime.tryParse(json['paymentDate'].toString())
          : null,
      paymentMethod: json['paymentMethod']?.toString(),
      transactionId: json['transactionId']?.toString(),
      createdDate: DateTime.tryParse(json['createdDate']?.toString() ?? '') ?? DateTime.now(),
      notes: json['notes']?.toString(),
      studentCount: json['studentCount'] as int? ?? 0,
      attendanceCount: json['attendanceCount'] as int? ?? 0,
      reportsCount: json['reportsCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'managerId': managerId,
        'managerName': managerName,
        'branchId': branchId,
        'branchName': branchName,
        'month': month,
        'year': year,
        'baseSalary': baseSalary,
        'allowances': allowances,
        'deductions': deductions,
        'bonuses': bonuses,
        'netSalary': netSalary,
        'status': status.id,
        'paymentDate': paymentDate?.toIso8601String(),
        'paymentMethod': paymentMethod,
        'transactionId': transactionId,
        'createdDate': createdDate.toIso8601String(),
        'notes': notes,
        'studentCount': studentCount,
        'attendanceCount': attendanceCount,
        'reportsCount': reportsCount,
      };
}

class SalarySummary {
  final int totalTeachers;
  final double totalSalaries;
  final double totalPaid;
  final double totalPending;
  final int paidCount;
  final int pendingCount;

  SalarySummary({
    required this.totalTeachers,
    required this.totalSalaries,
    required this.totalPaid,
    required this.totalPending,
    required this.paidCount,
    required this.pendingCount,
  });

  factory SalarySummary.fromJson(Map<String, dynamic> json) {
    return SalarySummary(
      totalTeachers: json['totalTeachers'] as int? ?? 0,
      totalSalaries: (json['totalSalaries'] as num?)?.toDouble() ?? 0.0,
      totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0.0,
      totalPending: (json['totalPending'] as num?)?.toDouble() ?? 0.0,
      paidCount: json['paidCount'] as int? ?? 0,
      pendingCount: json['pendingCount'] as int? ?? 0,
    );
  }
}
