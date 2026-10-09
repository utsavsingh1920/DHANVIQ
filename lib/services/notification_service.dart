import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final String category;
  final DateTime createdAt;
  final bool isRead;

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? category,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'body': body,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Notification',
      body: json['body'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}

class NotificationService extends ChangeNotifier {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String masterKey = 'dhanviq_notify_enabled';
  static const String incomeKey = 'dhanviq_notify_income';
  static const String expenseKey = 'dhanviq_notify_expense';
  static const String remindersKey = 'dhanviq_notify_transaction_reminders';
  static const String budgetKey = 'dhanviq_notify_budget';
  static const String goalsKey = 'dhanviq_notify_goals';
  static const String summaryKey = 'dhanviq_notify_summary';
  static const String appUpdatesKey = 'dhanviq_notify_app_updates';
  static const String securityKey = 'dhanviq_notify_security';

  static const String _storageKey = 'dhanviq_notifications_v1';

  final List<AppNotification> _items = <AppNotification>[];

  bool _initialized = false;

  List<AppNotification> get items =>
      List<AppNotification>.unmodifiable(_items);

  int get unreadCount => _items.where((item) => !item.isRead).length;

  bool get hasUnread => unreadCount > 0;

  Future<void> initialize() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _items
            ..clear()
            ..addAll(
              decoded
                  .whereType<Map>()
                  .map(
                    (item) => AppNotification.fromJson(
                      Map<String, dynamic>.from(item),
                    ),
                  )
                  .where((item) => item.id.isNotEmpty),
            );
        }
      } catch (error) {
        debugPrint('Could not load notifications: $error');
      }
    }

    _sort();
    _initialized = true;
  }

  Future<bool> preferenceEnabled(
    String key, {
    bool defaultValue = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final master = prefs.getBool(masterKey) ?? true;
    if (key != masterKey && !master) return false;

    return prefs.getBool(key) ?? defaultValue;
  }

  Future<void> setPreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setBool(key, value);

    if (!saved) {
      throw StateError('Notification preference could not be saved');
    }

    notifyListeners();
  }

  Future<void> addOrUpdate({
    required String id,
    required String title,
    required String body,
    required String category,
    DateTime? createdAt,
  }) async {
    await initialize();

    final index = _items.indexWhere((item) => item.id == id);

    if (index >= 0) {
      final current = _items[index];

      if (current.title == title &&
          current.body == body &&
          current.category == category) {
        return;
      }

      _items[index] = current.copyWith(
        title: title,
        body: body,
        category: category,
      );
    } else {
      _items.add(
        AppNotification(
          id: id,
          title: title,
          body: body,
          category: category,
          createdAt: createdAt ?? DateTime.now(),
        ),
      );
    }

    _sort();
    await _save();
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    await initialize();

    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0 || _items[index].isRead) return;

    _items[index] = _items[index].copyWith(isRead: true);

    await _save();
    notifyListeners();
  }

  Future<void> markAllRead() async {
    await initialize();

    var changed = false;

    for (var i = 0; i < _items.length; i++) {
      if (!_items[i].isRead) {
        _items[i] = _items[i].copyWith(isRead: true);
        changed = true;
      }
    }

    if (!changed) return;

    await _save();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await initialize();

    final oldLength = _items.length;
    _items.removeWhere((item) => item.id == id);

    if (_items.length == oldLength) return;

    await _save();
    notifyListeners();
  }

  Future<void> clearAll() async {
    await initialize();

    if (_items.isEmpty) return;

    _items.clear();
    await _save();
    notifyListeners();
  }

  void _sort() {
    _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _storageKey,
      jsonEncode(
        _items.map((item) => item.toJson()).toList(),
      ),
    );
  }
}
