import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../services/chart_service.dart';
import '../services/database_service.dart';
import '../utils/helpers.dart';
import '../widgets/chart_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/app_nav_bar.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'transaction_list.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  static const routeName = '/reports';

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _database = DatabaseService.instance;
  final _chartService = const ChartService();

  bool _isLoading = true;
  List<Transaction> _transactions = <Transaction>[];
  TransactionType _selectedType = TransactionType.expense;
  _Range _range = _Range.days30;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final transactions = await _database.getTransactions();
    setState(() {
      _transactions = transactions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryTotals = _chartService.categoryTotals(
      _transactions,
      type: _selectedType,
    );
    final totalAmount = _chartService.totalForType(
      _transactions,
      _selectedType,
    );
    final lineSpots = _spotsForRange(_transactions, _selectedType, _range);

    return Scaffold(
      appBar: AppBar(title: const Text('Spending Reports')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTransactions,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'Trend (${_range.label})',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              _RangeToggle(
                                selected: _range,
                                onChanged: (r) => setState(() => _range = r),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 220,
                            child: lineSpots.isEmpty
                                ? Center(
                                    child: Text(
                                      'No data in selected range.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Colors.grey),
                                    ),
                                  )
                                : ChartWidget.line(spots: lineSpots),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _TypeToggle(
                    selectedType: _selectedType,
                    onChanged: (type) => setState(() => _selectedType = type),
                  ),
                  const SizedBox(height: 20),
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
                            '${_selectedType == TransactionType.expense ? 'Expense' : 'Income'} by Category',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          ChartWidget.pie(data: categoryTotals),
                        ],
                      ),
                    ),
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
                            'Category Totals',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          ChartWidget.bar(data: categoryTotals),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Breakdown',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (categoryTotals.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'No data for the selected type yet.',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: categoryTotals.entries.map((entry) {
                        return _CategorySummaryCard(
                          category: entry.key,
                          amount: entry.value,
                          percent: totalAmount == 0
                              ? 0
                              : (entry.value / totalAmount * 100),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
      bottomNavigationBar: AppNavBar(
        currentIndex: 2,
        onSelected: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, HomeScreen.routeName);
              break;
            case 1:
              Navigator.pushReplacementNamed(context, TransactionListScreen.routeName);
              break;
            case 2:
              break;
            case 3:
              Navigator.pushReplacementNamed(context, SettingsScreen.routeName);
              break;
          }
        },
      ),
    );
  }
}

class _CategorySummaryCard extends StatelessWidget {
  const _CategorySummaryCard({required this.category, required this.amount, required this.percent});

  final String category;
  final double amount;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: (percent / 100).clamp(0, 1),
                backgroundColor: Colors.grey.shade200,
                color: Theme.of(context).colorScheme.primary,
                minHeight: 6,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    percent.isNaN ? '0%' : '${percent.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  Text(
                    formatCurrency(amount),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.selectedType, required this.onChanged});

  final TransactionType selectedType;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    final isExpense = selectedType == TransactionType.expense;

    return ToggleButtons(
      borderRadius: BorderRadius.circular(12),
      isSelected: [isExpense, !isExpense],
      onPressed: (index) => onChanged(
        index == 0 ? TransactionType.expense : TransactionType.income,
      ),
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Expenses'),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Income'),
        ),
      ],
    );
  }
}

enum _Range { days7, days30, days90 }

extension on _Range {
  String get label {
    switch (this) {
      case _Range.days7:
        return '7D';
      case _Range.days30:
        return '30D';
      case _Range.days90:
        return '90D';
    }
  }
}

class _RangeToggle extends StatelessWidget {
  const _RangeToggle({required this.selected, required this.onChanged});

  final _Range selected;
  final ValueChanged<_Range> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = const [_Range.days7, _Range.days30, _Range.days90];
    return SegmentedButton<_Range>(
      segments: items
          .map((r) => ButtonSegment(value: r, label: Text(r.label)))
          .toList(),
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

List<FlSpot> _spotsForRange(
  List<Transaction> txs,
  TransactionType type,
  _Range range,
) {
  final end = DateTime.now();
  final days = switch (range) { _Range.days7 => 7, _Range.days30 => 30, _Range.days90 => 90 };
  final start = end.subtract(Duration(days: days - 1));
  final map = <int, double>{};
  for (int i = 0; i < days; i++) {
    map[i] = 0;
  }
  for (final t in txs) {
    if (t.type != type) continue;
    if (t.date.isBefore(DateTime(start.year, start.month, start.day))) continue;
    final d = DateTime(t.date.year, t.date.month, t.date.day);
    final diff = d.difference(DateTime(start.year, start.month, start.day)).inDays;
    if (diff >= 0 && diff < days) {
      map[diff] = (map[diff] ?? 0) + t.amount;
    }
  }
  return map.entries
      .map((e) => FlSpot(e.key.toDouble(), e.value))
      .toList()
    ..sort((a, b) => a.x.compareTo(b.x));
}
