import 'package:flutter/material.dart';
import '../models/transaction.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';
import '../services/insight_service.dart';
import '../services/chart_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/category_visuals.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key, this.transaction});
  final Transaction? transaction;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _calendarKey = GlobalKey();
  late DatabaseService _database;
  final _insightService = const InsightService();
  final _chartService = const ChartService();
  late DateTime _selectedDate;
  Map<DateTime, List<Transaction>> _transactionsByDay = {};

  // Form State
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController = TextEditingController();
  late final TextEditingController _amountController = TextEditingController();
  String? _editingId;
  String _category = AppConstants.categories.first;
  TransactionType _type = TransactionType.expense;
  DateTime _formDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _database = DatabaseService.instance;
    _selectedDate = DateTime.now();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final txns = await _database.getTransactions();
    setState(() {
      _transactionsByDay = {};
      for (final t in txns) {
        final day = DateTime(t.date.year, t.date.month, t.date.day);
        _transactionsByDay[day] = [...?_transactionsByDay[day], t];
      }
    });
  }

  List<Transaction> get _selectedDayTransactions {
    final key = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    return _transactionsByDay[key] ?? [];
  }

  double get _selectedDayIncome =>
      _selectedDayTransactions.where((t) => t.isIncome).fold(0.0, (sum, t) => sum + t.amount);

  double get _selectedDayExpense =>
      _selectedDayTransactions.where((t) => t.isExpense).fold(0.0, (sum, t) => sum + t.amount);

  void _openFormBottomSheet(BuildContext context) {
    setState(() {
      _editingId = null;
      _titleController.clear();
      _amountController.clear();
      _category = AppConstants.categories.first;
      _type = TransactionType.expense;
      _formDate = _selectedDate;
    });
    
    HapticFeedback.selectionClick();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _buildForm(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transaction != null;
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          isEditing ? 'Edit Transaction' : 'Add Transaction',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined, color: Colors.white),
            onPressed: () {},
            tooltip: 'Filters (coming soon)',
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Material(
                elevation: 1.5,
                borderRadius: BorderRadius.circular(12),
                child: TableCalendar<Transaction>(
                  key: _calendarKey,
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _selectedDate,
                  selectedDayPredicate: (day) => day.year == _selectedDate.year && day.month == _selectedDate.month && day.day == _selectedDate.day,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarFormat: CalendarFormat.month,
                  headerStyle: HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    leftChevronIcon: Icon(Icons.chevron_left, color: Theme.of(context).colorScheme.primary),
                    rightChevronIcon: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.primary),
                    titleTextStyle: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekendStyle: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
                    weekdayStyle: Theme.of(context).textTheme.bodyMedium!,
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      final key = DateTime(day.year, day.month, day.day);
                      final txns = _transactionsByDay[key] ?? [];
                      if (txns.isEmpty) return const SizedBox.shrink();
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          txns.length > 3 ? 3 : txns.length,
                          (i) {
                            final cat = categoryVisuals[txns[i].category] ?? categoryVisuals['Other']!;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 1),
                              child: Icon(cat.icon, size: 13, color: cat.color ?? Colors.teal),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  eventLoader: (day) {
                    final key = DateTime(day.year, day.month, day.day);
                    return _transactionsByDay[key] ?? [];
                  },
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selectedDate = selected;
                    });
                    HapticFeedback.selectionClick();
                  },
                ),
              ),
              const SizedBox(height: 14),
              // Date summary and income/expense pills
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    child: Text(
                      'Selected: ${formatDate(_selectedDate, pattern: 'MMM d, yyyy')}',
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // INCOME
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_downward, size: 16, color: Colors.green),
                            const SizedBox(width: 4),
                            Text('+RM ${_selectedDayIncome.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: Colors.green)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // EXPENSE
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_upward, size: 16, color: Colors.red),
                            const SizedBox(width: 4),
                            Text('-RM ${_selectedDayExpense.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _selectedDayTransactions.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _selectedDayTransactions.length,
                      padding: const EdgeInsets.only(bottom: 12),
                      itemBuilder: (context, index) {
                          final tx = _selectedDayTransactions[index];
                          return Dismissible(
                            key: ValueKey(tx.id),
                            direction: DismissDirection.horizontal,
                            background: _swipeBG(
                              context,
                              Icons.delete_outline,
                              Colors.redAccent,
                              Alignment.centerLeft,
                            ),
                            secondaryBackground: _swipeBG(
                              context,
                              Icons.edit,
                              Theme.of(context).colorScheme.primary,
                              Alignment.centerRight,
                            ),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.endToStart) {
                                _onEdit(tx);
                                return false;
                              }
                              return await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete transaction?'),
                                      content: Text('This will remove ${tx.title}.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  ) ??
                                  false;
                            },
                            onDismissed: (_) => _deleteTransaction(tx),
                            child: _TransactionCard(
                              transaction: tx,
                              onTap: () => _onEdit(tx),
                            ),
                          );
                        },
                      ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 16),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                      textStyle: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Add Transaction', style: TextStyle(color: Colors.white)),
                    onPressed: () => _openFormBottomSheet(context),
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                _editingId == null ? 'Add Transaction' : 'Edit Transaction',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _category,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                items: AppConstants.categories.map((category) {
                  final visual = categoryVisuals[category] ?? categoryVisuals['Other']!;
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Row(
                      children: [
                        Icon(visual.icon, color: visual.color, size: 18),
                        const SizedBox(width: 8),
                        Text(category),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: 'RM ',
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                validator: (value) {
                  final parsed = double.tryParse((value ?? '').replaceAll(',', ''));
                  if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text('Type', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Expense'),
                    selected: _type == TransactionType.expense,
                    onSelected: (selected) {
                      if (selected) setState(() => _type = TransactionType.expense);
                    },
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('Income'),
                    selected: _type == TransactionType.income,
                    onSelected: (selected) {
                      if (selected) setState(() => _type = TransactionType.income);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Details (Optional)',
                  prefixIcon: Icon(Icons.notes),
                  hintText: 'E.g. Lunch at McD, Grab to office…',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _isSaving
                        ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2))
                        : FilledButton(
                            onPressed: _saveTransaction,
                            child: Text(_editingId == null ? 'Save' : 'Save Changes'),
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

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    final parsedAmount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount greater than 0')),
      );
      return;
    }
    setState(() => _isSaving = true);

    // Use category as title if no details provided
    final title = _titleController.text.trim().isEmpty 
        ? _category 
        : _titleController.text.trim();

    Transaction txn = Transaction(
      id: _editingId == null ? null : int.tryParse(_editingId!),
      title: title,
      amount: parsedAmount,
      category: _category,
      date: _formDate,
      type: _type,
    );
    if (_editingId == null) {
      await _database.insertTransaction(txn);
    } else {
      await _database.updateTransaction(txn);
    }
    await _loadTransactions();
    
    // Check for budget alerts (only for expenses)
    if (_type == TransactionType.expense && mounted) {
      await _checkBudgetAlerts();
    }
    
    setState(() {
      _isSaving = false;
      _titleController.clear();
      _amountController.clear();
      _category = AppConstants.categories.first;
      _type = TransactionType.expense;
      _formDate = DateTime.now();
    });
    HapticFeedback.mediumImpact();
    Navigator.pop(context); // Close bottom sheet
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_editingId == null ? 'Transaction added ✅' : 'Changes saved ✅')),
    );
  }

  Future<void> _checkBudgetAlerts() async {
    // Get current month's transactions and budgets
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    final budgets = await _database.getBudgets();
    final monthTransactions = await _database.getTransactions(
      startDate: month,
      endDate: DateTime(month.year, month.month + 1, 0, 23, 59, 59),
    );
    
    // Calculate category totals for the month
    final monthCategoryTotals = _chartService.categoryTotals(
      monthTransactions,
      type: TransactionType.expense,
    );
    
    // Check for exceeded budgets
    final alerts = _insightService.exceededBudgets(
      budgets: budgets,
      totals: monthCategoryTotals,
    );
    
    // Show alert if any budgets are exceeded
    if (alerts.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '⚠️ Budget exceeded for: ${alerts.join(", ")}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    if (transaction.id != null) {
      await _database.deleteTransaction(transaction.id!);
      await _loadTransactions();
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted ${transaction.title}')),
      );
    }
  }

  void _onEdit(Transaction tx) {
    setState(() {
      _editingId = tx.id?.toString();
      _titleController.text = tx.title;
      _amountController.text = tx.amount.toStringAsFixed(2);
      _category = tx.category;
      _type = tx.type;
      _formDate = tx.date;
    });
    HapticFeedback.selectionClick();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _buildForm(context),
      ),
    );
  }

  Widget _swipeBG(BuildContext context, IconData icon, Color color, Alignment alignment) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.93),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: alignment,
      child: Icon(icon, color: Colors.white, size: 26),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_outlined, color: theme.colorScheme.primary, size: 44),
            const SizedBox(height: 12),
            Text('No transactions yet for this day.', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// Transaction card widget
class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction, this.onTap});
  final Transaction transaction;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final visual = categoryVisuals[transaction.category] ?? categoryVisuals['Other']!;
    final color = transaction.isIncome
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        minVerticalPadding: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: (visual.color ?? color).withOpacity(0.13),
          child: Icon(visual.icon, color: visual.color ?? color),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${transaction.category} • ${formatDate(transaction.date)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
        ),
        trailing: Text(
          formatCurrency(
            transaction.amount,
            prefix: transaction.isIncome ? '+' : '-',
          ),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontFamily: 'RobotoMono',
            fontSize: 17,
          ),
        ),
      ),
    );
  }
}