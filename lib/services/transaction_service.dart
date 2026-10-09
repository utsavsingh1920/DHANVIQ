import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/transaction_model.dart';
import 'storage_service.dart';

class TransactionService extends ChangeNotifier {
  TransactionService._();

  static final TransactionService instance = TransactionService._();

  final List<TransactionModel> _transactions = [];
  int _nextId = 0;
  bool _isInitialized = false;
  Future<void>? _initializationFuture;
  Future<void> _operationQueue = Future<void>.value();

  bool get isInitialized => _isInitialized;

  Future<void> initialize() {
    if (_isInitialized) return Future<void>.value();
    return _initializationFuture ??= _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final saved = await StorageService.instance.loadTransactions();
      _transactions
        ..clear()
        ..addAll(saved);
      _isInitialized = true;
      notifyListeners();
    } catch (_) {
      _initializationFuture = null;
      rethrow;
    }
  }

  Future<T> _runExclusive<T>(Future<T> Function() action) async {
    final previous = _operationQueue;
    final done = Completer<void>();
    _operationQueue = done.future;
    await previous;
    try {
      await initialize();
      return await action();
    } finally {
      done.complete();
    }
  }

  List<TransactionModel> get transactions {
    final items = List<TransactionModel>.from(_transactions);
    items.sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(items);
  }

  // transactionId is used only for planned bills. Reusing the same ID
  // prevents duplicate payments, including after an interrupted save.
  Future<TransactionModel> addTransaction({
    required String title,
    required double amount,
    required TransactionType type,
    required String category,
    required DateTime date,
    required String paymentMethod,
    String note = '',
    String? transactionId,
  }) {
    return _runExclusive(() async {
      if (!amount.isFinite || amount <= 0) {
        throw ArgumentError('Amount must be greater than zero.');
      }
      if (transactionId != null && transactionId.trim().isEmpty) {
        throw ArgumentError('Transaction ID cannot be empty.');
      }
      if (transactionId != null) {
        final existing = getTransactionById(transactionId);
        if (existing != null) {
          if (existing.type != type || existing.amount != amount) {
            throw StateError('A different transaction already uses this ID.');
          }
          return existing;
        }
      }
      final transaction = TransactionModel(
        id: transactionId ??
            '${DateTime.now().microsecondsSinceEpoch}_${_nextId++}',
        title: title.trim().isEmpty ? category : title.trim(),
        amount: amount,
        type: type,
        category: category,
        date: date,
        paymentMethod: paymentMethod,
        note: note.trim(),
      );
      _transactions.add(transaction);
      try {
        await _saveTransactions();
      } catch (_) {
        _transactions.removeWhere((item) => item.id == transaction.id);
        rethrow;
      }
      notifyListeners();
      return transaction;
    });
  }

  Future<bool> updateTransaction(TransactionModel updatedTransaction) {
    return _runExclusive(() async {
      if (!updatedTransaction.amount.isFinite ||
          updatedTransaction.amount <= 0) {
        throw ArgumentError('Amount must be greater than zero.');
      }
      final index = _transactions.indexWhere(
        (item) => item.id == updatedTransaction.id,
      );
      if (index == -1) return false;
      final previous = _transactions[index];
      _transactions[index] = updatedTransaction;
      try {
        await _saveTransactions();
      } catch (_) {
        _transactions[index] = previous;
        rethrow;
      }
      notifyListeners();
      return true;
    });
  }

  Future<bool> deleteTransaction(String id) {
    return _runExclusive(() async {
      final index = _transactions.indexWhere((item) => item.id == id);
      if (index == -1) return false;
      final removed = _transactions.removeAt(index);
      try {
        await _saveTransactions();
      } catch (_) {
        _transactions.insert(index, removed);
        rethrow;
      }
      notifyListeners();
      return true;
    });
  }

  Future<void> replaceAllTransactions(
    List<TransactionModel> items,
  ) {
    return _runExclusive(() async {
      final previous = List<TransactionModel>.from(_transactions);

      _transactions
        ..clear()
        ..addAll(items);

      try {
        await _saveTransactions();
      } catch (_) {
        _transactions
          ..clear()
          ..addAll(previous);
        rethrow;
      }

      notifyListeners();
    });
  }

  TransactionModel? getTransactionById(String id) {
    for (final transaction in _transactions) {
      if (transaction.id == id) return transaction;
    }
    return null;
  }

  double get totalIncome => _sumByType(_transactions, TransactionType.income);
  double get totalExpenses => _sumByType(_transactions, TransactionType.expense);
  double get totalBalance => totalIncome - totalExpenses;

  List<TransactionModel> transactionsForMonth(int year, int month) {
    return List.unmodifiable(transactions.where(
      (transaction) =>
          transaction.date.year == year && transaction.date.month == month,
    ));
  }

  double incomeForMonth(int year, int month) =>
      _sumByType(transactionsForMonth(year, month), TransactionType.income);

  double expensesForMonth(int year, int month) =>
      _sumByType(transactionsForMonth(year, month), TransactionType.expense);

  double savingsForMonth(int year, int month) =>
      incomeForMonth(year, month) - expensesForMonth(year, month);

  List<TransactionModel> recentTransactions({int limit = 4}) {
    if (limit <= 0) return [];
    return List.unmodifiable(transactions.take(limit));
  }

  Map<String, double> expensesByCategory({int? year, int? month}) {
    if ((year == null) != (month == null)) {
      throw ArgumentError('Provide both year and month, or neither.');
    }
    final source = year != null && month != null
        ? transactionsForMonth(year, month)
        : transactions;
    final result = <String, double>{};
    for (final transaction in source) {
      if (!transaction.isExpense) continue;
      result.update(
        transaction.category,
        (current) => current + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }
    return Map.unmodifiable(result);
  }

  List<TransactionModel> transactionsByType(TransactionType type) {
    return List.unmodifiable(
      transactions.where((transaction) => transaction.type == type),
    );
  }

  double _sumByType(Iterable<TransactionModel> source, TransactionType type) {
    double total = 0;
    for (final transaction in source) {
      if (transaction.type == type) total += transaction.amount;
    }
    return total;
  }

  Future<void> _saveTransactions() async {
    await StorageService.instance.saveTransactions(
      List<TransactionModel>.from(_transactions),
    );
  }
}
