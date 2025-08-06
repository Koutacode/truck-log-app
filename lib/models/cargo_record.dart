enum CargoType {
  loading('荷積み'),
  unloading('荷下ろし');

  const CargoType(this.displayName);
  final String displayName;
}

class CargoRecord {
  final int? id;
  final int? tripId;
  final DateTime timestamp;
  final CargoType type;
  final String? location;
  final String? customer;
  final String? photoPath;
  final String? notes;
  final DateTime createdAt;

  CargoRecord({
    this.id,
    this.tripId,
    required this.timestamp,
    required this.type,
    this.location,
    this.customer,
    this.photoPath,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'location': location,
      'customer': customer,
      'photo_path': photoPath,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CargoRecord.fromMap(Map<String, dynamic> map) {
    return CargoRecord(
      id: map['id'],
      tripId: map['trip_id'],
      timestamp: DateTime.parse(map['timestamp']),
      type: CargoType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => CargoType.loading,
      ),
      location: map['location'],
      customer: map['customer'],
      photoPath: map['photo_path'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  CargoRecord copyWith({
    int? id,
    int? tripId,
    DateTime? timestamp,
    CargoType? type,
    String? location,
    String? customer,
    String? photoPath,
    String? notes,
    DateTime? createdAt,
  }) {
    return CargoRecord(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      location: location ?? this.location,
      customer: customer ?? this.customer,
      photoPath: photoPath ?? this.photoPath,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

