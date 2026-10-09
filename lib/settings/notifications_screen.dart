import 'package:flutter/material.dart';

import '../services/notification_service.dart';

bool _dark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _bg(BuildContext context) =>
    _dark(context) ? const Color(0xFF10141F) : const Color(0xFFF7F8FE);

Color _surface(BuildContext context) =>
    _dark(context) ? const Color(0xFF1B2030) : Colors.white;

Color _ink(BuildContext context) =>
    _dark(context) ? const Color(0xFFF7F7FE) : const Color(0xFF131A2E);

Color _sub(BuildContext context) =>
    _dark(context) ? const Color(0xFFADB5C8) : const Color(0xFF6E7891);

Color _border(BuildContext context) =>
    _dark(context) ? const Color(0xFF303749) : const Color(0xFFE7E9F4);

Color _accent(BuildContext context) => Theme.of(context).colorScheme.primary;

String _timeLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);

  if (day == today) {
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return 'Today • $hour:$minute $period';
  }

  if (day == today.subtract(const Duration(days: 1))) {
    return 'Yesterday';
  }

  const months = <String>[
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
  ];

  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final _service = NotificationService.instance;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service.addListener(_refresh);
    _load();
  }

  Future<void> _load() async {
    await _service.initialize();
    if (mounted) setState(() => _loading = false);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _service.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _clearAll() async {
    if (_service.items.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _surface(dialogContext),
        title: Text(
          'Clear notifications?',
          style: TextStyle(
            color: _ink(dialogContext),
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'This will remove all notifications from this device.',
          style: TextStyle(color: _sub(dialogContext)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Clear all',
              style: TextStyle(color: Color(0xFFE54862)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _service.clearAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _service.items;
    final unread = _service.unreadCount;

    return Scaffold(
      backgroundColor: _bg(context),
      appBar: AppBar(
        backgroundColor: _bg(context),
        foregroundColor: _ink(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: TextStyle(
                color: _ink(context),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              unread == 0
                  ? 'You’re all caught up'
                  : '$unread unread ${unread == 1 ? 'notification' : 'notifications'}',
              style: TextStyle(
                color: _sub(context),
                fontSize: 10.5,
              ),
            ),
          ],
        ),
        actions: [
          if (items.isNotEmpty)
            PopupMenuButton<String>(
              tooltip: 'Notification actions',
              color: _surface(context),
              onSelected: (value) {
                if (value == 'read') {
                  _service.markAllRead();
                } else if (value == 'clear') {
                  _clearAll();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem<String>(
                  value: 'read',
                  enabled: unread > 0,
                  child: const Row(
                    children: [
                      Icon(Icons.done_all_rounded, size: 20),
                      SizedBox(width: 10),
                      Text('Mark all as read'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 20),
                      SizedBox(width: 10),
                      Text('Clear all'),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(width: 5),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: _accent(context)),
            )
          : items.isEmpty
              ? _emptyState()
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, index) => _notificationCard(items[index]),
                ),
    );
  }

  Widget _emptyState() {
    return SafeArea(
      top: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: _accent(context).withValues(
                    alpha: _dark(context) ? .16 : .08,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: _accent(context),
                  size: 43,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'No notifications yet',
                style: TextStyle(
                  color: _ink(context),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Budget alerts, goal updates and upcoming expense reminders will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _sub(context),
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notificationCard(AppNotification item) {
    final visual = _visual(item.category);

    return Material(
      color: _surface(context),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _service.markRead(item.id),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 13, 8, 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: item.isRead
                  ? _border(context)
                  : _accent(context).withValues(alpha: .35),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: visual.$2.withValues(
                    alpha: _dark(context) ? .20 : .10,
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  visual.$1,
                  color: visual.$2,
                  size: 22,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              color: _ink(context),
                              fontSize: 13,
                              fontWeight:
                                  item.isRead ? FontWeight.w700 : FontWeight.w900,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _accent(context),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: TextStyle(
                        color: _sub(context),
                        fontSize: 11.2,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _timeLabel(item.createdAt),
                      style: TextStyle(
                        color: _sub(context),
                        fontSize: 9.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                iconSize: 19,
                color: _surface(context),
                onSelected: (value) {
                  if (value == 'read') {
                    _service.markRead(item.id);
                  } else if (value == 'delete') {
                    _service.delete(item.id);
                  }
                },
                itemBuilder: (_) => [
                  if (!item.isRead)
                    const PopupMenuItem<String>(
                      value: 'read',
                      child: Text('Mark as read'),
                    ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  (IconData, Color) _visual(String category) {
    switch (category) {
      case 'income':
        return (Icons.south_west_rounded, const Color(0xFF10B98E));
      case 'expense':
        return (Icons.north_east_rounded, const Color(0xFFFF4974));
      case 'budget':
        return (Icons.pie_chart_rounded, const Color(0xFFFF9B16));
      case 'goal':
        return (Icons.track_changes_rounded, const Color(0xFF289CF5));
      case 'reminder':
        return (Icons.event_note_rounded, const Color(0xFF7A5AF8));
      case 'security':
        return (Icons.shield_rounded, const Color(0xFF327FF6));
      default:
        return (Icons.notifications_rounded, _accent(context));
    }
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService.instance;

  final Map<String, bool> _preferences = <String, bool>{
    NotificationService.masterKey: true,
    NotificationService.incomeKey: true,
    NotificationService.expenseKey: true,
    NotificationService.remindersKey: true,
    NotificationService.budgetKey: true,
    NotificationService.goalsKey: true,
    NotificationService.summaryKey: false,
    NotificationService.appUpdatesKey: true,
    NotificationService.securityKey: true,
  };

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      await _service.initialize();

      for (final entry in _preferences.entries.toList()) {
        _preferences[entry.key] = await _service.preferenceEnabled(
          entry.key,
          defaultValue: entry.value,
        );
      }

      // Read the master independently because child preferences are forced
      // false by preferenceEnabled when the master switch is off.
      _preferences[NotificationService.masterKey] =
          await _service.preferenceEnabled(
        NotificationService.masterKey,
        defaultValue: true,
      );
    } catch (_) {
      if (mounted) {
        _message('Could not load notification preferences.');
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _change(String key, bool value) async {
    if (_saving || _loading) return;

    final master = _preferences[NotificationService.masterKey] ?? true;

    if (key != NotificationService.masterKey && !master) return;

    final previous = _preferences[key] ?? false;

    setState(() {
      _preferences[key] = value;
      _saving = true;
    });

    try {
      await _service.setPreference(key, value);
    } catch (_) {
      if (mounted) {
        setState(() => _preferences[key] = previous);
        _message('Could not save this setting.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text) {
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

  bool _value(String key) => _preferences[key] ?? false;

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);

    return Scaffold(
      backgroundColor: _bg(context),
      appBar: AppBar(
        backgroundColor: _bg(context),
        foregroundColor: _ink(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Settings',
              style: TextStyle(
                color: _ink(context),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Choose which in-app alerts you want',
              style: TextStyle(
                color: _sub(context),
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: accent),
            )
          : SafeArea(
              top: false,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(17, 9, 17, 28),
                children: [
                  _group([
                    _row(
                      keyName: NotificationService.masterKey,
                      icon: Icons.notifications_rounded,
                      iconColor: accent,
                      title: 'Enable Notifications',
                      subtitle: 'Turn all DHANVIQ alerts on or off',
                      master: true,
                    ),
                  ]),
                  _heading(
                    'Transactions',
                    'Alerts related to money you add or spend',
                  ),
                  _group([
                    _row(
                      keyName: NotificationService.incomeKey,
                      icon: Icons.south_west_rounded,
                      iconColor: const Color(0xFF10B98E),
                      title: 'Income Added',
                      subtitle: 'Alert when new income is recorded',
                    ),
                    _row(
                      keyName: NotificationService.expenseKey,
                      icon: Icons.north_east_rounded,
                      iconColor: const Color(0xFFFF4974),
                      title: 'Expense Added',
                      subtitle: 'Alert when a new expense is recorded',
                    ),
                    _row(
                      keyName: NotificationService.remindersKey,
                      icon: Icons.event_note_rounded,
                      iconColor: const Color(0xFF7A5AF8),
                      title: 'Upcoming Expenses',
                      subtitle: 'Bills and payment reminders due soon',
                    ),
                  ]),
                  _heading(
                    'Budget & Goals',
                    'Stay informed about your financial progress',
                  ),
                  _group([
                    _row(
                      keyName: NotificationService.budgetKey,
                      icon: Icons.pie_chart_rounded,
                      iconColor: const Color(0xFFFF9B16),
                      title: 'Budget Alerts',
                      subtitle: 'Warnings near 80% and 100% of a budget',
                    ),
                    _row(
                      keyName: NotificationService.goalsKey,
                      icon: Icons.track_changes_rounded,
                      iconColor: const Color(0xFF289CF5),
                      title: 'Goal Updates',
                      subtitle: 'Milestones as savings goals progress',
                    ),
                    _row(
                      keyName: NotificationService.summaryKey,
                      icon: Icons.insights_rounded,
                      iconColor: const Color(0xFF10B98E),
                      title: 'Weekly Summary',
                      subtitle: 'Keep this ready for weekly finance summaries',
                    ),
                  ]),
                  _heading(
                    'App & Security',
                    'Important app and account related alerts',
                  ),
                  _group([
                    _row(
                      keyName: NotificationService.appUpdatesKey,
                      icon: Icons.system_update_alt_rounded,
                      iconColor: accent,
                      title: 'App Updates',
                      subtitle: 'Important DHANVIQ app notices',
                    ),
                    _row(
                      keyName: NotificationService.securityKey,
                      icon: Icons.shield_rounded,
                      iconColor: const Color(0xFF327FF6),
                      title: 'Security Alerts',
                      subtitle: 'Important local security information',
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: accent.withValues(
                        alpha: _dark(context) ? .11 : .055,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: accent,
                          size: 18,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'These settings control DHANVIQ’s in-app notification center. '
                            'Alerts are stored locally on this device and appear from the Home bell.',
                            style: TextStyle(
                              color: _sub(context),
                              fontSize: 10.7,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _heading(String title, String description) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 19, 2, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _ink(context),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            description,
            style: TextStyle(
              color: _sub(context),
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _group(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: _surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border(context)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 52,
                endIndent: 12,
                color: _border(context),
              ),
            children[i],
          ],
        ],
      ),
    );
  }

  Widget _row({
    required String keyName,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool master = false,
  }) {
    final active = master ||
        (_preferences[NotificationService.masterKey] ?? true);

    return Opacity(
      opacity: active ? 1 : .48,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
        child: Row(
          children: [
            Container(
              width: 37,
              height: 37,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconColor.withValues(
                  alpha: _dark(context) ? .22 : .11,
                ),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
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
                    subtitle,
                    style: TextStyle(
                      color: _sub(context),
                      fontSize: 10.2,
                      height: 1.28,
                    ),
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: .84,
              alignment: Alignment.centerRight,
              child: Switch.adaptive(
                value: _value(keyName),
                onChanged: active && !_saving
                    ? (value) => _change(keyName, value)
                    : null,
                activeTrackColor: _accent(context),
                activeThumbColor: Colors.white,
                inactiveTrackColor: _dark(context)
                    ? const Color(0xFF535B70)
                    : const Color(0xFFD9DEEA),
                inactiveThumbColor: Colors.white,
                trackOutlineColor:
                    WidgetStateProperty.all(Colors.transparent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
