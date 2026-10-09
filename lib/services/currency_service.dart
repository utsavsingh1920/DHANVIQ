import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService extends ChangeNotifier {
  CurrencyService._();

  static final CurrencyService instance = CurrencyService._();

  static const String _currencyKey = 'dhanviq_currency';
  static const String _regionKey = 'dhanviq_region';
  static const String _numberFormatKey = 'dhanviq_number_format';
  static const String _dateFormatKey = 'dhanviq_date_format';
  static const String _timezoneKey = 'dhanviq_timezone';

  String _currencyCode = 'INR';
  String _region = 'India';
  String _numberFormat = 'Indian';
  String _dateFormat = 'dd MMM yyyy';
  String _timezone = 'Asia/Kolkata';

  String get currencyCode => _currencyCode;
  String get region => _region;
  String get numberFormat => _numberFormat;
  String get dateFormat => _dateFormat;
  String get timezone => _timezone;

  String get symbol {
    switch (_currencyCode) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'INR':
      default:
        return '₹';
    }
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    _currencyCode = prefs.getString(_currencyKey) ?? 'INR';
    _region = prefs.getString(_regionKey) ?? 'India';
    _numberFormat =
        prefs.getString(_numberFormatKey) ?? 'Indian';
    _dateFormat =
        prefs.getString(_dateFormatKey) ?? 'dd MMM yyyy';
    _timezone =
        prefs.getString(_timezoneKey) ?? 'Asia/Kolkata';

    notifyListeners();
  }

  Future<void> setCurrency(String code) async {
    if (_currencyCode == code) return;

    _currencyCode = code;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, code);

    notifyListeners();
  }

  Future<void> setRegion(String value) async {
    _region = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_regionKey, value);

    notifyListeners();
  }

  Future<void> setNumberFormat(String value) async {
    _numberFormat = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_numberFormatKey, value);

    notifyListeners();
  }

  Future<void> setDateFormat(String value) async {
    _dateFormat = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dateFormatKey, value);

    notifyListeners();
  }

  Future<void> setTimezone(String value) async {
    _timezone = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_timezoneKey, value);

    notifyListeners();
  }

  String formatAmount(
    num amount, {
    bool decimal = false,
  }) {
    final value = amount.abs();

    String formatted;

    if (_numberFormat == 'Indian') {
      formatted = _formatIndian(value, decimal: decimal);
    } else {
      formatted = _formatInternational(
        value,
        decimal: decimal,
      );
    }

    final sign = amount < 0 ? '-' : '';

    return '$sign$symbol$formatted';
  }

  String _formatInternational(
    num amount, {
    required bool decimal,
  }) {
    final text =
        decimal ? amount.toStringAsFixed(2) : amount.round().toString();

    final parts = text.split('.');

    final digits = parts[0];

    final buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;

      buffer.write(digits[i]);

      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }

    if (decimal && parts.length > 1) {
      buffer.write('.${parts[1]}');
    }

    return buffer.toString();
  }

  String _formatIndian(
    num amount, {
    required bool decimal,
  }) {
    final text =
        decimal ? amount.toStringAsFixed(2) : amount.round().toString();

    final parts = text.split('.');

    String digits = parts[0];

    if (digits.length <= 3) {
      return decimal && parts.length > 1
          ? '$digits.${parts[1]}'
          : digits;
    }

    final lastThree = digits.substring(digits.length - 3);

    String remaining =
        digits.substring(0, digits.length - 3);

    final groups = <String>[];

    while (remaining.length > 2) {
      groups.insert(
        0,
        remaining.substring(remaining.length - 2),
      );

      remaining =
          remaining.substring(0, remaining.length - 2);
    }

    if (remaining.isNotEmpty) {
      groups.insert(0, remaining);
    }

    final result = '${groups.join(',')},$lastThree';

    if (decimal && parts.length > 1) {
      return '$result.${parts[1]}';
    }

    return result;
  }
}