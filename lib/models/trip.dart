class Trip {
  final int? id;
  final DateTime startTime;
  final DateTime? endTime;
  final String? startLocation;
  final String? endLocation;
  final String destination;
  final bool isCompleted;
  final DateTime createdAt;

  Trip({
    this.id,
    required this.startTime,
    this.endTime,
    this.startLocation,
    this.endLocation,
    required this.destination,
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'start_location': startLocation,
      'end_location': endLocation,
      'destination': destination,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'],
      startTime: DateTime.parse(map['start_time']),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time']) : null,
      startLocation: map['start_location'],
      endLocation: map['end_location'],
      destination: map['destination'],
      isCompleted: map['is_completed'] == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Trip copyWith({
    int? id,
    DateTime? startTime,
    DateTime? endTime,
    String? startLocation,
    String? endLocation,
    String? destination,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return Trip(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      destination: destination ?? this.destination,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  String get formattedDuration {
    final d = duration;
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}

