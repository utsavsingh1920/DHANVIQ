import 'package:flutter/material.dart';

import '../models/transaction_model.dart';

import '../services/transaction_service.dart';

import '../services/currency_service.dart';

import '../navigation/main_navigation_screen.dart';

// Brand actions follow the accent selected in Settings > Appearance.

// Income/expense and category colors remain distinct for readability.

Color _accent(BuildContext context) => Theme.of(context).colorScheme.primary;

Color _onAccent(BuildContext context) =>
    ThemeData.estimateBrightnessForColor(_accent(context)) == Brightness.dark
    ? Colors.white
    : const Color(0xFF111827);

const _green = Color(0xFF10B981);

const _red = Color(0xFFF0445D);

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

Color _soft(BuildContext context) => Color.alphaBlend(
  _accent(context).withValues(alpha: _isDark(context) ? .17 : .09),

  _surface(context),
);

Color _line(BuildContext context) =>
    _isDark(context) ? const Color(0xFF35374C) : const Color(0xFFE8EBF3);

String _money(double value) {
  return CurrencyService.instance.formatAmount(
    value,

    decimal: value.abs() % 1 != 0,
  );
}

String _date(DateTime d) => '${d.day}/${d.month}/${d.year}';

String _dateHeading(DateTime d) {
  final now = DateTime.now();

  final today = DateTime(now.year, now.month, now.day);

  final day = DateTime(d.year, d.month, d.day);

  if (day == today) {
    return 'Today, ${_date(d)}';
  }

  if (day == today.subtract(const Duration(days: 1))) {
    return 'Yesterday, ${_date(d)}';
  }

  return _date(d);
}

const _incomeCategories = <String>[
  'Salary',
  'Freelance',
  'Business',
  'Bonus',
  'Investments',
  'Interest',
  'Rental',
  'Refund',
  'Gift',
  'Other',
];

const _expenseCategories = <String>[
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

bool _sameCategory(String left, String right) =>
    _normalizedCategory(left) == _normalizedCategory(right);

List<String> _filterCategoriesForType(String type) {
  if (type == 'Income') {
    return const ['All', ..._incomeCategories];
  }
  if (type == 'Expense') {
    return const ['All', ..._expenseCategories];
  }

  final values = <String>['All'];
  for (final category in [..._incomeCategories, ..._expenseCategories]) {
    if (!values.contains(category)) values.add(category);
  }
  return values;
}

IconData _categoryIcon(String value) => switch (_normalizedCategory(value)) {
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

Color _categoryAccent(String category, {TransactionType? type}) {
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
      _ => _green,
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

Color _categoryColor(TransactionModel item) =>
    _categoryAccent(item.category, type: item.type);

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key, this.onAdd});

  final VoidCallback? onAdd;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _service = TransactionService.instance;

  final _currency = CurrencyService.instance;

  final _searchController = TextEditingController();

  String _type = 'All';

  String _category = 'All';

  String _query = '';

  String _range = 'All Dates';

  String _sort = 'Date (Newest First)';

  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();

    _service.addListener(_refresh);

    _currency.addListener(_refresh);

    _service.initialize().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _service.removeListener(_refresh);

    _currency.removeListener(_refresh);

    _searchController.dispose();

    super.dispose();
  }

  List<TransactionModel> get _visible =>
      _service.transactions.where((item) {
        final type =
            _type == 'All' ||
            (_type == 'Income' && item.type == TransactionType.income) ||
            (_type == 'Expense' && item.type == TransactionType.expense);

        final category =
            _category == 'All' || _sameCategory(item.category, _category);

        final query = _query.trim().toLowerCase();

        final search =
            query.isEmpty ||
            [
              item.title,

              item.category,

              item.note,

              item.paymentMethod,
            ].any((value) => value.toLowerCase().contains(query));

        final now = DateTime.now();

        final start = switch (_range) {
          'This Week' => DateTime(
            now.year,

            now.month,

            now.day,
          ).subtract(Duration(days: now.weekday - 1)),

          'This Month' => DateTime(now.year, now.month),

          'Last 3 Months' => DateTime(now.year, now.month - 2),

          _ => DateTime(1900),
        };

        final inRange = _range == 'Custom Range' && _customRange != null
            ? !item.date.isBefore(_customRange!.start) &&
                  item.date.isBefore(
                    _customRange!.end.add(const Duration(days: 1)),
                  )
            : !item.date.isBefore(start);

        return type && category && search && inRange;
      }).toList()..sort(
        (a, b) => switch (_sort) {
          'Date (Oldest First)' => a.date.compareTo(b.date),

          'Amount (High to Low)' => b.amount.compareTo(a.amount),

          'Amount (Low to High)' => a.amount.compareTo(b.amount),

          'A to Z' => a.title.toLowerCase().compareTo(b.title.toLowerCase()),

          'Z to A' => b.title.toLowerCase().compareTo(a.title.toLowerCase()),

          _ => b.date.compareTo(a.date),
        },
      );

  @override
  Widget build(BuildContext context) {
    final items = _visible;

    final hasTransactions = _service.transactions.isNotEmpty;

    return Scaffold(
      backgroundColor: _canvas(context),

      body: SafeArea(
        bottom: false,

        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,

              delegate: _TransactionsStickyHeader(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Transactions',

                        style: TextStyle(
                          color: _ink(context),

                          fontSize: 25,

                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    _headerButton(Icons.sort_rounded, _openSort),

                    const SizedBox(width: 8),

                    _headerButton(Icons.tune_rounded, _openFilters),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),

                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,

                      onChanged: (value) => setState(() => _query = value),

                      decoration: InputDecoration(
                        hintText: 'Search transactions, category, merchant...',

                        hintStyle: TextStyle(
                          color: _hint(context),

                          fontSize: 12,
                        ),

                        prefixIcon: Icon(
                          Icons.search_rounded,

                          color: _hint(context),
                        ),

                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();

                                  setState(() => _query = '');
                                },

                                icon: const Icon(Icons.close_rounded),
                              ),

                        filled: true,

                        fillColor: _surface(context),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),

                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: ['All', 'Income', 'Expense']
                          .map(
                            (value) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 7),

                                child: _chip(
                                  value,

                                  _type == value,

                                  () => setState(() => _type = value),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),

            if (hasTransactions) SliverToBoxAdapter(child: _summary()),

            if (hasTransactions && items.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 2),

                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Transaction History',

                          style: TextStyle(
                            color: _ink(context),

                            fontSize: 16,

                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                      Text(
                        '${items.length} ${items.length == 1 ? 'transaction' : 'transactions'}',

                        style: TextStyle(
                          color: _hint(context),

                          fontSize: 11,

                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,

                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),

                  child: Center(
                    child: Container(
                      width: double.infinity,

                      padding: const EdgeInsets.fromLTRB(22, 30, 22, 28),

                      decoration: BoxDecoration(
                        color: _surface(context),

                        borderRadius: BorderRadius.circular(22),

                        border: Border.all(color: _line(context)),
                      ),

                      child: Column(
                        mainAxisSize: MainAxisSize.min,

                        children: [
                          Container(
                            width: 78,

                            height: 78,

                            decoration: BoxDecoration(
                              color: _soft(context),

                              shape: BoxShape.circle,
                            ),

                            child: Icon(
                              Icons.receipt_long_rounded,

                              color: _accent(context),

                              size: 36,
                            ),
                          ),

                          const SizedBox(height: 18),

                          Text(
                            hasTransactions
                                ? 'No transactions found'
                                : 'No transactions yet',

                            textAlign: TextAlign.center,

                            style: TextStyle(
                              color: _ink(context),

                              fontSize: 18,

                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            hasTransactions
                                ? 'Try another search, date range or filter to find your transactions.'
                                : 'Your income and expenses will appear here. Add your first transaction to get started.',

                            textAlign: TextAlign.center,

                            style: TextStyle(
                              color: _hint(context),

                              fontSize: 12.5,

                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 22),

                          if (!hasTransactions)
                            SizedBox(
                              width: double.infinity,

                              child: FilledButton.icon(
                                onPressed: _addTransaction,

                                icon: const Icon(Icons.add_rounded),

                                label: const Text('Add Your First Transaction'),

                                style: FilledButton.styleFrom(
                                  backgroundColor: _accent(context),

                                  foregroundColor: _onAccent(context),

                                  minimumSize: const Size.fromHeight(52),

                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              width: double.infinity,

                              child: OutlinedButton.icon(
                                onPressed: _clearFilters,

                                icon: const Icon(Icons.refresh_rounded),

                                label: const Text('Clear Filters'),

                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _accent(context),

                                  minimumSize: const Size.fromHeight(48),

                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 120),

                sliver: SliverList.builder(
                  itemCount: items.length,

                  itemBuilder: (context, index) {
                    final item = items[index];

                    final date = _dateHeading(item.date);

                    final showDate =
                        index == 0 ||
                        _date(items[index - 1].date) != _date(item.date);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        if (showDate)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(2, 15, 2, 7),

                            child: Text(
                              date,

                              style: TextStyle(
                                color: _ink(context),

                                fontSize: 12,

                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),

                        _transactionTile(item),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _addTransaction() {
    if (widget.onAdd != null) {
      widget.onAdd!();

      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AddTransactionForm(isIncome: false),
      ),
    );
  }

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _query = '';

      _type = 'All';

      _category = 'All';

      _range = 'All Dates';

      _customRange = null;
    });
  }

  Widget _headerButton(IconData icon, VoidCallback onTap) => Material(
    color: _surface(context),

    borderRadius: BorderRadius.circular(12),

    child: InkWell(
      onTap: onTap,

      borderRadius: BorderRadius.circular(12),

      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon, color: _ink(context), size: 21),
      ),
    ),
  );

  Widget _chip(String title, bool selected, VoidCallback onTap) => InkWell(
    onTap: onTap,

    borderRadius: BorderRadius.circular(11),

    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),

      height: 38,

      alignment: Alignment.center,

      decoration: BoxDecoration(
        color: selected ? _accent(context) : _surface(context),

        borderRadius: BorderRadius.circular(11),
      ),

      child: Text(
        title,

        style: TextStyle(
          color: selected ? _onAccent(context) : _ink(context),

          fontSize: 12,

          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );

  Widget _summary() {
    final now = DateTime.now();

    final income = _service.incomeForMonth(now.year, now.month);

    final expense = _service.expensesForMonth(now.year, now.month);

    final end = DateTime(now.year, now.month + 1, 0).day;

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 18, 18, 8),

      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),

      decoration: BoxDecoration(
        color: _surface(context),

        borderRadius: BorderRadius.circular(18),

        boxShadow: const [
          BoxShadow(
            color: Color(0x0D071536),

            blurRadius: 16,

            offset: Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            'This Month',

            style: TextStyle(color: _ink(context), fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 3),

          Text(
            '1–$end ${_month(now.month)} ${now.year}',

            style: TextStyle(color: _hint(context), fontSize: 11),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              _summaryValue(_money(income), 'Income', _green),

              _divider(),

              _summaryValue(_money(expense), 'Expense', _red),

              _divider(),

              _summaryValue(
                _money(income - expense),

                'Net Balance',

                _accent(context),
              ),
            ],
          ),
        ],
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

  Widget _summaryValue(String amount, String label, Color color) => Expanded(
    child: Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,

          child: Text(
            amount,

            style: TextStyle(
              color: color,

              fontSize: 15,

              fontWeight: FontWeight.w900,
            ),
          ),
        ),

        const SizedBox(height: 3),

        Text(label, style: TextStyle(color: _hint(context), fontSize: 9)),
      ],
    ),
  );

  Widget _divider() => Container(width: 1, height: 29, color: _line(context));

  Widget _transactionTile(TransactionModel item) {
    final income = item.type == TransactionType.income;

    final color = _categoryColor(item);

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),

      child: Material(
        color: _surface(context),

        borderRadius: BorderRadius.circular(16),

        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => _TransactionDetailsScreen(id: item.id),
            ),
          ),

          borderRadius: BorderRadius.circular(16),

          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),

              border: Border.all(color: _line(context)),
            ),

            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,

                  backgroundColor: color.withAlpha(24),

                  child: Icon(
                    _categoryIcon(item.category),

                    color: color,

                    size: 21,
                  ),
                ),

                const SizedBox(width: 11),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        item.title,

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: TextStyle(
                          color: _ink(context),

                          fontSize: 13,

                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        '${item.category} · ${_date(item.date)}',

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: TextStyle(color: _hint(context), fontSize: 10.5),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                Text(
                  '${income ? '+' : '-'} ${_money(item.amount)}',

                  style: TextStyle(
                    color: income ? _green : _red,

                    fontSize: 12.5,

                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(width: 2),

                Icon(
                  Icons.chevron_right_rounded,

                  color: _hint(context),

                  size: 17,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSort() async {
    final options = [
      'Date (Newest First)',

      'Date (Oldest First)',

      'Amount (High to Low)',

      'Amount (Low to High)',

      'A to Z',

      'Z to A',
    ];

    final result = await showModalBottomSheet<String>(
      context: context,

      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,

          padding: const EdgeInsets.all(18),

          children: [
            const Text(
              'Sort By',

              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),

            for (final option in options)
              ListTile(
                title: Text(option),

                trailing: Icon(
                  option == _sort
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,

                  color: option == _sort ? _accent(context) : _hint(context),
                ),

                onTap: () => Navigator.pop(sheetContext, option),
              ),
          ],
        ),
      ),
    );

    if (mounted && result != null) {
      setState(() => _sort = result);
    }
  }

  Widget _categoryFilterTile(String value, bool selected, VoidCallback onTap) {
    final isAll = value == 'All';
    final icon = isAll ? Icons.apps_rounded : _categoryIcon(value);
    final accent = isAll ? _accent(context) : _categoryAccent(value);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? _accent(context).withValues(alpha: _isDark(context) ? .20 : .11)
              : _surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? _accent(context).withValues(alpha: .65)
                : _line(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 27,
              height: 27,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: _isDark(context) ? .20 : .11),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: accent),
            ),
            const SizedBox(width: 7),
            Text(
              value,
              style: TextStyle(
                color: selected ? _accent(context) : _ink(context),
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFilters() async {
    String type = _type;

    String category = _category;

    String range = _range;

    DateTimeRange? customRange = _customRange;

    final result =
        await showModalBottomSheet<(String, String, String, DateTimeRange?)>(
          context: context,

          isScrollControlled: true,

          backgroundColor: Colors.transparent,

          builder: (sheetContext) => StatefulBuilder(
            builder: (sheetContext, update) => Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),

              decoration: BoxDecoration(
                color: _surface(context),

                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),

              child: SafeArea(
                top: false,

                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Filter Transactions',

                              style: TextStyle(
                                color: _ink(context),

                                fontSize: 18,

                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),

                          TextButton(
                            onPressed: () => update(() {
                              type = 'All';

                              category = 'All';

                              range = 'All Dates';

                              customRange = null;
                            }),

                            child: const Text('Reset'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Date Range',

                        style: TextStyle(
                          color: _ink(context),

                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 8,

                        runSpacing: 6,

                        children:
                            [
                                  'All Dates',

                                  'This Week',

                                  'This Month',

                                  'Last 3 Months',

                                  'Custom Range',
                                ]
                                .map(
                                  (value) => ChoiceChip(
                                    label: Text(value),

                                    selected: range == value,

                                    onSelected: (_) async {
                                      if (value == 'Custom Range') {
                                        final picked =
                                            await showDateRangePicker(
                                              context: sheetContext,

                                              firstDate: DateTime(2020),

                                              lastDate: DateTime(2100),

                                              initialDateRange: customRange,
                                            );

                                        if (picked != null) {
                                          update(() {
                                            range = value;

                                            customRange = picked;
                                          });
                                        }
                                      } else {
                                        update(() => range = value);
                                      }
                                    },
                                  ),
                                )
                                .toList(),
                      ),

                      const SizedBox(height: 18),

                      Text(
                        'Transaction Type',

                        style: TextStyle(
                          color: _ink(context),

                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: ['All', 'Income', 'Expense']
                            .map(
                              (value) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 6),

                                  child: _chip(
                                    value,

                                    type == value,

                                    () => update(() {
                                      type = value;
                                      category = 'All';
                                    }),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),

                      const SizedBox(height: 18),

                      Text(
                        'Categories',

                        style: TextStyle(
                          color: _ink(context),

                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _filterCategoriesForType(type)
                            .map(
                              (value) => _categoryFilterTile(
                                value,
                                category == value,
                                () => update(() => category = value),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,

                        child: FilledButton(
                          onPressed: () => Navigator.pop(sheetContext, (
                            type,

                            category,

                            range,

                            customRange,
                          )),

                          style: FilledButton.styleFrom(
                            backgroundColor: _accent(context),

                            foregroundColor: _onAccent(context),

                            minimumSize: const Size.fromHeight(50),
                          ),

                          child: const Text('Apply Filters'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _type = result.$1;

      _category = result.$2;

      _range = result.$3;

      _customRange = result.$4;
    });
  }
}

class _TransactionDetailsScreen extends StatefulWidget {
  const _TransactionDetailsScreen({required this.id});

  final String id;

  @override
  State<_TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<_TransactionDetailsScreen> {
  final _service = TransactionService.instance;

  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final item = _service.getTransactionById(widget.id);

    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transaction Details')),

        body: const Center(child: Text('Transaction no longer exists.')),
      );
    }

    final income = item.type == TransactionType.income;

    final color = _categoryColor(item);

    return Scaffold(
      backgroundColor: _canvas(context),

      appBar: AppBar(
        backgroundColor: _canvas(context),

        foregroundColor: _ink(context),

        title: const Text(
          'Transaction Details',

          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),

        children: [
          Center(
            child: CircleAvatar(
              radius: 36,

              backgroundColor: color.withAlpha(28),

              child: Icon(_categoryIcon(item.category), color: color, size: 34),
            ),
          ),

          const SizedBox(height: 12),

          Center(
            child: Text(
              item.title,

              style: TextStyle(
                color: _ink(context),

                fontSize: 20,

                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(height: 4),

          Center(
            child: Text(
              '${income ? '+' : '-'} ${_money(item.amount)}',

              style: TextStyle(
                color: income ? _green : _red,

                fontSize: 24,

                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(height: 22),

          Container(
            decoration: BoxDecoration(
              color: _surface(context),

              borderRadius: BorderRadius.circular(18),
            ),

            child: Column(
              children: [
                _detail(
                  _categoryIcon(item.category),
                  'Category',
                  item.category,
                ),

                _detail(Icons.calendar_month_rounded, 'Date', _date(item.date)),

                _detail(
                  Icons.credit_card_rounded,

                  'Payment Method',

                  item.paymentMethod,
                ),

                _detail(
                  Icons.description_outlined,

                  'Note',

                  item.note.isEmpty ? 'No note' : item.note,
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          OutlinedButton.icon(
            onPressed: _deleting
                ? null
                : () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AddTransactionForm(
                          isIncome: income,

                          existing: item,
                        ),
                      ),
                    );

                    if (mounted) {
                      setState(() {});
                    }
                  },

            icon: const Icon(Icons.edit_outlined),

            label: const Text('Edit Transaction'),

            style: OutlinedButton.styleFrom(
              foregroundColor: _accent(context),

              minimumSize: const Size.fromHeight(48),
            ),
          ),

          const SizedBox(height: 10),

          OutlinedButton.icon(
            onPressed: _deleting ? null : _delete,

            icon: _deleting
                ? const SizedBox(
                    width: 17,

                    height: 17,

                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline_rounded),

            label: const Text('Delete Transaction'),

            style: OutlinedButton.styleFrom(
              foregroundColor: _red,

              side: const BorderSide(color: Color(0x66F0445D)),

              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),

    child: Row(
      children: [
        Icon(icon, size: 18, color: _ink(context)),

        const SizedBox(width: 10),

        SizedBox(
          width: 110,

          child: Text(
            label,

            style: TextStyle(
              color: _ink(context),

              fontSize: 11,

              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        Expanded(
          child: Text(
            value,

            textAlign: TextAlign.right,

            style: TextStyle(
              color: _ink(context),

              fontSize: 11,

              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            decoration: BoxDecoration(
              color: _surface(dialogContext),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _line(dialogContext)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: _isDark(dialogContext) ? .32 : .10,
                  ),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _red.withValues(
                      alpha: _isDark(dialogContext) ? .18 : .09,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: _red,
                    size: 29,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'Delete transaction?',
                  style: TextStyle(
                    color: _ink(dialogContext),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'This transaction will be permanently removed from your local records.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _hint(dialogContext),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _ink(dialogContext),
                          minimumSize: const Size.fromHeight(46),
                          side: BorderSide(color: _line(dialogContext)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: _red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'Delete',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm != true || !mounted) {
      return;
    }

    setState(() => _deleting = true);

    try {
      final deleted = await _service.deleteTransaction(widget.id);

      if (!mounted) {
        return;
      }

      if (deleted) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction was not found.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete transaction. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }
}

class _TransactionsStickyHeader extends SliverPersistentHeaderDelegate {
  const _TransactionsStickyHeader({required this.child});

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
      color: _canvas(context),

      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),

      alignment: Alignment.center,

      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _TransactionsStickyHeader oldDelegate) => true;
}
