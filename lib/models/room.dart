class Room {
  final String id;
  final String roomNumber;
  final String floor; // e.g., "1", "2", "3"
  final String roomType; // e.g., "Studio", "1BHK", "2BHK"
  final double rentAmount;
  final double deposit; // Deposit required for the room
  final String status; // "Available", "Occupied", "Maintenance"
  final String? currentTenant;

  Room({
    required this.id,
    required this.roomNumber,
    required this.floor,
    required this.roomType,
    required this.rentAmount,
    required this.deposit,
    required this.status,
    this.currentTenant,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomNumber': roomNumber,
      'floor': floor,
      'roomType': roomType,
      'rentAmount': rentAmount,
      'deposit': deposit,
      'status': status,
      'currentTenant': currentTenant,
    };
  }

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'],
      roomNumber: map['roomNumber'],
      floor: map['floor'] ?? map['roomType'].split(' ').first, // Fallback for old data
      roomType: map['roomType'],
      rentAmount: map['rentAmount'],
      deposit: map['deposit'] ?? 0.0, // Default to 0 if not set
      status: map['status'],
      currentTenant: map['currentTenant'],
    );
  }
}
