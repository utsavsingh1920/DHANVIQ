import 'package:flutter/material.dart';



import '../services/finance_plan_service.dart';
import '../services/currency_service.dart';



class _BudgetTheme {

  static bool dark(BuildContext context) =>

      Theme.of(context).brightness == Brightness.dark;



  static Color background(BuildContext context) =>

      dark(context) ? const Color(0xFF070B1A) : const Color(0xFFF7F8FD);



  static Color surface(BuildContext context) =>

      dark(context) ? const Color(0xFF151D33) : Colors.white;



  static Color surfaceAlt(BuildContext context) =>

      dark(context) ? const Color(0xFF1A2440) : const Color(0xFFF1F3FB);



  static Color ink(BuildContext context) =>

      dark(context) ? Colors.white : const Color(0xFF101936);



  static Color muted(BuildContext context) =>

      dark(context) ? const Color(0xFFADB7CD) : const Color(0xFF747D94);



  static Color border(BuildContext context) =>

      dark(context) ? const Color(0xFF45506A) : const Color(0xFFDDE2EF);



  static Color accent(BuildContext context) =>

      Theme.of(context).colorScheme.primary;



  static Color onAccent(BuildContext context) =>

      ThemeData.estimateBrightnessForColor(accent(context)) == Brightness.dark

          ? Colors.white

          : const Color(0xFF101936);



  static Color track(BuildContext context) =>

      dark(context) ? const Color(0xFF263552) : const Color(0xFFE8ECF6);

}



class BudgetCategory {

  const BudgetCategory(this.name, this.icon, this.color);



  final String name;

  final IconData icon;

  final Color color;

}



const List<BudgetCategory> _budgetCategories = [

  BudgetCategory('Food', Icons.restaurant_rounded, Color(0xFF6C3BFF)),

  BudgetCategory('Shopping', Icons.shopping_bag_rounded, Color(0xFFFF4D6D)),

  BudgetCategory('Transport', Icons.directions_car_rounded, Color(0xFF22B8A7)),

  BudgetCategory('Bills & Utilities', Icons.receipt_long_rounded, Color(0xFF9FD8D0)),

  BudgetCategory('Entertainment', Icons.sports_esports_rounded, Color(0xFF7B4CFF)),

  BudgetCategory('Health & Medical', Icons.favorite_rounded, Color(0xFFFF3F5E)),

  BudgetCategory('Education', Icons.menu_book_rounded, Color(0xFF30B9D5)),

  BudgetCategory('Personal Care', Icons.spa_rounded, Color(0xFFB15CDE)),

  BudgetCategory('Travel', Icons.flight_rounded, Color(0xFF6B63FF)),

  BudgetCategory('Others', Icons.more_horiz_rounded, Color(0xFF66728F)),

];



class SetMonthlyBudgetScreen extends StatefulWidget {

  const SetMonthlyBudgetScreen({

    super.key,

    this.initialCategory,

    this.initialAmount,

  });



  final BudgetCategory? initialCategory;

  final double? initialAmount;



  @override

  State<SetMonthlyBudgetScreen> createState() => _SetMonthlyBudgetScreenState();

}



class _SetMonthlyBudgetScreenState extends State<SetMonthlyBudgetScreen> {

  late BudgetCategory _selectedCategory;

  final TextEditingController _amountController = TextEditingController();



  static const _quickAmounts = [500, 1000, 2000, 5000, 10000];



  @override

  void initState() {

    super.initState();

    _selectedCategory = widget.initialCategory ?? _budgetCategories.first;

    if (widget.initialAmount != null && widget.initialAmount! > 0) {

      _amountController.text = widget.initialAmount!.toStringAsFixed(

        widget.initialAmount! % 1 == 0 ? 0 : 2,

      );

    }

  }



  @override

  void dispose() {

    _amountController.dispose();

    super.dispose();

  }



  double? get _amount => double.tryParse(

        _amountController.text.trim().replaceAll(',', '').replaceAll('₹', ''),

      );



  Future<void> _chooseCategory() async {

    final picked = await Navigator.of(context).push<BudgetCategory>(

      MaterialPageRoute(

        builder: (_) => SelectBudgetCategoryScreen(

          selected: _selectedCategory,

        ),

      ),

    );

    if (!mounted || picked == null) return;

    setState(() => _selectedCategory = picked);

  }



  void _setQuickAmount(int amount) {

    setState(() => _amountController.text = amount.toString());

  }



  void _continue() {

    final amount = _amount;

    if (amount == null || !amount.isFinite || amount <= 0) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(content: Text('Please enter a valid monthly limit.')),

      );

      return;

    }



    Navigator.of(context).push(

      MaterialPageRoute<void>(

        builder: (_) => BudgetPreviewScreen(

          category: _selectedCategory,

          amount: amount,

        ),

      ),

    );

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: _BudgetTheme.background(context),

      appBar: AppBar(

        elevation: 0,

        scrolledUnderElevation: 0,

        backgroundColor: _BudgetTheme.background(context),

        foregroundColor: _BudgetTheme.ink(context),

        title: Text(

          'Set Monthly Budget',

          style: TextStyle(

            color: _BudgetTheme.ink(context),

            fontWeight: FontWeight.w800,

          ),

        ),

      ),

      body: SafeArea(

        top: false,

        child: SingleChildScrollView(

          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text(

                'Choose a category and set a monthly spending\nlimit for better control.',

                style: TextStyle(

                  color: _BudgetTheme.muted(context),

                  fontSize: 13,

                  height: 1.45,

                ),

              ),

              const SizedBox(height: 28),

              _label(context, 'Category'),

              const SizedBox(height: 9),

              _PickerField(

                text: _selectedCategory.name,

                onTap: _chooseCategory,

              ),

              const SizedBox(height: 24),

              _label(context, 'Monthly limit (${CurrencyService.instance.symbol})'),

              const SizedBox(height: 9),

              TextField(

                controller: _amountController,

                onChanged: (_) => setState(() {}),

                keyboardType: const TextInputType.numberWithOptions(decimal: true),

                style: TextStyle(

                  color: _BudgetTheme.ink(context),

                  fontSize: 17,

                  fontWeight: FontWeight.w600,

                ),

                decoration: InputDecoration(

                  hintText: 'Enter amount',

                  hintStyle: TextStyle(color: _BudgetTheme.muted(context)),

                  filled: true,

                  fillColor: _BudgetTheme.surface(context),

                  contentPadding: const EdgeInsets.symmetric(

                    horizontal: 16,

                    vertical: 19,

                  ),

                  border: _outline(context),

                  enabledBorder: _outline(context),

                  focusedBorder: _outline(

                    context,

                    color: _BudgetTheme.accent(context),

                    width: 1.6,

                  ),

                ),

              ),

              const SizedBox(height: 26),

              Container(

                width: double.infinity,

                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(

                  color: _BudgetTheme.surface(context),

                  borderRadius: BorderRadius.circular(18),

                  border: Border.all(color: _BudgetTheme.border(context)),

                ),

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(

                      'Quick Amounts',

                      style: TextStyle(

                        color: _BudgetTheme.ink(context),

                        fontWeight: FontWeight.w800,

                      ),

                    ),

                    const SizedBox(height: 14),

                    Wrap(

                      spacing: 10,

                      runSpacing: 10,

                      children: [

                        for (final amount in _quickAmounts)

                          _QuickAmountChip(

                            label: _money(amount),

                            selected: _amount == amount,

                            onTap: () => _setQuickAmount(amount),

                          ),

                        _QuickAmountChip(

                          label: 'Custom',

                          onTap: () {

                            setState(_amountController.clear);

                            FocusScope.of(context).unfocus();

                          },

                        ),

                      ],

                    ),

                  ],

                ),

              ),

              const SizedBox(height: 34),

              _GradientButton(

                text: 'Save Budget',

                onTap: _continue,

              ),

            ],

          ),

        ),

      ),

    );

  }

}



class SelectBudgetCategoryScreen extends StatefulWidget {

  const SelectBudgetCategoryScreen({

    super.key,

    required this.selected,

  });



  final BudgetCategory selected;



  @override

  State<SelectBudgetCategoryScreen> createState() =>

      _SelectBudgetCategoryScreenState();

}



class _SelectBudgetCategoryScreenState extends State<SelectBudgetCategoryScreen> {

  final TextEditingController _search = TextEditingController();

  String _query = '';



  @override

  void dispose() {

    _search.dispose();

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    final items = _budgetCategories

        .where((item) => item.name.toLowerCase().contains(_query.toLowerCase()))

        .toList();



    return Scaffold(

      backgroundColor: _BudgetTheme.background(context),

      appBar: AppBar(

        elevation: 0,

        scrolledUnderElevation: 0,

        backgroundColor: _BudgetTheme.background(context),

        foregroundColor: _BudgetTheme.ink(context),

        title: Text(

          'Select Category',

          style: TextStyle(

            color: _BudgetTheme.ink(context),

            fontWeight: FontWeight.w800,

          ),

        ),

      ),

      body: SafeArea(

        top: false,

        child: Padding(

          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),

          child: Column(

            children: [

              TextField(

                controller: _search,

                onChanged: (value) => setState(() => _query = value),

                style: TextStyle(color: _BudgetTheme.ink(context)),

                decoration: InputDecoration(

                  hintText: 'Search category...',

                  hintStyle: TextStyle(color: _BudgetTheme.muted(context)),

                  prefixIcon: Icon(

                    Icons.search_rounded,

                    color: _BudgetTheme.muted(context),

                  ),

                  filled: true,

                  fillColor: _BudgetTheme.surface(context),

                  border: _outline(context),

                  enabledBorder: _outline(context),

                  focusedBorder: _outline(

                    context,

                    color: _BudgetTheme.accent(context),

                    width: 1.5,

                  ),

                ),

              ),

              const SizedBox(height: 16),

              Expanded(

                child: Container(

                  decoration: BoxDecoration(

                    color: _BudgetTheme.surface(context),

                    borderRadius: BorderRadius.circular(18),

                    border: Border.all(color: _BudgetTheme.border(context)),

                  ),

                  child: ListView.separated(

                    padding: EdgeInsets.zero,

                    itemCount: items.length,

                    separatorBuilder: (_, _) => Divider(

                      height: 1,

                      color: _BudgetTheme.border(context),

                    ),

                    itemBuilder: (context, index) {

                      final item = items[index];

                      final selected = item.name == widget.selected.name;

                      return InkWell(

                        onTap: () => Navigator.pop(context, item),

                        child: Container(

                          padding: const EdgeInsets.symmetric(

                            horizontal: 14,

                            vertical: 13,

                          ),

                          decoration: BoxDecoration(

                            color: selected

                                ? _BudgetTheme.accent(context).withValues(alpha: .10)

                                : Colors.transparent,

                            border: selected

                                ? Border.all(

                                    color: _BudgetTheme.accent(context),

                                    width: 1.2,

                                  )

                                : null,

                            borderRadius: selected

                                ? BorderRadius.circular(13)

                                : BorderRadius.zero,

                          ),

                          child: Row(

                            children: [

                              _CategoryIcon(category: item, size: 42),

                              const SizedBox(width: 12),

                              Expanded(

                                child: Text(

                                  item.name,

                                  style: TextStyle(

                                    color: _BudgetTheme.ink(context),

                                    fontSize: 14,

                                    fontWeight: FontWeight.w700,

                                  ),

                                ),

                              ),

                              Icon(

                                selected

                                    ? Icons.radio_button_checked_rounded

                                    : Icons.radio_button_off_rounded,

                                color: selected

                                    ? _BudgetTheme.accent(context)

                                    : _BudgetTheme.muted(context),

                              ),

                            ],

                          ),

                        ),

                      );

                    },

                  ),

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

}



class BudgetPreviewScreen extends StatefulWidget {

  const BudgetPreviewScreen({

    super.key,

    required this.category,

    required this.amount,

  });



  final BudgetCategory category;

  final double amount;



  @override

  State<BudgetPreviewScreen> createState() => _BudgetPreviewScreenState();

}



class _BudgetPreviewScreenState extends State<BudgetPreviewScreen> {

  bool _saving = false;



  Future<void> _confirm() async {

    if (_saving) return;

    setState(() => _saving = true);



    try {

      final now = DateTime.now();

      await FinancePlanService.instance.setBudget(

        now.year,

        now.month,

        _serviceCategory(widget.category.name),

        widget.amount,

      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(

        MaterialPageRoute<void>(

          builder: (_) => BudgetSuccessScreen(

            category: widget.category,

            amount: widget.amount,

          ),

        ),

      );

    } catch (e) {

      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text('Could not save budget: $e')),

      );

    }

  }



  void _edit() {

    Navigator.of(context).pushReplacement(

      MaterialPageRoute<void>(

        builder: (_) => SetMonthlyBudgetScreen(

          initialCategory: widget.category,

          initialAmount: widget.amount,

        ),

      ),

    );

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: _BudgetTheme.background(context),

      appBar: AppBar(

        elevation: 0,

        scrolledUnderElevation: 0,

        backgroundColor: _BudgetTheme.background(context),

        foregroundColor: _BudgetTheme.ink(context),

        title: Text(

          'Set Monthly Budget',

          style: TextStyle(

            color: _BudgetTheme.ink(context),

            fontWeight: FontWeight.w800,

          ),

        ),

      ),

      body: SafeArea(

        top: false,

        child: SingleChildScrollView(

          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Container(

                width: double.infinity,

                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(

                  color: _BudgetTheme.surface(context),

                  borderRadius: BorderRadius.circular(18),

                  border: Border.all(color: _BudgetTheme.border(context)),

                ),

                child: Row(

                  children: [

                    _CategoryIcon(category: widget.category, size: 62),

                    const SizedBox(width: 16),

                    Expanded(

                      child: Column(

                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          Text(

                            widget.category.name,

                            style: TextStyle(

                              color: _BudgetTheme.ink(context),

                              fontSize: 18,

                              fontWeight: FontWeight.w800,

                            ),

                          ),

                          const SizedBox(height: 5),

                          Text(

                            'Monthly limit',

                            style: TextStyle(

                              color: _BudgetTheme.muted(context),

                              fontSize: 12,

                            ),

                          ),

                          const SizedBox(height: 4),

                          Text(

                            _money(widget.amount),

                            style: TextStyle(

                              color: _BudgetTheme.ink(context),

                              fontSize: 23,

                              fontWeight: FontWeight.w800,

                            ),

                          ),

                        ],

                      ),

                    ),

                    TextButton.icon(

                      onPressed: _edit,

                      icon: Icon(

                        Icons.edit_rounded,

                        color: _BudgetTheme.accent(context),

                        size: 17,

                      ),

                      label: Text(

                        'Edit',

                        style: TextStyle(

                          color: _BudgetTheme.accent(context),

                          fontWeight: FontWeight.w700,

                        ),

                      ),

                    ),

                  ],

                ),

              ),

              const SizedBox(height: 28),

              _label(context, 'Spending breakdown (Example)'),

              const SizedBox(height: 14),

              ClipRRect(

                borderRadius: BorderRadius.circular(10),

                child: LinearProgressIndicator(

                  value: .5,

                  minHeight: 11,

                  color: _BudgetTheme.accent(context),

                  backgroundColor: _BudgetTheme.track(context),

                ),

              ),

              const SizedBox(height: 8),

              Row(

                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [

                  Text('0%', style: _small(context)),

                  Text('50%', style: _small(context)),

                  Text('100%', style: _small(context)),

                ],

              ),

              const SizedBox(height: 30),

              Container(

                width: double.infinity,

                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(

                  color: _BudgetTheme.surface(context),

                  borderRadius: BorderRadius.circular(18),

                  border: Border.all(color: _BudgetTheme.border(context)),

                ),

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Row(

                      children: [

                        const Text('💡', style: TextStyle(fontSize: 24)),

                        const SizedBox(width: 10),

                        Text(

                          'Tips',

                          style: TextStyle(

                            color: _BudgetTheme.ink(context),

                            fontSize: 16,

                            fontWeight: FontWeight.w800,

                          ),

                        ),

                      ],

                    ),

                    const SizedBox(height: 14),

                    _tip(context, 'Set realistic limits based on your past expenses.'),

                    _tip(context, 'You can edit or delete this budget anytime.'),

                    _tip(context, 'Track your spending to stay within the limit.'),

                  ],

                ),

              ),

              const SizedBox(height: 32),

              _GradientButton(

                text: _saving ? 'Saving...' : 'Confirm Budget',

                onTap: _saving ? null : _confirm,

              ),

            ],

          ),

        ),

      ),

    );

  }

}



class BudgetSuccessScreen extends StatelessWidget {

  const BudgetSuccessScreen({

    super.key,

    required this.category,

    required this.amount,

  });



  final BudgetCategory category;

  final double amount;



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: _BudgetTheme.background(context),

      body: SafeArea(

        child: Padding(

          padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),

          child: Column(

            mainAxisAlignment: MainAxisAlignment.center,

            children: [

              const Spacer(),

              SizedBox(

                width: 190,

                height: 190,

                child: Stack(

                  alignment: Alignment.center,

                  children: [

                    for (final data in const [

                      (Alignment(-.85, -.4), Color(0xFFFF72C8), 8.0),

                      (Alignment(.78, -.62), Color(0xFF7B5CFF), 9.0),

                      (Alignment(-.65, .65), Color(0xFF7B5CFF), 7.0),

                      (Alignment(.88, .35), Color(0xFFFFA52C), 8.0),

                      (Alignment(.10, -.94), Color(0xFF1ED4A3), 7.0),

                    ])

                      Align(

                        alignment: data.$1,

                        child: Container(

                          width: data.$3,

                          height: data.$3,

                          decoration: BoxDecoration(

                            color: data.$2,

                            borderRadius: BorderRadius.circular(3),

                          ),

                        ),

                      ),

                    Container(

                      width: 118,

                      height: 118,

                      decoration: BoxDecoration(

                        shape: BoxShape.circle,

                        gradient: LinearGradient(

                          begin: Alignment.topLeft,

                          end: Alignment.bottomRight,

                          colors: [

                            Color.lerp(_BudgetTheme.accent(context), Colors.white, .12)!,

                            _BudgetTheme.accent(context),

                          ],

                        ),

                        boxShadow: [

                          BoxShadow(

                            color: _BudgetTheme.accent(context).withValues(alpha: .27),

                            blurRadius: 28,

                            offset: Offset(0, 12),

                          ),

                        ],

                      ),

                      child: Icon(

                        Icons.check_rounded,

                        color: _BudgetTheme.onAccent(context),

                        size: 68,

                      ),

                    ),

                  ],

                ),

              ),

              const SizedBox(height: 24),

              Text(

                'Budget Set Successfully!',

                textAlign: TextAlign.center,

                style: TextStyle(

                  color: _BudgetTheme.ink(context),

                  fontSize: 24,

                  fontWeight: FontWeight.w900,

                ),

              ),

              const SizedBox(height: 14),

              Text(

                'You have set a monthly budget of',

                style: TextStyle(

                  color: _BudgetTheme.muted(context),

                  fontSize: 14,

                ),

              ),

              const SizedBox(height: 10),

              Text(

                _money(amount),

                style: TextStyle(

                  color: _BudgetTheme.accent(context),

                  fontSize: 34,

                  fontWeight: FontWeight.w900,

                ),

              ),

              const SizedBox(height: 9),

              Text(

                'for ${category.name} category',

                style: TextStyle(

                  color: _BudgetTheme.muted(context),

                  fontSize: 14,

                ),

              ),

              const Spacer(),

              _GradientButton(

                text: 'Go to Home',

                onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),

              ),

              const SizedBox(height: 12),

              SizedBox(

                width: double.infinity,

                height: 54,

                child: OutlinedButton(

                  onPressed: () {

                    Navigator.of(context).pushReplacement(

                      MaterialPageRoute<void>(

                        builder: (_) => const SetMonthlyBudgetScreen(),

                      ),

                    );

                  },

                  style: OutlinedButton.styleFrom(

                    foregroundColor: _BudgetTheme.ink(context),

                    side: BorderSide(color: _BudgetTheme.border(context)),

                    shape: RoundedRectangleBorder(

                      borderRadius: BorderRadius.circular(16),

                    ),

                  ),

                  child: const Text(

                    'Set Another Budget',

                    style: TextStyle(fontWeight: FontWeight.w700),

                  ),

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

}



class _PickerField extends StatelessWidget {

  const _PickerField({required this.text, required this.onTap});



  final String text;

  final VoidCallback onTap;



  @override

  Widget build(BuildContext context) {

    return InkWell(

      onTap: onTap,

      borderRadius: BorderRadius.circular(14),

      child: Container(

        width: double.infinity,

        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 19),

        decoration: BoxDecoration(

          color: _BudgetTheme.surface(context),

          borderRadius: BorderRadius.circular(14),

          border: Border.all(color: _BudgetTheme.border(context)),

        ),

        child: Row(

          children: [

            Expanded(

              child: Text(

                text,

                style: TextStyle(

                  color: _BudgetTheme.ink(context),

                  fontSize: 17,

                  fontWeight: FontWeight.w600,

                ),

              ),

            ),

            Icon(

              Icons.keyboard_arrow_down_rounded,

              color: _BudgetTheme.muted(context),

            ),

          ],

        ),

      ),

    );

  }

}



class _QuickAmountChip extends StatelessWidget {

  const _QuickAmountChip({required this.label, required this.onTap, this.selected = false});



  final String label;

  final VoidCallback onTap;

  final bool selected;



  @override

  Widget build(BuildContext context) {

    return InkWell(

      onTap: onTap,

      borderRadius: BorderRadius.circular(14),

      child: Container(

        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),

        decoration: BoxDecoration(

          color: selected

              ? _BudgetTheme.accent(context).withValues(alpha: .10)

              : _BudgetTheme.surfaceAlt(context),

          borderRadius: BorderRadius.circular(14),

          border: Border.all(

            color: selected ? _BudgetTheme.accent(context) : _BudgetTheme.border(context),

          ),

        ),

        child: Text(

          label,

          style: TextStyle(

            color: selected ? _BudgetTheme.accent(context) : _BudgetTheme.ink(context),

            fontWeight: FontWeight.w700,

          ),

        ),

      ),

    );

  }

}



class _CategoryIcon extends StatelessWidget {

  const _CategoryIcon({required this.category, required this.size});



  final BudgetCategory category;

  final double size;



  @override

  Widget build(BuildContext context) {

    return Container(

      width: size,

      height: size,

      decoration: BoxDecoration(

        color: category.color,

        shape: BoxShape.circle,

        boxShadow: [

          BoxShadow(

            color: category.color.withValues(alpha: .24),

            blurRadius: 14,

            offset: const Offset(0, 5),

          ),

        ],

      ),

      child: Icon(

        category.icon,

        color: Colors.white,

        size: size * .50,

      ),

    );

  }

}



class _GradientButton extends StatelessWidget {

  const _GradientButton({required this.text, required this.onTap});



  final String text;

  final VoidCallback? onTap;



  @override

  Widget build(BuildContext context) {

    final enabled = onTap != null;

    return Opacity(

      opacity: enabled ? 1 : .65,

      child: Container(

        width: double.infinity,

        height: 56,

        decoration: BoxDecoration(

          borderRadius: BorderRadius.circular(18),

          gradient: LinearGradient(

            begin: Alignment.centerLeft,

            end: Alignment.centerRight,

            colors: [

              Color.lerp(_BudgetTheme.accent(context), Colors.white, .11)!,

              _BudgetTheme.accent(context),

            ],

          ),

          boxShadow: [

            BoxShadow(

              color: _BudgetTheme.accent(context).withValues(alpha: .20),

              blurRadius: 18,

              offset: Offset(0, 8),

            ),

          ],

        ),

        child: Material(

          color: Colors.transparent,

          child: InkWell(

            onTap: onTap,

            borderRadius: BorderRadius.circular(18),

            child: Center(

              child: Text(

                text,

                style: TextStyle(

                  color: _BudgetTheme.onAccent(context),

                  fontSize: 15,

                  fontWeight: FontWeight.w800,

                ),

              ),

            ),

          ),

        ),

      ),

    );

  }

}



Widget _label(BuildContext context, String text) => Text(

      text,

      style: TextStyle(

        color: _BudgetTheme.ink(context),

        fontSize: 14,

        fontWeight: FontWeight.w800,

      ),

    );



OutlineInputBorder _outline(

  BuildContext context, {

  Color? color,

  double width = 1,

}) =>

    OutlineInputBorder(

      borderRadius: BorderRadius.circular(14),

      borderSide: BorderSide(

        color: color ?? _BudgetTheme.border(context),

        width: width,

      ),

    );



TextStyle _small(BuildContext context) => TextStyle(

      color: _BudgetTheme.muted(context),

      fontSize: 11,

      fontWeight: FontWeight.w600,

    );



Widget _tip(BuildContext context, String text) => Padding(

      padding: const EdgeInsets.only(bottom: 12),

      child: Row(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Padding(

            padding: const EdgeInsets.only(top: 7),

            child: Container(

              width: 5,

              height: 5,

              decoration: BoxDecoration(

                color: _BudgetTheme.muted(context),

                shape: BoxShape.circle,

              ),

            ),

          ),

          const SizedBox(width: 10),

          Expanded(

            child: Text(

              text,

              style: TextStyle(

                color: _BudgetTheme.muted(context),

                height: 1.45,

                fontSize: 12.5,

              ),

            ),

          ),

        ],

      ),

    );



String _money(num value) {
  return CurrencyService.instance.formatAmount(
    value,
    decimal: value.abs() % 1 != 0,
  );
}






String _serviceCategory(String category) {

  switch (category) {

    case 'Bills & Utilities':

      return 'Bills';

    case 'Health & Medical':

      return 'Health';

    case 'Personal Care':

      return 'Other';

    case 'Travel':

      return 'Transport';

    case 'Others':

      return 'Other';

    default:

      return category;

  }

}
