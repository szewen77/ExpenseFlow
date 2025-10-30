import 'package:intl/intl.dart';

String formatCurrency(
  double amount, {
  String prefix = '',
  bool withSymbol = true,
}) {
  final formatter = NumberFormat.currency(
    locale: 'en_MY',
    symbol: withSymbol ? 'RM ' : '',
    decimalDigits: 2,
  );
  final formatted = formatter.format(amount);
  if (prefix.isEmpty) return formatted.trim();
  return '$prefix $formatted'.trim();
}

String formatDate(DateTime date, {String pattern = 'd MMM yyyy'}) {
  return DateFormat(pattern).format(date);
}

String formatMonthYear(DateTime date) {
  return DateFormat('MMMM yyyy').format(date);
}

String twoDigit(int value) => value.toString().padLeft(2, '0');

DateTime startOfDay(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

DateTime endOfDay(DateTime date) {
  return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
}

DateTime startOfMonth(DateTime date) {
  return DateTime(date.year, date.month);
}

DateTime endOfMonth(DateTime date) {
  final nextMonth = DateTime(date.year, date.month + 1);
  return nextMonth.subtract(const Duration(milliseconds: 1));
}

DateTime addMonths(DateTime date, int months) {
  final newMonth = date.month + months;
  final yearAdjustment = (newMonth - 1) ~/ 12;
  final month = ((newMonth - 1) % 12) + 1;
  final year = date.year + yearAdjustment;
  final day = date.day;
  final lastDayOfMonth = DateTime(year, month + 1, 0).day;
  return DateTime(
    year,
    month,
    day > lastDayOfMonth ? lastDayOfMonth : day,
    date.hour,
    date.minute,
    date.second,
    date.millisecond,
    date.microsecond,
  );
}

List<DateTime> recentMonths({int count = 12}) {
  final now = DateTime.now();
  return List<DateTime>.generate(count, (index) {
    final date = DateTime(now.year, now.month - index);
    return DateTime(date.year, date.month);
  });
}
