import 'dart:math' as math;



import 'package:flutter/material.dart';



import '../services/finance_plan_service.dart';

import '../services/transaction_service.dart';
import '../services/currency_service.dart';



const _green = Color(0xFF11AD83);



// Uses the MaterialApp themeMode (Light / Dark / System Default).

Color _accent(BuildContext context) => Theme.of(context).colorScheme.primary;

Color _onAccent(BuildContext context) =>

    ThemeData.estimateBrightnessForColor(_accent(context)) == Brightness.dark

        ? Colors.white

        : const Color(0xFF101936);

bool _isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

Color _ink(BuildContext context) => _isDark(context) ? const Color(0xFFF0F1FC) : const Color(0xFF071536);

Color _hint(BuildContext context) => _isDark(context) ? const Color(0xFFACB4CB) : const Color(0xFF7D879D);

Color _canvas(BuildContext context) => _isDark(context) ? const Color(0xFF10111D) : const Color(0xFFF7F8FD);

Color _surface(BuildContext context) => _isDark(context) ? const Color(0xFF1B1D2E) : Colors.white;

Color _soft(BuildContext context) => Color.alphaBlend(

  _accent(context).withValues(alpha: _isDark(context) ? .12 : .07),

  _surface(context),

);

Color _line(BuildContext context) => _isDark(context) ? const Color(0xFF35374C) : const Color(0xFFE8EBF3);



String _money(num value) {
  return CurrencyService.instance.formatAmount(
    value,
    decimal: value.abs() % 1 != 0,
  );
}



String _date(DateTime? d) =>

    d == null ? 'No target date' : '${d.day}/${d.month}/${d.year}';

const _categories = <String, IconData>{

  'Custom': Icons.track_changes_rounded,

  'Laptop': Icons.laptop_mac_rounded,

  'Vacation': Icons.beach_access_rounded,

  'Car': Icons.directions_car_rounded,

  'Home': Icons.home_rounded,

  'Education': Icons.school_rounded,

  'Emergency': Icons.health_and_safety_rounded,

  'Others': Icons.more_horiz_rounded,

};

IconData _icon(String category) =>

    _categories[category] ?? Icons.savings_rounded;



class GoalsScreen extends StatefulWidget {

  const GoalsScreen({super.key});

  @override

  State<GoalsScreen> createState() => _GoalsScreenState();

}



class _GoalsScreenState extends State<GoalsScreen> {

  final store = FinancePlanService.instance;

  final transactions = TransactionService.instance;
  final currency = CurrencyService.instance;

  String filter = 'All';

  bool busy = false;

  @override

  void initState() {

    super.initState();

    store.addListener(_refresh);

    transactions.addListener(_refresh);
    currency.addListener(_refresh);

    Future.wait([store.initialize(), transactions.initialize()])

        .then((_) => _refresh())

        .catchError((Object e) => _message('$e'));

  }



  void _refresh() {

    if (mounted) setState(() {});

  }



  @override

  void dispose() {

    store.removeListener(_refresh);

    transactions.removeListener(_refresh);
    currency.removeListener(_refresh);

    super.dispose();

  }



  void _message(String message) {

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),

    );

  }



  Future<T?> _page<T>(Widget screen) =>

      Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => screen));

  Future<void> _create() async {

    final id = await _page<String>(GoalFormScreen());

    if (!mounted || id == null) return;

    final goal = store.goalById(id);

    if (goal != null) await _details(goal.id);

  }



  Future<void> _details(String id) async {

    await _page<void>(GoalDetailsScreen(goalId: id));

  }



  @override

  Widget build(BuildContext context) {

    final all = store.goals;

    final goals = all

        .where(

          (g) =>

              filter == 'All' ||

              (filter == 'Active' ? !g.completed : g.completed),

        )

        .toList();

    final total = all.fold<double>(0, (v, g) => v + g.target);

    final saved = store.totalGoalSavings;



    // Show the onboarding layout only until the first goal is created.

    // Existing goal cards and all create/edit/transfer flows remain intact.

    if (all.isEmpty) {

      return Scaffold(

        backgroundColor: _canvas(context),

        body: SafeArea(

          bottom: false,

          child: Padding(

            padding: const EdgeInsets.fromLTRB(22, 18, 22, 110),

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text('Goals', style: _headingStyle(context)),

                Expanded(

                  child: Center(

                    child: SingleChildScrollView(

                      child: Column(

                        mainAxisSize: MainAxisSize.min,

                        children: [

                          SizedBox(

                            width: 220,

                            height: 175,

                            child: Stack(

                              alignment: Alignment.center,

                              children: [

                                Positioned(

                                  left: 5,

                                  top: 90,

                                  child: Icon(

                                    Icons.cloud_rounded,

                                    size: 44,

                                    color: _accent(context).withValues(alpha: 0.10),

                                  ),

                                ),

                                Positioned(

                                  right: 5,

                                  top: 45,

                                  child: Icon(

                                    Icons.cloud_rounded,

                                    size: 48,

                                    color: _accent(context).withValues(alpha: 0.10),

                                  ),

                                ),

                                Container(

                                  width: 145,

                                  height: 145,

                                  decoration: BoxDecoration(

                                    color: _accent(context).withValues(alpha: 0.07),

                                    shape: BoxShape.circle,

                                  ),

                                  child: Icon(

                                    Icons.track_changes_rounded,

                                    size: 112,

                                    color: _accent(context),

                                  ),

                                ),

                                Positioned(

                                  right: 29,

                                  top: 8,

                                  child: Transform.rotate(

                                    angle: -0.35,

                                    child: Icon(

                                      Icons.north_east_rounded,

                                      size: 53,

                                      color: _accent(context),

                                    ),

                                  ),

                                ),

                              ],

                            ),

                          ),

                          const SizedBox(height: 22),

                          Text(

                            'No Goals Yet',

                            textAlign: TextAlign.center,

                            style: TextStyle(

                              fontSize: 25,

                              fontWeight: FontWeight.w800,

                              color: _ink(context),

                            ),

                          ),

                          const SizedBox(height: 12),

                          Text(

                            'Set your first goal and start\n'

                            'building a better tomorrow.',

                            textAlign: TextAlign.center,

                            style: TextStyle(

                              fontSize: 15,

                              height: 1.5,

                              color: _hint(context),

                            ),

                          ),

                          const SizedBox(height: 35),

                          ConstrainedBox(

                            constraints: const BoxConstraints(maxWidth: 285),

                            child: const Column(

                              children: [

                                _EmptyGoalBenefit('Save for your dreams'),

                                SizedBox(height: 17),

                                _EmptyGoalBenefit('Stay motivated'),

                                SizedBox(height: 17),

                                _EmptyGoalBenefit('Track your progress'),

                              ],

                            ),

                          ),

                        ],

                      ),

                    ),

                  ),

                ),

                const SizedBox(height: 12),

                _button(context, '＋  Create Your First Goal', _create),

              ],

            ),

          ),

        ),

      );

    }



    return Scaffold(

      backgroundColor: _canvas(context),

      body: SafeArea(

        bottom: false,

        child: ListView(

          padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),

          children: [

            Row(

              children: [

                Expanded(child: Text('Goals', style: _headingStyle(context))),

                FilledButton.icon(

                  onPressed: _create,

                  icon: const Icon(Icons.add, size: 19),

                  label: const Text('Add Goal'),

                  style: _filled(context),

                ),

              ],

            ),

            const SizedBox(height: 18),

            Row(

              children: [

                Expanded(

                  flex: 3,

                  child: _card(context,

                    Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Text(

                          'Total Goal Savings',

                          style: TextStyle(color: _hint(context), fontSize: 12),

                        ),

                        const SizedBox(height: 7),

                        Text(

                          _money(saved),

                          style: TextStyle(

                            fontSize: 22,

                            fontWeight: FontWeight.w800,

                            color: _ink(context),

                          ),

                        ),

                        Text(

                          'of ${_money(total)}',

                          style: TextStyle(fontSize: 12, color: _hint(context)),

                        ),

                        const SizedBox(height: 12),

                        _bar(context, total == 0 ? 0 : saved / total, _green),

                        const SizedBox(height: 5),

                        Text(

                          '${total == 0 ? 0 : (saved / total * 100).round()}% saved',

                          style: TextStyle(fontSize: 11, color: _hint(context)),

                        ),

                      ],

                    ),

                  ),

                ),

                const SizedBox(width: 10),

                Expanded(

                  flex: 2,

                  child: _card(context,

                    Column(

                      children: [

                        const Icon(

                          Icons.track_changes_rounded,

                          color: _green,

                          size: 30,

                        ),

                        const SizedBox(height: 9),

                        Text(

                          '${all.where((g) => !g.completed).length}',

                          style: TextStyle(

                            fontSize: 24,

                            fontWeight: FontWeight.w800,

                            color: _ink(context),

                          ),

                        ),

                        Text(

                          'Active Goals',

                          style: TextStyle(fontSize: 12, color: _hint(context)),

                        ),

                        const SizedBox(height: 10),

                        Text(

                          'Available ${_money(store.availableBalance)}',

                          textAlign: TextAlign.center,

                          style: TextStyle(fontSize: 10, color: _accent(context)),

                        ),

                      ],

                    ),

                  ),

                ),

              ],

            ),

            const SizedBox(height: 15),

            _segments(context,

              ['All', 'Active', 'Completed'],

              filter,

              (s) => setState(() => filter = s),

            ),

            const SizedBox(height: 16),

            if (goals.isEmpty)

              _card(context,

                Text(

                  'No ${filter.toLowerCase()} goals yet.',

                  style: TextStyle(color: _hint(context)),

                ),

              )

            else

              ...goals.map(

                (g) => Padding(

                  key: ValueKey(g.id),

                  padding: const EdgeInsets.only(bottom: 12),

                  child: InkWell(

                    borderRadius: BorderRadius.circular(20),

                    onTap: () => _details(g.id),

                    child: _card(context,

                      Column(

                        children: [

                          Row(

                            children: [

                              _badge(context, g.category),

                              const SizedBox(width: 12),

                              Expanded(

                                child: Column(

                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [

                                    Text(

                                      g.name,

                                      style: TextStyle(

                                        fontWeight: FontWeight.w800,

                                        color: _ink(context),

                                      ),

                                    ),

                                    const SizedBox(height: 4),

                                    Text(

                                      '${_money(g.saved)} of ${_money(g.target)}',

                                      style: TextStyle(

                                        color: _hint(context),

                                        fontSize: 12,

                                      ),

                                    ),

                                  ],

                                ),

                              ),

                              Text(

                                '${(g.progress.clamp(0.0, 1.0) * 100).round()}%',

                                style: TextStyle(

                                  color: _accent(context),

                                  fontWeight: FontWeight.w800,

                                ),

                              ),

                            ],

                          ),

                          const SizedBox(height: 11),

                          _bar(context, g.progress, g.completed ? _green : _accent(context)),

                          if (g.completed)

                            const Padding(

                              padding: EdgeInsets.only(top: 6),

                              child: Text(

                                '✓ Goal achieved!',

                                style: TextStyle(color: _green, fontSize: 12),

                              ),

                            ),

                        ],

                      ),

                    ),

                  ),

                ),

              ),

          ],

        ),

      ),

    );

  }

}



class _EmptyGoalBenefit extends StatelessWidget {

  const _EmptyGoalBenefit(this.label);



  final String label;



  @override

  Widget build(BuildContext context) {

    return Row(

      children: [

        const Icon(Icons.check_circle_rounded, color: _green, size: 23),

        const SizedBox(width: 13),

        Expanded(

          child: Text(

            label,

            style: TextStyle(

              fontSize: 15,

              fontWeight: FontWeight.w600,

              color: _ink(context),

            ),

          ),

        ),

      ],

    );

  }

}



TextStyle _headingStyle(BuildContext context) => TextStyle(

  fontSize: 25,

  fontWeight: FontWeight.w800,

  color: _ink(context),

);

TextStyle _sectionStyle(BuildContext context) => TextStyle(

  fontSize: 18,

  fontWeight: FontWeight.w800,

  color: _ink(context),

);

ButtonStyle _filled(BuildContext context) => FilledButton.styleFrom(

  backgroundColor: _accent(context),

  foregroundColor: _onAccent(context),

  minimumSize: const Size(0, 48),

  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

);

Widget _card(BuildContext context, Widget child) => Container(

  width: double.infinity,

  padding: const EdgeInsets.all(16),

  decoration: BoxDecoration(

    color: _surface(context),

    borderRadius: BorderRadius.circular(20),

    boxShadow: const [

      BoxShadow(color: Color(0x0A151D46), blurRadius: 18, offset: Offset(0, 5)),

    ],

  ),

  child: child,

);

Widget _bar(BuildContext context, double value, Color color) => ClipRRect(

  borderRadius: BorderRadius.circular(12),

  child: LinearProgressIndicator(

    value: value.clamp(0.0, 1.0),

    minHeight: 7,

    color: color,

    backgroundColor: _line(context),

  ),

);

Widget _badge(BuildContext context, String category, {double size = 48}) => Container(

  width: size,

  height: size,

  decoration: BoxDecoration(

    color: _soft(context),

    borderRadius: BorderRadius.circular(14),

  ),

  child: Icon(_icon(category), color: _accent(context), size: size * .5),

);

Widget _button(BuildContext context, String text, VoidCallback? action, {bool outline = false}) =>

    SizedBox(

      width: double.infinity,

      child: outline

          ? OutlinedButton(

              onPressed: action,

              style: OutlinedButton.styleFrom(

                minimumSize: const Size(0, 49),

                side: BorderSide(color: _accent(context)),

                foregroundColor: _accent(context),

                shape: RoundedRectangleBorder(

                  borderRadius: BorderRadius.circular(12),

                ),

              ),

              child: Text(text),

            )

          : FilledButton(onPressed: action, style: _filled(context), child: Text(text)),

    );

Widget _segments(BuildContext context,

  List<String> values,

  String selected,

  ValueChanged<String> onSelect,

) => Container(

  padding: const EdgeInsets.all(4),

  decoration: BoxDecoration(

    color: _soft(context),

    borderRadius: BorderRadius.circular(14),

  ),

  child: Row(

    children: values

        .map(

          (v) => Expanded(

            child: InkWell(

              onTap: () => onSelect(v),

              borderRadius: BorderRadius.circular(11),

              child: Container(

                padding: const EdgeInsets.symmetric(vertical: 12),

                decoration: BoxDecoration(

                  color: v == selected ? _accent(context) : Colors.transparent,

                  borderRadius: BorderRadius.circular(11),

                ),

                child: Text(

                  v,

                  textAlign: TextAlign.center,

                  style: TextStyle(

                    color: v == selected ? _onAccent(context) : _ink(context),

                    fontSize: 12,

                    fontWeight: FontWeight.w700,

                  ),

                ),

              ),

            ),

          ),

        )

        .toList(),

  ),

);

InputDecoration _input(BuildContext context, String label, {String? hint}) => InputDecoration(

  labelText: label,

  hintText: hint,

  filled: true,

  fillColor: _surface(context),

  border: OutlineInputBorder(

    borderRadius: BorderRadius.circular(12),

    borderSide: BorderSide(color: _line(context)),

  ),

  enabledBorder: OutlineInputBorder(

    borderRadius: BorderRadius.circular(12),

    borderSide: BorderSide(color: _line(context)),

  ),

);

void _snack(BuildContext context, Object e) {

  if (context.mounted) {

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));

  }

}



class GoalFormScreen extends StatefulWidget {

  const GoalFormScreen({super.key, this.goalId});

  final String? goalId;

  @override

  State<GoalFormScreen> createState() => _GoalFormScreenState();

}



class _GoalFormScreenState extends State<GoalFormScreen> {

  final store = FinancePlanService.instance;

  final name = TextEditingController(),

      target = TextEditingController(),

      notes = TextEditingController();

  String category = 'Custom';

  DateTime? date;

  bool saving = false;

  @override

  void initState() {

    super.initState();

    final g = widget.goalId == null ? null : store.goalById(widget.goalId!);

    if (g != null) {

      name.text = g.name;

      target.text = g.target.toStringAsFixed(0);

      notes.text = g.note;

      category = g.category;

      date = g.targetDate;

    }

  }



  @override

  void dispose() {

    name.dispose();

    target.dispose();

    notes.dispose();

    super.dispose();

  }



  Future<void> _save() async {

    final amount = double.tryParse(target.text.trim());

    if (name.text.trim().isEmpty ||

        amount == null ||

        !amount.isFinite ||

        amount <= 0) {

      _snack(context, 'Enter a valid name and target amount.');

      return;

    }

    setState(() => saving = true);

    try {

      if (widget.goalId == null) {

        await store.addGoal(name.text, category, amount, date);

        final created = store.goals.last;

        if (notes.text.trim().isNotEmpty) {

          await store.editGoal(

            created.id,

            name: created.name,

            category: created.category,

            target: created.target,

            targetDate: created.targetDate,

            note: notes.text,

          );

        }

        if (mounted) Navigator.pop(context, created.id);

      } else {

        await store.editGoal(

          widget.goalId!,

          name: name.text,

          category: category,

          target: amount,

          targetDate: date,

          note: notes.text,

        );

        if (mounted) Navigator.pop(context, widget.goalId);

      }

    } catch (e) {

      if (mounted) _snack(context, e);

    } finally {

      if (mounted) setState(() => saving = false);

    }

  }



  @override

  Widget build(BuildContext context) => Scaffold(

    backgroundColor: _canvas(context),

    appBar: AppBar(

      title: Text(widget.goalId == null ? 'Create Goal' : 'Edit Goal'),

      backgroundColor: _canvas(context),

    ),

    body: SafeArea(

      child: ListView(

        padding: const EdgeInsets.all(18),

        children: [

          _card(context,

            Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text('Choose a category', style: _sectionStyle(context)),

                const SizedBox(height: 14),

                Wrap(

                  spacing: 9,

                  runSpacing: 12,

                  children: _categories.entries

                      .map(

                        (e) => InkWell(

                          onTap: () => setState(() => category = e.key),

                          child: Container(

                            width: 72,

                            padding: const EdgeInsets.symmetric(vertical: 9),

                            decoration: BoxDecoration(

                              color: category == e.key

                                  ? _soft(context)

                                  : _canvas(context),

                              borderRadius: BorderRadius.circular(12),

                              border: Border.all(

                                color: category == e.key

                                    ? _accent(context)

                                    : Colors.transparent,

                              ),

                            ),

                            child: Column(

                              children: [

                                Icon(e.value, color: _accent(context)),

                                const SizedBox(height: 5),

                                Text(

                                  e.key,

                                  style: TextStyle(

                                    fontSize: 10,

                                    color: _ink(context),

                                  ),

                                ),

                              ],

                            ),

                          ),

                        ),

                      )

                      .toList(),

                ),

                const SizedBox(height: 16),

                TextField(

                  controller: name,

                  decoration: _input(context, 'Goal Name', hint: 'e.g. New Laptop'),

                ),

                const SizedBox(height: 12),

                TextField(

                  controller: target,

                  keyboardType: const TextInputType.numberWithOptions(

                    decimal: true,

                  ),

                  decoration: _input(context, 'Target Amount (${CurrencyService.instance.symbol})'),

                ),

                const SizedBox(height: 12),

                OutlinedButton.icon(

                  onPressed: () async {

                    final d = await showDatePicker(

                      context: context,

                      initialDate: date ?? DateTime.now(),

                      firstDate: DateTime(2000),

                      lastDate: DateTime(2100),

                    );

                    if (d != null && mounted) setState(() => date = d);

                  },

                  icon: const Icon(Icons.calendar_month),

                  label: Text(

                    date == null

                        ? 'Select Target Date (Optional)'

                        : _date(date),

                  ),

                ),

                const SizedBox(height: 12),

                TextField(

                  controller: notes,

                  maxLines: 2,

                  decoration: _input(context, 'Notes (Optional)'),

                ),

                const SizedBox(height: 8),

                Text(

                  'Category icons are stored offline. Custom photo uploads are not enabled in this version.',

                  style: TextStyle(fontSize: 11, color: _hint(context)),

                ),

                const SizedBox(height: 20),

                _button(context,

                  saving

                      ? 'Saving...'

                      : widget.goalId == null

                      ? 'Create Goal'

                      : 'Update Goal',

                  saving ? null : _save,

                ),

              ],

            ),

          ),

        ],

      ),

    ),

  );

}



class GoalDetailsScreen extends StatefulWidget {

  const GoalDetailsScreen({super.key, required this.goalId});

  final String goalId;

  @override

  State<GoalDetailsScreen> createState() => _GoalDetailsScreenState();

}



class _GoalDetailsScreenState extends State<GoalDetailsScreen> {

  final store = FinancePlanService.instance;

  @override

  void initState() {

    super.initState();

    store.addListener(_refresh);

  }



  void _refresh() {

    if (mounted) setState(() {});

  }



  @override

  void dispose() {

    store.removeListener(_refresh);

    super.dispose();

  }



  Future<void> _move(bool withdraw) async {

    final result = await Navigator.push<bool>(

      context,

      MaterialPageRoute(

        builder: (_) =>

            GoalTransferScreen(goalId: widget.goalId, withdraw: withdraw),

      ),

    );

    if (result == true && mounted) {

      final g = store.goalById(widget.goalId);

      if (g != null) {

        await Navigator.push<void>(

          context,

          MaterialPageRoute(

            builder: (_) => GoalSuccessScreen(

              goalId: widget.goalId,

              completed: g.completed,

            ),

          ),

        );

      }

    }

  }



  Future<void> _delete() async {

    final g = store.goalById(widget.goalId);

    if (g == null) return;

    final yes = await showModalBottomSheet<bool>(

      context: context,

      backgroundColor: Colors.transparent,

      builder: (ctx) => Container(

        padding: const EdgeInsets.all(24),

        decoration: BoxDecoration(

          color: _surface(context),

          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),

        ),

        child: SafeArea(

          top: false,

          child: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              const Icon(

                Icons.delete_outline_rounded,

                color: Colors.red,

                size: 42,

              ),

              const SizedBox(height: 12),

              Text('Delete Goal?', style: _sectionStyle(context)),

              const SizedBox(height: 10),

              Text(

                'Delete ${g.name}? ${_money(g.saved)} of reserved savings will return to your available balance. This action cannot be undone.',

                textAlign: TextAlign.center,

              ),

              const SizedBox(height: 20),

              _button(context, 'Delete Goal', () => Navigator.pop(ctx, true)),

              _button(context, 'Cancel', () => Navigator.pop(ctx, false), outline: true),

            ],

          ),

        ),

      ),

    );

    if (yes != true || !mounted) return;

    try {

      await store.deleteGoal(widget.goalId);

      if (mounted) Navigator.pop(context);

    } catch (e) {

      if (mounted) _snack(context, e);

    }

  }



  @override

  Widget build(BuildContext context) {

    final g = store.goalById(widget.goalId);

    if (g == null) {

      return Scaffold(

        appBar: AppBar(),

        body: const Center(child: Text('Goal not found')),

      );

    }

    final remaining = math.max(0.0, g.target - g.saved);

    return Scaffold(

      backgroundColor: _canvas(context),

      appBar: AppBar(

        backgroundColor: _canvas(context),

        actions: [

          IconButton(

            onPressed: () async {

              await Navigator.push<void>(

                context,

                MaterialPageRoute(builder: (_) => GoalFormScreen(goalId: g.id)),

              );

            },

            icon: const Icon(Icons.edit_outlined),

          ),

          PopupMenuButton<String>(

            onSelected: (v) {

              if (v == 'delete') _delete();

              if (v == 'analytics') {

                Navigator.push<void>(

                  context,

                  MaterialPageRoute(

                    builder: (_) => GoalAnalyticsScreen(goalId: g.id),

                  ),

                );

              }

            },

            itemBuilder: (_) => [

              const PopupMenuItem(

                value: 'analytics',

                child: Text('Goal Analytics'),

              ),

              const PopupMenuItem(value: 'delete', child: Text('Delete Goal')),

            ],

          ),

        ],

      ),

      body: SafeArea(

        child: ListView(

          padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),

          children: [

            _card(context,

              Column(

                children: [

                  _badge(context, g.category, size: 80),

                  const SizedBox(height: 12),

                  Text(g.name, style: _headingStyle(context)),

                  const SizedBox(height: 5),

                  Text(g.category, style: TextStyle(color: _hint(context))),

                  const SizedBox(height: 20),

                  Text(

                    '${_money(g.saved)} of ${_money(g.target)}',

                    style: _sectionStyle(context),

                  ),

                  const SizedBox(height: 10),

                  _bar(context, g.progress, _green),

                  const SizedBox(height: 7),

                  Text(

                    '${(g.progress * 100).round()}% complete',

                    style: TextStyle(color: _hint(context)),

                  ),

                  const SizedBox(height: 20),

                  Row(

                    mainAxisAlignment: MainAxisAlignment.spaceAround,

                    children: [

                      _stat(context, 'Saved', _money(g.saved)),

                      _stat(context, 'Remaining', _money(remaining)),

                      _stat(context,

                        'Days Left',

                        g.targetDate == null

                            ? '—'

                            : '${math.max(0, g.targetDate!.difference(DateTime.now()).inDays)}',

                      ),

                    ],

                  ),

                ],

              ),

            ),

            const SizedBox(height: 14),

            _card(context,

              Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text('Target Date', style: _sectionStyle(context)),

                  const SizedBox(height: 8),

                  Text(_date(g.targetDate)),

                  const SizedBox(height: 16),

                  Text('Notes', style: _sectionStyle(context)),

                  const SizedBox(height: 8),

                  Text(g.note.isEmpty ? 'No notes added' : g.note),

                ],

              ),

            ),

            const SizedBox(height: 14),

            _button(context,

              'View Goal Analytics',

              () => Navigator.push<void>(

                context,

                MaterialPageRoute(

                  builder: (_) => GoalAnalyticsScreen(goalId: g.id),

                ),

              ),

              outline: true,

            ),

            const SizedBox(height: 8),

            if (!g.completed) _button(context, 'Add Money', () => _move(false)),

            const SizedBox(height: 8),

            _button(context,

              'Withdraw',

              g.saved <= 0 ? null : () => _move(true),

              outline: true,

            ),

            if (g.completed)

              Padding(

                padding: const EdgeInsets.only(top: 10),

                child: _button(context,

                  '🏆 Goal Achieved',

                  () => Navigator.push<void>(

                    context,

                    MaterialPageRoute(

                      builder: (_) =>

                          GoalSuccessScreen(goalId: g.id, completed: true),

                    ),

                  ),

                ),

              ),

          ],

        ),

      ),

    );

  }

}



Widget _stat(BuildContext context, String title, String value) => Column(

  children: [

    Text(

      value,

      style: TextStyle(color: _ink(context), fontWeight: FontWeight.w800),

    ),

    const SizedBox(height: 5),

    Text(title, style: TextStyle(color: _hint(context), fontSize: 11)),

  ],

);



class GoalTransferScreen extends StatefulWidget {

  const GoalTransferScreen({

    super.key,

    required this.goalId,

    required this.withdraw,

  });

  final String goalId;

  final bool withdraw;

  @override

  State<GoalTransferScreen> createState() => _GoalTransferScreenState();

}



class _GoalTransferScreenState extends State<GoalTransferScreen> {

  final amount = TextEditingController(), note = TextEditingController();

  late bool withdraw = widget.withdraw;

  String method = 'Other';

  DateTime date = DateTime.now();

  bool saving = false;

  @override

  void dispose() {

    amount.dispose();

    note.dispose();

    super.dispose();

  }



  Future<void> _save() async {

    final v = double.tryParse(amount.text.trim());

    if (v == null || !v.isFinite || v <= 0) {

      _snack(context, 'Enter a valid amount');

      return;

    }

    setState(() => saving = true);

    try {

      await FinancePlanService.instance.changeSavings(

        widget.goalId,

        withdraw ? -v : v,

        paymentMethod: method,

        date: date,

        note: note.text,

      );

      if (mounted) Navigator.pop(context, true);

    } catch (e) {

      if (!mounted) return;

      _snack(context, e);

    } finally {

      if (mounted) setState(() => saving = false);

    }

  }



  @override

  Widget build(BuildContext context) {

    final g = FinancePlanService.instance.goalById(widget.goalId);

    if (g == null) {

      return Scaffold(

        appBar: AppBar(),

        body: const Center(child: Text('Goal not found')),

      );

    }

    return Scaffold(

      backgroundColor: _canvas(context),

      appBar: AppBar(

        title: Text(withdraw ? 'Withdraw from Goal' : 'Add to Goal'),

        backgroundColor: _canvas(context),

      ),

      body: SafeArea(

        child: ListView(

          padding: const EdgeInsets.all(18),

          children: [

            _card(context,

              Row(

                children: [

                  _badge(context, g.category),

                  const SizedBox(width: 12),

                  Expanded(

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Text(g.name, style: _sectionStyle(context)),

                        Text(

                          '${_money(g.saved)} / ${_money(g.target)}',

                          style: TextStyle(color: _hint(context)),

                        ),

                      ],

                    ),

                  ),

                ],

              ),

            ),

            const SizedBox(height: 15),

            _segments(context,

              ['Add Money', 'Withdraw'],

              withdraw ? 'Withdraw' : 'Add Money',

              (s) => setState(() => withdraw = s == 'Withdraw'),

            ),

            const SizedBox(height: 15),

            _card(context,

              Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(

                    withdraw

                        ? 'Saved: ${_money(g.saved)}'

                        : 'Available: ${_money(FinancePlanService.instance.availableBalance)}',

                    style: TextStyle(color: _hint(context)),

                  ),

                  const SizedBox(height: 12),

                  TextField(

                    controller: amount,

                    keyboardType: const TextInputType.numberWithOptions(

                      decimal: true,

                    ),

                    decoration: _input(context, 'Amount (${CurrencyService.instance.symbol})'),

                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(

                    initialValue: method,

                    decoration: _input(context, 'Payment Method (for your records)'),

                    items: ['Other', 'Cash', 'Bank Account', 'UPI']

                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))

                        .toList(),

                    onChanged: (v) => setState(() => method = v ?? 'Other'),

                  ),

                  const SizedBox(height: 12),

                  OutlinedButton.icon(

                    onPressed: () async {

                      final d = await showDatePicker(

                        context: context,

                        initialDate: date,

                        firstDate: DateTime(2000),

                        lastDate: DateTime(2100),

                      );

                      if (d != null && mounted) setState(() => date = d);

                    },

                    icon: const Icon(Icons.calendar_month),

                    label: Text(_date(date)),

                  ),

                  const SizedBox(height: 12),

                  TextField(

                    controller: note,

                    decoration: _input(context, 'Note (Optional)'),

                  ),

                  const SizedBox(height: 18),

                  _button(context,

                    saving

                        ? 'Saving...'

                        : withdraw

                        ? 'Withdraw from Goal'

                        : 'Add to Goal',

                    saving ? null : _save,

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



class GoalSuccessScreen extends StatelessWidget {

  const GoalSuccessScreen({

    super.key,

    required this.goalId,

    required this.completed,

  });

  final String goalId;

  final bool completed;

  @override

  Widget build(BuildContext context) {

    final g = FinancePlanService.instance.goalById(goalId);

    return Scaffold(

      backgroundColor: _surface(context),

      body: SafeArea(

        child: Padding(

          padding: const EdgeInsets.all(24),

          child: Column(

            mainAxisAlignment: MainAxisAlignment.center,

            children: [

              Icon(

                completed

                    ? Icons.emoji_events_rounded

                    : Icons.check_circle_rounded,

                size: 110,

                color: _green,

              ),

              const SizedBox(height: 22),

              Text(

                completed ? 'Goal Achieved!' : 'Money Updated!',

                style: _headingStyle(context),

              ),

              const SizedBox(height: 12),

              Text(

                completed

                    ? 'Congratulations! You have reached your goal.'

                    : 'Your goal savings have been updated.',

                textAlign: TextAlign.center,

                style: TextStyle(color: _hint(context)),

              ),

              const SizedBox(height: 25),

              if (g != null)

                _card(context,

                  Column(

                    children: [

                      Row(

                        children: [

                          _badge(context, g.category),

                          const SizedBox(width: 12),

                          Expanded(child: Text(g.name, style: _sectionStyle(context))),

                        ],

                      ),

                      const SizedBox(height: 15),

                      Text(

                        '${_money(g.saved)} of ${_money(g.target)}',

                        style: _sectionStyle(context),

                      ),

                      const SizedBox(height: 9),

                      _bar(context, g.progress, _green),

                    ],

                  ),

                ),

              const SizedBox(height: 28),

              _button(context, 'View Goal', () => Navigator.pop(context)),

              const SizedBox(height: 9),

              _button(context, 'Back to Goals', () {

                Navigator.pop(context);

                Navigator.pop(context);

              }, outline: true),

            ],

          ),

        ),

      ),

    );

  }

}



class GoalAnalyticsScreen extends StatefulWidget {

  const GoalAnalyticsScreen({super.key, required this.goalId});

  final String goalId;

  @override

  State<GoalAnalyticsScreen> createState() => _GoalAnalyticsScreenState();

}



class _GoalAnalyticsScreenState extends State<GoalAnalyticsScreen> {

  String tab = 'Overview';

  @override

  Widget build(BuildContext context) {

    final store = FinancePlanService.instance;

    final g = store.goalById(widget.goalId);

    if (g == null) {

      return Scaffold(

        appBar: AppBar(),

        body: const Center(child: Text('Goal not found')),

      );

    }

    final entries = store.contributionsFor(g.id);

    final deposits = entries

        .where((e) => e.amount > 0)

        .fold<double>(0, (sum, e) => sum + e.amount);

    final withdrawals = entries

        .where((e) => e.amount < 0)

        .fold<double>(0, (sum, e) => sum - e.amount);

    final trackedNet = deposits - withdrawals;

    final opening =

        g.saved - trackedNet; // Existing savings before history tracking began.

    return Scaffold(

      backgroundColor: _canvas(context),

      appBar: AppBar(title: const Text('Goal Analytics'), backgroundColor: _canvas(context)),

      body: SafeArea(

        child: ListView(

          padding: const EdgeInsets.all(18),

          children: [

            _card(context,

              Row(

                children: [

                  _badge(context, g.category),

                  const SizedBox(width: 12),

                  Expanded(child: Text(g.name, style: _sectionStyle(context))),

                ],

              ),

            ),

            const SizedBox(height: 14),

            _segments(context,

              ['Overview', 'Contributions', 'Projections'],

              tab,

              (s) => setState(() => tab = s),

            ),

            const SizedBox(height: 14),

            if (tab == 'Overview') ...[

              _card(context,

                Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text('Savings Progress', style: _sectionStyle(context)),

                    const SizedBox(height: 8),

                    Text(

                      '${_money(g.saved)} / ${_money(g.target)}',

                      style: _sectionStyle(context),

                    ),

                    const SizedBox(height: 12),

                    _bar(context, g.progress, _green),

                    const SizedBox(height: 8),

                    Text(

                      '${(g.progress * 100).round()}% of goal saved',

                      style: TextStyle(color: _hint(context)),

                    ),

                  ],

                ),

              ),

              const SizedBox(height: 14),

              _card(context,

                Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text('Contribution Breakdown', style: _sectionStyle(context)),

                    const SizedBox(height: 15),

                    _stat(context, 'Existing savings before tracking', _money(opening)),

                    const Divider(height: 25),

                    _stat(context, 'Added since tracking', _money(deposits)),

                    const Divider(height: 25),

                    _stat(context, 'Withdrawn since tracking', _money(withdrawals)),

                    const Divider(height: 25),

                    _stat(context, 'Current saved', _money(g.saved)),

                  ],

                ),

              ),

            ] else if (tab == 'Contributions') ...[

              if (entries.isEmpty)

                _card(context,

                  Text(

                    'No contribution history recorded yet. Existing saved money is preserved.',

                    style: TextStyle(color: _hint(context)),

                  ),

                )

              else

                ...entries.map(

                  (e) => Padding(

                    padding: const EdgeInsets.only(bottom: 10),

                    child: _card(context,

                      Row(

                        children: [

                          Icon(

                            e.amount > 0

                                ? Icons.add_circle

                                : Icons.remove_circle,

                            color: e.amount > 0 ? _green : Colors.red,

                          ),

                          const SizedBox(width: 12),

                          Expanded(

                            child: Column(

                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [

                                Text(

                                  e.note.isEmpty ? e.method : e.note,

                                  style: const TextStyle(

                                    fontWeight: FontWeight.w700,

                                  ),

                                ),

                                Text(

                                  _date(e.date),

                                  style: TextStyle(

                                    color: _hint(context),

                                    fontSize: 12,

                                  ),

                                ),

                              ],

                            ),

                          ),

                          Text(

                            '${e.amount > 0 ? '+' : '−'}${_money(e.amount.abs())}',

                            style: TextStyle(

                              fontWeight: FontWeight.w800,

                              color: e.amount > 0 ? _green : Colors.red,

                            ),

                          ),

                        ],

                      ),

                    ),

                  ),

                ),

            ] else ...[

              _card(context,

                Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text('Goal Projection', style: _sectionStyle(context)),

                    const SizedBox(height: 12),

                    _stat(context, 'Remaining', _money(math.max(0, g.target - g.saved))),

                    const Divider(height: 24),

                    _stat(context, 'Target date', _date(g.targetDate)),

                    const SizedBox(height: 14),

                    Text(

                      'A reliable completion forecast needs regular contribution history. No estimated deposits are invented.',

                      style: TextStyle(color: _hint(context)),

                    ),

                  ],

                ),

              ),

            ],

          ],

        ),

      ),

    );

  }

}
