import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction_model.dart';
import 'transaction_service.dart';

class SavedGoal {
  SavedGoal({
    required this.id,
    required this.name,
    required this.category,
    required this.target,
    this.saved = 0,
    this.targetDate,
    this.note = '',
    this.imagePath,
  });

  final String id;
  String name;
  String category;
  double target;

  double saved;

  DateTime? targetDate;
  String note;
  String? imagePath;

  double get progress {
    if (target <= 0) return 0;

    return (saved / target).clamp(0.0, 1.0);
  }

  bool get completed => saved >= target;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'target': target,
      'saved': saved,
      'targetDate': targetDate?.toIso8601String(),
      'note': note,
      'imagePath': imagePath,
    };
  }

  factory SavedGoal.fromJson(Map<String, dynamic> json) {
    return SavedGoal(
      id: json['id'].toString(),
      name: json['name'] as String,
      category: json['category'] as String? ?? 'Custom',
      target: (json['target'] as num).toDouble(),
      saved: (json['saved'] as num?)?.toDouble() ?? 0,
      targetDate: DateTime.tryParse(json['targetDate'] as String? ?? ''),
      note: json['note'] as String? ?? '',
      imagePath: json['imagePath'] as String?,
    );
  }
}

class GoalContribution {
  const GoalContribution({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.date,
    required this.method,
    this.note = '',
  });
  final String id;
  final String goalId;
  final double amount; // Negative values are withdrawals.
  final DateTime date;
  final String method;
  final String note;
  Map<String, dynamic> toJson() => {
    'id': id,
    'goalId': goalId,
    'amount': amount,
    'date': date.toIso8601String(),
    'method': method,
    'note': note,
  };
  factory GoalContribution.fromJson(Map<String, dynamic> json) =>
      GoalContribution(
        id: json['id'].toString(),
        goalId: json['goalId'].toString(),
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        method: json['method'] as String? ?? 'Other',
        note: json['note'] as String? ?? '',
      );
}

class PlannedExpense {
  PlannedExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    this.paid = false,
  });

  final String id;
  final String title;
  final double amount;
  final DateTime dueDate;

  bool paid;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'paid': paid,
    };
  }

  factory PlannedExpense.fromJson(Map<String, dynamic> json) {
    return PlannedExpense(
      id: json['id'].toString(),
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['dueDate'] as String),
      paid: json['paid'] as bool? ?? false,
    );
  }
}

class FinancePlanService extends ChangeNotifier {
  FinancePlanService._();

  static final FinancePlanService instance = FinancePlanService._();

  static const String _goalsKey = 'dhanviq_goals_v1';
  static const String _contributionsKey = 'dhanviq_goal_contributions_v1';
  static const String _billsKey = 'dhanviq_bills_v1';
  static const String _budgetsKey = 'dhanviq_budgets_v1';

  final List<SavedGoal> goals = [];
  final List<GoalContribution> contributions = [];
  final List<PlannedExpense> bills = [];
  final Map<String, double> budgets = {};

  Future<void>? _initializationFuture;

  Future<void> _operationQueue = Future<void>.value();

  bool _ready = false;

  int _nextId = 0;

  bool get isInitialized => _ready;

  // ------------------------------------------------------------
  // GOAL TOTALS
  // ------------------------------------------------------------

  double get totalGoalSavings {
    return goals.fold<double>(0, (sum, goal) => sum + goal.saved);
  }

  // Available money after reserving money for goals.
  //
  // Goal savings are NOT expenses.
  double get availableBalance {
    return TransactionService.instance.totalBalance - totalGoalSavings;
  }

  // ------------------------------------------------------------
  // INITIALIZATION
  // ------------------------------------------------------------

  Future<void> initialize() {
    if (_ready) {
      return Future<void>.value();
    }

    return _initializationFuture ??= _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final loadedGoals = <SavedGoal>[];
      final loadedContributions = <GoalContribution>[];
      final loadedBills = <PlannedExpense>[];
      final loadedBudgets = <String, double>{};

      // --------------------------------------------------------
      // LOAD GOALS
      // --------------------------------------------------------

      final rawGoals = jsonDecode(prefs.getString(_goalsKey) ?? '[]');

      if (rawGoals is List) {
        for (final item in rawGoals) {
          try {
            loadedGoals.add(
              SavedGoal.fromJson(Map<String, dynamic>.from(item as Map)),
            );
          } catch (error) {
            debugPrint('Could not load a goal: $error');
          }
        }
      }

      // --------------------------------------------------------
      // LOAD BILLS
      // --------------------------------------------------------

      final rawContributions = jsonDecode(
        prefs.getString(_contributionsKey) ?? '[]',
      );
      if (rawContributions is List) {
        for (final item in rawContributions) {
          try {
            loadedContributions.add(
              GoalContribution.fromJson(Map<String, dynamic>.from(item as Map)),
            );
          } catch (error) {
            debugPrint('Could not load a goal contribution: $error');
          }
        }
      }

      final rawBills = jsonDecode(prefs.getString(_billsKey) ?? '[]');

      if (rawBills is List) {
        for (final item in rawBills) {
          try {
            loadedBills.add(
              PlannedExpense.fromJson(Map<String, dynamic>.from(item as Map)),
            );
          } catch (error) {
            debugPrint('Could not load a bill: $error');
          }
        }
      }

      // --------------------------------------------------------
      // LOAD BUDGETS
      // --------------------------------------------------------

      final rawBudgets = jsonDecode(prefs.getString(_budgetsKey) ?? '{}');

      if (rawBudgets is Map) {
        rawBudgets.forEach((key, value) {
          if (value is num) {
            loadedBudgets[key.toString()] = value.toDouble();
          }
        });
      }

      // ========================================================
      // IMPORTANT:
      // REPAIR DUPLICATE GOAL IDs FROM OLD SAVED DATA
      // ========================================================

      final uniqueGoals = <String, SavedGoal>{};

      for (final goal in loadedGoals) {
        final existing = uniqueGoals[goal.id];

        if (existing == null) {
          uniqueGoals[goal.id] = goal;
          continue;
        }

        /*
         * Old versions could accidentally load/store the
         * same goal more than once with the same ID.
         *
         * Flutter ValueKey(goal.id) then caused:
         *
         * Duplicate keys found
         *
         * We keep ONE copy.
         *
         * If copies contain different saved amounts, keep
         * the one with the greater saved amount so savings
         * are not accidentally lost.
         */

        if (goal.saved > existing.saved) {
          uniqueGoals[goal.id] = goal;
        }
      }

      // ========================================================
      // REPAIR DUPLICATE BILL IDs
      // ========================================================

      final uniqueBills = <String, PlannedExpense>{};

      for (final bill in loadedBills) {
        final existing = uniqueBills[bill.id];

        if (existing == null) {
          uniqueBills[bill.id] = bill;
          continue;
        }

        // If either copy was already paid, preserve paid state.
        if (bill.paid && !existing.paid) {
          uniqueBills[bill.id] = bill;
        }
      }

      // --------------------------------------------------------
      // APPLY CLEAN DATA
      // --------------------------------------------------------

      goals
        ..clear()
        ..addAll(uniqueGoals.values);

      bills
        ..clear()
        ..addAll(uniqueBills.values);

      contributions
        ..clear()
        ..addAll({for (final c in loadedContributions) c.id: c}.values);

      budgets
        ..clear()
        ..addAll(loadedBudgets);

      _ready = true;

      // --------------------------------------------------------
      // SAVE REPAIRED DATA BACK
      //
      // This permanently removes duplicate IDs from the
      // SharedPreferences data.
      // --------------------------------------------------------

      await prefs.setString(
        _goalsKey,
        jsonEncode(goals.map((goal) => goal.toJson()).toList()),
      );

      await prefs.setString(
        _billsKey,
        jsonEncode(bills.map((bill) => bill.toJson()).toList()),
      );

      await prefs.setString(_budgetsKey, jsonEncode(budgets));
      await prefs.setString(
        _contributionsKey,
        jsonEncode(contributions.map((c) => c.toJson()).toList()),
      );

      notifyListeners();
    } catch (error) {
      debugPrint('Finance data could not be loaded: $error');

      _initializationFuture = null;

      rethrow;
    }
  }

  // ------------------------------------------------------------
  // SAFE OPERATION QUEUE
  // ------------------------------------------------------------

  Future<T> _runExclusive<T>(Future<T> Function() operation) async {
    final previousOperation = _operationQueue;

    final completer = Completer<void>();

    _operationQueue = completer.future;

    await previousOperation;

    try {
      await initialize();

      return await operation();
    } finally {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }

  // ------------------------------------------------------------
  // SAVE
  // ------------------------------------------------------------

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();

    final goalsSaved = await prefs.setString(
      _goalsKey,
      jsonEncode(goals.map((goal) => goal.toJson()).toList()),
    );

    final billsSaved = await prefs.setString(
      _billsKey,
      jsonEncode(bills.map((bill) => bill.toJson()).toList()),
    );

    final budgetsSaved = await prefs.setString(
      _budgetsKey,
      jsonEncode(budgets),
    );

    final contributionsSaved = await prefs.setString(
      _contributionsKey,
      jsonEncode(contributions.map((c) => c.toJson()).toList()),
    );
    if (!goalsSaved || !billsSaved || !budgetsSaved || !contributionsSaved) {
      throw StateError('Could not save finance data.');
    }

    notifyListeners();
  }

  // ------------------------------------------------------------
  // UNIQUE ID
  // ------------------------------------------------------------

  String _id() {
    return '${DateTime.now().microsecondsSinceEpoch}_${_nextId++}';
  }

  // ------------------------------------------------------------
  // GOAL HELPERS
  // ------------------------------------------------------------

  SavedGoal? goalById(String id) {
    for (final goal in goals) {
      if (goal.id == id) {
        return goal;
      }
    }

    return null;
  }

  bool goalNameExists(String name, {String? excludingId}) {
    final normalizedName = name.trim().toLowerCase();

    return goals.any(
      (goal) =>
          goal.id != excludingId &&
          !goal.completed &&
          goal.name.trim().toLowerCase() == normalizedName,
    );
  }

  // ------------------------------------------------------------
  // ADD GOAL
  // ------------------------------------------------------------

  Future<void> addGoal(
    String name,
    String category,
    double target,
    DateTime? date,
  ) {
    return _runExclusive(() async {
      final cleanName = name.trim();

      if (cleanName.isEmpty || !target.isFinite || target <= 0) {
        throw ArgumentError('Enter a valid goal name and target amount.');
      }

      if (goalNameExists(cleanName)) {
        throw StateError('An active goal with this name already exists.');
      }

      final newGoal = SavedGoal(
        id: _id(),
        name: cleanName,
        category: category.trim().isEmpty ? 'Custom' : category.trim(),
        target: target,
        targetDate: date,
      );

      goals.add(newGoal);

      try {
        await _save();
      } catch (_) {
        goals.removeWhere((goal) => goal.id == newGoal.id);

        notifyListeners();

        rethrow;
      }
    });
  }

  // ------------------------------------------------------------
  // ADD MONEY / WITHDRAW
  // ------------------------------------------------------------

  List<GoalContribution> contributionsFor(String goalId) {
    final result = contributions.where((c) => c.goalId == goalId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(result);
  }

  Future<void> editGoal(
    String id, {
    required String name,
    required String category,
    required double target,
    DateTime? targetDate,
    String note = '',
    String? imagePath,
  }) {
    return _runExclusive(() async {
      final goal = goalById(id);
      if (goal == null) throw StateError('Goal not found.');
      final cleanName = name.trim();
      if (cleanName.isEmpty ||
          !target.isFinite ||
          target <= 0 ||
          target < goal.saved) {
        throw ArgumentError(
          'Enter a valid name and target (at least the saved amount).',
        );
      }
      if (goalNameExists(cleanName, excludingId: id)) {
        throw StateError('An active goal with this name already exists.');
      }
      final old = [
        goal.name,
        goal.category,
        goal.target,
        goal.targetDate,
        goal.note,
        goal.imagePath,
      ];
      goal.name = cleanName;
      goal.category = category.trim().isEmpty ? 'Custom' : category.trim();
      goal.target = target;
      goal.targetDate = targetDate;
      goal.note = note.trim();
      goal.imagePath = imagePath;
      try {
        await _save();
      } catch (_) {
        goal.name = old[0] as String;
        goal.category = old[1] as String;
        goal.target = old[2] as double;
        goal.targetDate = old[3] as DateTime?;
        goal.note = old[4] as String;
        goal.imagePath = old[5] as String?;
        notifyListeners();
        rethrow;
      }
    });
  }

  Future<void> changeSavings(
    String id,
    double delta, {
    String paymentMethod = 'Other',
    DateTime? date,
    String note = '',
  }) {
    return _runExclusive(() async {
      await TransactionService.instance.initialize();

      final goal = goalById(id);

      if (goal == null) {
        throw StateError('Goal not found.');
      }

      if (!delta.isFinite || delta == 0) {
        throw ArgumentError('Enter a valid amount.');
      }

      final newSavings = goal.saved + delta;

      if (newSavings < -0.000001) {
        throw ArgumentError('You cannot withdraw more than the saved amount.');
      }

      if (newSavings > goal.target + 0.000001) {
        throw ArgumentError('Amount exceeds the remaining goal target.');
      }

      /*
         * Only ADD MONEY needs available-balance validation.
         *
         * Withdraw gives reserved money back, therefore no
         * balance validation is needed for negative delta.
         */
      if (delta > 0) {
        final balanceBeforeAllocation = availableBalance;

        if (delta > balanceBeforeAllocation + 0.000001) {
          throw StateError(
            'Insufficient available balance. '
            'Add income first or enter a smaller amount.',
          );
        }
      }

      final previousSaved = goal.saved;

      goal.saved = newSavings.clamp(0.0, goal.target);
      final contribution = GoalContribution(
        id: _id(),
        goalId: id,
        amount: delta,
        date: date ?? DateTime.now(),
        method: paymentMethod,
        note: note.trim(),
      );
      contributions.add(contribution);

      try {
        await _save();
      } catch (_) {
        goal.saved = previousSaved;
        contributions.removeWhere((c) => c.id == contribution.id);

        notifyListeners();

        rethrow;
      }
    });
  }

  // ------------------------------------------------------------
  // DELETE GOAL
  // ------------------------------------------------------------

  Future<void> deleteGoal(String id) {
    return _runExclusive(() async {
      final index = goals.indexWhere((goal) => goal.id == id);

      if (index == -1) {
        throw StateError('Goal not found.');
      }

      final removedGoal = goals.removeAt(index);
      final removedContributions = contributions
          .where((c) => c.goalId == id)
          .toList();
      contributions.removeWhere((c) => c.goalId == id);

      try {
        await _save();
      } catch (_) {
        goals.insert(index, removedGoal);
        contributions.addAll(removedContributions);

        notifyListeners();

        rethrow;
      }
    });
  }

  // ------------------------------------------------------------
  // BUDGET
  // ------------------------------------------------------------

  String budgetKey(int year, int month, String category) {
    return '$year-$month-$category';
  }

  double budgetFor(int year, int month, String category) {
    return budgets[budgetKey(year, month, category)] ?? 0;
  }

  Future<void> setBudget(int year, int month, String category, double amount) {
    return _runExclusive(() async {
      if (!amount.isFinite || amount <= 0) {
        throw ArgumentError('Budget must be greater than zero.');
      }

      final key = budgetKey(year, month, category);

      final previousValue = budgets[key];

      budgets[key] = amount;

      try {
        await _save();
      } catch (_) {
        if (previousValue == null) {
          budgets.remove(key);
        } else {
          budgets[key] = previousValue;
        }

        notifyListeners();

        rethrow;
      }
    });
  }

  // ------------------------------------------------------------
  // UPCOMING EXPENSES
  // ------------------------------------------------------------

  Future<void> addBill(String title, double amount, DateTime dueDate) {
    return _runExclusive(() async {
      final cleanTitle = title.trim();

      if (cleanTitle.isEmpty || !amount.isFinite || amount <= 0) {
        throw ArgumentError('Enter valid expense details.');
      }

      final bill = PlannedExpense(
        id: _id(),
        title: cleanTitle,
        amount: amount,
        dueDate: dueDate,
      );

      bills.add(bill);

      try {
        await _save();
      } catch (_) {
        bills.removeWhere((item) => item.id == bill.id);

        notifyListeners();

        rethrow;
      }
    });
  }

  // Save the expense first; mark the bill paid only after it is recorded.
  // The deterministic transaction ID makes retries idempotent.
  Future<void> markPaid(String id) {
    return _runExclusive(() async {
      final index = bills.indexWhere((bill) => bill.id == id);
      if (index == -1) throw StateError('Expense not found.');

      final bill = bills[index];
      // Preserve old paid bills as-is; never charge them a second time.
      if (bill.paid) return;

      await TransactionService.instance.addTransaction(
        transactionId: 'planned_expense_${bill.id}',
        title: bill.title,
        amount: bill.amount,
        type: TransactionType.expense,
        category: 'Bills',
        date: DateTime.now(),
        paymentMethod: 'Other',
        note: 'Paid scheduled expense (bill ID: ${bill.id})',
      );

      bill.paid = true;
      try {
        await _save();
      } catch (_) {
        bill.paid = false;
        notifyListeners();
        // The transaction remains saved. Retrying markPaid will find its
        // existing ID and only retry updating the bill's paid status.
        rethrow;
      }
    });
  }

  Future<void> deleteBill(String id) {
    return _runExclusive(() async {
      final index = bills.indexWhere((bill) => bill.id == id);

      if (index == -1) {
        throw StateError('Expense not found.');
      }

      final removedBill = bills.removeAt(index);

      try {
        await _save();
      } catch (_) {
        bills.insert(index, removedBill);

        notifyListeners();

        rethrow;
      }
    });
  }
}
