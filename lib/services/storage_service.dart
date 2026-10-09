import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction_model.dart';

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  static const String _transactionsKey = 'dhanviq_transactions_v1';

  // Save all transactions on the device.
  Future<void> saveTransactions(List<TransactionModel> transactions) async {
    final preferences = await SharedPreferences.getInstance();

    final encodedTransactions = transactions
        .map((transaction) => transaction.toJson())
        .toList();

    final jsonString = jsonEncode(encodedTransactions);

    final saved = await preferences.setString(_transactionsKey, jsonString);

    if (!saved) {
      throw StateError('Transactions could not be saved.');
    }
  }

  // Load previously saved transactions.
  Future<List<TransactionModel>> loadTransactions() async {
    final preferences = await SharedPreferences.getInstance();

    final jsonString = preferences.getString(_transactionsKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(jsonString);

    if (decoded is! List) {
      throw const FormatException('Saved transactions have an invalid format.');
    }

    return decoded.map<TransactionModel>((item) {
      if (item is! Map) {
        throw const FormatException(
          'A saved transaction has an invalid format.',
        );
      }

      return TransactionModel.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }
}
