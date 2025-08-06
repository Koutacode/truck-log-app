class FuelRecord {
  final int? id;
  final int? tripId;
  final DateTime timestamp;
  final String? location;
  final double liters;
  final double amount;
  final DateTime createdAt;

  FuelRecord({
    this.id,
    this.tripId,
    required this.timestamp,
    this.location,
    required this.liters,
    required this.amount,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'timestamp': timestamp.toIso8601String(),
      'location': location,
      'liters': liters,
      'amount': amount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FuelRecord.fromMap(Map<String, dynamic> map) {
    return FuelRecord(
      id: map['id'],
      tripId: map['trip_id'],
      timestamp: DateTime.parse(map['timestamp']),
      location: map['location'],
      liters: map['liters'].toDouble(),
      amount: map['amount'].toDouble(),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  FuelRecord copyWith({
    int? id,
    int? tripId,
    DateTime? timestamp,
    String? location,
    double? liters,
    double? amount,
    DateTime? createdAt,
  }) {
    return FuelRecord(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
      liters: liters ?? this.liters,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  double get pricePerLiter => amount / liters;
}

