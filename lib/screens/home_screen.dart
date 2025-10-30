import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/goal.dart';
import '../models/profile.dart';
import '../models/transaction.dart';
import '../services/chart_service.dart';
import '../services/database_service.dart';
import '../services/insight_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/chart_widget.dart';
import '../widgets/transaction_card.dart';
import '../widgets/app_nav_bar.dart';
import 'add_transaction.dart';
import 'profile_screen.dart';
import 'report_screen.dart';
import 'settings_screen.dart';
import 'summary_screen.dart';
import 'transaction_list.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _chartService = const ChartService();
  final _insightService = const InsightService();
  final _database = DatabaseService.instance;

  bool _isLoading = true;
  List<Transaction> _allTransactions = <Transaction>[];
  List<DailyTotal> _dailyTotals = <DailyTotal>[];
  _GoalProgress? _primaryGoal;
  UserProfile _profile = UserProfile.defaultProfile;

  double _totalIncome = 0;
  double _totalExpense = 0;
  Map<String, double> _expenseBreakdown = <String, double>{};
  String _dailyTip = '';
  final DateTime _currentMonth = DateTime.now();
  bool _addExpenseLinkHovered = false;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    final month = DateTime(_currentMonth.year, _currentMonth.month);

    final transactionsFuture = _database.getTransactions();
    final profileFuture = _database.getUserProfile();
    final goalFuture = _database.getGoal();
    final monthTransactionsFuture = _database.getTransactionsForMonth(month);
    final monthCategoryTotalsFuture = _database.categoryTotalsForMonth(month);

    final transactions = await transactionsFuture;
    final profile = await profileFuture;
    final goal = await goalFuture;
    final monthTransactions = await monthTransactionsFuture;
    final monthCategoryTotals = await monthCategoryTotalsFuture;
    final dailyTotals = _chartService.dailyTotalsForMonth(
      monthTransactions,
      month,
    );

    // Calculate totals first for daily tip
    final totalIncome = _chartService.totalForType(
      transactions,
      TransactionType.income,
    );
    final totalExpense = _chartService.totalForType(
      transactions,
      TransactionType.expense,
    );

    // Generate daily tip based on user behavior
    final dailyTip = _insightService.getDailyTip(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      categoryExpenses: monthCategoryTotals,
    );

    _GoalProgress? goalProgress;
    if (goal != null) {
      final goalTransactions = await _database.getTransactions(
        startDate: goal.startDate,
        endDate: goal.endDate,
      );
      final income = _chartService.totalForType(
        goalTransactions,
        TransactionType.income,
      );
      final expense = _chartService.totalForType(
        goalTransactions,
        TransactionType.expense,
      );
      final net = income - expense;
      final progress = goal.targetAmount == 0
          ? 0.0
          : (net / goal.targetAmount).clamp(0.0, 1.0).toDouble();
      goalProgress = _GoalProgress(
        goal: goal,
        amountSaved: net,
        progress: progress,
      );
    }

    setState(() {
      _profile = profile;
      _primaryGoal = goalProgress;
      _dailyTip = dailyTip;
      _dailyTotals = dailyTotals;
      _expenseBreakdown = monthCategoryTotals;
      _allTransactions = transactions;
      _totalIncome = totalIncome;
      _totalExpense = totalExpense;
      _isLoading = false;
    });
  }

  Future<void> _openAddTransaction([Transaction? transaction]) async {
    final shouldRefresh = await Navigator.of(context).push<bool>(
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
    if (shouldRefresh == true) {
      await _loadDashboard();
    }
  }

  Future<void> _openScreen(String routeName) async {
    await Navigator.pushNamed(context, routeName);
    await _loadDashboard();
  }

  List<Transaction> get _recentTransactions {
    return _allTransactions.take(5).toList();
  }

  List<FlSpot> get _timelineSpots {
    return _dailyTotals
        .map((daily) => FlSpot(daily.date.day.toDouble(), daily.expense))
        .toList();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }

  @override
  Widget build(BuildContext context) {
    final netBalance = _totalIncome - _totalExpense;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            child: const Icon(Icons.account_balance_wallet_outlined),
          ),
        ),
        title: Text('$_greeting, ${_profile.name}!'),
        actions: [
          PopupMenuButton<String>(
            icon: const CircleAvatar(child: Icon(Icons.person_rounded)),
            onSelected: (value) async {
              if (value == 'profile') {
                await _openScreen(ProfileScreen.routeName);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'profile', child: Text('Profile')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadDashboard();
          // Provide a light haptic after refresh
          // ignore: use_build_context_synchronously
          Feedback.forTap(context);
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _BalanceCard(
                    income: _totalIncome,
                    expense: _totalExpense,
                    net: netBalance,
                    goalProgress: _primaryGoal,
                  ),
                  const SizedBox(height: 20),
                  _InsightsCard(
                    dailyTip: _dailyTip,
                  ),
                  const SizedBox(height: 20),
                  _GradientDivider(),
                  const SizedBox(height: 20),
                  Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Spending Breakdown',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              TextButton(
                                onPressed: () =>
                                    _openScreen(ReportScreen.routeName),
                                child: const Text('View Reports'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ChartWidget.pie(data: _expenseBreakdown),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Expense Timeline',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: _timelineSpots.isEmpty
                        ? Center(
                            child: Text(
                              'No spending recorded for ${formatMonthYear(_currentMonth)} yet.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey.shade600),
                            ),
                          )
                        : ChartWidget.line(spots: _timelineSpots),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Transactions',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () =>
                            _openScreen(TransactionListScreen.routeName),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_recentTransactions.isEmpty)
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.grey.shade100,
                                child: const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: Colors.grey,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No transactions yet',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                onEnter: (_) {
                                  setState(() => _addExpenseLinkHovered = true);
                                },
                                onExit: (_) {
                                  setState(() => _addExpenseLinkHovered = false);
                                },
                                child: GestureDetector(
                                  onTap: () => _openAddTransaction(),
                                  child: Text(
                                    "Let's add your first expense 💸",
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                          decoration: _addExpenseLinkHovered
                                              ? TextDecoration.underline
                                              : TextDecoration.none,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ..._recentTransactions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final transaction = entry.value;
                      return TweenAnimationBuilder<double>(
                        key: ValueKey(
                          transaction.id ??
                              '${transaction.title}-${transaction.date}',
                        ),
                        tween: Tween(begin: 20, end: 0),
                        duration: Duration(milliseconds: 200 + 60 * index),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: (1 - (value / 20)).clamp(0.0, 1.0),
                            child: Transform.translate(
                              offset: Offset(0, value),
                              child: child,
                            ),
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.only(top: index == 0 ? 0 : 6),
                          child: TransactionCard(
                            transaction: transaction,
                            onTap: () => _openAddTransaction(transaction),
                          ),
                        ),
                      );
                    }),
                  FilledButton.tonal(
                    onPressed: () => _openScreen(SummaryScreen.routeName),
                    child: const Text('Go to Monthly Summary'),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
        child: AppNavBar(
          currentIndex: 0,
          onSelected: (index) {
            switch (index) {
              case 0:
                break;
              case 1:
                Navigator.pushReplacementNamed(
                  context,
                  TransactionListScreen.routeName,
                );
                break;
              case 2:
                Navigator.pushReplacementNamed(
                  context,
                  ReportScreen.routeName,
                );
                break;
              case 3:
                Navigator.pushReplacementNamed(
                  context,
                  SettingsScreen.routeName,
                );
                break;
            }
          },
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.income,
    required this.expense,
    required this.net,
    this.goalProgress,
  });

  final double income;
  final double expense;
  final double net;
  final _GoalProgress? goalProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Net Balance',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: net),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Text(
                  formatCurrency(value),
                  style: GoogleFonts.robotoMono(
                    textStyle: theme.textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _BalanceItem(
                  label: 'Income',
                  value: formatCurrency(income),
                  icon: Icons.arrow_downward_rounded,
                  color: AppColors.secondary,
                ),
                _BalanceItem(
                  label: 'Expense',
                  value: formatCurrency(expense),
                  icon: Icons.arrow_upward_rounded,
                  color: AppColors.expense,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _TugOfWarBar(
              expense: expense,
              goalProgress: goalProgress,
            ),
            if (goalProgress != null) ...[
              const SizedBox(height: 20),
              Text(
                goalProgress!.goal.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${formatCurrency(goalProgress!.amountSaved)} of '
                '${formatCurrency(goalProgress!.goal.targetAmount)} saved',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: goalProgress!.progress.clamp(0, 1),
                  minHeight: 8,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.secondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  const _BalanceItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({
    required this.dailyTip,
  });

  final String dailyTip;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AI Tip of the Day',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: const Text('AI'),
                  backgroundColor: Colors.deepPurple.shade100,
                  labelStyle: const TextStyle(color: Colors.deepPurple),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.deepPurple.shade100,
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Colors.deepPurple.shade400,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      dailyTip,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: Colors.deepPurple.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalProgress {
  _GoalProgress({
    required this.goal,
    required this.amountSaved,
    required this.progress,
  });

  final Goal goal;
  final double amountSaved;
  final double progress;
}

class _GradientDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A9D8F), Color(0xFFE9C46A)],
        ),
      ),
    );
  }
}

class _TugOfWarBar extends StatefulWidget {
  const _TugOfWarBar({
    required this.expense,
    this.goalProgress,
  });

  final double expense;
  final _GoalProgress? goalProgress;

  @override
  State<_TugOfWarBar> createState() => _TugOfWarBarState();
}

class _TugOfWarBarState extends State<_TugOfWarBar> with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  double _previousPosition = 0.5;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _playSound(double position) {
    // Play different sounds based on position
    try {
      if (position >= 1.0) {
        // Victory sound - use system haptic as fallback
        HapticFeedback.heavyImpact();
      } else if ((position - _previousPosition).abs() > 0.1) {
        // Tug sound - significant movement
        HapticFeedback.mediumImpact();
        _shakeController.forward(from: 0);
      } else if (position < 0.3) {
        // Danger sound
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      // Silently fail if sound doesn't work
    }
    _previousPosition = position;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.goalProgress == null) {
      return const SizedBox.shrink();
    }

    // Calculate the tug-of-war ratio
    // Left side = Goal Failed 💀, Right side = Goal Achieved 🏆
    // Progress closer to 1.0 = closer to achieving goal (right side wins)
    // Progress closer to 0.0 = failing goal (left side wins)
    final progress = widget.goalProgress!.progress.clamp(0.0, 1.0);
    
    // Net position: 0 = total failure (left), 0.5 = halfway, 1.0 = achieved (right)
    final netPosition = progress;

    // Trigger sound and animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playSound(netPosition);
    });

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: Column(
        children: [
          // Labels with bounce animation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 1.0, end: netPosition < 0.3 ? 1.2 : 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      alignment: Alignment.centerLeft,
                      child: child,
                    );
                  },
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '💀',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Goal Failed',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Flexible(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 1.0, end: netPosition >= 0.75 ? 1.2 : 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      alignment: Alignment.centerRight,
                      child: child,
                    );
                  },
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Goal Achieved',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '🏆',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Pixel-style tug-of-war bar with pulse animation
          TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.5, end: netPosition),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Container(
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.zero, // Pixel-style: no rounding
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  // Background gradient (dark to light = failure to success)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.shade900.withOpacity(0.4),
                          Colors.orange.withOpacity(0.3),
                          Colors.yellow.withOpacity(0.3),
                          Colors.green.withOpacity(0.4),
                        ],
                      ),
                    ),
                  ),
                  // Animated pixel blocks (progress fills from left to right)
                  ClipRect(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final barWidth = constraints.maxWidth * value;
                        final blockWidth = 12.0; // Pixel block width
                        final blockMargin = 4.0; // Total horizontal margin (2 + 2)
                        final totalBlockWidth = blockWidth + blockMargin; // Total space per block
                        final numBlocks = (barWidth / totalBlockWidth).floor();
                        
                        return OverflowBox(
                          maxWidth: constraints.maxWidth,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (int i = 0; i < numBlocks; i++)
                                Container(
                                  width: blockWidth - 0.5, // Slightly smaller to prevent overflow
                                  height: 24,
                                  margin: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Color.lerp(
                                      Colors.red.shade700,
                                      Colors.green.shade400,
                                      i / numBlocks.clamp(1, double.infinity),
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // Center indicator (the "rope" or marker)
                  Positioned(
                    left: value * MediaQuery.of(context).size.width * 0.85 - 12,
                    child: Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade300,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '⚡',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        // Status text
        Text(
          netPosition >= 1.0
              ? '🏆 GOAL WON!'
              : netPosition >= 0.75
                  ? '🔥 Almost there!'
                  : netPosition >= 0.5
                      ? '⚔️ Keep fighting!'
                      : netPosition >= 0.25
                          ? '⚠️ Danger zone!'
                          : '💀 Critical!',
          style: GoogleFonts.pressStart2p(
            fontSize: 8,
            color: netPosition >= 0.75
                ? Colors.green.shade200
                : netPosition >= 0.5
                    ? Colors.yellow.shade200
                    : Colors.red.shade200,
          ),
        ),
        ],
      ),
    );
  }
}
