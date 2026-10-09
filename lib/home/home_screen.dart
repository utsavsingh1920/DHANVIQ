import 'dart:math' as math;
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../settings/profile_screen.dart';
import '../goals/goals_screen.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import '../services/finance_plan_service.dart';
import '../services/currency_service.dart';
import '../services/notification_service.dart';
import '../settings/notifications_screen.dart';
import '../navigation/main_navigation_screen.dart';
import '../budget/set_monthly_budget_screen.dart';

bool _isDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;
Color _ink(BuildContext context) =>
    _isDark(context) ? const Color(0xFFF8FAFF) : const Color(0xFF101936);
Color _subtle(BuildContext context) =>
    _isDark(context) ? const Color(0xFFB8C0D9) : const Color(0xFF747D94);
Color _surface(BuildContext context) =>
    _isDark(context) ? const Color(0xFF171D2B) : Colors.white;
Color _page(BuildContext context) =>
    _isDark(context) ? const Color(0xFF111522) : const Color(0xFFF7F8FD);
Color _stroke(BuildContext context) =>
    _isDark(context) ? const Color(0xFF30364A) : const Color(0xFFE4E6EF);
// Read the Appearance selection through MaterialApp's dynamic ColorScheme.
Color _accent(BuildContext context) => Theme.of(context).colorScheme.primary;
Color _onAccent(BuildContext context) =>
    ThemeData.estimateBrightnessForColor(_accent(context)) == Brightness.dark
    ? Colors.white
    : const Color(0xFF111827);
Color _tint(BuildContext context) => Color.alphaBlend(
  _accent(context).withValues(alpha: _isDark(context) ? .18 : .10),
  _surface(context),
);

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.onNavigationTap,
    this.showNavigation = true,
  });
  final ValueChanged<int>? onNavigationTap;
  final bool showNavigation;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Color get _brand => _accent(context);

  String get _greeting {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    }
    if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    }
    if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    }
    return 'Good Night';
  }

  String get _greetingIcon {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return '🌤️';
    }
    if (hour >= 12 && hour < 17) {
      return '☀️';
    }
    if (hour >= 17 && hour < 21) {
      return '🌅';
    }
    return '🌙';
  }

  static const _mint = Color(0xFF16CFA5);
  static const _pink = Color(0xFFFF4D82);
  bool _showBalance = true;
  String? _profilePhotoPath;
  Future<void> _loadProfilePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('dhanviq_profile_photo_path');
    final available = path != null && await File(path).exists();
    if (mounted) setState(() => _profilePhotoPath = available ? path : null);
  }

  Future<void> _openProfile() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
    );
    if (mounted) await _loadProfilePhoto();
  }

  bool get _firstTime =>
      _service.transactions.isEmpty &&
      _plans.goals.isEmpty &&
      _plans.bills.isEmpty &&
      !_hasBudget;
  bool get _hasBudget {
    final now = DateTime.now();
    return _budgetCategories.any(
      (c) => _plans.budgetFor(now.year, now.month, c) > 0,
    );
  }

  static const _budgetCategories = <String>[
    'Food',
    'Groceries',
    'Transport',
    'Shopping',
    'Bills',
    'Rent',
    'Health',
    'Education',
    'Entertainment',
    'Travel',
    'Fuel',
    'EMI / Loan',
    'Personal Care',
    'Subscriptions',
    'Family',
    'Insurance',
    'Other',
  ];
  final _service = TransactionService.instance;
  final _plans = FinancePlanService.instance;
  final _currency = CurrencyService.instance;
  final _notifications = NotificationService.instance;
  @override
  void initState() {
    super.initState();
    _service.addListener(_refreshFinance);
    _plans.addListener(_refreshFinance);
    _currency.addListener(_refreshVisuals);
    _notifications.addListener(_refreshVisuals);
    _initializeHomeData();
    _loadProfilePhoto();
  }

  Future<void> _initializeHomeData() async {
    try {
      await Future.wait([
        _service.initialize(),
        _plans.initialize(),
        _notifications.initialize(),
      ]);

      await _syncNotifications();

      if (mounted) setState(() {});
    } catch (error) {
      debugPrint('Could not initialize Home data: $error');
    }
  }

  void _refreshFinance() {
    if (mounted) setState(() {});
    Future<void>.microtask(_syncNotifications);
  }

  void _refreshVisuals() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _service.removeListener(_refreshFinance);
    _plans.removeListener(_refreshFinance);
    _currency.removeListener(_refreshVisuals);
    _notifications.removeListener(_refreshVisuals);
    super.dispose();
  }

  String _amount(double value) {
    return _currency.formatAmount(value, decimal: value.abs() % 1 != 0);
  }

  void _add(bool income) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AddTransactionForm(isIncome: income),
    ),
  );
  // Goals is a separate screen, not a bottom navigation tab.
  void _openGoals() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const GoalsScreen()));
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const NotificationCenterScreen(),
      ),
    );
  }

  String _normalizedCategory(String value) {
    final key = value.trim().toLowerCase();

    return switch (key) {
      'bills & utilities' || 'utilities' => 'bills',
      'health & medical' || 'medical' => 'health',
      'others' => 'other',
      'home' => 'rent',
      'emi' || 'loan' || 'emi/loan' => 'emi / loan',
      'subscription' => 'subscriptions',
      _ => key,
    };
  }

  bool _sameCategory(String left, String right) {
    return _normalizedCategory(left) == _normalizedCategory(right);
  }

  Future<void> _syncNotifications() async {
    final master = await _notifications.preferenceEnabled(
      NotificationService.masterKey,
    );

    if (!master) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Recent transactions from today.
    final incomeEnabled = await _notifications.preferenceEnabled(
      NotificationService.incomeKey,
    );
    final expenseEnabled = await _notifications.preferenceEnabled(
      NotificationService.expenseKey,
    );

    for (final item in _service.transactions.take(8)) {
      final itemDay = DateTime(
        item.date.year,
        item.date.month,
        item.date.day,
      );

      if (itemDay != today) continue;

      if (item.type == TransactionType.income && incomeEnabled) {
        await _notifications.addOrUpdate(
          id: 'income_${item.date.millisecondsSinceEpoch}_${item.amount}_${item.title}',
          title: 'Income added',
          body: '${_amount(item.amount)} • ${item.title}',
          category: 'income',
          createdAt: item.date,
        );
      } else if (item.type == TransactionType.expense && expenseEnabled) {
        await _notifications.addOrUpdate(
          id: 'expense_${item.date.millisecondsSinceEpoch}_${item.amount}_${item.title}',
          title: 'Expense recorded',
          body: '${_amount(item.amount)} • ${item.title}',
          category: 'expense',
          createdAt: item.date,
        );
      }
    }

    // Upcoming bill / expense reminders.
    final remindersEnabled = await _notifications.preferenceEnabled(
      NotificationService.remindersKey,
    );

    if (remindersEnabled) {
      for (final bill in _plans.bills.where((bill) => !bill.paid)) {
        final due = DateTime(
          bill.dueDate.year,
          bill.dueDate.month,
          bill.dueDate.day,
        );
        final days = due.difference(today).inDays;

        if (days < 0 || days > 7) continue;

        final dueText = days == 0
            ? 'due today'
            : days == 1
                ? 'due tomorrow'
                : 'due in $days days';

        await _notifications.addOrUpdate(
          id: 'bill_${bill.id}_${bill.dueDate.millisecondsSinceEpoch}',
          title: bill.title,
          body: '${_amount(bill.amount)} • $dueText',
          category: 'reminder',
          createdAt: now,
        );
      }
    }

    // Monthly budget alerts at 80% and 100%.
    final budgetEnabled = await _notifications.preferenceEnabled(
      NotificationService.budgetKey,
    );

    if (budgetEnabled) {
      final monthTransactions =
          _service.transactionsForMonth(now.year, now.month);

      for (final category in _budgetCategories) {
        final budget = _plans.budgetFor(
          now.year,
          now.month,
          category,
        );

        if (budget <= 0) continue;

        final spent = monthTransactions
            .where(
              (item) =>
                  item.type == TransactionType.expense &&
                  _sameCategory(item.category, category),
            )
            .fold<double>(0, (sum, item) => sum + item.amount);

        if (spent <= 0) continue;

        final ratio = spent / budget;

        if (ratio >= 1) {
          await _notifications.addOrUpdate(
            id: 'budget_${now.year}_${now.month}_${category}_100',
            title: '$category budget reached',
            body:
                'You spent ${_amount(spent)} of ${_amount(budget)} this month.',
            category: 'budget',
            createdAt: now,
          );
        } else if (ratio >= .8) {
          await _notifications.addOrUpdate(
            id: 'budget_${now.year}_${now.month}_${category}_80',
            title: '$category budget is nearly full',
            body:
                '${(ratio * 100).round()}% used • ${_amount(spent)} of ${_amount(budget)}',
            category: 'budget',
            createdAt: now,
          );
        }
      }
    }

    // Savings-goal milestones.
    final goalsEnabled = await _notifications.preferenceEnabled(
      NotificationService.goalsKey,
    );

    if (goalsEnabled) {
      for (final goal in _plans.goals) {
        if (goal.target <= 0) continue;

        final percent =
            ((goal.saved / goal.target) * 100).clamp(0, 100).round();

        final milestone = percent >= 100
            ? 100
            : percent >= 75
                ? 75
                : percent >= 50
                    ? 50
                    : percent >= 25
                        ? 25
                        : 0;

        if (milestone == 0) continue;

        await _notifications.addOrUpdate(
          id: 'goal_${goal.id}_$milestone',
          title: milestone == 100
              ? '${goal.name} completed!'
              : '${goal.name} reached $milestone%',
          body:
              '${_amount(goal.saved)} saved of ${_amount(goal.target)}',
          category: 'goal',
          createdAt: now,
        );
      }
    }
  }

  void _navigate(int index, String label) {
    if (label == 'Goals') {
      _openGoals();
      return;
    }
    if (widget.onNavigationTap != null) {
      widget.onNavigationTap!(index);
    } else if (index != 0) {
      // When Home is opened standalone, use the app's main navigation.
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const MainNavigationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _isDark(context)
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: _isDark(context)
            ? Brightness.dark
            : Brightness.light,
        systemNavigationBarColor: _page(context),
        systemNavigationBarIconBrightness: _isDark(context)
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarDividerColor: _page(context),
      ),
      child: Scaffold(
        backgroundColor: _page(context),
        extendBody: true,
        body: Stack(
          children: [
            const Positioned.fill(child: _HomeBackground()),
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _HomeStickyHeader(child: _header()),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 112),
                    sliver: SliverList.list(
                      children: [
                        _balanceCard(),
                        SizedBox(height: 14),
                        _quickActions(),
                        SizedBox(height: 12),
                        _tipCard(),
                        SizedBox(height: 17),
                        _sectionTitle(
                          'Recent Transactions',
                          action: 'See All',
                          onTap: () => _navigate(1, 'Transactions'),
                        ),
                        SizedBox(height: 8),
                        _transactionsCard(),
                        SizedBox(height: 17),
                        _sectionTitle(
                          'Monthly Overview',
                          action: 'See Details',
                          onTap: () => _navigate(3, 'Insights'),
                        ),
                        SizedBox(height: 10),
                        _monthlyOverview(),
                        SizedBox(height: 17),
                        _sectionTitle(
                          'Budget Progress',
                          action: 'See All',
                          onTap: _setBudget,
                        ),
                        SizedBox(height: 10),
                        _budgetProgress(),
                        SizedBox(height: 17),
                        _sectionTitle(
                          'Savings Goals',
                          action: 'See All',
                          onTap: () => _openGoals(),
                        ),
                        SizedBox(height: 10),
                        _savingsGoals(),
                        SizedBox(height: 17),
                        _sectionTitle(
                          'Income vs Expense',
                          trailing: _periodChip(),
                        ),
                        SizedBox(height: 10),
                        _incomeExpenseChart(),
                        SizedBox(height: 17),
                        _sectionTitle('Upcoming Expenses'),
                        SizedBox(height: 10),
                        _upcomingExpenses(),
                        SizedBox(height: 14),
                        _smartInsight(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: widget.showNavigation
            ? Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(_brand, Colors.white, .12)!,
                      Color.lerp(_brand, Colors.black, .15)!,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _brand.withValues(alpha: .32),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _navigate(2, 'Add Transaction'),
                    customBorder: const CircleBorder(),
                    child: Icon(
                      Icons.add_rounded,
                      color: _onAccent(context),
                      size: 34,
                    ),
                  ),
                ),
              )
            : null,
        bottomNavigationBar: widget.showNavigation
            ? _BottomNavigation(onTap: _navigate)
            : null,
      ),
    );
  }

  Widget _header() {
    final unread = _notifications.unreadCount;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: _isDark(context)
                ? const Color(0xFF10182B)
                : _surface(context),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: _stroke(context).withValues(alpha: .58),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.asset(
              'assets/icon/dhanviq_icon.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, _, _) => Container(
                alignment: Alignment.center,
                color: _tint(context),
                child: Text(
                  'D',
                  style: TextStyle(
                    color: _brand,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DHANVIQ',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _ink(context),
                  fontSize: 18,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.20,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      _greeting,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _subtle(context),
                        fontSize: 12.3,
                        height: 1.05,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _greetingIcon,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 7),
        _notificationAction(unread),
        const SizedBox(width: 7),
        GestureDetector(
          onTap: _openProfile,
          child: Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _tint(context),
              border: Border.all(
                color: _stroke(context),
                width: 1.1,
              ),
            ),
            child: ClipOval(
              child: _profilePhotoPath == null
                  ? Icon(
                      Icons.person_rounded,
                      color: _brand,
                      size: 24,
                    )
                  : Image.file(
                      File(_profilePhotoPath!),
                      width: 43,
                      height: 43,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stack) => Icon(
                        Icons.person_rounded,
                        color: _brand,
                        size: 24,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _notificationAction(int unread) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: unread > 0
              ? _tint(context)
              : (_isDark(context)
                    ? const Color(0xFF10182B)
                    : _surface(context)),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: _openNotifications,
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 43,
              height: 43,
              child: Icon(
                unread > 0
                    ? Icons.notifications_rounded
                    : Icons.notifications_none_rounded,
                color: unread > 0 ? _brand : _ink(context),
                size: 23,
              ),
            ),
          ),
        ),
        if (unread > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _pink,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _page(context),
                  width: 2,
                ),
              ),
              child: Text(
                unread > 9 ? '9+' : '$unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }


  Widget _balanceCard() {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isDark(context)
              ? [
                  const Color(0xFF132B54),
                  Color.lerp(const Color(0xFF19235F), _brand, .35)!,
                  Color.lerp(const Color(0xFF132B54), _brand, .65)!,
                ]
              : [
                  const Color(0xFF0A2B66),
                  Color.lerp(const Color(0xFF25218A), _brand, .40)!,
                  Color.lerp(const Color(0xFF0A2B66), _brand, .72)!,
                ],
          stops: const [0, .56, 1],
        ),
        border: Border.all(
          color: _brand.withValues(alpha: _isDark(context) ? .55 : .40),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: _brand.withValues(alpha: _isDark(context) ? .18 : .22),
            blurRadius: 23,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            child: _firstTime
                ? _GrowingPlant()
                : SizedBox(
                    width: 145,
                    height: 92,
                    child: CustomPaint(
                      painter: _BalanceGraphPainter(accent: _brand),
                    ),
                  ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Total Balance',
                    style: TextStyle(color: Color(0xFFDDE8FF), fontSize: 14),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showBalance = !_showBalance;
                      });
                    },
                    child: Container(
                      width: 39,
                      height: 39,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _showBalance
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 7),
              Text(
                _showBalance
                    ? _amount(
                        _service.totalBalance -
                            _plans.goals.fold<double>(
                              0,
                              (sum, goal) => sum + goal.saved,
                            ),
                      )
                    : '${_currency.symbol}••••••',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.7,
                ),
              ),
              const Spacer(),
              Text(
                _monthlySavingComparison(),
                style: const TextStyle(
                  color: Color(0xFFE8F5FF),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _monthlySavingComparison() {
    final now = DateTime.now();
    final thisNet =
        _service.incomeForMonth(now.year, now.month) -
        _service.expensesForMonth(now.year, now.month);
    final last = DateTime(now.year, now.month - 1);
    final previousIncome = _service.incomeForMonth(last.year, last.month);
    final previousExpense = _service.expensesForMonth(last.year, last.month);
    if (previousIncome == 0 && previousExpense == 0) {
      return thisNet >= 0
          ? 'Saved this month  ${_amount(thisNet)}'
          : 'Net this month  -${_amount(thisNet.abs())}';
    }
    final previousNet = previousIncome - previousExpense;
    if (previousNet <= 0) {
      return thisNet >= 0
          ? 'Saved this month  ${_amount(thisNet)}'
          : 'Net this month  -${_amount(thisNet.abs())}';
    }
    final delta = (thisNet - previousNet) / previousNet * 100;
    final arrow = delta >= 0 ? '▲' : '▼';
    return '$arrow ${delta.abs().toStringAsFixed(0)}% vs last month  •  '
        '${thisNet >= 0 ? 'Saved ${_amount(thisNet)}' : 'Net -${_amount(thisNet.abs())}'}';
  }

  Widget _quickActions() {
    final actions = [
      (Icons.add_rounded, 'Add\nIncome', const Color(0xFFE0FAF2), _mint),
      (Icons.remove_rounded, 'Add\nExpense', const Color(0xFFFFE6EF), _pink),
      (Icons.pie_chart_rounded, 'Set\nBudget', _tint(context), _brand),
      (
        Icons.track_changes_rounded,
        'Add\nGoal',
        Color(0xFFFFF1D8),
        Color(0xFFFFA91E),
      ),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((item) {
        return Expanded(
          child: InkWell(
            onTap: () {
              if (item.$2 == 'Add\nIncome') {
                _add(true);
              } else if (item.$2 == 'Add\nExpense') {
                _add(false);
              } else if (item.$2 == 'Add\nGoal') {
                _openGoals();
              } else {
                _setBudget();
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Column(
                children: [
                  Container(
                    width: 57,
                    height: 57,
                    decoration: BoxDecoration(
                      color: _isDark(context)
                          ? switch (item.$2) {
                              'Add\nIncome' => const Color(0xFF112B28),
                              'Add\nExpense' => const Color(0xFF2A1724),
                              'Set\nBudget' => _tint(context),
                              _ => const Color(0xFF2E2412),
                            }
                          : item.$3,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isDark(context)
                            ? item.$4.withValues(alpha: .22)
                            : Colors.transparent,
                      ),
                      boxShadow: _isDark(context)
                          ? [
                              BoxShadow(
                                color: item.$4.withValues(alpha: .10),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(item.$1, color: item.$4, size: 28),
                  ),
                  SizedBox(height: 7),
                  Text(
                    item.$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _ink(context),
                      fontSize: 12,
                      height: 1.18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _tipCard() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _navigate(3, 'Insights'),
      child: _SoftCard(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        color: _isDark(context)
            ? const Color(0xFF1A2031)
            : const Color(0xFFF1F5FF),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: (_isDark(context)
                    ? const Color(0xFF4A3815)
                    : const Color(0xFFFFF0C9)),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(Icons.lightbulb_rounded, color: Color(0xFFFFB621)),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _firstTime
                        ? 'Welcome to DHANVIQ!'
                        : (_service.expensesForMonth(
                                    DateTime.now().year,
                                    DateTime.now().month,
                                  ) >
                                  _service.incomeForMonth(
                                    DateTime.now().year,
                                    DateTime.now().month,
                                  )
                              ? 'Review your spending'
                              : 'You’re on track!'),
                    style: TextStyle(
                      color: _ink(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    _service.transactions.isEmpty
                        ? 'Start by adding your first transaction to build your financial journey.'
                        : 'This month you spent ${_amount(_service.expensesForMonth(DateTime.now().year, DateTime.now().month))}. Check your monthly overview for details.',
                    style: TextStyle(
                      color: _subtle(context),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: _subtle(context)),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(
    String title, {
    String? action,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: _ink(context),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing is Widget) trailing,
        if (action != null)
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              action,
              style: TextStyle(
                color: _brand,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
      ],
    );
  }

  // Icons stay in this Home file; no additional widget files required.
  IconData _categoryIcon(String category, TransactionType type) {
    switch (_normalizedCategory(category)) {
      case 'salary':
        return Icons.work_rounded;
      case 'freelance':
        return Icons.laptop_mac_rounded;
      case 'business':
        return Icons.business_rounded;
      case 'bonus':
        return Icons.card_giftcard_rounded;
      case 'investments':
        return Icons.trending_up_rounded;
      case 'interest':
        return Icons.savings_rounded;
      case 'rental':
        return Icons.home_work_rounded;
      case 'refund':
        return Icons.replay_rounded;
      case 'gift':
        return Icons.redeem_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'groceries':
        return Icons.shopping_cart_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'rent':
        return Icons.home_rounded;
      case 'health':
        return Icons.favorite_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'travel':
        return Icons.flight_rounded;
      case 'fuel':
        return Icons.local_gas_station_rounded;
      case 'emi / loan':
        return Icons.account_balance_rounded;
      case 'personal care':
        return Icons.spa_rounded;
      case 'subscriptions':
        return Icons.autorenew_rounded;
      case 'family':
        return Icons.family_restroom_rounded;
      case 'insurance':
        return Icons.verified_user_rounded;
      case 'other':
        return type == TransactionType.income
            ? Icons.payments_rounded
            : Icons.more_horiz_rounded;
      default:
        return type == TransactionType.income
            ? Icons.payments_rounded
            : Icons.category_rounded;
    }
  }

  // Shared category visual language across Recent Transactions, Monthly Overview,
  // Budget Progress and the income/expense summary.
  Color _categoryColor(String category, TransactionType type) {
    if (type == TransactionType.income) {
      return switch (_normalizedCategory(category)) {
        'salary' => const Color(0xFF16CFA5),
        'freelance' => const Color(0xFF20BFA9),
        'business' => const Color(0xFF2E9FDC),
        'bonus' => const Color(0xFF16CFA5),
        'investments' => const Color(0xFF35B97B),
        'interest' => const Color(0xFF20BFA9),
        'rental' => const Color(0xFF2E9FDC),
        'refund' => const Color(0xFF32BFA3),
        'gift' => const Color(0xFF37B58D),
        _ => _mint,
      };
    }

    return switch (_normalizedCategory(category)) {
      'food' => const Color(0xFFFF4D82),
      'groceries' => const Color(0xFFFF6B6B),
      'transport' => const Color(0xFF22B8A8),
      'shopping' => const Color(0xFFFF648B),
      'bills' => const Color(0xFF3498E8),
      'rent' => const Color(0xFFFFA144),
      'health' => const Color(0xFFFF5271),
      'education' => const Color(0xFF36AACC),
      'entertainment' => const Color(0xFF8257FF),
      'travel' => const Color(0xFF20BFA9),
      'fuel' => const Color(0xFFF59E0B),
      'emi / loan' => const Color(0xFF5B78D6),
      'personal care' => const Color(0xFFB65BDC),
      'subscriptions' => const Color(0xFF7D63D9),
      'family' => const Color(0xFFE879A9),
      'insurance' => const Color(0xFF4588C9),
      _ => const Color(0xFF9E8BF7),
    };
  }

  Widget _categoryBadge(
    String category,
    TransactionType type, {
    double size = 32,
  }) {
    final accent = _categoryColor(category, type);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: _isDark(context) ? .19 : .11),
        borderRadius: BorderRadius.circular(size * .32),
      ),
      child: Icon(
        _categoryIcon(category, type),
        color: accent,
        size: size * .52,
      ),
    );
  }

  Widget _emptyCard({
    required IconData icon,
    required String title,
    required String description,
    required String button,
    required VoidCallback onTap,
    bool tall = false,
  }) {
    if (tall) {
      return _SoftCard(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 15),
        child: Column(
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: _tint(context),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 43, color: _brand),
            ),
            SizedBox(height: 13),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ink(context),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _subtle(context),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: FilledButton.icon(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: _brand,
                  foregroundColor: _onAccent(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(Icons.add_rounded, size: 23),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    button,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return _SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
      child: Row(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: _tint(context),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 37, color: _brand),
          ),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _ink(context),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(
                    color: _subtle(context),
                    fontSize: 11.8,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 11),
                SizedBox(
                  width: double.infinity,
                  height: 35,
                  child: FilledButton(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: _tint(context),
                      foregroundColor: _brand,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      button,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _transactionsCard() {
    final items = _service.transactions.take(4).toList();
    if (items.isEmpty) {
      return _emptyCard(
        icon: Icons.find_in_page_outlined,
        title: 'No transactions yet',
        description: 'Add your first income or expense\nto get started.',
        button: 'Add Your First Transaction',
        onTap: () => _add(true),
        tall: true,
      );
    }
    return _SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
      child: Column(
        children: [
          for (final item in items) ...[
            InkWell(
              onTap: () => _navigate(1, 'Transactions'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    _categoryBadge(item.category, item.type, size: 42),
                    SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              color: _ink(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            '${item.date.day}/${item.date.month}/${item.date.year} • ${item.category}',
                            style: TextStyle(
                              color: _subtle(context),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${item.type == TransactionType.income ? '+' : '-'}${_amount(item.amount)}',
                      style: TextStyle(
                        color: item.type == TransactionType.income
                            ? _mint
                            : _pink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (item != items.last)
              Divider(
                height: 1,
                color: _stroke(context).withValues(alpha: .72),
              ),
          ],
        ],
      ),
    );
  }

  Widget _monthlyOverview() {
    final now = DateTime.now();
    final expenses = _service
        .transactionsForMonth(now.year, now.month)
        .where((t) => t.type == TransactionType.expense)
        .toList();
    final total = expenses.fold<double>(0, (sum, t) => sum + t.amount);
    final byCategory = <String, double>{};
    for (final t in expenses) {
      byCategory.update(
        t.category,
        (v) => v + t.amount,
        ifAbsent: () => t.amount,
      );
    }
    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (total <= 0) {
      return _SoftCard(
        child: Row(
          children: [
            _PlaceholderBars(),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No data yet',
                    style: TextStyle(
                      color: _ink(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Add transactions to see your spending breakdown.',
                    style: TextStyle(color: _subtle(context), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return _SoftCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 142,
            height: 142,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size.square(120),
                  painter: _DonutPainter(
                    values: sorted.map((e) => e.value).toList(),
                    colors: List.generate(
                      sorted.length,
                      (i) => _categoryColor(
                        sorted[i].key,
                        TransactionType.expense,
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      child: Text(
                        _amount(total),
                        style: TextStyle(
                          color: _ink(context),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      'Spent',
                      style: TextStyle(color: _subtle(context), fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 11),
          Expanded(
            child: sorted.isEmpty
                ? Text(
                    'No expenses this month',
                    style: TextStyle(color: _subtle(context), fontSize: 11),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < sorted.length && i < 5; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              _categoryBadge(
                                sorted[i].key,
                                TransactionType.expense,
                                size: 26,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  sorted[i].key,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _subtle(context),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              Text(
                                '${(sorted[i].value / total * 100).round()}%',
                                style: TextStyle(
                                  color: _ink(context),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _budgetProgress() {
    final now = DateTime.now();
    final items = <({String name, double limit, double spent})>[];
    final expenses = _service
        .transactionsForMonth(now.year, now.month)
        .where((t) => t.type == TransactionType.expense)
        .toList();
    for (final category in _budgetCategories) {
      final legacyAlias = switch (category) {
        'Bills' => 'Bills & Utilities',
        'Health' => 'Health & Medical',
        'Other' => 'Others',
        _ => category,
      };

      final currentBudget = _plans.budgetFor(
        now.year,
        now.month,
        category,
      );
      final legacyBudget = legacyAlias == category
          ? 0.0
          : _plans.budgetFor(
              now.year,
              now.month,
              legacyAlias,
            );

      final limit = math.max(currentBudget, legacyBudget);
      if (limit <= 0) continue;

      final used = expenses
          .where((t) => _sameCategory(t.category, category))
          .fold<double>(0, (sum, t) => sum + t.amount);
      items.add((name: category, limit: limit, spent: used));
    }
    if (items.isEmpty) {
      return _emptyCard(
        icon: Icons.donut_large_rounded,
        title: 'No budget set yet',
        description: 'Set monthly category budgets to track your spending.',
        button: 'Set Budget',
        onTap: _setBudget,
      );
    }
    items.sort((a, b) => b.spent.compareTo(a.spent));
    final totalLimit = items.fold<double>(0, (s, x) => s + x.limit);
    final totalUsed = items.fold<double>(0, (s, x) => s + x.spent);
    final percent = totalLimit <= 0 ? 0.0 : totalUsed / totalLimit;
    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
      child: Column(
        children: [
          InkWell(
            onTap: _setBudget,
            borderRadius: BorderRadius.circular(14),
            child: Row(
              children: [
                SizedBox(
                  width: 66,
                  height: 66,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: percent.clamp(0.0, 1.0),
                          strokeWidth: 7,
                          strokeCap: StrokeCap.round,
                          backgroundColor: _stroke(context),
                          color: totalUsed > totalLimit ? _pink : _brand,
                        ),
                      ),
                      Text(
                        '${(percent * 100).round()}%',
                        style: TextStyle(
                          color: _ink(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_amount(totalUsed)} / ${_amount(totalLimit)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _ink(context),
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Spent this month',
                        style: TextStyle(color: _subtle(context), fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: percent.clamp(0.0, 1.0),
                          minHeight: 7,
                          color: totalUsed > totalLimit ? _pink : _brand,
                          backgroundColor: _stroke(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: _subtle(context)),
              ],
            ),
          ),
          const SizedBox(height: 13),
          for (final item in items.take(4)) ...[
            InkWell(
              onTap: _setBudget,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    _categoryBadge(
                      item.name,
                      TransactionType.expense,
                      size: 27,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _ink(context),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              Text(
                                '${_amount(item.spent)} / ${_amount(item.limit)}',
                                style: TextStyle(
                                  color: _subtle(context),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: LinearProgressIndicator(
                              value: (item.spent / item.limit).clamp(0.0, 1.0),
                              minHeight: 5,
                              color: item.spent > item.limit
                                  ? _pink
                                  : _categoryColor(
                                      item.name,
                                      TransactionType.expense,
                                    ),
                              backgroundColor: _stroke(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (items.length > 4)
            TextButton(
              onPressed: _setBudget,
              child: Text('View all ${items.length} categories'),
            ),
        ],
      ),
    );
  }

  Widget _savingsGoals() {
    final goals = _plans.goals;
    if (goals.isEmpty) {
      return _emptyCard(
        icon: Icons.flag_rounded,
        title: 'No savings goals yet',
        description: 'Create a savings goal to see your progress here.',
        button: 'Add Goal',
        onTap: _openGoals,
      );
    }
    const accents = <Color>[
      Color(0xFF16CFA5),
      Color(0xFF3A8FF5),
      Color(0xFF8B5CFF),
    ];
    const icons = <IconData>[
      Icons.laptop_mac_rounded,
      Icons.flight_takeoff_rounded,
      Icons.savings_rounded,
    ];
    return _SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Column(
        children: [
          for (var i = 0; i < goals.length && i < 3; i++) ...[
            InkWell(
              onTap: _openGoals,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: accents[i % accents.length].withValues(
                          alpha: .13,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icons[i % icons.length],
                        color: accents[i % accents.length],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goals[i].name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _ink(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_amount(goals[i].saved)} / ${_amount(goals[i].target)}',
                            style: TextStyle(
                              color: _subtle(context),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: LinearProgressIndicator(
                              value: goals[i].progress.clamp(0.0, 1.0),
                              minHeight: 5,
                              backgroundColor: _stroke(context),
                              color: accents[i % accents.length],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '${(goals[i].progress * 100).round()}%',
                      style: TextStyle(
                        color: accents[i % accents.length],
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (i != goals.length - 1 && i != 2)
              Divider(height: 1, color: _stroke(context)),
          ],
        ],
      ),
    );
  }

  Future<void> _setBudget() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const SetMonthlyBudgetScreen()),
    );
  }

  Future<void> _addBill() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const UpcomingExpenseSheet(),
    );
  }

  Future<void> _openUpcomingExpenses() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const _UpcomingExpensesScreen()),
    );
  }

  Widget _periodChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: _surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _stroke(context)),
      ),
      child: Row(
        children: [
          Text(
            'This Month',
            style: TextStyle(
              color: _ink(context),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _subtle(context),
            size: 17,
          ),
        ],
      ),
    );
  }

  Widget _incomeExpenseChart() {
    final now = DateTime.now();
    final weeksIncome = List<double>.filled(4, 0);
    final weeksExpense = List<double>.filled(4, 0);
    for (final t in _service.transactionsForMonth(now.year, now.month)) {
      final index = ((t.date.day - 1) ~/ 8).clamp(0, 3);
      if (t.type == TransactionType.income) {
        weeksIncome[index] += t.amount;
      } else {
        weeksExpense[index] += t.amount;
      }
    }
    if (weeksIncome.every((v) => v == 0) && weeksExpense.every((v) => v == 0)) {
      return _SoftCard(
        child: Column(
          children: [
            SizedBox(height: 8),
            _PlaceholderBars(wide: true),
            SizedBox(height: 12),
            Text(
              'Add transactions to see your income vs expense trend.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _subtle(context), fontSize: 12),
            ),
          ],
        ),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _navigate(3, 'Insights'),
      child: _SoftCard(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 11),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.account_balance_wallet_rounded,
                  color: _mint,
                  size: 17,
                ),
                SizedBox(width: 5),
                Text(
                  'Income',
                  style: TextStyle(color: _subtle(context), fontSize: 10),
                ),
                SizedBox(width: 13),
                Icon(Icons.shopping_bag_rounded, color: _pink, size: 17),
                SizedBox(width: 5),
                Text(
                  'Expense',
                  style: TextStyle(color: _subtle(context), fontSize: 10),
                ),
              ],
            ),
            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 150,
              child: CustomPaint(
                painter: _BarChartPainter(
                  income: weeksIncome,
                  expense: weeksExpense,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _upcomingExpenses() {
    final bills = _plans.bills.where((b) => !b.paid).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    // FIRST-TIME / EMPTY STATE
    if (bills.isEmpty) {
      return _SoftCard(
        padding: const EdgeInsets.fromLTRB(14, 15, 14, 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _tint(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                color: _brand,
                size: 25,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No upcoming expenses yet',
                    style: TextStyle(
                      color: _ink(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add bills, subscriptions or payment reminders.',
                    style: TextStyle(
                      color: _subtle(context),
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 36,
                    child: FilledButton.icon(
                      onPressed: _addBill,
                      style: FilledButton.styleFrom(
                        backgroundColor: _brand,
                        foregroundColor: _onAccent(context),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(
                        'Add Upcoming Expense',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // AFTER-DATA COMPACT SUMMARY
    final nextBill = bills.first;
    final totalAmount = bills.fold<double>(0, (sum, bill) => sum + bill.amount);

    final dueDate =
        '${nextBill.dueDate.day.toString().padLeft(2, '0')}/'
        '${nextBill.dueDate.month.toString().padLeft(2, '0')}/'
        '${nextBill.dueDate.year}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openUpcomingExpenses,
        borderRadius: BorderRadius.circular(20),
        child: _SoftCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _tint(context),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: _brand,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${bills.length} upcoming '
                          '${bills.length == 1 ? 'expense' : 'expenses'}',
                          style: TextStyle(
                            color: _ink(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Total ${_amount(totalAmount)} scheduled',
                          style: TextStyle(
                            color: _subtle(context),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _openUpcomingExpenses,
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 5,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'View All',
                      style: TextStyle(
                        color: _brand,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: _stroke(context).withValues(alpha: .75),
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _pink.withValues(
                        alpha: _isDark(context) ? .16 : .10,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.schedule_rounded,
                      color: _pink,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next: ${nextBill.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _ink(context),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Due $dueDate',
                          style: TextStyle(
                            color: _subtle(context),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _amount(nextBill.amount),
                    style: const TextStyle(
                      color: _pink,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: _subtle(context),
                    size: 19,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smartInsight() {
    final now = DateTime.now();
    final income = _service.incomeForMonth(now.year, now.month);
    final expense = _service.expensesForMonth(now.year, now.month);
    final net = income - expense;
    final message = income == 0 && expense == 0
        ? 'Add income or an expense to see your monthly summary.'
        : expense > income && income > 0
        ? 'Spending is above your recorded income this month. Review your expenses.'
        : 'Income ${_amount(income)} • Expenses ${_amount(expense)} • Net ${_amount(net)}';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigate(3, 'Insights'),
        borderRadius: BorderRadius.circular(20),
        child: _SoftCard(
          color: _tint(context),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: _brand,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.lightbulb_outline_rounded,
                  color: _onAccent(context),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Insight',
                      style: TextStyle(
                        color: _ink(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _subtle(context),
                        fontSize: 10.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: _subtle(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingExpensesScreen extends StatefulWidget {
  const _UpcomingExpensesScreen();

  @override
  State<_UpcomingExpensesScreen> createState() =>
      _UpcomingExpensesScreenState();
}

class _UpcomingExpensesScreenState extends State<_UpcomingExpensesScreen> {
  final _plans = FinancePlanService.instance;
  final _currency = CurrencyService.instance;

  bool get _dark => Theme.of(context).brightness == Brightness.dark;
  Color get _brand => Theme.of(context).colorScheme.primary;
  Color get _background =>
      _dark ? const Color(0xFF111522) : const Color(0xFFF7F8FD);
  Color get _card => _dark ? const Color(0xFF171D2B) : Colors.white;
  Color get _text => _dark ? const Color(0xFFF8FAFF) : const Color(0xFF101936);
  Color get _muted => _dark ? const Color(0xFFB8C0D9) : const Color(0xFF747D94);
  Color get _border =>
      _dark ? const Color(0xFF30364A) : const Color(0xFFE4E6EF);

  @override
  void initState() {
    super.initState();
    _plans.addListener(_refresh);
    _currency.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _plans.removeListener(_refresh);
    _currency.removeListener(_refresh);
    super.dispose();
  }

  String _amount(double value) {
    return _currency.formatAmount(value, decimal: value.abs() % 1 != 0);
  }

  String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  Future<void> _addExpense() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const UpcomingExpenseSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _plans.bills.where((bill) => !bill.paid).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final paid = _plans.bills.where((bill) => bill.paid).toList()
      ..sort((a, b) => b.dueDate.compareTo(a.dueDate));

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _text,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upcoming Expenses',
              style: TextStyle(
                color: _text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${upcoming.length} upcoming',
              style: TextStyle(color: _muted, fontSize: 10.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Add upcoming expense',
            onPressed: _addExpense,
            icon: Icon(Icons.add_circle_rounded, color: _brand, size: 28),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: upcoming.isEmpty && paid.isEmpty
          ? _emptyState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
              children: [
                if (upcoming.isNotEmpty) ...[
                  _sectionTitle('Upcoming', upcoming.length),
                  const SizedBox(height: 10),
                  for (final bill in upcoming)
                    _expenseCard(bill: bill, paid: false),
                ],
                if (paid.isNotEmpty) ...[
                  if (upcoming.isNotEmpty) const SizedBox(height: 22),
                  _sectionTitle('Paid', paid.length),
                  const SizedBox(height: 10),
                  for (final bill in paid) _expenseCard(bill: bill, paid: true),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExpense,
        backgroundColor: _brand,
        foregroundColor:
            ThemeData.estimateBrightnessForColor(_brand) == Brightness.dark
            ? Colors.white
            : const Color(0xFF111827),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Expense',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, int count) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: _text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: _brand.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: _brand,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _expenseCard({required dynamic bill, required bool paid}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 13, 6, 13),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: paid
                  ? const Color(0xFF16CFA5).withValues(alpha: .12)
                  : _brand.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              paid ? Icons.check_circle_rounded : Icons.receipt_long_rounded,
              color: paid ? const Color(0xFF16CFA5) : _brand,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    decoration: paid ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  paid
                      ? 'Paid • ${_date(bill.dueDate)}'
                      : 'Due ${_date(bill.dueDate)}',
                  style: TextStyle(color: _muted, fontSize: 10.5),
                ),
                const SizedBox(height: 5),
                Text(
                  _amount(bill.amount),
                  style: TextStyle(
                    color: paid
                        ? const Color(0xFF16CFA5)
                        : const Color(0xFFFF4D82),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Expense actions',
            icon: Icon(Icons.more_vert_rounded, color: _muted),
            onSelected: (action) async {
              if (action == 'paid') {
                await _plans.markPaid(bill.id);
              } else if (action == 'delete') {
                await _plans.deleteBill(bill.id);
              }
            },
            itemBuilder: (_) => [
              if (!paid)
                const PopupMenuItem<String>(
                  value: 'paid',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded),
                      SizedBox(width: 10),
                      Text('Mark Paid'),
                    ],
                  ),
                ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded),
                    SizedBox(width: 10),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: _brand.withValues(alpha: .10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                color: _brand,
                size: 46,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No upcoming expenses',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Add bills, subscriptions, rent or other future expenses and DHANVIQ will keep them organized here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 12.5, height: 1.45),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _addExpense,
              style: FilledButton.styleFrom(
                backgroundColor: _brand,
                foregroundColor:
                    ThemeData.estimateBrightnessForColor(_brand) ==
                        Brightness.dark
                    ? Colors.white
                    : const Color(0xFF111827),
                padding: const EdgeInsets.symmetric(
                  horizontal: 21,
                  vertical: 13,
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add Upcoming Expense',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: (color ?? _surface(context)).withValues(
          alpha: _isDark(context) ? .98 : .94,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _stroke(context).withValues(alpha: .88)),
        boxShadow: [
          BoxShadow(
            color: _isDark(context)
                ? _accent(context).withValues(alpha: .10)
                : _accent(context).withValues(alpha: .06),
            blurRadius: _isDark(context) ? 22 : 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({required this.onTap});
  final void Function(int index, String label) onTap;
  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, 'Home'),
      (Icons.swap_horiz_rounded, 'Transactions'),
      (Icons.add_rounded, ''),
      (Icons.bar_chart_rounded, 'Insights'),
      (Icons.settings_rounded, 'Settings'),
    ];
    return Container(
      height: 78 + MediaQuery.paddingOf(context).bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: _isDark(context) ? const Color(0xFF10182B) : _surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1F101936),
            blurRadius: 22,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          if (index == 2) {
            return Expanded(child: SizedBox());
          }
          final selected = index == 0;
          return Expanded(
            child: InkWell(
              onTap: () => onTap(index, items[index].$2),
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      items[index].$1,
                      color: selected ? _accent(context) : _subtle(context),
                      size: 24,
                    ),
                    SizedBox(height: 3),
                    Text(
                      items[index].$2,
                      style: TextStyle(
                        color: selected ? _accent(context) : _subtle(context),
                        fontSize: 9.5,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _HomeBackground extends StatelessWidget {
  const _HomeBackground();
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isDark(context)
                  ? const [
                      Color(0xFF121522),
                      Color(0xFF151827),
                      Color(0xFF101725),
                    ]
                  : const [
                      Color(0xFFFBFBFF),
                      Color(0xFFF7F9FF),
                      Color(0xFFF4FAFC),
                    ],
            ),
          ),
        ),
        Positioned(
          top: -145,
          left: -125,
          child: _blob(310, _accent(context), _isDark(context) ? .045 : .10),
        ),
        Positioned(
          top: 150,
          right: -190,
          child: _blob(
            410,
            const Color(0xFF22D3B6),
            _isDark(context) ? .017 : .07,
          ),
        ),
        Positioned(
          bottom: 120,
          left: -180,
          child: _blob(
            390,
            const Color(0xFF5A8DFF),
            _isDark(context) ? .025 : .06,
          ),
        ),
      ],
    );
  }

  static Widget _blob(double size, Color color, double opacity) {
    return Transform.rotate(
      angle: math.pi / 8,
      child: Container(
        width: size,
        height: size * .68,
        decoration: BoxDecoration(
          color: color.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(size * .35),
        ),
      ),
    );
  }
}

class _BalanceGraphPainter extends CustomPainter {
  const _BalanceGraphPainter({required this.accent});
  final Color accent;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [accent.withValues(alpha: .30), const Color(0xFF36D7D0)],
      ).createShader(Offset.zero & size);
    final heights = [28.0, 47.0, 62.0, 49.0, 78.0];
    for (var i = 0; i < heights.length; i++) {
      final rect = Rect.fromLTWH(
        i * 25.0 + 10,
        size.height - heights[i],
        13,
        heights[i],
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(7)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BalanceGraphPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.values, required this.colors});
  final List<double> values;
  final List<Color> colors;
  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (sum, v) => sum + v);
    if (total <= 0) {
      canvas.drawArc(
        (Offset.zero & size).deflate(15),
        0,
        math.pi * 2,
        false,
        Paint()
          ..color = const Color(0xFFECEEF6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 19,
      );
      return;
    }
    final rect = Offset.zero & size;
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = math.pi * 2 * values[i] / total;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 19
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect.deflate(15), start, sweep - .025, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class _BarChartPainter extends CustomPainter {
  const _BarChartPainter({required this.income, required this.expense});
  final List<double> income;
  final List<double> expense;
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE8EAF2)
      ..strokeWidth = 1;
    final maxAmount = [
      ...income,
      ...expense,
    ].fold<double>(0, (max, v) => v > max ? v : max);
    final labels = List.generate(
      4,
      (i) => (maxAmount * (3 - i) / 3).toStringAsFixed(0),
    );
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < 4; i++) {
      final y = 8 + i * ((size.height - 35) / 3);
      canvas.drawLine(Offset(34, y), Offset(size.width, y), gridPaint);
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(color: Color(0xFF8C94A8), fontSize: 8),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 5));
    }
    final maxValue = [
      ...income,
      ...expense,
    ].fold<double>(0, (max, v) => v > max ? v : max);
    final scale = maxValue <= 0 ? 1.0 : maxValue;
    final chartHeight = size.height - 38;
    final groupWidth = (size.width - 42) / 4;
    for (var i = 0; i < 4; i++) {
      final x = 43 + i * groupWidth;
      _bar(
        canvas,
        Rect.fromLTWH(
          x,
          8 + chartHeight * (1 - income[i] / scale),
          14,
          chartHeight * income[i] / scale,
        ),
        _HomeScreenState._mint,
      );
      _bar(
        canvas,
        Rect.fromLTWH(
          x + 18,
          8 + chartHeight * (1 - expense[i] / scale),
          14,
          chartHeight * expense[i] / scale,
        ),
        _HomeScreenState._pink,
      );
      textPainter.text = TextSpan(
        text: 'Week ${i + 1}',
        style: TextStyle(color: Color(0xFF8C94A8), fontSize: 8),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - 4, size.height - 17));
    }
  }

  void _bar(Canvas canvas, Rect rect, Color color) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()..color = color.withValues(alpha: .88),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class _HomeStickyHeader extends SliverPersistentHeaderDelegate {
  _HomeStickyHeader({required this.child});
  final Widget child;
  @override
  double get minExtent => 70;
  @override
  double get maxExtent => 70;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: _isDark(context) ? const Color(0xFF121522) : _page(context),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _HomeStickyHeader oldDelegate) => true;
}

class _PlaceholderBars extends StatelessWidget {
  const _PlaceholderBars({this.wide = false});
  final bool wide;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: wide ? double.infinity : 112,
      height: wide ? 95 : 88,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          wide ? 8 : 4,
          (i) => Container(
            width: wide ? 15 : 19,
            height: (wide ? 32.0 : 25.0) + (i % 4) * 14,
            decoration: BoxDecoration(
              color: _tint(context),
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ),
        ),
      ),
    );
  }
}

class _GrowingPlant extends StatelessWidget {
  const _GrowingPlant();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 100,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 15,
            child: Container(
              width: 7,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF62D9AA),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          Positioned(
            bottom: 42,
            left: 24,
            child: Transform.rotate(
              angle: -.65,
              child: Container(
                width: 35,
                height: 19,
                decoration: BoxDecoration(
                  color: Color(0xFF55DDA6),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(35),
                    bottomRight: Radius.circular(35),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 48,
            right: 22,
            child: Transform.rotate(
              angle: .65,
              child: Container(
                width: 35,
                height: 19,
                decoration: BoxDecoration(
                  color: Color(0xFF77EDBC),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(35),
                    bottomLeft: Radius.circular(35),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              width: 43,
              height: 32,
              decoration: BoxDecoration(
                color: _accent(context).withValues(alpha: .70),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12),
                  top: Radius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Local notification inbox. Notification preferences remain in Settings.
// No sample notifications are shown as if they were real user activity.
