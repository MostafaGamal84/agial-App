enum InvoiceStatus {
  paid('1', 'مدفوع'),
  unpaid('2', 'غير مدفوع'),
  partial('3', 'مدفوع جزئياً'),
  cancelled('4', 'ملغي');

  final String id;
  final String label;
  const InvoiceStatus(this.id, this.label);

  static InvoiceStatus fromString(String? value) {
    switch (value) {
      case '1':
      case 'paid':
        return InvoiceStatus.paid;
      case '2':
      case 'unpaid':
        return InvoiceStatus.unpaid;
      case '3':
      case 'partial':
        return InvoiceStatus.partial;
      case '4':
      case 'cancelled':
        return InvoiceStatus.cancelled;
      default:
        return InvoiceStatus.unpaid;
    }
  }
}

class Invoice {
  final String id;
  final String invoiceNumber;
  final String userId;
  final String userName;
  final String? userEmail;
  final String? userMobile;
  final InvoiceStatus status;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final DateTime dueDate;
  final DateTime createdDate;
  final DateTime? paidDate;
  final String? description;
  final String? paymentMethod;
  final String? transactionId;
  final List<InvoiceItem> items;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.userId,
    required this.userName,
    this.userEmail,
    this.userMobile,
    required this.status,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.dueDate,
    required this.createdDate,
    this.paidDate,
    this.description,
    this.paymentMethod,
    this.transactionId,
    this.items = const [],
  });

  bool get isPaid => status == InvoiceStatus.paid;
  bool get isUnpaid => status == InvoiceStatus.unpaid;
  bool get isOverdue => dueDate.isBefore(DateTime.now()) && !isPaid;

  factory Invoice.fromJson(Map<String, dynamic> json) {
    List<InvoiceItem> itemsList = [];
    if (json['items'] != null) {
      itemsList = (json['items'] as List)
          .map((item) => InvoiceItem.fromJson(item))
          .toList();
    }

    return Invoice(
      id: json['id']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber']?.toString() ?? 
                     json['number']?.toString() ?? 
                     '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? 
                json['user']?['fullName']?.toString() ?? 
                '',
      userEmail: json['userEmail']?.toString() ?? 
                 json['user']?['email']?.toString(),
      userMobile: json['userMobile']?.toString() ?? 
                  json['user']?['mobile']?.toString(),
      status: InvoiceStatus.fromString(json['status']?.toString()),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 
                   double.tryParse(json['totalAmount']?.toString() ?? '') ?? 
                   0.0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      dueDate: DateTime.tryParse(json['dueDate']?.toString() ?? '') ?? DateTime.now(),
      createdDate: DateTime.tryParse(json['createdDate']?.toString() ?? '') ?? DateTime.now(),
      paidDate: json['paidDate'] != null
          ? DateTime.tryParse(json['paidDate'].toString())
          : null,
      description: json['description']?.toString(),
      paymentMethod: json['paymentMethod']?.toString(),
      transactionId: json['transactionId']?.toString(),
      items: itemsList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'invoiceNumber': invoiceNumber,
        'userId': userId,
        'userName': userName,
        'status': status.id,
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'remainingAmount': remainingAmount,
        'dueDate': dueDate.toIso8601String(),
        'createdDate': createdDate.toIso8601String(),
        'paidDate': paidDate?.toIso8601String(),
        'description': description,
        'paymentMethod': paymentMethod,
        'transactionId': transactionId,
      };
}

class InvoiceItem {
  final String id;
  final String description;
  final double quantity;
  final double unitPrice;
  final double totalPrice;

  InvoiceItem({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
