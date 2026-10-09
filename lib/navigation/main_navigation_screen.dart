import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import '../home/home_screen.dart';

import '../goals/goals_screen.dart';

import '../budget/set_monthly_budget_screen.dart';

import '../settings/settings_screen.dart';

import '../insights/insights_screen.dart';

import '../transactions/transactions_screen.dart';

import '../models/transaction_model.dart';

import '../services/transaction_service.dart';

import '../services/finance_plan_service.dart';

import '../services/currency_service.dart';

class _NavTheme {
  static bool dark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  static Color surface(BuildContext context) =>
      dark(context) ? const Color(0xFF141D32) : Colors.white;

  static Color ink(BuildContext context) =>
      dark(context) ? Colors.white : const Color(0xFF101936);

  static Color muted(BuildContext context) =>
      dark(context) ? const Color(0xFFADB7CD) : const Color(0xFF747D94);

  static Color border(BuildContext context) =>
      dark(context) ? const Color(0xFF303B53) : const Color(0xFFE7EAF3);

  static Color accent(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  static Color accentTint(BuildContext context) => Color.alphaBlend(
    accent(context).withValues(alpha: dark(context) ? 0.22 : 0.10),

    surface(context),
  );

  static Color onAccent(BuildContext context) =>
      ThemeData.estimateBrightnessForColor(accent(context)) == Brightness.light
      ? const Color(0xFF182033)
      : Colors.white;

  static Color accentInk(BuildContext context) {
    final color = accent(context);

    if (dark(context) ||
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark) {
      return color;
    }

    return Color.lerp(color, Colors.black, 0.32)!;
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      HomeScreen(showNavigation: false, onNavigationTap: _onHomeNavigationTap),

      TransactionsScreen(onAdd: _openCreateScreen),

      const SizedBox.shrink(),

      const InsightsScreen(),

      const SettingsScreen(),
    ];
  }

  void _onHomeNavigationTap(int index) => _selectTab(index);

  void _selectTab(int index) {
    if (index == 2) {
      _openCreateScreen();

      return;
    }

    if (index < 0 || index >= _pages.length) return;
    if (index == _selectedIndex) return;

    setState(() => _selectedIndex = index);
  }

  Future<void> _openCreateScreen() async {
    await showModalBottomSheet<void>(
      context: context,

      isScrollControlled: true,

      useSafeArea: false,

      backgroundColor: Colors.transparent,

      barrierColor: Colors.black.withValues(alpha: 0.42),

      builder: (_) => const _CreateNewScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = _NavTheme.dark(context);

    final surface = _NavTheme.surface(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,

        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,

        statusBarBrightness: dark ? Brightness.dark : Brightness.light,

        systemNavigationBarColor: surface,

        systemNavigationBarIconBrightness: dark
            ? Brightness.light
            : Brightness.dark,

        systemNavigationBarDividerColor: surface,
      ),

      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;

          if (_selectedIndex != 0) {
            setState(() => _selectedIndex = 0);
            return;
          }

          SystemNavigator.pop();
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          extendBody: true,
          backgroundColor: _NavTheme.background(context),
          body: IndexedStack(index: _selectedIndex, children: _pages),
          bottomNavigationBar: _MainBottomNavigation(
            selectedIndex: _selectedIndex,
            onTap: _selectTab,
          ),
        ),
      ),
    );
  }
}

class _MainBottomNavigation extends StatelessWidget {
  const _MainBottomNavigation({
    required this.selectedIndex,

    required this.onTap,
  });

  final int selectedIndex;

  final ValueChanged<int> onTap;

  static const _items = <(IconData, String)>[
    (Icons.home_rounded, 'Home'),

    (Icons.swap_horiz_rounded, 'Transactions'),

    (Icons.add_rounded, ''),

    (Icons.bar_chart_rounded, 'Insights'),

    (Icons.settings_outlined, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final dark = _NavTheme.dark(context);

    final activeBackground = _NavTheme.accentTint(context);

    final activeColor = _NavTheme.accentInk(context);

    final inactiveColor = _NavTheme.muted(context);

    return Container(
      height: 76 + bottomInset,

      padding: EdgeInsets.fromLTRB(8, 5, 8, bottomInset + 5),

      decoration: BoxDecoration(
        color: _NavTheme.surface(context),

        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),

        border: Border(top: BorderSide(color: _NavTheme.border(context))),

        boxShadow: [
          BoxShadow(
            color: dark ? const Color(0x66000000) : const Color(0x1A101936),

            blurRadius: 22,

            offset: const Offset(0, -5),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: List.generate(_items.length, (index) {
          if (index == 2) {
            return Expanded(
              child: Center(child: _AddButton(onTap: () => onTap(2))),
            );
          }

          final selected = selectedIndex == index;

          return Expanded(
            child: Material(
              color: Colors.transparent,

              child: InkWell(
                onTap: () => onTap(index),

                borderRadius: BorderRadius.circular(16),

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),

                      curve: Curves.easeOutCubic,

                      width: 58,

                      height: 34,

                      alignment: Alignment.center,

                      decoration: BoxDecoration(
                        color: selected ? activeBackground : Colors.transparent,

                        borderRadius: BorderRadius.circular(17),
                      ),

                      child: Icon(
                        selected ? _selectedIcon(index) : _items[index].$1,

                        color: selected ? activeColor : inactiveColor,

                        size: 22,
                      ),
                    ),

                    const SizedBox(height: 3),

                    FittedBox(
                      fit: BoxFit.scaleDown,

                      child: Text(
                        _items[index].$2,

                        maxLines: 1,

                        style: TextStyle(
                          color: selected ? activeColor : inactiveColor,

                          fontSize: 9.5,

                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
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

  IconData _selectedIcon(int index) => switch (index) {
    0 => Icons.home_rounded,

    1 => Icons.swap_horiz_rounded,

    3 => Icons.bar_chart_rounded,

    4 => Icons.settings_rounded,

    _ => Icons.circle,
  };
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,

      height: 50,

      decoration: BoxDecoration(
        shape: BoxShape.circle,

        gradient: LinearGradient(
          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

          colors: [
            Color.lerp(_NavTheme.accent(context), Colors.white, 0.12)!,

            Color.lerp(_NavTheme.accent(context), Colors.black, 0.12)!,
          ],
        ),

        boxShadow: [
          BoxShadow(
            color: _NavTheme.accent(context).withValues(alpha: 0.32),

            blurRadius: 14,

            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          onTap: onTap,

          customBorder: const CircleBorder(),

          child: Icon(
            Icons.add_rounded,

            color: _NavTheme.onAccent(context),

            size: 28,
          ),
        ),
      ),
    );
  }
}

/// Center + button opens this page.

/// All create actions stay in one place.

class _CreateNewScreen extends StatelessWidget {
  const _CreateNewScreen();

  Future<void> _open(BuildContext context, Widget screen) async {
    final navigator = Navigator.of(context);

    navigator.pop();

    await Future<void>.delayed(const Duration(milliseconds: 100));

    if (!navigator.mounted) return;

    await navigator.push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  Future<void> _openUpcomingExpense(BuildContext context) async {
    final navigator = Navigator.of(context);

    navigator.pop();

    await Future<void>.delayed(const Duration(milliseconds: 100));

    if (!navigator.mounted) return;

    await showModalBottomSheet<void>(
      context: navigator.context,

      isScrollControlled: true,

      useSafeArea: true,

      backgroundColor: Colors.transparent,

      builder: (_) => const UpcomingExpenseSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = _NavTheme.dark(context);

    final sheet = dark ? const Color(0xFF10182B) : const Color(0xFFF8FAFF);

    final outline = dark ? const Color(0xFF2B3857) : const Color(0xFFE1E7F2);

    final incomeAccent = dark
        ? const Color(0xFF1ED7B1)
        : const Color(0xFF05B987);

    final expenseAccent = dark
        ? const Color(0xFFFF4F86)
        : const Color(0xFFF64270);

    final goalAccent = dark ? const Color(0xFF4C90FF) : const Color(0xFF286EF0);

    final budgetAccent = dark
        ? const Color(0xFFFFB654)
        : const Color(0xFFF39A1A);

    final upcomingAccent = dark
        ? const Color(0xFF71AAFF)
        : const Color(0xFF4D8EF7);

    final size = MediaQuery.sizeOf(context);

    final sheetHeight = (size.height * .72).clamp(590.0, 720.0);

    final horizontalPadding = 18.0;

    final gap = 12.0;

    final cardWidth = (size.width - (horizontalPadding * 2) - gap) / 2;

    final cardHeight = cardWidth * 1.02;

    final bottomCardHeight = (cardWidth * .58).clamp(96.0, 124.0);

    return SizedBox(
      height: sheetHeight,

      child: Container(
        decoration: BoxDecoration(
          color: sheet,

          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),

          border: Border(
            top: BorderSide(color: outline.withValues(alpha: .85)),
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? .32 : .14),

              blurRadius: 28,

              offset: const Offset(0, -6),
            ),
          ],
        ),

        child: SafeArea(
          top: false,

          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,

              11,

              horizontalPadding,

              16,
            ),

            child: Column(
              children: [
                Container(
                  width: 104,

                  height: 6,

                  decoration: BoxDecoration(
                    color: dark
                        ? const Color(0xFF7D88AA)
                        : const Color(0xFFC3CBDB),

                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 7),

                SizedBox(
                  height: 44,

                  child: Align(
                    alignment: Alignment.centerRight,

                    child: Container(
                      width: 44,

                      height: 44,

                      decoration: BoxDecoration(
                        color: dark
                            ? const Color(0xFF1B2742)
                            : const Color(0xFFE9EEF8),

                        shape: BoxShape.circle,

                        border: Border.all(
                          color: outline.withValues(alpha: .75),
                        ),
                      ),

                      child: IconButton(
                        tooltip: 'Close',

                        padding: EdgeInsets.zero,

                        onPressed: () => Navigator.of(context).pop(),

                        icon: Icon(
                          Icons.close_rounded,

                          size: 27,

                          color: _NavTheme.ink(context),
                        ),
                      ),
                    ),
                  ),
                ),

                Transform.translate(
                  offset: const Offset(0, -10),

                  child: Column(
                    children: [
                      Text(
                        'Create New',

                        textAlign: TextAlign.center,

                        style: TextStyle(
                          color: _NavTheme.ink(context),

                          fontSize: 27,

                          fontWeight: FontWeight.w900,

                          letterSpacing: -.4,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'What would you like to add?',

                        textAlign: TextAlign.center,

                        style: TextStyle(
                          color: _NavTheme.muted(context),

                          fontSize: 14.5,

                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                SizedBox(
                  height: cardHeight,

                  child: Row(
                    children: [
                      Expanded(
                        child: _CreateGridCard(
                          title: 'Add Income',

                          subtitle: 'Record money you\nreceived',

                          icon: Icons.account_balance_wallet_rounded,

                          accent: incomeAccent,

                          background: dark
                              ? const Color(0xFF0E312F)
                              : const Color(0xFFE5FAF4),

                          border: dark
                              ? const Color(0xFF0A6D61)
                              : const Color(0xFF97E1CC),

                          onTap: () => _open(
                            context,

                            const AddTransactionForm(isIncome: true),
                          ),
                        ),
                      ),

                      SizedBox(width: gap),

                      Expanded(
                        child: _CreateGridCard(
                          title: 'Add Expense',

                          subtitle: 'Track your\nspending',

                          icon: Icons.remove_rounded,

                          accent: expenseAccent,

                          background: dark
                              ? const Color(0xFF321A2A)
                              : const Color(0xFFFFECF2),

                          border: dark
                              ? const Color(0xFF71304C)
                              : const Color(0xFFF3A5BE),

                          onTap: () => _open(
                            context,

                            const AddTransactionForm(isIncome: false),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  height: cardHeight,

                  child: Row(
                    children: [
                      Expanded(
                        child: _CreateGridCard(
                          title: 'Add Goal',

                          subtitle: 'Save for your\ndreams',

                          icon: Icons.track_changes_rounded,

                          accent: goalAccent,

                          background: dark
                              ? const Color(0xFF12264A)
                              : const Color(0xFFEAF2FF),

                          border: dark
                              ? const Color(0xFF2455A2)
                              : const Color(0xFFAFCBFF),

                          onTap: () => _open(context, const GoalFormScreen()),
                        ),
                      ),

                      SizedBox(width: gap),

                      Expanded(
                        child: _CreateGridCard(
                          title: 'Set Budget',

                          subtitle: 'Manage your\nmonthly limit',

                          icon: Icons.bar_chart_rounded,

                          accent: budgetAccent,

                          background: dark
                              ? const Color(0xFF332718)
                              : const Color(0xFFFFF4E6),

                          border: dark
                              ? const Color(0xFF72501D)
                              : const Color(0xFFF3CE95),

                          onTap: () =>
                              _open(context, const SetMonthlyBudgetScreen()),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  height: bottomCardHeight,

                  child: _UpcomingCreateCard(
                    accent: upcomingAccent,

                    background: dark
                        ? const Color(0xFF14264A)
                        : const Color(0xFFEAF2FF),

                    border: dark
                        ? const Color(0xFF2858A4)
                        : const Color(0xFFAFCBFF),

                    onTap: () => _openUpcomingExpense(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateGridCard extends StatelessWidget {
  const _CreateGridCard({
    required this.title,

    required this.subtitle,

    required this.icon,

    required this.accent,

    required this.background,

    required this.border,

    required this.onTap,
  });

  final String title;

  final String subtitle;

  final IconData icon;

  final Color accent;

  final Color background;

  final Color border;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = _NavTheme.dark(context);

    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(22),

        child: Ink(
          padding: const EdgeInsets.fromLTRB(17, 16, 14, 15),

          decoration: BoxDecoration(
            color: background,

            borderRadius: BorderRadius.circular(22),

            border: Border.all(
              color: border.withValues(alpha: dark ? .78 : .95),

              width: 1.15,
            ),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Container(
                width: 56,

                height: 56,

                alignment: Alignment.center,

                decoration: BoxDecoration(
                  color: accent,

                  shape: BoxShape.circle,
                ),

                child: Icon(
                  icon,

                  color:
                      ThemeData.estimateBrightnessForColor(accent) ==
                          Brightness.light
                      ? const Color(0xFF152036)
                      : Colors.white,

                  size: 28,
                ),
              ),

              const Spacer(),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,

                      maxLines: 1,

                      softWrap: false,

                      overflow: TextOverflow.fade,

                      style: TextStyle(
                        color: _NavTheme.ink(context),

                        fontSize: 16,

                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),

                  const SizedBox(width: 4),

                  Icon(
                    Icons.chevron_right_rounded,

                    color: _NavTheme.muted(context),

                    size: 24,
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Text(
                subtitle,

                maxLines: 2,

                style: TextStyle(
                  color: _NavTheme.muted(context),

                  fontSize: 11.8,

                  height: 1.30,

                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingCreateCard extends StatelessWidget {
  const _UpcomingCreateCard({
    required this.accent,

    required this.background,

    required this.border,

    required this.onTap,
  });

  final Color accent;

  final Color background;

  final Color border;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = _NavTheme.dark(context);

    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(22),

        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),

          decoration: BoxDecoration(
            color: background,

            borderRadius: BorderRadius.circular(22),

            border: Border.all(
              color: border.withValues(alpha: dark ? .78 : .95),

              width: 1.15,
            ),
          ),

          child: Row(
            children: [
              Container(
                width: 56,

                height: 56,

                alignment: Alignment.center,

                decoration: BoxDecoration(
                  color: accent,

                  shape: BoxShape.circle,
                ),

                child: Icon(
                  Icons.calendar_month_rounded,

                  color:
                      ThemeData.estimateBrightnessForColor(accent) ==
                          Brightness.light
                      ? const Color(0xFF152036)
                      : Colors.white,

                  size: 27,
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Add Upcoming Expense',

                      maxLines: 1,

                      softWrap: false,

                      overflow: TextOverflow.fade,

                      style: TextStyle(
                        color: _NavTheme.ink(context),

                        fontSize: 15.5,

                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'Schedule a bill or future payment',

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: TextStyle(
                        color: _NavTheme.muted(context),

                        fontSize: 11.5,

                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              Icon(
                Icons.chevron_right_rounded,

                color: _NavTheme.muted(context),

                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Used from the center + menu to schedule a future expense.

/// Saves into the same FinancePlanService.bills list used by Home.

class UpcomingExpenseSheet extends StatefulWidget {
  const UpcomingExpenseSheet({super.key});

  @override
  State<UpcomingExpenseSheet> createState() => _UpcomingExpenseSheetState();
}

class _UpcomingExpenseSheetState extends State<UpcomingExpenseSheet> {
  final _titleController = TextEditingController();

  final _amountController = TextEditingController();

  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));

  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();

    _amountController.dispose();

    super.dispose();
  }

  Future<void> _chooseDate() async {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,

      firstDate: today,

      lastDate: DateTime(2040),

      initialDate: _dueDate.isBefore(today) ? today : _dueDate,
    );

    if (!mounted || picked == null) return;

    setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (_saving) return;

    final title = _titleController.text.trim();

    final rawAmount = _amountController.text
        .trim()
        .replaceAll(',', '')
        .replaceAll('₹', '')
        .replaceAll(r'$', '')
        .replaceAll('€', '')
        .replaceAll('£', '');

    final amount = double.tryParse(rawAmount);

    if (title.isEmpty || amount == null || !amount.isFinite || amount <= 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Enter a title and valid amount.')),
        );

      return;
    }

    setState(() => _saving = true);

    try {
      await FinancePlanService.instance.addBill(title, amount, _dueDate);

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(Navigator.of(context).context);
    } catch (error) {
      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Could not save upcoming expense: $error')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = _NavTheme.dark(context);

    final accent = _NavTheme.accent(context);

    final sheetColor = dark ? const Color(0xFF141D32) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: sheetColor,

        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),

      child: SafeArea(
        top: false,

        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,

            12,

            20,

            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),

          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Center(
                  child: Container(
                    width: 42,

                    height: 4,

                    decoration: BoxDecoration(
                      color: _NavTheme.border(context),

                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Container(
                      width: 44,

                      height: 44,

                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: dark ? .20 : .10),

                        borderRadius: BorderRadius.circular(13),
                      ),

                      child: Icon(Icons.calendar_month_rounded, color: accent),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            'Add Upcoming Expense',

                            style: TextStyle(
                              color: _NavTheme.ink(context),

                              fontSize: 19,

                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 2),

                          Text(
                            'Schedule a bill or future payment',

                            style: TextStyle(
                              color: _NavTheme.muted(context),

                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      tooltip: 'Close',

                      onPressed: _saving ? null : () => Navigator.pop(context),

                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                _fieldLabel(context, 'Expense Title'),

                const SizedBox(height: 7),

                TextField(
                  controller: _titleController,

                  enabled: !_saving,

                  textInputAction: TextInputAction.next,

                  decoration: _sheetInputDecoration(
                    context,

                    hint: 'Rent, Netflix, Electricity...',

                    icon: Icons.receipt_long_rounded,
                  ),
                ),

                const SizedBox(height: 18),

                _fieldLabel(context, 'Amount'),

                const SizedBox(height: 7),

                TextField(
                  controller: _amountController,

                  enabled: !_saving,

                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),

                  decoration: _sheetInputDecoration(
                    context,

                    hint: '${CurrencyService.instance.symbol}0',

                    icon: Icons.payments_outlined,
                  ),
                ),

                const SizedBox(height: 18),

                _fieldLabel(context, 'Due Date'),

                const SizedBox(height: 7),

                Material(
                  color: _NavTheme.surface(context),

                  borderRadius: BorderRadius.circular(14),

                  child: InkWell(
                    onTap: _saving ? null : _chooseDate,

                    borderRadius: BorderRadius.circular(14),

                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,

                        vertical: 15,
                      ),

                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),

                        border: Border.all(color: _NavTheme.border(context)),
                      ),

                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,

                            color: accent,

                            size: 21,
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              '${_dueDate.day.toString().padLeft(2, '0')}/'
                              '${_dueDate.month.toString().padLeft(2, '0')}/'
                              '${_dueDate.year}',

                              style: TextStyle(
                                color: _NavTheme.ink(context),

                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                          Icon(
                            Icons.chevron_right_rounded,

                            color: _NavTheme.muted(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,

                  height: 52,

                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,

                    style: FilledButton.styleFrom(
                      backgroundColor: accent,

                      foregroundColor: _NavTheme.onAccent(context),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),

                    icon: _saving
                        ? const SizedBox(
                            width: 19,

                            height: 19,

                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,

                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_circle_outline_rounded),

                    label: Text(
                      _saving ? 'Saving...' : 'Save Upcoming Expense',

                      style: const TextStyle(fontWeight: FontWeight.w800),
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

  Widget _fieldLabel(BuildContext context, String label) {
    return Text(
      label,

      style: TextStyle(
        color: _NavTheme.ink(context),

        fontSize: 13,

        fontWeight: FontWeight.w800,
      ),
    );
  }

  InputDecoration _sheetInputDecoration(
    BuildContext context, {

    required String hint,

    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,

      prefixIcon: Icon(icon, color: _NavTheme.muted(context)),

      filled: true,

      fillColor: _NavTheme.surface(context),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),

        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),

        borderSide: BorderSide(color: _NavTheme.border(context)),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),

        borderSide: BorderSide(color: _NavTheme.accent(context), width: 1.5),
      ),
    );
  }
}

const Map<String, IconData> _incomeCategoryIcons = {
  'Salary': Icons.work_rounded,

  'Freelance': Icons.laptop_mac_rounded,

  'Business': Icons.business_rounded,

  'Bonus': Icons.card_giftcard_rounded,

  'Investments': Icons.trending_up_rounded,

  'Interest': Icons.savings_rounded,

  'Rental': Icons.home_work_rounded,

  'Refund': Icons.replay_rounded,

  'Gift': Icons.redeem_rounded,

  'Other': Icons.more_horiz_rounded,
};

const Map<String, IconData> _expenseCategoryIcons = {
  'Food': Icons.restaurant_rounded,

  'Groceries': Icons.shopping_cart_rounded,

  'Transport': Icons.directions_car_rounded,

  'Shopping': Icons.shopping_bag_rounded,

  'Bills': Icons.receipt_long_rounded,

  'Rent': Icons.home_rounded,

  'Health': Icons.favorite_rounded,

  'Education': Icons.school_rounded,

  'Entertainment': Icons.movie_rounded,

  'Travel': Icons.flight_rounded,

  'Fuel': Icons.local_gas_station_rounded,

  'EMI / Loan': Icons.account_balance_rounded,

  'Personal Care': Icons.spa_rounded,

  'Subscriptions': Icons.autorenew_rounded,

  'Family': Icons.family_restroom_rounded,

  'Insurance': Icons.verified_user_rounded,

  'Other': Icons.more_horiz_rounded,
};

IconData _transactionCategoryIcon(String category, {required bool isIncome}) {
  final source = isIncome ? _incomeCategoryIcons : _expenseCategoryIcons;

  return source[category] ??
      (isIncome ? Icons.payments_rounded : Icons.category_rounded);
}

List<String> _transactionCategoryNames({required bool isIncome}) {
  return (isIncome ? _incomeCategoryIcons : _expenseCategoryIcons).keys.toList(
    growable: false,
  );
}

class AddTransactionForm extends StatefulWidget {
  const AddTransactionForm({super.key, required this.isIncome, this.existing});

  final TransactionModel? existing;

  final bool isIncome;

  @override
  State<AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<AddTransactionForm> {
  late bool isIncome = widget.existing?.isIncome ?? widget.isIncome;

  final amountController = TextEditingController();

  final noteController = TextEditingController();

  late String category =
      widget.existing?.category ?? (widget.isIncome ? 'Salary' : 'Food');

  String paymentMethod = 'Cash';

  DateTime selectedDate = DateTime.now();

  bool isSaving = false;

  String get date =>
      '${selectedDate.day} ${_month(selectedDate.month)} ${selectedDate.year}';

  @override
  void initState() {
    super.initState();

    final item = widget.existing;

    if (item != null) {
      amountController.text = item.amount.toStringAsFixed(
        item.amount % 1 == 0 ? 0 : 2,
      );

      noteController.text = item.note;

      paymentMethod = item.paymentMethod;

      selectedDate = item.date;
    }
  }

  @override
  void dispose() {
    amountController.dispose();

    noteController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = isIncome ? const Color(0xFF16B981) : const Color(0xFFFF3D6E);

    return Scaffold(
      backgroundColor: _NavTheme.background(context),

      appBar: AppBar(
        backgroundColor: _NavTheme.background(context),

        foregroundColor: _NavTheme.ink(context),

        elevation: 0,

        title: Text(
          widget.existing != null
              ? 'Edit Transaction'
              : (isIncome ? 'Add Income' : 'Add Expense'),

          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),

        centerTitle: true,
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),

          children: [
            _typeSwitch(),

            const SizedBox(height: 25),

            _fieldLabel('Amount'),

            const SizedBox(height: 7),

            TextField(
              controller: amountController,

              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),

              style: TextStyle(
                fontSize: 28,

                fontWeight: FontWeight.w800,

                color: _NavTheme.ink(context),
              ),

              decoration: _inputDecoration(
                '${CurrencyService.instance.symbol}0',

                Icons.calculate_outlined,
              ),
            ),

            const SizedBox(height: 22),

            _fieldLabel('Category'),

            const SizedBox(height: 7),

            _selectTile(
              icon: _transactionCategoryIcon(category, isIncome: isIncome),

              color: isIncome
                  ? const Color(0xFF16B981)
                  : const Color(0xFFFF3D6E),

              title: category,

              onTap: _chooseCategory,
            ),

            const SizedBox(height: 18),

            _fieldLabel('Date'),

            const SizedBox(height: 7),

            _selectTile(
              icon: Icons.calendar_month_outlined,

              color: _NavTheme.ink(context),

              title: date,

              onTap: _chooseDate,
            ),

            const SizedBox(height: 18),

            _fieldLabel('Payment Method'),

            const SizedBox(height: 7),

            _selectTile(
              icon: Icons.account_balance_wallet_outlined,

              color: _NavTheme.ink(context),

              title: paymentMethod,

              onTap: _choosePayment,
            ),

            const SizedBox(height: 18),

            _fieldLabel('Note (Optional)'),

            const SizedBox(height: 7),

            TextField(
              controller: noteController,

              decoration: _inputDecoration(
                'Add a note...',

                Icons.note_alt_outlined,
              ).copyWith(suffixIcon: null),
            ),

            const SizedBox(height: 28),

            FilledButton(
              onPressed: isSaving ? null : _save,

              style: FilledButton.styleFrom(
                backgroundColor: accent,

                minimumSize: const Size.fromHeight(54),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),

              child: isSaving
                  ? const SizedBox(
                      width: 22,

                      height: 22,

                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,

                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.existing != null
                          ? 'Save Changes'
                          : (isIncome ? 'Save Income' : 'Save Expense'),

                      style: const TextStyle(
                        fontSize: 15,

                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),

      decoration: BoxDecoration(
        color: _NavTheme.dark(context)
            ? const Color(0xFF222D45)
            : const Color(0xFFECEFF8),

        borderRadius: BorderRadius.circular(12),
      ),

      child: Row(
        children: [
          Expanded(child: _typeButton(false, 'Expense')),

          Expanded(child: _typeButton(true, 'Income')),
        ],
      ),
    );
  }

  Widget _typeButton(bool income, String label) {
    final selected = income == isIncome;

    return GestureDetector(
      onTap: () {
        setState(() {
          isIncome = income;

          category = income ? 'Salary' : 'Food';
        });
      },

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),

        padding: const EdgeInsets.symmetric(vertical: 12),

        decoration: BoxDecoration(
          color: selected
              ? (income ? const Color(0xFF16B981) : const Color(0xFFFF3D6E))
              : Colors.transparent,

          borderRadius: BorderRadius.circular(9),
        ),

        child: Text(
          label,

          textAlign: TextAlign.center,

          style: TextStyle(
            color: selected ? Colors.white : _NavTheme.muted(context),

            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,

      style: TextStyle(
        color: _NavTheme.ink(context),

        fontSize: 13,

        fontWeight: FontWeight.w800,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,

      prefixIcon: Icon(icon, color: _NavTheme.ink(context)),

      filled: true,

      fillColor: _NavTheme.surface(context),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),

        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),

        borderSide: BorderSide(color: _NavTheme.border(context)),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),

        borderSide: BorderSide(color: _NavTheme.accent(context), width: 1.5),
      ),
    );
  }

  Widget _selectTile({
    required IconData icon,

    required Color color,

    required String title,

    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,

      borderRadius: BorderRadius.circular(14),

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),

        decoration: BoxDecoration(
          color: _NavTheme.surface(context),

          borderRadius: BorderRadius.circular(14),

          border: Border.all(color: _NavTheme.border(context)),
        ),

        child: Row(
          children: [
            Icon(icon, color: color, size: 22),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                title,

                style: TextStyle(
                  color: _NavTheme.ink(context),

                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            Icon(Icons.chevron_right_rounded, color: _NavTheme.muted(context)),
          ],
        ),
      ),
    );
  }

  void _chooseCategory() {
    final options = _transactionCategoryNames(isIncome: isIncome);

    showModalBottomSheet<void>(
      context: context,

      builder: (_) => _ChoiceSheet(
        title: 'Select Category',

        options: options,

        icons: isIncome ? _incomeCategoryIcons : _expenseCategoryIcons,

        selected: category,

        onSelected: (value) {
          setState(() => category = value);
        },
      ),
    );
  }

  Future<void> _chooseDate() async {
    final pickedDate = await showDatePicker(
      context: context,

      firstDate: DateTime(2020),

      lastDate: DateTime(2100),

      initialDate: selectedDate,
    );

    if (!mounted || pickedDate == null) return;

    setState(() => selectedDate = pickedDate);
  }

  void _choosePayment() {
    showModalBottomSheet<void>(
      context: context,

      builder: (_) => _ChoiceSheet(
        title: 'Payment Method',

        options: const [
          'Cash',

          'UPI (PhonePe)',

          'UPI (Google Pay)',

          'UPI (Paytm)',

          'Debit Card',

          'Credit Card',

          'Net Banking',

          'Wallet',

          'Other',
        ],

        selected: paymentMethod,

        onSelected: (value) {
          setState(() => paymentMethod = value);
        },
      ),
    );
  }

  String _month(int month) => const [
    'Jan',

    'Feb',

    'Mar',

    'Apr',

    'May',

    'Jun',

    'Jul',

    'Aug',

    'Sep',

    'Oct',

    'Nov',

    'Dec',
  ][month - 1];

  Future<void> _save() async {
    if (isSaving) return;

    final amountText = amountController.text
        .trim()
        .replaceAll(',', '')
        .replaceAll('₹', '')
        .replaceAll(r'$', '')
        .replaceAll('€', '')
        .replaceAll('£', '');

    final amount = double.tryParse(amountText);

    if (amount == null || !amount.isFinite || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount greater than zero.'),
        ),
      );

      return;
    }

    setState(() => isSaving = true);

    try {
      final transaction = widget.existing != null
          ? widget.existing!.copyWith(
              title: noteController.text.trim().isEmpty
                  ? category
                  : noteController.text.trim(),

              amount: amount,

              type: isIncome ? TransactionType.income : TransactionType.expense,

              category: category,

              date: selectedDate,

              paymentMethod: paymentMethod,

              note: noteController.text.trim(),
            )
          : await TransactionService.instance.addTransaction(
              title: noteController.text.trim().isEmpty
                  ? category
                  : noteController.text.trim(),

              amount: amount,

              type: isIncome ? TransactionType.income : TransactionType.expense,

              category: category,

              date: selectedDate,

              paymentMethod: paymentMethod,

              note: noteController.text.trim(),
            );

      if (widget.existing != null) {
        final updated = await TransactionService.instance.updateTransaction(
          transaction,
        );

        if (!mounted) return;

        if (!updated) {
          throw StateError('Transaction no longer exists');
        }

        Navigator.of(context).pop();

        return;
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => TransactionSuccessScreen(
            isIncome: isIncome,

            amount: amount.toStringAsFixed(
              amount == amount.roundToDouble() ? 0 : 2,
            ),

            category: category,

            accent: isIncome
                ? const Color(0xFF16B981)
                : const Color(0xFFFF3D6E),

            transactionDate: transaction.date,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction could not be saved. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }
}

class _ChoiceSheet extends StatelessWidget {
  const _ChoiceSheet({
    required this.title,

    required this.options,

    this.icons,

    required this.selected,

    required this.onSelected,
  });

  final String title;

  final List<String> options;

  final Map<String, IconData>? icons;

  final String selected;

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,

        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),

        children: [
          Text(
            title,

            style: TextStyle(
              color: _NavTheme.ink(context),

              fontSize: 18,

              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 12),

          ...options.map(
            (item) => ListTile(
              leading: icons == null
                  ? null
                  : Container(
                      width: 40,

                      height: 40,

                      alignment: Alignment.center,

                      decoration: BoxDecoration(
                        color: _NavTheme.accentTint(context),

                        borderRadius: BorderRadius.circular(12),
                      ),

                      child: Icon(
                        icons![item] ?? Icons.category_rounded,

                        color: _NavTheme.accentInk(context),

                        size: 21,
                      ),
                    ),

              title: Text(
                item,

                style: TextStyle(
                  color: _NavTheme.ink(context),

                  fontWeight: item == selected
                      ? FontWeight.w800
                      : FontWeight.w600,
                ),
              ),

              trailing: item == selected
                  ? Icon(
                      Icons.check_circle_rounded,

                      color: _NavTheme.accentInk(context),
                    )
                  : null,

              onTap: () {
                onSelected(item);

                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionSuccessScreen extends StatelessWidget {
  const TransactionSuccessScreen({
    super.key,

    required this.isIncome,

    required this.amount,

    required this.category,

    required this.accent,

    required this.transactionDate,
  });

  final bool isIncome;

  final String amount;

  final String category;

  final Color accent;

  final DateTime transactionDate;

  @override
  Widget build(BuildContext context) {
    final numericAmount = double.tryParse(amount) ?? 0;

    final formattedAmount = CurrencyService.instance.formatAmount(
      numericAmount,

      decimal: numericAmount % 1 != 0,
    );

    return Scaffold(
      backgroundColor: _NavTheme.background(context),

      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(22),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                Container(
                  width: 142,

                  height: 142,

                  decoration: BoxDecoration(
                    shape: BoxShape.circle,

                    color: accent.withAlpha(28),
                  ),

                  child: Center(
                    child: Container(
                      width: 88,

                      height: 88,

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,

                        color: accent,
                      ),

                      child: const Icon(
                        Icons.check_rounded,

                        color: Colors.white,

                        size: 52,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                Text(
                  'Transaction Added!',

                  style: TextStyle(
                    color: _NavTheme.ink(context),

                    fontSize: 24,

                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Your ${isIncome ? 'income' : 'expense'} of $formattedAmount has been added successfully.',

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    color: _NavTheme.muted(context),

                    fontSize: 14,

                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 26),

                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(15),

                  decoration: BoxDecoration(
                    color: _NavTheme.surface(context),

                    borderRadius: BorderRadius.circular(16),

                    border: Border.all(color: _NavTheme.border(context)),
                  ),

                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: accent.withAlpha(28),

                        child: Icon(
                          _transactionCategoryIcon(
                            category,

                            isIncome: isIncome,
                          ),

                          color: accent,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              category,

                              style: TextStyle(
                                color: _NavTheme.ink(context),

                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              '${transactionDate.day}/${transactionDate.month}/${transactionDate.year}',

                              style: TextStyle(
                                color: _NavTheme.muted(context),

                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Text(
                        '${isIncome ? '+' : '-'} $formattedAmount',

                        style: TextStyle(
                          color: accent,

                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                FilledButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },

                  style: FilledButton.styleFrom(
                    backgroundColor: _NavTheme.accent(context),

                    foregroundColor: _NavTheme.onAccent(context),

                    minimumSize: const Size.fromHeight(52),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  child: const Text(
                    'Back to Home',

                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),

                const SizedBox(height: 10),

                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => AddTransactionForm(isIncome: isIncome),
                      ),
                    );
                  },

                  style: OutlinedButton.styleFrom(
                    foregroundColor: _NavTheme.accentInk(context),

                    minimumSize: const Size.fromHeight(52),

                    side: BorderSide(color: _NavTheme.accent(context)),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  child: const Text(
                    'Add Another Transaction',

                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
