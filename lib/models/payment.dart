class Payment {
  final String id;
  final String roomNumber;
  final String tenantName;
  final String tenantPhone;
  final double amount;
  final DateTime date;
  final bool isPaid;

  Payment({
    required this.id,
    required this.roomNumber,
    required this.tenantName,
    required this.tenantPhone,
    required this.amount,
    required this.date,
    required this.isPaid,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomNumber': roomNumber,
      'tenantName': tenantName,
      'tenantPhone': tenantPhone,
      'amount': amount,
      'date': date.toIso8601String(),
      'isPaid': isPaid,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      roomNumber: map['roomNumber'],
      tenantName: map['tenantName'],
      tenantPhone: map['tenantPhone'],
      amount: map['amount']?.toDouble() ?? 0.0,
      date: DateTime.parse(map['date']),
      isPaid: map['isPaid'] ?? false,
    );
  }
}
