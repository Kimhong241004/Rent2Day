class Tenant {
  final String id;
  final String name;
  final String phone;
  final String nationalId;
  final double deposit;
  final String assignedRoom;
  final DateTime moveInDate;
  final DateTime? moveOutDate;

  Tenant({
    required this.id,
    required this.name,
    required this.phone,
    required this.nationalId,
    required this.deposit,
    required this.assignedRoom,
    required this.moveInDate,
    this.moveOutDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'nationalId': nationalId,
      'deposit': deposit,
      'assignedRoom': assignedRoom,
      'moveInDate': moveInDate.toIso8601String(),
      'moveOutDate': moveOutDate?.toIso8601String(),
    };
  }

  factory Tenant.fromMap(Map<String, dynamic> map) {
    return Tenant(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      nationalId: map['nationalId'],
      deposit: map['deposit'],
      assignedRoom: map['assignedRoom'],
      moveInDate: DateTime.parse(map['moveInDate']),
      moveOutDate: map['moveOutDate'] != null ? DateTime.parse(map['moveOutDate']) : null,
    );
  }
}
