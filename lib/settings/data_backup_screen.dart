import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

// Uses the MaterialApp color scheme, so Appearance -> Accent Color and
// Light / Dark / System are reflected automatically.
class DataBackupScreen extends StatefulWidget {
  const DataBackupScreen({super.key});

  @override
  State<DataBackupScreen> createState() => _DataBackupScreenState();
}

class _DataBackupScreenState extends State<DataBackupScreen> {
  static const _backupKey = 'dhanviq_full_backup_v2';
  static const _lastBackupKey = 'dhanviq_last_backup_at_v2';
  static const _autoBackupKey = 'dhanviq_auto_backup_enabled_v2';
  static const _frequencyKey = 'dhanviq_backup_frequency_v2';

  static const _excludedKeys = <String>{
    _backupKey,
    _lastBackupKey,
    _autoBackupKey,
    _frequencyKey,
  };

  bool _busy = false;
  bool _autoBackup = false;
  String _frequency = 'Once a Week';
  DateTime? _lastBackup;
  bool _hasBackup = false;
  int _backupItems = 0;

  bool _dark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Color _accent(BuildContext context) => Theme.of(context).colorScheme.primary;

  Color _bg(BuildContext context) => _dark(context)
      ? const Color(0xFF0D121D)
      : const Color(0xFFF8F8FF);

  Color _surface(BuildContext context) => _dark(context)
      ? const Color(0xFF171E2C)
      : Colors.white;

  Color _ink(BuildContext context) => _dark(context)
      ? const Color(0xFFF7F8FF)
      : const Color(0xFF172039);

  Color _muted(BuildContext context) => _dark(context)
      ? const Color(0xFF9CA8BD)
      : const Color(0xFF727D93);

  Color _border(BuildContext context) => _dark(context)
      ? const Color(0xFF293447)
      : const Color(0xFFE9E7F5);

  Color _tint(BuildContext context) =>
      _accent(context).withValues(alpha: _dark(context) ? .19 : .10);

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Duration get _interval => switch (_frequency) {
        'Every Day' => const Duration(days: 1),
        'Once a Month' => const Duration(days: 30),
        _ => const Duration(days: 7),
      };

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawTime = prefs.getString(_lastBackupKey);
      final rawBackup = prefs.getString(_backupKey);

      var itemCount = 0;

      if (rawBackup != null && rawBackup.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawBackup);
          if (decoded is Map<String, dynamic>) {
            final prefsData = decoded['preferences'];
            final transactions = decoded['transactions'];

            if (prefsData is Map) itemCount += prefsData.length;
            if (transactions is List) itemCount += transactions.length;
          }
        } catch (_) {}
      }

      if (!mounted) return;

      setState(() {
        _autoBackup = prefs.getBool(_autoBackupKey) ?? false;
        _frequency = prefs.getString(_frequencyKey) ?? 'Once a Week';
        _lastBackup = rawTime == null ? null : DateTime.tryParse(rawTime);
        _hasBackup = rawBackup?.isNotEmpty ?? false;
        _backupItems = itemCount;
      });

      // This is an on-open check, not a background scheduler.
      await _backupIfDue();
    } catch (error) {
      debugPrint('Backup settings load error: $error');
      if (mounted) _toast('Could not load backup settings.');
    }
  }

  bool _shouldBackupPreference(String key) {
    if (_excludedKeys.contains(key)) return false;
    if (!key.startsWith('dhanviq_')) return false;

    // App Lock credentials/security state should not be copied or restored.
    if (key.startsWith('dhanviq_app_lock')) return false;

    return true;
  }

  Map<String, dynamic>? _encodePreference(Object? value) {
    if (value is String) {
      return {'type': 'string', 'value': value};
    }
    if (value is bool) {
      return {'type': 'bool', 'value': value};
    }
    if (value is int) {
      return {'type': 'int', 'value': value};
    }
    if (value is double) {
      return {'type': 'double', 'value': value};
    }
    if (value is List<String>) {
      return {'type': 'stringList', 'value': value};
    }
    return null;
  }

  Future<Map<String, dynamic>> _collectPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, dynamic>{};

    for (final key in prefs.getKeys()) {
      if (!_shouldBackupPreference(key)) continue;

      final encoded = _encodePreference(prefs.get(key));
      if (encoded != null) {
        result[key] = encoded;
      }
    }

    return result;
  }

  Future<void> _backupIfDue() async {
    if (!_autoBackup || _busy) return;

    if (_lastBackup == null ||
        DateTime.now().difference(_lastBackup!) >= _interval) {
      await _createBackup(automatic: true);
    }
  }

  Future<void> _setAutoBackup(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = await prefs.setBool(_autoBackupKey, enabled);

      if (!saved) throw StateError('Could not save auto backup preference');

      if (!mounted) return;

      setState(() => _autoBackup = enabled);

      if (enabled) {
        await _backupIfDue();
      }
    } catch (error) {
      debugPrint('Auto backup error: $error');
      if (mounted) _toast('Could not update Auto Backup.');
    }
  }

  Future<void> _chooseFrequency() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: _surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(7, 5, 7, 12),
                child: Text(
                  'Backup Frequency',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _ink(context),
                  ),
                ),
              ),
              for (final option in const [
                'Every Day',
                'Once a Week',
                'Once a Month',
              ])
                ListTile(
                  title: Text(
                    option,
                    style: TextStyle(color: _ink(context)),
                  ),
                  leading: Icon(
                    option == _frequency
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: option == _frequency
                        ? _accent(context)
                        : _muted(context),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () => Navigator.pop(sheetContext, option),
                ),
            ],
          ),
        ),
      ),
    );

    if (selected == null || !mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = await prefs.setString(_frequencyKey, selected);

      if (!saved) throw StateError('Could not save frequency');

      setState(() => _frequency = selected);
      await _backupIfDue();
    } catch (error) {
      debugPrint('Backup frequency error: $error');
      if (mounted) _toast('Could not save backup frequency.');
    }
  }

  Future<void> _createBackup({bool automatic = false}) async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      await TransactionService.instance.initialize();

      final preferences = await _collectPreferences();
      final transactions = TransactionService.instance.transactions;
      final now = DateTime.now();

      final payload = <String, dynamic>{
        'app': 'DHANVIQ',
        'format': 'dhanviq-full-v2',
        'exportedAt': now.toIso8601String(),
        'preferences': preferences,
        'transactions': transactions.map((item) => item.toJson()).toList(),
      };

      final json = jsonEncode(payload);
      final prefs = await SharedPreferences.getInstance();

      final saved = await prefs.setString(_backupKey, json);
      final timeSaved =
          await prefs.setString(_lastBackupKey, now.toIso8601String());

      if (!saved || !timeSaved) {
        throw StateError('Backup could not be saved');
      }

      if (!mounted) return;

      setState(() {
        _lastBackup = now;
        _hasBackup = true;
        _backupItems = preferences.length + transactions.length;
      });

      if (!automatic) {
        _toast(
          'Backup saved locally: $_backupItems records. '
          'Use Copy Backup JSON to keep a separate copy.',
        );
      }
    } catch (error) {
      debugPrint('DHANVIQ backup error: $error');
      if (mounted) _toast('Backup failed. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_backupKey);

      if (json == null || json.isEmpty) {
        if (mounted) _toast('Create a backup first.');
        return;
      }

      await Clipboard.setData(ClipboardData(text: json));

      if (mounted) {
        _toast(
          'Backup JSON copied. Save it in a private file outside the app.',
        );
      }
    } catch (error) {
      debugPrint('Could not copy backup: $error');
      if (mounted) _toast('Could not copy backup.');
    }
  }

  Future<void> _restoreLastBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_backupKey);

      if (json == null || json.isEmpty) {
        _toast('No local backup is available.');
        return;
      }

      await _confirmAndRestore(json);
    } catch (error) {
      debugPrint('Restore local backup error: $error');
      if (mounted) _toast('Could not read the local backup.');
    }
  }

  Future<void> _restoreFromJson() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => const _PasteBackupJsonScreen(),
      ),
    );

    if (result == null || result.trim().isEmpty || !mounted) return;

    // Wait until the paste screen has fully unmounted before starting
    // restore. This avoids inherited-widget teardown assertions.
    await WidgetsBinding.instance.endOfFrame;

    if (!mounted) return;

    await _confirmAndRestore(result.trim());
  }

  Future<void> _confirmAndRestore(String rawJson) async {
    Map<String, dynamic> backup;

    try {
      final decoded = jsonDecode(rawJson);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid root');
      }

      if (decoded['app'] != 'DHANVIQ' ||
          decoded['format'] != 'dhanviq-full-v2') {
        throw const FormatException('Unsupported DHANVIQ backup');
      }

      if (decoded['preferences'] is! Map ||
          decoded['transactions'] is! List) {
        throw const FormatException('Backup data missing');
      }

      backup = decoded;
    } catch (_) {
      _toast('This is not a valid DHANVIQ backup.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _surface(dialogContext),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Restore backup?',
          style: TextStyle(
            color: _ink(dialogContext),
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'Matching local DHANVIQ data will be replaced with values from '
          'this backup. App Lock data is never restored.',
          style: TextStyle(
            color: _muted(dialogContext),
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await _restoreBackup(backup);
  }

  Future<void> _restoreBackup(Map<String, dynamic> backup) async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      final preferences = Map<String, dynamic>.from(
        backup['preferences'] as Map,
      );

      var restoredPrefs = 0;

      for (final entry in preferences.entries) {
        if (!_shouldBackupPreference(entry.key)) continue;

        final raw = entry.value;
        if (raw is! Map) continue;

        final item = Map<String, dynamic>.from(raw);
        final type = item['type'];
        final value = item['value'];

        bool saved = false;

        switch (type) {
          case 'string':
            if (value is String) {
              saved = await prefs.setString(entry.key, value);
            }
            break;
          case 'bool':
            if (value is bool) {
              saved = await prefs.setBool(entry.key, value);
            }
            break;
          case 'int':
            if (value is int) {
              saved = await prefs.setInt(entry.key, value);
            }
            break;
          case 'double':
            if (value is num) {
              saved = await prefs.setDouble(
                entry.key,
                value.toDouble(),
              );
            }
            break;
          case 'stringList':
            if (value is List) {
              saved = await prefs.setStringList(
                entry.key,
                value.map((item) => item.toString()).toList(),
              );
            }
            break;
        }

        if (saved) restoredPrefs++;
      }

      final transactionMaps =
          (backup['transactions'] as List)
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();

      await TransactionService.instance.initialize();

      final restoredItems = <TransactionModel>[];

      for (final map in transactionMaps) {
        final id = map['id']?.toString().trim() ?? '';
        final amount = (map['amount'] as num?)?.toDouble();
        final title = map['title']?.toString().trim() ?? '';
        final category = map['category']?.toString().trim() ?? 'Other';
        final paymentMethod =
            map['paymentMethod']?.toString().trim() ?? 'Other';
        final note = map['note']?.toString() ?? '';

        final date = DateTime.tryParse(
              map['date']?.toString() ?? '',
            ) ??
            DateTime.now();

        final typeText =
            map['type']?.toString().toLowerCase() ?? '';

        final type = typeText.contains('income')
            ? TransactionType.income
            : TransactionType.expense;

        if (amount == null ||
            !amount.isFinite ||
            amount <= 0 ||
            title.isEmpty) {
          continue;
        }

        restoredItems.add(
          TransactionModel(
            id: id.isEmpty
                ? 'restore_${DateTime.now().microsecondsSinceEpoch}_${restoredItems.length}'
                : id,
            title: title,
            amount: amount,
            type: type,
            category: category.isEmpty ? 'Other' : category,
            date: date,
            paymentMethod:
                paymentMethod.isEmpty ? 'Other' : paymentMethod,
            note: note,
          ),
        );
      }

      await TransactionService.instance.replaceAllTransactions(
        restoredItems,
      );

      final restoredTransactions = restoredItems.length;

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: _surface(dialogContext),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: Icon(
            Icons.check_circle_rounded,
            color: _accent(dialogContext),
            size: 44,
          ),
          title: Text(
            'Restore Complete',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ink(dialogContext),
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            '$restoredTransactions transactions and $restoredPrefs app '
            'preferences were restored. Reopen DHANVIQ once so Goals, '
            'Budgets and other cached screens reload restored values.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted(dialogContext),
              height: 1.45,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (error) {
      debugPrint('DHANVIQ restore error: $error');
      if (mounted) {
        _toast('Restore failed. Please check the backup and try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String get _lastBackupLabel {
    final value = _lastBackup;
    if (value == null) return 'No backup created yet';

    final date = '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/${value.year}';

    final time = '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';

    return 'Last backup: $date at $time';
  }

  Widget _panel({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border(context)),
      ),
      child: child,
    );
  }

  Widget _iconTile(IconData icon, {double size = 37}) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _tint(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        color: _accent(context),
        size: size * .58,
      ),
    );
  }

  Widget _itemRow({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Row(
        children: [
          _iconTile(icon),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _ink(context),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: _muted(context),
                    height: 1.28,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _hero() {
    final accent = _accent(context);
    final dark = _dark(context);

    return Container(
      height: 157,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [
                  accent.withValues(alpha: .20),
                  accent.withValues(alpha: .08),
                ]
              : [
                  accent.withValues(alpha: .11),
                  accent.withValues(alpha: .045),
                ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 20,
            left: 39,
            child: Transform.rotate(
              angle: -.13,
              child: _floatingSymbol(Icons.description_rounded),
            ),
          ),
          Positioned(
            top: 24,
            right: 40,
            child: Transform.rotate(
              angle: .15,
              child: _floatingSymbol(
                Icons.image_rounded,
                strong: true,
              ),
            ),
          ),
          Positioned(
            bottom: 21,
            left: 30,
            child: _floatingSymbol(Icons.settings_outlined),
          ),
          Positioned(
            bottom: 23,
            right: 31,
            child: _floatingSymbol(Icons.settings_rounded),
          ),
          Container(
            width: 112,
            height: 112,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(
                    alpha: dark ? .23 : .16,
                  ),
                  blurRadius: 32,
                ),
              ],
            ),
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(accent, Colors.white, .28)!,
                  accent,
                  Color.lerp(accent, Colors.black, .14)!,
                ],
              ).createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: const Icon(
                Icons.cloud_rounded,
                size: 121,
                color: Colors.white,
              ),
            ),
          ),
          const Positioned(
            child: Icon(
              Icons.swap_vert_rounded,
              color: Colors.white,
              size: 49,
            ),
          ),
        ],
      ),
    );
  }

  Widget _floatingSymbol(
    IconData icon, {
    bool strong = false,
  }) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: strong ? _accent(context) : _surface(context),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: _accent(context).withValues(alpha: .08),
            blurRadius: 10,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: strong ? Colors.white : _accent(context),
        size: 18,
      ),
    );
  }

  Widget _primaryButton() {
    final accent = _accent(context);

    return SizedBox(
      width: double.infinity,
      height: 47,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          gradient: LinearGradient(
            colors: [
              Color.lerp(accent, Colors.white, .12)!,
              Color.lerp(accent, Colors.black, .07)!,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: .22),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _busy ? null : () => _createBackup(),
            borderRadius: BorderRadius.circular(11),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_busy)
                    const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(
                      Icons.cloud_upload_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  const SizedBox(width: 9),
                  Text(
                    _busy
                        ? 'Creating Backup...'
                        : 'Create Backup Now',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
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

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);
    final dark = _dark(context);

    return Scaffold(
      backgroundColor: _bg(context),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(17, 10, 17, 30),
          children: [
            Row(
              children: [
                SizedBox(
                  width: 34,
                  height: 42,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.maybePop(context),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: _ink(context),
                      size: 23,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Backup',
                        style: TextStyle(
                          color: _ink(context),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Keep your DHANVIQ data safe on this device',
                        style: TextStyle(
                          color: _muted(context),
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _hero(),
            const SizedBox(height: 13),
            _panel(
              child: _itemRow(
                icon: Icons.schedule_rounded,
                title: 'Auto Backup',
                subtitle:
                    'Checks for a due backup when you open this screen.',
                trailing: Switch.adaptive(
                  value: _autoBackup,
                  activeTrackColor: accent,
                  onChanged: _busy ? null : _setAutoBackup,
                ),
              ),
            ),
            const SizedBox(height: 9),
            _panel(
              child: _itemRow(
                icon: Icons.calendar_month_rounded,
                title: 'Backup Frequency',
                subtitle: _frequency,
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: _muted(context),
                  size: 21,
                ),
                onTap:
                    _autoBackup && !_busy ? _chooseFrequency : null,
              ),
            ),
            const SizedBox(height: 13),
            _primaryButton(),
            const SizedBox(height: 12),
            _panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _itemRow(
                    icon: Icons.settings_backup_restore_rounded,
                    title: 'Restore Data',
                    subtitle:
                        'Restore your data from the local backup or copied JSON.',
                  ),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: FilledButton.icon(
                            onPressed: _busy || !_hasBackup
                                ? null
                                : _restoreLastBackup,
                            icon: const Icon(
                              Icons.restore_rounded,
                              size: 18,
                            ),
                            label: const Text('Last Backup'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _tint(context),
                              foregroundColor: accent,
                              disabledBackgroundColor:
                                  _border(context),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: FilledButton.icon(
                            onPressed:
                                _busy ? null : _restoreFromJson,
                            icon: const Icon(
                              Icons.content_paste_rounded,
                              size: 18,
                            ),
                            label: const Text('Paste JSON'),
                            style: FilledButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _panel(
              child: Column(
                children: [
                  _itemRow(
                    icon: Icons.info_rounded,
                    title: 'Backup Information',
                    subtitle:
                        'Transactions plus DHANVIQ local settings, goals, bills, budgets and supported preferences are included.',
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const SizedBox(width: 48),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              _lastBackupLabel,
                              style: TextStyle(
                                color: _muted(context),
                                fontSize: 10.5,
                              ),
                            ),
                            if (_hasBackup) ...[
                              const SizedBox(height: 2),
                              Text(
                                '$_backupItems records in latest backup',
                                style: TextStyle(
                                  color: _muted(context),
                                  fontSize: 9.8,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (_hasBackup)
                        TextButton.icon(
                          onPressed: _busy ? null : _copyBackup,
                          icon: Icon(
                            Icons.copy_rounded,
                            color: accent,
                            size: 15,
                          ),
                          label: Text(
                            'Copy JSON',
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                            ),
                            minimumSize: const Size(0, 32),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Local backup • No cloud upload • App Lock excluded',
                style: TextStyle(
                  color: _muted(context),
                  fontSize: 10,
                ),
              ),
            ),
            if (dark) const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}


class _PasteBackupJsonScreen extends StatefulWidget {
  const _PasteBackupJsonScreen();

  @override
  State<_PasteBackupJsonScreen> createState() =>
      _PasteBackupJsonScreenState();
}

class _PasteBackupJsonScreenState extends State<_PasteBackupJsonScreen> {
  final TextEditingController _controller = TextEditingController();

  bool get _dark =>
      Theme.of(context).brightness == Brightness.dark;

  Color get _accent => Theme.of(context).colorScheme.primary;

  Color get _bg =>
      _dark ? const Color(0xFF0D121D) : const Color(0xFFF8F8FF);

  Color get _surface =>
      _dark ? const Color(0xFF171E2C) : Colors.white;

  Color get _ink =>
      _dark ? const Color(0xFFF7F8FF) : const Color(0xFF172039);

  Color get _muted =>
      _dark ? const Color(0xFF9CA8BD) : const Color(0xFF727D93);

  Color get _border =>
      _dark ? const Color(0xFF293447) : const Color(0xFFE9E7F5);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    final value = _controller.text.trim();

    if (value.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Paste your DHANVIQ backup JSON first.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 19,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste Backup JSON',
              style: TextStyle(
                color: _ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Restore from a copied DHANVIQ backup',
              style: TextStyle(
                color: _muted,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(17, 12, 17, 18),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: _accent,
                      size: 18,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Paste the complete JSON copied from Data Backup. '
                        'DHANVIQ will validate it before restoring anything.',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 10.7,
                          height: 1.42,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: TextStyle(
                    color: _ink,
                    fontSize: 11,
                    height: 1.35,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Paste DHANVIQ backup JSON here...',
                    hintStyle: TextStyle(
                      color: _muted,
                      fontSize: 11,
                    ),
                    filled: true,
                    fillColor: _surface,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: _border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: _border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: _accent,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 49,
                child: FilledButton.icon(
                  onPressed: _continue,
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  icon: const Icon(
                    Icons.settings_backup_restore_rounded,
                    size: 19,
                  ),
                  label: const Text(
                    'Continue to Restore',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
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
