import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/category_visuals.dart';
import '../widgets/transaction_card.dart';
import 'add_transaction.dart';
import '../widgets/app_nav_bar.dart';
import 'report_screen.dart';
import 'settings_screen.dart';
import 'home_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  static const routeName = '/transactions';

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final _database = DatabaseService.instance;
  String? _selectedCategory;
  DateTimeRange? _selectedRange;

  bool _isLoading = true;
  List<Transaction> _transactions = <Transaction>[];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final transactions = await _database.getTransactions(
      category: _selectedCategory,
      startDate: _selectedRange?.start,
      endDate: _selectedRange?.end,
    );
    setState(() {
      _transactions = transactions;
      _isLoading = false;
    });
  }

  Future<void> _openAddTransaction([Transaction? transaction]) async {
    final result = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 160),
        pageBuilder: (_, __, ___) => AddTransactionScreen(transaction: transaction),
        transitionsBuilder: (_, animation, __, child) {
          final slide = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeOutCubic));
          final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
          return SlideTransition(
            position: animation.drive(slide),
            child: FadeTransition(opacity: fade, child: child),
          );
        },
      ),
    );
    if (result == true) {
      await _loadTransactions();
    }
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    await _database.deleteTransaction(transaction.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Deleted ${transaction.title}')));
    await _loadTransactions();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      initialDateRange:
          _selectedRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: DateTime(now.year, now.month, now.day),
          ),
    );

    if (range != null) {
      setState(() => _selectedRange = range);
      await _loadTransactions();
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedRange = null;
    });
    _loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            tooltip: 'Clear filters',
            icon: const Icon(Icons.filter_alt_off_outlined),
            onPressed: _selectedCategory == null && _selectedRange == null
                ? null
                : _clearFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Flexible(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _selectedCategory,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: SizedBox(width: 20, child: Icon(FontAwesomeIcons.tags, size: 18)),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Row(
                          children: [
                            Icon(FontAwesomeIcons.listUl, size: 16),
                            SizedBox(width: 8),
                            Expanded(child: Text('All categories', overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                      ...AppConstants.categories.map(
                        (category) {
                          final visual = categoryVisuals[category] ?? categoryVisuals['Other']!;
                          return DropdownMenuItem<String?>(
                            value: category,
                            child: Row(
                              children: [
                                Icon(visual.icon, color: visual.color, size: 16),
                                const SizedBox(width: 8),
                                Expanded(child: Text(category, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                    onChanged: (String? value) async {
                      setState(() => _selectedCategory = value);
                      await _loadTransactions();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: OutlinedButton.icon(
                    onPressed: _pickDateRange,
                    icon: const Icon(FontAwesomeIcons.calendarDays),
                    label: Text(
                      _selectedRange == null
                          ? 'Any time'
                          : '${formatDate(_selectedRange!.start, pattern: 'dd MMM')}'
                                ' - ${formatDate(_selectedRange!.end, pattern: 'dd MMM')}',
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                ? const _EmptyListState()
                : RefreshIndicator(
                    onRefresh: () async {
                      await _loadTransactions();
                      // Light haptic to confirm refresh
                      // ignore: use_build_context_synchronously
                      Feedback.forTap(context);
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _transactions.length,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemBuilder: (context, index) {
                        final transaction = _transactions[index];
                        return Dismissible(
                          key: ValueKey(transaction.id),
                          direction: DismissDirection.horizontal,
                          background: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.centerRight,
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                            ),
                          ),
                          secondaryBackground: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.only(left: 20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.centerLeft,
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.startToEnd) {
                              // Edit
                              await _openAddTransaction(transaction);
                              return false;
                            }
                            return await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete transaction?'),
                                    content: Text(
                                      'This will remove ${transaction.title}.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                ) ??
                                false;
                          },
                          onDismissed: (_) => _deleteTransaction(transaction),
                          child: TransactionCard(
                            transaction: transaction,
                            onTap: () => _openAddTransaction(transaction),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddTransaction(),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      bottomNavigationBar: AppNavBar(
        currentIndex: 1,
        onSelected: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, HomeScreen.routeName);
              break;
            case 1:
              break;
            case 2:
              Navigator.pushReplacementNamed(context, ReportScreen.routeName);
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

class _EmptyListState extends StatelessWidget {
  const _EmptyListState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 40,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            "Let's add your first expense 💸",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }
}
