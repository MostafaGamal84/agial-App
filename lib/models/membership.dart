enum MembershipStatus {
  active('1', 'نشط'),
  expired('2', 'منتهي'),
  pending('3', 'معلق'),
  cancelled('4', 'ملغي');

  final String id;
  final String label;
  const MembershipStatus(this.id, this.label);

  static MembershipStatus fromString(String? value) {
    switch (value) {
      case '1':
      case 'active':
        return MembershipStatus.active;
      case '2':
      case 'expired':
        return MembershipStatus.expired;
      case '3':
      case 'pending':
        return MembershipStatus.pending;
      case '4':
      case 'cancelled':
        return MembershipStatus.cancelled;
      default:
        return MembershipStatus.pending;
    }
  }
}

class Membership {
  final String id;
  final String userId;
  final String userName;
  final String? userEmail;
  final String? userMobile;
  final String planId;
  final String planName;
  final MembershipStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final double price;
  final String? paymentMethod;
  final String? transactionId;
  final DateTime createdDate;

  Membership({
    required this.id,
    required this.userId,
    required this.userName,
    this.userEmail,
    this.userMobile,
    required this.planId,
    required this.planName,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.price,
    this.paymentMethod,
    this.transactionId,
    required this.createdDate,
  });

  bool get isActive => status == MembershipStatus.active;
  bool get isExpired => status == MembershipStatus.expired;
  
  int get remainingDays {
    final now = DateTime.now();
    if (endDate.isBefore(now)) return 0;
    return endDate.difference(now).inDays;
  }

  factory Membership.fromJson(Map<String, dynamic> json) {
    return Membership(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? 
                json['user']?['fullName']?.toString() ?? 
                '',
      userEmail: json['userEmail']?.toString() ?? 
                 json['user']?['email']?.toString(),
      userMobile: json['userMobile']?.toString() ?? 
                  json['user']?['mobile']?.toString(),
      planId: json['planId']?.toString() ?? '',
      planName: json['planName']?.toString() ?? 
                json['plan']?['name']?.toString() ?? 
                '',
      status: MembershipStatus.fromString(json['status']?.toString()),
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate']?.toString() ?? '') ?? DateTime.now(),
      price: (json['price'] as num?)?.toDouble() ?? 
             double.tryParse(json['price']?.toString() ?? '') ?? 
             0.0,
      paymentMethod: json['paymentMethod']?.toString(),
      transactionId: json['transactionId']?.toString(),
      createdDate: DateTime.tryParse(json['createdDate']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'userMobile': userMobile,
        'planId': planId,
        'planName': planName,
        'status': status.id,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'price': price,
        'paymentMethod': paymentMethod,
        'transactionId': transactionId,
        'createdDate': createdDate.toIso8601String(),
      };
}

class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final int durationDays;
  final String? features;
  final bool isActive;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationDays,
    this.features,
    required this.isActive,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      durationDays: json['durationDays'] as int? ?? 30,
      features: json['features']?.toString(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
