class Goal {
  const Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.startDate,
    required this.endDate,
  });

  final int? id;
  final String name;
  final double targetAmount;
  final DateTime startDate;
  final DateTime endDate;

  Goal copyWith({
    int? id,
    String? name,
    double? targetAmount,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
    };
  }

  factory Goal.fromMap(Map<String, Object?> map) {
    return Goal(
      id: map['id'] as int?,
      name: map['name'] as String,
      targetAmount: (map['targetAmount'] as num).toDouble(),
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate'] as int),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['endDate'] as int),
    );
  }
}
