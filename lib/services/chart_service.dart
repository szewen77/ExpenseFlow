import 'dart:collection';

import '../models/transaction.dart';
import '../utils/helpers.dart';

class DailyTotal {
  DailyTotal({required this.date, this.income = 0, this.expense = 0});

  final DateTime date;
  final double income;
  final double expense;

  double get net => income - expense;

  DailyTotal copyWith({DateTime? date, double? income, double? expense}) {
    return DailyTotal(
      date: date ?? this.date,
      income: income ?? this.income,
      expense: expense ?? this.expense,
    );
  }
}

class ChartService {
  const ChartService();

  Map<String, double> categoryTotals(
    List<Transaction> transactions, {
    TransactionType? type,
  }) {
    final filtered = type == null
        ? transactions
        : transactions.where((transaction) => transaction.type == type);

    final totals = SplayTreeMap<String, double>();

    for (final transaction in filtered) {
      totals.update(
        transaction.category,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }

    return totals;
  }

  double totalForType(List<Transaction> transactions, TransactionType type) {
    return transactions
        .where((transaction) => transaction.type == type)
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
  }

  double netBalance(List<Transaction> transactions) {
    return totalForType(transactions, TransactionType.income) -
        totalForType(transactions, TransactionType.expense);
  }

  List<Transaction> transactionsForMonth(
    List<Transaction> transactions,
    DateTime month,
  ) {
    final start = startOfMonth(month);
    final end = endOfMonth(month);

    return transactions.where((transaction) {
      return !transaction.date.isBefore(start) &&
          !transaction.date.isAfter(end);
    }).toList();
  }

  List<DailyTotal> dailyTotalsForMonth(
    List<Transaction> transactions,
    DateTime month,
  ) {
    final monthStart = startOfMonth(month);
    final lastDay = endOfMonth(month);
    final daysInMonth = lastDay.day;

    final totals = <int, DailyTotal>{};

    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(monthStart.year, monthStart.month, day);
      totals[day] = DailyTotal(date: date);
    }

    for (final transaction in transactionsForMonth(transactions, month)) {
      final day = transaction.date.day;
      final existing = totals[day] ?? DailyTotal(date: transaction.date);
      if (transaction.isIncome) {
        totals[day] = existing.copyWith(
          income: existing.income + transaction.amount,
        );
      } else {
        totals[day] = existing.copyWith(
          expense: existing.expense + transaction.amount,
        );
      }
    }

    return totals.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }
}
