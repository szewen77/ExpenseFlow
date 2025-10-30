import 'transaction.dart';

enum RecurrenceInterval { weekly, monthly, yearly }

class RecurringTransaction {
  const RecurringTransaction({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.type,
    required this.interval,
    required this.nextOccurrence,
  });

  final int? id;
  final String title;
  final double amount;
  final String category;
  final TransactionType type;
  final RecurrenceInterval interval;
  final DateTime nextOccurrence;

  RecurringTransaction copyWith({
    int? id,
    String? title,
    double? amount,
    String? category,
    TransactionType? type,
    RecurrenceInterval? interval,
    DateTime? nextOccurrence,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      type: type ?? this.type,
      interval: interval ?? this.interval,
      nextOccurrence: nextOccurrence ?? this.nextOccurrence,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'type': type.name,
      'interval': interval.name,
      'nextOccurrence': nextOccurrence.millisecondsSinceEpoch,
    };
  }

  factory RecurringTransaction.fromMap(Map<String, Object?> map) {
    return RecurringTransaction(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      type: TransactionType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      interval: RecurrenceInterval.values.firstWhere(
        (value) => value.name == map['interval'],
        orElse: () => RecurrenceInterval.monthly,
      ),
      nextOccurrence: DateTime.fromMillisecondsSinceEpoch(
        map['nextOccurrence'] as int,
      ),
    );
  }
}
