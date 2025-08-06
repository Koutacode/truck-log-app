enum BreakType {
  rest('休憩'),
  sleep('仮眠'),
  meal('食事'),
  other('その他');

  const BreakType(this.displayName);
  final String displayName;
}

class BreakRecord {
  final int? id;
  final int? tripId;
  final DateTime startTime;
  final DateTime? endTime;
  final BreakType breakType;
  final String? location;
  final DateTime createdAt;

  BreakRecord({
    this.id,
    this.tripId,
    required this.startTime,
    this.endTime,
    required this.breakType,
    this.location,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'break_type': breakType.name,
      'location': location,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory BreakRecord.fromMap(Map<String, dynamic> map) {
    return BreakRecord(
      id: map['id'],
      tripId: map['trip_id'],
      startTime: DateTime.parse(map['start_time']),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time']) : null,
      breakType: BreakType.values.firstWhere(
        (type) => type.name == map['break_type'],
        orElse: () => BreakType.rest,
      ),
      location: map['location'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  BreakRecord copyWith({
    int? id,
    int? tripId,
    DateTime? startTime,
    DateTime? endTime,
    BreakType? breakType,
    String? location,
    DateTime? createdAt,
  }) {
    return BreakRecord(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      breakType: breakType ?? this.breakType,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  String get formattedDuration {
    final d = duration;
    if (d == null) return '進行中';
    
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  bool get isActive => endTime == null;
}

