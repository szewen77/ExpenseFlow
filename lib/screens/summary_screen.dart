import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../services/chart_service.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/chart_widget.dart';
import '../widgets/summary_tile.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  static const routeName = '/summary';

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final _database = DatabaseService.instance;
  final _chartService = const ChartService();

  DateTime _selectedMonth = startOfMonth(DateTime.now());
  bool _isLoading = true;

  List<Transaction> _transactions = <Transaction>[];
  List<DailyTotal> _dailyTotals = <DailyTotal>[];

  double _totalIncome = 0;
  double _totalExpense = 0;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoading = true);
    final transactions = await _database.getTransactionsForMonth(
      _selectedMonth,
    );
    final dailyTotals = _chartService.dailyTotalsForMonth(
      transactions,
      _selectedMonth,
    );

    setState(() {
      _transactions = transactions;
      _dailyTotals = dailyTotals;
      _totalIncome = _chartService.totalForType(
        transactions,
        TransactionType.income,
      );
      _totalExpense = _chartService.totalForType(
        transactions,
        TransactionType.expense,
      );
      _isLoading = false;
    });
  }

  List<FlSpot> get _netSpots {
    return _dailyTotals
        .map((daily) => FlSpot(daily.date.day.toDouble(), daily.net))
        .toList();
  }

  String get _monthLabel => formatMonthYear(_selectedMonth);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Summary')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSummary,
              child: ListView(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<DateTime>(
                          initialValue: _selectedMonth,
                          decoration: const InputDecoration(
                            labelText: 'Select Month',
                            border: OutlineInputBorder(),
                          ),
                          items: recentMonths(count: 12)
                              .map(
                                (month) => DropdownMenuItem<DateTime>(
                                  value: month,
                                  child: Text(formatMonthYear(month)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) async {
                            if (value == null) return;
                            setState(
                              () => _selectedMonth = startOfMonth(value),
                            );
                            await _loadSummary();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SummaryTile(
                    icon: Icons.arrow_downward_rounded,
                    label: 'Total Income',
                    value: formatCurrency(_totalIncome),
                    color: AppColors.secondary,
                  ),
                  const SizedBox(height: 12),
                  SummaryTile(
                    icon: Icons.arrow_upward_rounded,
                    label: 'Total Expense',
                    value: formatCurrency(_totalExpense),
                    color: AppColors.expense,
                  ),
                  const SizedBox(height: 12),
                  SummaryTile(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Net',
                    value: formatCurrency(_totalIncome - _totalExpense),
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Net Trend',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          ChartWidget.line(spots: _netSpots),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Daily Breakdown ($_monthLabel)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_transactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'No transactions recorded for $_monthLabel yet.',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ..._dailyTotals
                        .where((daily) => daily.income > 0 || daily.expense > 0)
                        .map(
                      (daily) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(formatDate(daily.date, pattern: 'd MMM')),
                        subtitle: Text(
                          'Income: ${formatCurrency(daily.income)} • '
                          'Expense: ${formatCurrency(daily.expense)}',
                        ),
                        trailing: Text(
                          formatCurrency(daily.net),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: daily.net >= 0
                                    ? AppColors.secondary
                                    : AppColors.expense,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
