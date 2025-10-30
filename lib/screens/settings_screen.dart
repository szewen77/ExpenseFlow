import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/budget.dart';
import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/app_nav_bar.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<Budget> _budgets = <Budget>[];
  List<RecurringTransaction> _recurring = <RecurringTransaction>[];
  bool _loading = true;
  String _currentThemeMode = 'System';

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadThemeMode();
  }

  Future<void> _loadData() async {
    final budgets = await DatabaseService.instance.getBudgets();
    final recurring = await DatabaseService.instance.getRecurringTransactions();
    if (!mounted) return;
    setState(() {
      _budgets = budgets;
      _recurring = recurring;
      _loading = false;
    });
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('themeMode') ?? 'system';
    setState(() {
      _currentThemeMode = _formatThemeMode(mode);
    });
  }

  String _formatThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      default:
        return 'System';
    }
  }

  Future<void> _addOrEditBudget([Budget? budget]) async {
    final formKey = GlobalKey<FormState>();
    String category = budget?.category ?? AppConstants.categories.first;
    double limit = budget?.limit ?? 500;
    final period = 'monthly';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(budget == null ? 'Add Budget' : 'Edit Budget'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: category,
                isExpanded: true,
                items: AppConstants.categories
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) => category = value ?? category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(FontAwesomeIcons.tag),
                ),
              ),
              TextFormField(
                initialValue: limit.toStringAsFixed(2),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Limit (RM)',
                  prefixIcon: Icon(FontAwesomeIcons.dollarSign),
                ),
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a positive number';
                  }
                  limit = parsed;
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      await DatabaseService.instance.upsertBudget(
        Budget(
          id: budget?.id,
          category: category,
          limit: limit,
          period: period,
        ),
      );
      await _loadData();
    }
  }

  Future<void> _deleteBudget(Budget budget) async {
    if (budget.id == null) return;
    await DatabaseService.instance.deleteBudget(budget.id!);
    await _loadData();
  }

  Future<void> _addOrEditRecurring([RecurringTransaction? recurrence]) async {
    final formKey = GlobalKey<FormState>();
    String title = recurrence?.title ?? '';
    double amount = recurrence?.amount ?? 0;
    String category = recurrence?.category ?? AppConstants.categories.first;
    TransactionType type = recurrence?.type ?? TransactionType.expense;
    RecurrenceInterval interval =
        recurrence?.interval ?? RecurrenceInterval.monthly;
    DateTime nextDate = recurrence?.nextOccurrence ?? DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          recurrence == null
              ? 'Add Recurring Transaction'
              : 'Edit Recurring Transaction',
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: category,
                  isExpanded: true,
                  items: AppConstants.categories
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) => category = value ?? category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(FontAwesomeIcons.tag),
                  ),
                ),
                TextFormField(
                  initialValue: amount == 0 ? '' : amount.toStringAsFixed(2),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Amount (RM)',
                    prefixIcon: Icon(FontAwesomeIcons.dollarSign),
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(value ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid amount';
                    }
                    amount = parsed;
                    return null;
                  },
                ),
                DropdownButtonFormField<TransactionType>(
                  initialValue: type,
                  isExpanded: true,
                  items: TransactionType.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => type = value ?? type,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    prefixIcon: Icon(FontAwesomeIcons.arrowRightArrowLeft),
                  ),
                ),
                TextFormField(
                  initialValue: title,
                  decoration: const InputDecoration(
                    labelText: 'Details (Optional)',
                    prefixIcon: Icon(FontAwesomeIcons.noteSticky),
                  ),
                  onSaved: (value) {
                    title = value ?? '';
                  },
                ),
                DropdownButtonFormField<RecurrenceInterval>(
                  initialValue: interval,
                  isExpanded: true,
                  items: RecurrenceInterval.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => interval = value ?? interval,
                  decoration: const InputDecoration(
                    labelText: 'Interval',
                    prefixIcon: Icon(FontAwesomeIcons.repeat),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: nextDate,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365 * 5),
                            ),
                          );
                          if (picked != null) {
                            nextDate = picked;
                          }
                        },
                        icon: const Icon(FontAwesomeIcons.calendarDays),
                        label: Text(formatDate(nextDate)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      // Use category as title if no details provided
      final finalTitle = title.trim().isEmpty ? category : title.trim();
      
      await DatabaseService.instance.upsertRecurringTransaction(
        RecurringTransaction(
          id: recurrence?.id,
          title: finalTitle,
          amount: amount,
          category: category,
          type: type,
          interval: interval,
          nextOccurrence: nextDate,
        ),
      );
      await _loadData();
    }
  }

  Future<void> _deleteRecurring(RecurringTransaction recurrence) async {
    if (recurrence.id == null) return;
    await DatabaseService.instance.deleteRecurringTransaction(recurrence.id!);
    await _loadData();
  }

  String _getThemeModeLabel() {
    return _currentThemeMode;
  }

  Future<void> _showThemeModeDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final currentMode = prefs.getString('themeMode') ?? 'system';
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Row(
                children: [
                  Icon(FontAwesomeIcons.sun, size: 18),
                  SizedBox(width: 12),
                  Text('Light'),
                ],
              ),
              value: 'light',
              groupValue: currentMode,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<String>(
              title: const Row(
                children: [
                  Icon(FontAwesomeIcons.moon, size: 18),
                  SizedBox(width: 12),
                  Text('Dark'),
                ],
              ),
              value: 'dark',
              groupValue: currentMode,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<String>(
              title: const Row(
                children: [
                  Icon(FontAwesomeIcons.circleHalfStroke, size: 18),
                  SizedBox(width: 12),
                  Text('System'),
                ],
              ),
              value: 'system',
              groupValue: currentMode,
              onChanged: (value) => Navigator.pop(context, value),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final appState = ExpenseFlowApp.of(context);
      if (appState != null) {
        ThemeMode mode;
        switch (result) {
          case 'light':
            mode = ThemeMode.light;
            break;
          case 'dark':
            mode = ThemeMode.dark;
            break;
          default:
            mode = ThemeMode.system;
        }
        await appState.setThemeMode(mode);
        await _loadThemeMode(); // Refresh to update subtitle
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Appearance',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(FontAwesomeIcons.sun),
                          title: const Text('Theme Mode'),
                          subtitle: Text(_getThemeModeLabel()),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _showThemeModeDialog,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Budgets & Alerts',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Column(
                      children: [
                        if (_budgets.isEmpty)
                          const ListTile(
                            title: Text('No budgets set'),
                            subtitle: Text('Add a budget to receive alerts'),
                          )
                        else
                          ..._budgets.map(
                            (budget) => ListTile(
                              title: Text(budget.category),
                              subtitle: Text(
                                'Limit: ${formatCurrency(budget.limit)} / ${budget.period}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _addOrEditBudget(budget),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _deleteBudget(budget),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ListTile(
                          leading: const Icon(Icons.add_circle_outline),
                          title: const Text('Add budget'),
                          onTap: () => _addOrEditBudget(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Recurring Transactions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Column(
                      children: [
                        if (_recurring.isEmpty)
                          const ListTile(
                            title: Text('No recurring entries'),
                            subtitle: Text(
                              'Add your monthly bills or salary here',
                            ),
                          )
                        else
                          ..._recurring.map(
                            (recurrence) => ListTile(
                              title: Text(recurrence.title),
                              subtitle: Text(
                                '${formatCurrency(recurrence.amount)} ${recurrence.type.name.toUpperCase()} • next ${formatDate(recurrence.nextOccurrence)} (${recurrence.interval.name})',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () =>
                                        _addOrEditRecurring(recurrence),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () =>
                                        _deleteRecurring(recurrence),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ListTile(
                          leading: const Icon(Icons.add_circle_outline),
                          title: const Text('Add recurring transaction'),
                          onTap: () => _addOrEditRecurring(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: AppNavBar(
        currentIndex: 3,
        onSelected: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/transactions');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/reports');
              break;
            case 3:
              break;
          }
        },
      ),
    );
  }
}

