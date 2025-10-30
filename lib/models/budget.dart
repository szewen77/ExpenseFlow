class Budget {
  const Budget({
    required this.id,
    required this.category,
    required this.limit,
    required this.period, // monthly, weekly, etc.
  });

  final int? id;
  final String category;
  final double limit;
  final String period;

  Budget copyWith({int? id, String? category, double? limit, String? period}) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      limit: limit ?? this.limit,
      period: period ?? this.period,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'category': category,
      'limitAmount': limit,
      'period': period,
    };
  }

  factory Budget.fromMap(Map<String, Object?> map) {
    return Budget(
      id: map['id'] as int?,
      category: map['category'] as String,
      limit: (map['limitAmount'] as num).toDouble(),
      period: map['period'] as String,
    );
  }
}
