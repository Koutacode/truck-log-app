enum ExpenseCategory {
  fuel('燃料代'),
  toll('高速代'),
  food('食費'),
  parking('駐車場代'),
  maintenance('整備費'),
  other('その他');

  const ExpenseCategory(this.displayName);
  final String displayName;
}

class ExpenseRecord {
  final int? id;
  final int? tripId;
  final DateTime timestamp;
  final ExpenseCategory category;
  final double amount;
  final String? description;
  final String? receiptPath;
  final DateTime createdAt;

  ExpenseRecord({
    this.id,
    this.tripId,
    required this.timestamp,
    required this.category,
    required this.amount,
    this.description,
    this.receiptPath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'timestamp': timestamp.toIso8601String(),
      'category': category.name,
      'amount': amount,
      'description': description,
      'receipt_path': receiptPath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ExpenseRecord.fromMap(Map<String, dynamic> map) {
    return ExpenseRecord(
      id: map['id'],
      tripId: map['trip_id'],
      timestamp: DateTime.parse(map['timestamp']),
      category: ExpenseCategory.values.firstWhere(
        (category) => category.name == map['category'],
        orElse: () => ExpenseCategory.other,
      ),
      amount: map['amount'].toDouble(),
      description: map['description'],
      receiptPath: map['receipt_path'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  ExpenseRecord copyWith({
    int? id,
    int? tripId,
    DateTime? timestamp,
    ExpenseCategory? category,
    double? amount,
    String? description,
    String? receiptPath,
    DateTime? createdAt,
  }) {
    return ExpenseRecord(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      receiptPath: receiptPath ?? this.receiptPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

