import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import '../services/finance_plan_service.dart';
import '../services/currency_service.dart';
import '../navigation/main_navigation_screen.dart';

// Uses the MaterialApp themeMode (Light / Dark / System Default).
bool _isDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;
Color _ink(BuildContext context) =>
    _isDark(context) ? const Color(0xFFF0F1FC) : const Color(0xFF071536);
Color _hint(BuildContext context) =>
    _isDark(context) ? const Color(0xFFACB4CB) : const Color(0xFF7D879D);
Color _canvas(BuildContext context) =>
    _isDark(context) ? const Color(0xFF10111D) : const Color(0xFFF7F8FD);
Color _surface(BuildContext context) =>
    _isDark(context) ? const Color(0xFF1B1D2E) : Colors.white;
// The same MaterialApp accent selected in Settings > Appearance.
Color _accent(BuildContext context) => Theme.of(context).colorScheme.primary;

// Make labels legible even when the selected accent is Yellow.
Color _onAccent(BuildContext context) =>
    ThemeData.estimateBrightnessForColor(_accent(context)) == Brightness.dark
        ? Colors.white
        : const Color(0xFF111827);

// Accent-tinted neutral panels adapt to both light and dark themes.
Color _soft(BuildContext context) => Color.alphaBlend(
    _accent(context).withValues(alpha: _isDark(context) ? 0.15 : 0.08),
    _surface(context),
);
Color _line(BuildContext context) =>
    _isDark(context) ? const Color(0xFF35374C) : const Color(0xFFE8EBF3);
Color _softGreen(BuildContext context) =>
    _isDark(context) ? const Color(0xFF153B34) : const Color(0xFFE5F8F1);

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});
  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  static const green = Color(0xFF16B981);
  static const red = Color(0xFFF0445D);
  final _tx = TransactionService.instance;
  final _plans = FinancePlanService.instance;
  final _currency = CurrencyService.instance;
  final _tabs = const ['Overview', 'Categories', 'Budget', 'Trends'];
  int _tab = 0;
  bool _expense = true;
  String _period = 'This Month';
  DateTimeRange? _custom;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tx.addListener(_refresh);
    _plans.addListener(_refresh);
    _currency.addListener(_refresh);
    _load();
  }

  Future<void> _load() async {
    try {
      await Future.wait([_tx.initialize(), _plans.initialize()]);
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tx.removeListener(_refresh);
    _plans.removeListener(_refresh);
    _currency.removeListener(_refresh);
    super.dispose();
  }

  DateTime get _now => DateTime.now();
  DateTime _startOf(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _monthStart(DateTime d) => DateTime(d.year, d.month);
  DateTime _addMonths(DateTime d, int n) => DateTime(d.year, d.month + n);
  DateTimeRange get _range {
    final now = _now;
    final today = _startOf(now);
    switch (_period) {
      case 'This Week':
        return DateTimeRange(
          start: today.subtract(Duration(days: today.weekday - 1)),
          end: now,
        );
      case 'Last 3 Months':
        return DateTimeRange(start: _addMonths(_monthStart(now), -2), end: now);
      case 'Last 6 Months':
        return DateTimeRange(start: _addMonths(_monthStart(now), -5), end: now);
      case 'This Year':
        return DateTimeRange(start: DateTime(now.year), end: now);
      case 'Custom Range':
        return _custom ?? DateTimeRange(start: _monthStart(now), end: now);
      default:
        return DateTimeRange(start: _monthStart(now), end: now);
    }
  }

  List<TransactionModel> get _filtered {
    final range = _range;
    final endExclusive = _startOf(range.end).add(const Duration(days: 1));
    return _tx.transactions
        .where(
          (t) => !t.date.isBefore(range.start) && t.date.isBefore(endExclusive),
        )
        .toList();
  }

  double _sum(Iterable<TransactionModel> source, TransactionType type) =>
      source.where((t) => t.type == type).fold(0.0, (s, t) => s + t.amount);
  double get _income => _sum(_filtered, TransactionType.income);
  double get _spent => _sum(_filtered, TransactionType.expense);
  String _money(num value) {
    return CurrencyService.instance.formatAmount(
      value,
      decimal: value.abs() % 1 != 0,
    );
  }

  String _date(DateTime d) =>
      '${d.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]} ${d.year}';
  String _month(DateTime d) => const [
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
  ][d.month - 1];
  double _ratio(double value, double total) =>
      total <= 0 ? 0 : (value / total).clamp(0.0, 1.0).toDouble();
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

  Color _color(String category) {
    return switch (_normalizedCategory(category)) {
      'salary' => green,
      'freelance' => const Color(0xFF20BFA9),
      'business' => const Color(0xFF2E9FDC),
      'bonus' => const Color(0xFF16CFA5),
      'investments' => const Color(0xFF35B97B),
      'interest' => const Color(0xFF20BFA9),
      'rental' => const Color(0xFF2E9FDC),
      'refund' => const Color(0xFF32BFA3),
      'gift' => const Color(0xFF37B58D),
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

  IconData _icon(String category) {
    return switch (_normalizedCategory(category)) {
      'salary' => Icons.work_rounded,
      'freelance' => Icons.laptop_mac_rounded,
      'business' => Icons.business_rounded,
      'bonus' => Icons.card_giftcard_rounded,
      'investments' => Icons.trending_up_rounded,
      'interest' => Icons.savings_rounded,
      'rental' => Icons.home_work_rounded,
      'refund' => Icons.replay_rounded,
      'gift' => Icons.redeem_rounded,
      'food' => Icons.restaurant_rounded,
      'groceries' => Icons.shopping_cart_rounded,
      'transport' => Icons.directions_car_rounded,
      'shopping' => Icons.shopping_bag_rounded,
      'bills' => Icons.receipt_long_rounded,
      'rent' => Icons.home_rounded,
      'health' => Icons.favorite_rounded,
      'education' => Icons.school_rounded,
      'entertainment' => Icons.movie_rounded,
      'travel' => Icons.flight_rounded,
      'fuel' => Icons.local_gas_station_rounded,
      'emi / loan' => Icons.account_balance_rounded,
      'personal care' => Icons.spa_rounded,
      'subscriptions' => Icons.autorenew_rounded,
      'family' => Icons.family_restroom_rounded,
      'insurance' => Icons.verified_user_rounded,
      'other' => Icons.more_horiz_rounded,
      _ => Icons.category_rounded,
    };
  }

  Map<String, double> _categories(TransactionType type) {
    final totals = <String, double>{};
    final labels = <String, String>{};

    for (final t in _filtered.where((t) => t.type == type)) {
      final normalized = _normalizedCategory(t.category);
      labels.putIfAbsent(normalized, () {
        return switch (normalized) {
          'bills' => 'Bills',
          'health' => 'Health',
          'other' => 'Other',
          'rent' => 'Rent',
          'emi / loan' => 'EMI / Loan',
          'subscriptions' => 'Subscriptions',
          _ => t.category.trim().isEmpty ? 'Other' : t.category.trim(),
        };
      });
      totals.update(
        normalized,
        (value) => value + t.amount,
        ifAbsent: () => t.amount,
      );
    }

    final entries = totals.entries
        .map((entry) => MapEntry(labels[entry.key] ?? entry.key, entry.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(entries);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _canvas(context),
    body: SafeArea(
      bottom: false,
      child: _loading
          ? Center(child: CircularProgressIndicator(color: _accent(context)))
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load insights: $_error'),
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _InsightsPinnedHeader(child: _header()),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _InsightsPinnedHeader(height: 58, child: _tabBar()),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                    child: [
                      _overview,
                      _categoryPage,
                      _budgetPage,
                      _trendsPage,
                    ][_tab](),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
    ),
  );

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            'Insights',
            style: TextStyle(
              color: _ink(context),
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        InkWell(
          onTap: _pickPeriod,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: _surface(context),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Text(
                  _period,
                  style: TextStyle(
                    color: _ink(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _ink(context),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
  Widget _tabBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18),
    child: Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _soft(context),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: List.generate(
          _tabs.length,
          (i) => Expanded(
            child: InkWell(
              onTap: () => setState(() => _tab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _tab == i ? _accent(context) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _tabs[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _tab == i ? _onAccent(context) : _ink(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  Future<void> _pickPeriod() async {
    String pending = _period;
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, update) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _handle(),
                const SizedBox(height: 17),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Select Date Range',
                        style: TextStyle(
                          color: _ink(context),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(sheet, pending),
                      child: Text(
                        'Done',
                        style: TextStyle(
                          color: _accent(context),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                for (final item in const [
                  'This Week',
                  'This Month',
                  'Last 3 Months',
                  'Last 6 Months',
                  'This Year',
                  'Custom Range',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => update(() => pending = item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: pending == item
                              ? _soft(context)
                              : _surface(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              pending == item
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: pending == item ? _accent(context) : _hint(context),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item,
                                style: TextStyle(
                                  color: _ink(context),
                                  fontWeight: pending == item
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (item == 'Custom Range')
                              Icon(
                                Icons.calendar_month_rounded,
                                color: _accent(context),
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted || selected == null) return;
    if (selected == 'Custom Range') {
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        initialDateRange: _custom,
      );
      if (!mounted || range == null) return;
      setState(() {
        _custom = range;
        _period = selected;
      });
    } else {
      setState(() => _period = selected);
    }
  }

  Widget _handle() => Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFD6D7E8),
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );

  Widget _sheetIcon(IconData icon, Color color, {double size = 50}) =>
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withAlpha(22),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: size * .48),
      );

  Widget _sheetSwitch(
    String left,
    String right,
    bool leftSelected,
    ValueChanged<bool> onChanged,
  ) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: _soft(context),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        for (final isLeft in [true, false])
          Expanded(
            child: InkWell(
              onTap: () => onChanged(isLeft),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: leftSelected == isLeft ? _accent(context) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isLeft ? left : right,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: leftSelected == isLeft
                        ? _onAccent(context)
                        : _ink(context),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _card(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _surface(context),
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0B071536),
          blurRadius: 14,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: child,
  );
  Widget _title(String label, {String? link, VoidCallback? onTap}) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: _ink(context),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      if (link != null && onTap != null)
        TextButton(
          onPressed: onTap,
          child: Text(
            link,
            style: TextStyle(
              fontSize: 11,
              color: _accent(context),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
    ],
  );
  bool _hasValues(Iterable<double> values) =>
      values.any((v) => v.abs() > 0.000001);
  Widget _emptyIllustration(
    IconData icon,
    String heading,
    String description, {
    String? button,
    VoidCallback? onPressed,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
    child: Column(
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            color: _soft(context),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 59, color: _accent(context)),
        ),
        const SizedBox(height: 17),
        Text(
          heading,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ink(context),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          description,
          textAlign: TextAlign.center,
          style: TextStyle(color: _hint(context), fontSize: 12, height: 1.45),
        ),
        if (button != null && onPressed != null) ...[
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent(context),
                foregroundColor: _onAccent(context),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                button,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ],
    ),
  );

  void _openTransactions() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AddTransactionForm(isIncome: false),
      ),
    );
  }

  Widget _chartEmpty(String message) => SizedBox(
    height: 148,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insert_chart_outlined_rounded,
            color: _hint(context),
            size: 25,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: _hint(context), fontSize: 11),
          ),
        ],
      ),
    ),
  );
  Widget _empty(String message) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: _hint(context), fontSize: 12),
      ),
    ),
  );
  Widget _insight(String title, String message, {VoidCallback? onTap}) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: _soft(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _accent(context).withAlpha(22),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.lightbulb_rounded,
                  color: _accent(context),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: _ink(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      message,
                      style: TextStyle(color: _hint(context), fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded, color: _ink(context)),
            ],
          ),
        ),
      );

  Widget _overview() {
    final byCategory = _categories(TransactionType.expense);
    final previous = _previousSpent();
    final difference = previous > 0
        ? ((_spent - previous) / previous * 100).abs()
        : 0.0;
    final insight = previous <= 0
        ? 'Add expenses across two periods to compare spending.'
        : _spent < previous
        ? 'Spending is ${difference.toStringAsFixed(0)}% lower than the previous period.'
        : _spent > previous
        ? 'Spending is ${difference.toStringAsFixed(0)}% higher than the previous period.'
        : 'Spending matches the previous period.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _metricCard('Income', _income, green, Icons.trending_up_rounded),
            const SizedBox(width: 8),
            _metricCard('Expense', _spent, red, Icons.trending_down_rounded),
            const SizedBox(width: 8),
            _metricCard(
              'Saved',
              _income - _spent,
              _accent(context),
              Icons.savings_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _title('Income vs Expense'),
        const SizedBox(height: 8),
        _card(
          _hasValues(_weeklyPairs().expand((pair) => pair))
              ? Column(
                  children: [
                    const _ChartLegend(),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 145,
                      child: CustomPaint(
                        painter: _PairBars(
                          _weeklyPairs(),
                          _weekLabels(),
                          ink: _ink(context),
                          grid: _line(context),
                        ),
                      ),
                    ),
                  ],
                )
              : _chartEmpty(
                  'No data yet\nAdd transactions to see your income vs expense trend.',
                ),
        ),
        const SizedBox(height: 16),
        _title(
          'Spending by Category',
          link: 'See All',
          onTap: () => setState(() {
            _tab = 1;
            _expense = true;
          }),
        ),
        const SizedBox(height: 10),
        _card(
          byCategory.isEmpty
              ? _emptyIllustration(
                  Icons.donut_large_rounded,
                  'No spending data yet',
                  'Start adding expenses to see your spending breakdown.',
                  button: 'Add Your First Expense',
                  onPressed: _openTransactions,
                )
              : Row(
                  children: [
                    SizedBox(
                      width: 112,
                      height: 112,
                      child: CustomPaint(
                        painter: _Donut(
                          byCategory,
                          _spent,
                          _color,
                          _money,
                          ink: _ink(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          for (final entry in byCategory.entries.take(5))
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    color: _color(entry.key),
                                    size: 9,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: _ink(context),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${(_ratio(entry.value, _spent) * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: _hint(context),
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
        ),
        const SizedBox(height: 12),
        _insight(
          _filtered.isEmpty ? 'Add your first transaction' : 'Smart Insight',
          _filtered.isEmpty
              ? 'Your insights will appear here automatically.'
              : insight,
          onTap: _filtered.isEmpty ? _openTransactions : _insightDetails,
        ),
      ],
    );
  }

  Widget _metricCard(String label, double value, Color color, IconData icon) =>
      Expanded(
        child: Container(
          constraints: const BoxConstraints(minHeight: 89),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          decoration: BoxDecoration(
            color: _surface(context),
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08071536),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 19, color: color),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _money(value),
                  maxLines: 1,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(color: _hint(context), fontSize: 10),
              ),
            ],
          ),
        ),
      );

  Widget _categoryPage() {
    final type = _expense ? TransactionType.expense : TransactionType.income;
    final entries = _categories(type);
    final total = _expense ? _spent : _income;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (entries.isNotEmpty) ...[
          _title('Category Breakdown'),
          const SizedBox(height: 10),
        ],
        Container(
          height: 40,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: _soft(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              for (final expense in [true, false])
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _expense = expense),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _expense == expense
                            ? _accent(context)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        expense ? 'Expense' : 'Income',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _expense == expense
                              ? _onAccent(context)
                              : _ink(context),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          entries.isEmpty
              ? _emptyIllustration(
                  Icons.pie_chart_rounded,
                  'No category data yet',
                  'Add your first ${_expense ? 'expense' : 'income'} to see how your money is ${_expense ? 'spent' : 'earned'} across different categories.',
                  button: 'Add Your First ${_expense ? 'Expense' : 'Income'}',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AddTransactionForm(isIncome: !_expense),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (final entry in entries.entries)
                      _categoryRow(
                        entry.key,
                        entry.value,
                        total,
                        () => _categoryDetails(entry.key, type),
                      ),
                  ],
                ),
        ),
        if (entries.isEmpty) ...[
          const SizedBox(height: 16),
          _popularCategories(),
        ] else ...[
          const SizedBox(height: 16),
          _title('Top Category'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: _soft(context),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: _color(entries.keys.first).withAlpha(24),
                child: Icon(
                  _icon(entries.keys.first),
                  color: _color(entries.keys.first),
                  size: 21,
                ),
              ),
              title: Text(
                entries.keys.first,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _ink(context),
                ),
              ),
              subtitle: Text(
                '${(_ratio(entries.values.first, total) * 100).toStringAsFixed(0)}% of total ${_expense ? 'spending' : 'income'}',
                style: TextStyle(color: _hint(context), fontSize: 11),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _categoryDetails(entries.keys.first, type),
            ),
          ),
        ],
      ],
    );
  }

  Widget _popularCategories() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _title('Popular Categories'),
      const SizedBox(height: 10),
      _card(
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          childAspectRatio: .88,
          children: [
            for (final name in const [
              'Food',
              'Groceries',
              'Transport',
              'Shopping',
              'Bills',
              'Rent',
              'Fuel',
              'Subscriptions',
            ])
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _sheetIcon(_icon(name), _color(name), size: 38),
                  const SizedBox(height: 5),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _ink(context), fontSize: 10),
                  ),
                ],
              ),
          ],
        ),
      ),
    ],
  );

  Widget _categoryRow(
    String name,
    double amount,
    double total,
    VoidCallback onTap,
  ) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _color(name).withAlpha(25),
            child: Icon(_icon(name), color: _color(name), size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 11,
                    color: _ink(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _money(amount),
                  style: TextStyle(fontSize: 10, color: _hint(context)),
                ),
                const SizedBox(height: 5),
                LinearProgressIndicator(
                  value: _ratio(amount, total),
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(8),
                  backgroundColor: _soft(context),
                  color: _color(name),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${(_ratio(amount, total) * 100).toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 10, color: _hint(context)),
          ),
        ],
      ),
    ),
  );
  void _categoryDetails(String category, TransactionType type) {
    final items =
        _filtered
            .where((t) => t.category == category && t.type == type)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final amount = items.fold(0.0, (double sum, t) => sum + t.amount);
    final total = type == TransactionType.expense ? _spent : _income;
    final share = total > 0 ? amount / total * 100 : 0.0;
    bool showTransactions = true;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, update) => SafeArea(
          child: FractionallySizedBox(
            heightFactor: .72,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              child: Column(
                children: [
                  _handle(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(sheet),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: _ink(context),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Category Details',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _ink(context),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _sheetIcon(_icon(category), _color(category), size: 58),
                  const SizedBox(height: 9),
                  Text(
                    category,
                    style: TextStyle(
                      color: _ink(context),
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _money(amount),
                    style: TextStyle(
                      color: _ink(context),
                      fontWeight: FontWeight.w900,
                      fontSize: 23,
                    ),
                  ),
                  Text(
                    '${share.toStringAsFixed(0)}% of total ${type == TransactionType.expense ? 'spending' : 'income'}',
                    style: TextStyle(color: _hint(context), fontSize: 12),
                  ),
                  const SizedBox(height: 18),
                  _sheetSwitch(
                    'Transactions',
                    'Insights',
                    showTransactions,
                    (value) => update(() => showTransactions = value),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: showTransactions
                        ? items.isEmpty
                              ? _empty('No transactions for this category')
                              : ListView.separated(
                                  itemCount: items.length,
                                  separatorBuilder: (_, _) =>
                                      Divider(height: 1, color: _line(context)),
                                  itemBuilder: (_, index) {
                                    final t = items[index];
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: _sheetIcon(
                                        _icon(t.category),
                                        _color(t.category),
                                        size: 38,
                                      ),
                                      title: Text(
                                        t.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: _ink(context),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                      subtitle: Text(
                                        _date(t.date),
                                        style: TextStyle(
                                          color: _hint(context),
                                          fontSize: 11,
                                        ),
                                      ),
                                      trailing: Text(
                                        '${type == TransactionType.expense ? '-' : '+'}${_money(t.amount)}',
                                        style: TextStyle(
                                          color: type == TransactionType.expense
                                              ? red
                                              : green,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                      ),
                                    );
                                  },
                                )
                        : ListView(
                            children: [
                              _insight(
                                'Category share',
                                '$category accounts for ${share.toStringAsFixed(0)}% of your '
                                    '${type == TransactionType.expense ? 'expenses' : 'income'} in $_period.',
                              ),
                              const SizedBox(height: 12),
                              _card(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${items.length} recorded transaction${items.length == 1 ? '' : 's'}',
                                      style: TextStyle(
                                        color: _ink(context),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    LinearProgressIndicator(
                                      value: _ratio(amount, total),
                                      minHeight: 7,
                                      borderRadius: BorderRadius.circular(8),
                                      backgroundColor: _soft(context),
                                      color: _color(category),
                                    ),
                                    const SizedBox(height: 9),
                                    Text(
                                      '${_money(amount)} out of ${_money(total)}',
                                      style: TextStyle(
                                        color: _hint(context),
                                        fontSize: 12,
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
            ),
          ),
        ),
      ),
    );
  }

  Map<String, double> get _monthBudgets {
    final now = _now;
    final prefix = '${now.year}-${now.month}-';
    return {
      for (final e in _plans.budgets.entries)
        if (e.key.startsWith(prefix) && e.value > 0)
          e.key.substring(prefix.length): e.value,
    };
  }

  double _monthSpent(String category) => _tx
      .transactionsForMonth(_now.year, _now.month)
      .where((t) => t.isExpense && _sameCategory(t.category, category))
      .fold(0.0, (s, t) => s + t.amount);
  String _billDueText(DateTime dueDate) {
    final today = _startOf(_now);
    final due = _startOf(dueDate);
    final days = due.difference(today).inDays;

    if (days < 0) {
      final overdueDays = days.abs();
      return overdueDays == 1
          ? 'Overdue by 1 day • ${_date(dueDate)}'
          : 'Overdue by $overdueDays days • ${_date(dueDate)}';
    }
    if (days == 0) return 'Due today • ${_date(dueDate)}';
    if (days == 1) return 'Due tomorrow • ${_date(dueDate)}';
    return 'Due in $days days • ${_date(dueDate)}';
  }

  Widget _budgetPage() {
    final budgets = _monthBudgets;
    final total = budgets.values.fold(0.0, (s, v) => s + v);
    final spent = budgets.keys.fold(0.0, (s, c) => s + _monthSpent(c));
    final bills = _plans.bills.where((b) => !b.paid).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final progress = _ratio(spent, total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Overall Budget Progress'),
        const SizedBox(height: 10),
        _card(
          budgets.isEmpty
              ? _emptyIllustration(
                  Icons.track_changes_rounded,
                  'No budget set yet',
                  'Create a monthly budget to track your spending and stay on top of your goals.',
                  button: 'Set Your First Budget',
                  onPressed: _budgetGuidance,
                )
              : Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 86,
                          height: 86,
                          child: CustomPaint(
                            painter: _Ring(
                              progress,
                              '${(spent / total * 100).toStringAsFixed(0)}%',
                              accent: _accent(context),
                              ink: _ink(context),
                              grid: _line(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${_money(spent)} / ${_money(total)}',
                                  style: TextStyle(
                                    color: _ink(context),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Spent this month',
                                style: TextStyle(
                                  color: _hint(context),
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(10),
                                backgroundColor: _soft(context),
                                color: _accent(context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    for (final entry in budgets.entries)
                      _budgetRow(
                        entry.key,
                        _monthSpent(entry.key),
                        entry.value,
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        if (budgets.isEmpty)
          _budgetBenefits()
        else
          _insight(
            'Budget Insights',
            budgets.isEmpty
                ? 'Set a monthly budget on Home to track progress here.'
                : spent > total
                ? 'You have exceeded your combined category budgets by ${_money(spent - total)}.'
                : 'You have ${_money(total - spent)} remaining across your category budgets.',
          ),
        if (budgets.isNotEmpty || bills.isNotEmpty) ...[
          const SizedBox(height: 16),
          _title('Upcoming Bills'),
          const SizedBox(height: 8),
          _card(
            bills.isEmpty
                ? _empty('No upcoming unpaid expenses')
                : Column(
                    children: [
                      for (final bill in bills)
                        ListTile(
                          dense: true,
                          visualDensity: const VisualDensity(vertical: -2),
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: _softGreen(context),
                            child: Icon(
                              Icons.receipt_long_rounded,
                              color: green,
                            ),
                          ),
                          title: Text(
                            bill.title,
                            style: TextStyle(
                              fontSize: 11,
                              color: _ink(context),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Text(
                            _billDueText(bill.dueDate),
                            style: TextStyle(
                              fontSize: 10,
                              color: bill.dueDate.isBefore(_startOf(_now))
                                  ? red
                                  : _hint(context),
                              fontWeight: bill.dueDate.isBefore(_startOf(_now))
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          trailing: Text(
                            '-${_money(bill.amount)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: red,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ],
    );
  }

  void _budgetGuidance() => ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Open Home and tap Set Budget to create your first budget.',
      ),
    ),
  );

  Widget _budgetBenefits() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _soft(context),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Why set a budget?',
          style: TextStyle(color: _ink(context), fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        for (final item in const [
          'Track your spending',
          'Avoid overspending',
          'Reach your financial goals',
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: _accent(context), size: 18),
                const SizedBox(width: 10),
                Text(
                  item,
                  style: TextStyle(color: _hint(context), fontSize: 12),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _budgetRow(String name, double spent, double limit) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(Icons.circle, color: _color(name), size: 10),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 11,
                        color: _ink(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${_money(spent)} / ${_money(limit)}',
                        style: TextStyle(fontSize: 10, color: _hint(context)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: _ratio(spent, limit),
                minHeight: 5,
                borderRadius: BorderRadius.circular(8),
                backgroundColor: _soft(context),
                color: spent > limit ? red : _color(name),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(spent / limit * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            color: spent > limit ? red : green,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  List<DateTime> get _sixMonths =>
      List.generate(6, (i) => _addMonths(_monthStart(_now), i - 5));
  List<List<double>> _monthlyPairs() => [
    for (final m in _sixMonths)
      [
        _tx.incomeForMonth(m.year, m.month),
        _tx.expensesForMonth(m.year, m.month),
      ],
  ];
  List<List<double>> _weeklyPairs() {
    final range = _range;
    final days = range.end.difference(range.start).inDays + 1;
    final groups = math.min(5, math.max(1, (days / 7).ceil()));
    final result = List.generate(groups, (_) => <double>[0, 0]);
    for (final t in _filtered) {
      final offset = t.date.difference(range.start).inDays;
      final index = ((offset / math.max(1, days) * groups).floor()).clamp(
        0,
        groups - 1,
      );
      result[index][t.isIncome ? 0 : 1] += t.amount;
    }
    return result;
  }

  List<String> _weekLabels() {
    final range = _range;
    final groups = _weeklyPairs().length;
    final days = range.end.difference(range.start).inDays + 1;
    final groupSize = math.max(1, (days / groups).ceil());

    return List.generate(groups, (index) {
      final start = range.start.add(Duration(days: index * groupSize));
      if (start.isAfter(range.end)) return 'W${index + 1}';
      return '${start.day} ${_month(start)}';
    });
  }
  Widget _trendsPage() {
    final pairs = _monthlyPairs();
    final expenses = pairs.map((p) => p[1]).toList();
    final savings = pairs.map((p) => p[0] - p[1]).toList();
    final labels = _sixMonths.map(_month).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_hasValues(pairs.expand((pair) => pair))) ...[
          _card(
            _emptyIllustration(
              Icons.trending_up_rounded,
              'No trends to show yet',
              'Add a few transactions to see your spending, savings and income trends over time.',
              button: 'Add Your First Transaction',
              onPressed: _openTransactions,
            ),
          ),
          const SizedBox(height: 16),
          _trendBenefits(),
        ] else ...[
          _title('Spending Trend'),
          const SizedBox(height: 10),
          _card(
            _hasValues(expenses)
                ? SizedBox(
                    width: double.infinity,
                    height: 156,
                    child: CustomPaint(
                      painter: _Line(
                        expenses,
                        labels,
                        _accent(context),
                        ink: _ink(context),
                        grid: _line(context),
                      ),
                    ),
                  )
                : _chartEmpty('No expenses recorded in the last 6 months.'),
          ),
          const SizedBox(height: 16),
          _title('Income vs Expense Trend'),
          const SizedBox(height: 10),
          _card(
            _hasValues(pairs.expand((pair) => pair))
                ? Column(
                    children: [
                      const _ChartLegend(),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 148,
                        child: CustomPaint(
                          painter: _PairBars(
                            pairs,
                            labels,
                            ink: _ink(context),
                            grid: _line(context),
                          ),
                        ),
                      ),
                    ],
                  )
                : _chartEmpty(
                    'No income or expenses recorded in the last 6 months.',
                  ),
          ),
          const SizedBox(height: 16),
          _title('Savings Trend', link: 'See Details', onTap: _savingsDetails),
          const SizedBox(height: 10),
          _card(
            _hasValues(savings)
                ? SizedBox(
                    width: double.infinity,
                    height: 156,
                    child: CustomPaint(
                      painter: _Line(
                        savings,
                        labels,
                        _accent(context),
                        ink: _ink(context),
                        grid: _line(context),
                      ),
                    ),
                  )
                : _chartEmpty(
                    'No savings activity recorded in the last 6 months.',
                  ),
          ),
          const SizedBox(height: 12),
          _insight(
            'Smart Insight',
            _trendInsightText(),
            onTap: _insightDetails,
          ),
        ],
      ],
    );
  }

  String _trendInsightText() {
    final currentSavings = _tx.savingsForMonth(_now.year, _now.month);
    final previousMonth = _addMonths(_monthStart(_now), -1);
    final previousSavings = _tx.savingsForMonth(
      previousMonth.year,
      previousMonth.month,
    );

    if (currentSavings == 0 && previousSavings == 0) {
      return 'Add income and expenses to build a monthly savings trend.';
    }

    if (previousSavings == 0) {
      return 'Net savings this month: ${_money(currentSavings)}. Keep tracking to unlock month-over-month comparison.';
    }

    final change = (currentSavings - previousSavings) / previousSavings.abs() * 100;
    final direction = change >= 0 ? 'higher' : 'lower';

    return 'Net savings this month: ${_money(currentSavings)}, ${change.abs().toStringAsFixed(0)}% $direction than last month.';
  }

  Widget _trendBenefits() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _soft(context),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What you'll get here:",
          style: TextStyle(color: _ink(context), fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        for (final item in const [
          'Monthly spending trends',
          'Income vs expense comparison',
          'Savings growth over time',
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(Icons.insights_rounded, color: _accent(context), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(color: _hint(context), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  void _savingsDetails() {
    final monthly = _tx.savingsForMonth(_now.year, _now.month);
    final savedGoals = _plans.goals.fold(0.0, (double sum, g) => sum + g.saved);
    final target = _plans.goals.fold(0.0, (double sum, g) => sum + g.target);
    _sheet(
      'Savings Details',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Column(
              children: [
                _sheetIcon(
                  Icons.savings_rounded,
                  _accent(context),
                  size: 56,
                ),
                const SizedBox(height: 10),
                Text(
                  'Savings Progress',
                  style: TextStyle(
                    color: _ink(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_money(savedGoals)} / ${_money(target)}',
                  style: TextStyle(
                    color: _ink(context),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 9),
                LinearProgressIndicator(
                  value: _ratio(savedGoals, target),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(10),
                  color: green,
                  backgroundColor: _softGreen(context),
                ),
                const SizedBox(height: 6),
                Text(
                  target > 0
                      ? '${(savedGoals / target * 100).toStringAsFixed(0)}% of goal targets saved'
                      : 'Set a savings goal to track your progress',
                  style: TextStyle(color: _hint(context), fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          _insight(
            'Net savings this month',
            '${_money(monthly)} (income minus expenses). Goal contributions are tracked separately.',
          ),
          const SizedBox(height: 18),
          Text(
            'Your Savings Goals',
            style: TextStyle(
              color: _ink(context),
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 9),
          if (_plans.goals.isEmpty)
            _empty('No savings goals created yet')
          else
            for (final goal in _plans.goals)
              Padding(
                padding: const EdgeInsets.only(bottom: 13),
                child: Row(
                  children: [
                    _sheetIcon(Icons.savings_rounded, _accent(context), size: 38),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.name,
                            style: TextStyle(
                              color: _ink(context),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${_money(goal.saved)} / ${_money(goal.target)}',
                            style: TextStyle(
                              color: _hint(context),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: goal.progress.clamp(0.0, 1.0).toDouble(),
                            minHeight: 5,
                            borderRadius: BorderRadius.circular(8),
                            color: green,
                            backgroundColor: _softGreen(context),
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

  void _insightDetails() {
    final previous = _previousSpent();
    final current = _spent;
    final change = previous > 0 ? (current - previous) / previous * 100 : 0.0;
    final comparable = previous > 0;
    final headline = !comparable
        ? 'More history needed'
        : change > 0
        ? 'Spending Increased'
        : change < 0
        ? 'Spending Decreased'
        : 'Spending Unchanged';
    _sheet(
      'Insight Detail',
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _sheetIcon(
            Icons.lightbulb_rounded,
            const Color(0xFFF4AD22),
            size: 58,
          ),
          const SizedBox(height: 10),
          Text(
            headline,
            style: TextStyle(
              color: _ink(context),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          if (comparable)
            Text(
              '${change > 0 ? '+' : ''}${change.toStringAsFixed(0)}%',
              style: TextStyle(
                color: change > 0 ? red : green,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
          const SizedBox(height: 6),
          Text(
            comparable
                ? 'Your spending is ${_money(current)} in $_period, compared with ${_money(previous)} in the previous equivalent period.'
                : 'Record expenses in two comparable periods to see a reliable spending comparison.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _hint(context), fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: _soft(context),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips to Improve',
                  style: TextStyle(
                    color: _ink(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  !comparable
                      ? '• Keep recording income and expenses regularly.\n• Set category budgets to monitor your spending.'
                      : change > 0
                      ? '• Review your largest expense categories.\n• Set realistic category budgets.\n• Check upcoming bills before new purchases.'
                      : '• Keep tracking expenses regularly.\n• Review your budgets and savings goals.',
                  style: TextStyle(
                    color: _hint(context),
                    fontSize: 12,
                    height: 1.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sheet(String title, Widget body) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: _surface(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.viewInsetsOf(sheet).bottom + 22,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _handle(),
              const SizedBox(height: 13),
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(sheet),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: _ink(context),
                      size: 18,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _ink(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 12),
              body,
            ],
          ),
        ),
      ),
    ),
  );

  double _previousSpent() {
    final range = _range;
    final days =
        _startOf(range.end).difference(_startOf(range.start)).inDays + 1;
    final previousEnd = range.start.subtract(const Duration(microseconds: 1));
    final previousStart = _startOf(range.start).subtract(Duration(days: days));
    return _sum(
      _tx.transactions.where(
        (t) => !t.date.isBefore(previousStart) && !t.date.isAfter(previousEnd),
      ),
      TransactionType.expense,
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend();
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Icon(Icons.circle, size: 9, color: Color(0xFF16B981)),
      SizedBox(width: 4),
      Text('Income', style: TextStyle(fontSize: 10, color: _hint(context))),
      SizedBox(width: 12),
      Icon(Icons.circle, size: 9, color: Color(0xFFF0445D)),
      SizedBox(width: 4),
      Text('Expense', style: TextStyle(fontSize: 10, color: _hint(context))),
    ],
  );
}

class _PairBars extends CustomPainter {
  _PairBars(this.values, this.labels, {required this.ink, required this.grid});
  final List<List<double>> values;
  final List<String> labels;
  final Color ink;
  final Color grid;
  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const left = 32.0;
    const top = 8.0;
    final right = size.width - 5;
    final bottom = size.height - 23;
    final chartHeight = bottom - top;
    final maxValue = values.expand((v) => v).fold(0.0, math.max);
    final ceiling = maxValue <= 0 ? 1.0 : maxValue * 1.12;
    for (var tick = 0; tick <= 3; tick++) {
      final y = bottom - chartHeight * tick / 3;
      canvas.drawLine(
        Offset(left, y),
        Offset(right, y),
        Paint()
          ..color = grid
          ..strokeWidth = .8,
      );
      _paintText(
        canvas,
        _axisMoney(ceiling * tick / 3),
        Offset(0, y - 6),
        8,
        textColor: ink,
      );
    }
    final cell = (right - left) / values.length;
    final barWidth = math.min(13.0, cell / 5);
    for (var i = 0; i < values.length; i++) {
      final x = left + cell * (i + .5);
      for (var j = 0; j < 2; j++) {
        final h = values[i][j] / ceiling * chartHeight;
        if (h <= 0) continue;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              x + (j == 0 ? -barWidth - 1.5 : 1.5),
              bottom - h,
              barWidth,
              h,
            ),
            const Radius.circular(3),
          ),
          Paint()
            ..color = j == 0
                ? const Color(0xFF16B981)
                : const Color(0xFFF0445D),
        );
      }
      _paintText(
        canvas,
        labels[i],
        Offset(x, bottom + 11),
        9,
        center: true,
        textColor: ink,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PairBars old) => true;
}

String _axisMoney(double value) {
  if (value.abs() >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
  if (value.abs() >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
  return value.toStringAsFixed(0);
}

class _Donut extends CustomPainter {
  _Donut(
    this.categories,
    this.total,
    this.color,
    this.money, {
    required this.ink,
  });
  final Color ink;
  final Map<String, double> categories;
  final double total;
  final Color Function(String) color;
  final String Function(num) money;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 12;
    var start = -math.pi / 2;
    for (final entry in categories.entries) {
      final sweep = entry.value / total * math.pi * 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        math.max(0, sweep - .025),
        false,
        Paint()
          ..color = color(entry.key)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14,
      );
      start += sweep;
    }
    _paintText(
      canvas,
      money(total),
      Offset(center.dx, center.dy - 7),
      10,
      center: true,
      bold: true,
      textColor: ink,
    );
    _paintText(
      canvas,
      'Total Spent',
      Offset(center.dx, center.dy + 9),
      7,
      center: true,
      textColor: ink,
    );
  }

  @override
  bool shouldRepaint(covariant _Donut old) =>
      old.total != total || old.categories != categories;
}

class _Ring extends CustomPainter {
  _Ring(this.progress, this.label, {required this.accent, required this.ink, required this.grid});
  final Color ink;
  final Color grid;
  final Color accent;
  final double progress;
  final String label;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 10;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = grid
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress * 2 * math.pi,
      false,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );
    _paintText(
      canvas,
      label,
      center,
      15,
      center: true,
      bold: true,
      textColor: ink,
    );
  }

  @override
  bool shouldRepaint(covariant _Ring old) =>
      old.progress != progress || old.label != label || old.accent != accent || old.ink != ink || old.grid != grid;
}

class _Line extends CustomPainter {
  _Line(
    this.values,
    this.labels,
    this.color, {
    required this.ink,
    required this.grid,
  });
  final Color ink;
  final Color grid;
  final List<double> values;
  final List<String> labels;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const left = 31.0;
    const top = 12.0;
    final right = size.width - 12;
    final bottom = size.height - 24;
    final low = math.min(0.0, values.reduce(math.min));
    final high = math.max(0.0, values.reduce(math.max));
    final span = math.max(1.0, high - low);
    final upper = high + span * .12;
    final lower = low < 0 ? low - span * .08 : 0.0;
    final axisSpan = math.max(1.0, upper - lower);
    for (var i = 0; i <= 3; i++) {
      final y = bottom - (bottom - top) * i / 3;
      canvas.drawLine(
        Offset(left, y),
        Offset(right, y),
        Paint()
          ..color = grid
          ..strokeWidth = .8,
      );
      _paintText(
        canvas,
        _axisMoney(lower + axisSpan * i / 3),
        Offset(0, y - 6),
        8,
        textColor: ink,
      );
    }
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? (left + right) / 2
          : left + (right - left) * i / (values.length - 1);
      final y = bottom - (values[i] - lower) / axisSpan * (bottom - top);
      points.add(Offset(x, y));
      _paintText(
        canvas,
        labels[i],
        Offset(x, bottom + 11),
        9,
        center: true,
        textColor: ink,
      );
    }
    final baseline = bottom - (0 - lower) / axisSpan * (bottom - top);
    final area = Path()
      ..moveTo(points.first.dx, baseline)
      ..lineTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      area.lineTo(p.dx, p.dy);
    }
    area
      ..lineTo(points.last.dx, baseline)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withAlpha(55), color.withAlpha(4)],
        ).createShader(Rect.fromLTRB(left, top, right, bottom)),
    );
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (final p in points) {
      canvas.drawCircle(p, 3.6, Paint()..color = Colors.white);
      canvas.drawCircle(p, 2.8, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _Line old) => true;
}

void _paintText(
  Canvas canvas,
  String text,
  Offset at,
  double size, {
  bool center = false,
  bool bold = false,
  Color textColor = const Color(0xFF071536),
}) {
  final p = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: textColor,
        fontSize: size,
        fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  p.paint(
    canvas,
    center ? Offset(at.dx - p.width / 2, at.dy - p.height / 2) : at,
  );
}

/// Keeps the Insights title and section tabs visible while the content scrolls.
class _InsightsPinnedHeader extends SliverPersistentHeaderDelegate {
  const _InsightsPinnedHeader({required this.child, this.height = 70});

  final Widget child;
  final double height;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: _canvas(context),
      child: Align(alignment: Alignment.center, child: child),
    );
  }

  @override
  bool shouldRebuild(covariant _InsightsPinnedHeader oldDelegate) =>
      oldDelegate.height != height || oldDelegate.child != child;
}
