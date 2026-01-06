class Maintenance {
  final String id;
  final String roomId;
  final String description;
  final String status; // "Pending", "In Progress", "Completed"
  final DateTime reportedDate;
  final DateTime? completedDate;
  final double? cost;

  Maintenance({
    required this.id,
    required this.roomId,
    required this.description,
    required this.status,
    required this.reportedDate,
    this.completedDate,
    this.cost,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomId': roomId,
      'description': description,
      'status': status,
      'reportedDate': reportedDate.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'cost': cost,
    };
  }

  factory Maintenance.fromMap(Map<String, dynamic> map) {
    return Maintenance(
      id: map['id'],
      roomId: map['roomId'],
      description: map['description'],
      status: map['status'],
      reportedDate: DateTime.parse(map['reportedDate']),
      completedDate: map['completedDate'] != null ? DateTime.parse(map['completedDate']) : null,
      cost: map['cost'],
    );
  }
}
