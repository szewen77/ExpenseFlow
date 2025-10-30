import '../models/budget.dart';
import '../models/transaction.dart';
import '../utils/helpers.dart';

class InsightService {
  const InsightService();

  /// Predicts next month's expense using a simple moving average across
  /// the previous [window] months (default 3). Falls back to current month.
  double predictNextMonthExpense(
    List<Transaction> transactions, {
    int window = 3,
  }) {
    if (transactions.isEmpty) {
      return 0;
    }

    final monthlyTotals = <String, double>{};
    for (final transaction in transactions.where((t) => t.isExpense)) {
      final key =
          '${transaction.date.year}-${twoDigit(transaction.date.month)}';
      monthlyTotals.update(
        key,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }

    if (monthlyTotals.isEmpty) {
      return 0;
    }

    final sortedKeys = monthlyTotals.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    final recentKeys = sortedKeys.takeRight(window);
    final average =
        recentKeys.fold<double>(0, (sum, key) => sum + monthlyTotals[key]!) /
        recentKeys.length;
    return average;
  }

  /// Returns categories exceeding budget limits.
  List<String> exceededBudgets({
    required List<Budget> budgets,
    required Map<String, double> totals,
  }) {
    final exceeded = <String>[];
    for (final budget in budgets) {
      final spent = totals[budget.category] ?? 0;
      if (spent > budget.limit) {
        exceeded.add(budget.category);
      }
    }
    return exceeded;
  }

  /// Suggests a category by matching keywords in the [title].
  String suggestCategory(String title, Iterable<String> categories) {
    final lowercaseTitle = title.toLowerCase();
    for (final entry in _keywordCategory.entries) {
      if (entry.key.any(lowercaseTitle.contains)) {
        return entry.value;
      }
    }
    return categories.first;
  }

  /// Returns a daily financial tip based on the current day and user behavior.
  String getDailyTip({
    required double totalIncome,
    required double totalExpense,
    required Map<String, double> categoryExpenses,
  }) {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    
    // Behavioral tips based on spending patterns
    if (totalIncome > 0) {
      final expenseRatio = totalExpense / totalIncome;
      final netSavings = totalIncome - totalExpense;
      
      // Critical spending (over 90%)
      if (expenseRatio > 0.9) {
        return "⚠️ Tip: You're spending over 90% of your income. Try to reduce non-essential expenses to build an emergency fund.";
      }
      
      // High spending (70-90%)
      if (expenseRatio > 0.7) {
        return "📊 Tip: Consider the 50/30/20 rule: 50% needs, 30% wants, 20% savings. You're currently saving less than recommended.";
      }
      
      // Good savings rate
      if (expenseRatio < 0.5 && netSavings > 0) {
        return "🌟 Tip: Great job! You're saving over 50% of your income. Consider investing some of it for long-term growth.";
      }
    }
    
    // Check for specific category overspending
    if (categoryExpenses.isNotEmpty) {
      final topCategory = categoryExpenses.entries.reduce((a, b) => a.value > b.value ? a : b);
      if (totalExpense > 0 && topCategory.value / totalExpense > 0.4) {
        return "💡 Tip: ${topCategory.key} is your biggest expense (${((topCategory.value / totalExpense) * 100).toStringAsFixed(0)}%). Look for ways to optimize it.";
      }
    }
    
    // Rotate through general tips based on day of year
    final generalTips = _generalFinancialTips;
    return generalTips[dayOfYear % generalTips.length];
  }

  static final List<String> _generalFinancialTips = [
    "📈 Tip: Move 10% to savings when your salary comes in. Pay yourself first!",
    "💳 Tip: Avoid spending more than 30% of your income on non-essentials.",
    "🎯 Tip: Set a specific savings goal. You're 3x more likely to save with a clear target.",
    "☕ Tip: Small daily expenses add up! That RM15 coffee becomes RM450/month.",
    "🏦 Tip: Build an emergency fund covering 3-6 months of expenses for peace of mind.",
    "📱 Tip: Review subscriptions monthly. Cancel what you don't actively use.",
    "🛒 Tip: Use the 24-hour rule: Wait a day before making non-essential purchases.",
    "💰 Tip: Track every expense. Awareness is the first step to better spending habits.",
    "🎁 Tip: Set a monthly 'fun money' budget and stick to it guilt-free.",
    "📊 Tip: Review your budget weekly to stay on track with your financial goals.",
  ];

  static final Map<List<String>, String> _keywordCategory = {
    ['grab', 'ride', 'taxi']: 'Travel',
    ['flight', 'airasia', 'mas']: 'Travel',
    ['food', 'lunch', 'dinner', 'meal', 'restaurant', 'caf']: 'Food',
    ['grocer', 'tesco', 'lotus', 'giant', 'fairprice']: 'Food',
    ['bill', 'electric', 'water', 'utilities']: 'Bills',
    ['netflix', 'spotify', 'movie', 'cinema']: 'Entertainment',
    ['doctor', 'clinic', 'hospital', 'pharmacy']: 'Health',
    ['shopping', 'mall', 'shopee', 'lazada']: 'Shopping',
    ['salary', 'payroll', 'freelance']: 'Work',
  };
}

extension<T> on List<T> {
  List<T> takeRight(int count) {
    if (length <= count) return List<T>.from(this);
    return sublist(length - count);
  }
}
