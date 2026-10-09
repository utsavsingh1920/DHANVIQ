import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:flutter_windowmanager_plus/flutter_windowmanager_plus.dart';

import 'package:local_auth/local_auth.dart';

import 'package:shared_preferences/shared_preferences.dart';

// DHANVIQ App Lock — settings, credential storage and app-wide guard.

// Add AppLockGate to MaterialApp.builder (see app_lock_setup.txt).

Color _accent(BuildContext c) => Theme.of(c).colorScheme.primary;

bool _dark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

Color _bg(BuildContext c) => _dark(c) ? const Color(0xFF0F141E) : const Color(0xFFF7F8FE);

Color _card(BuildContext c) => _dark(c) ? const Color(0xFF191F2D) : Colors.white;

Color _ink(BuildContext c) => _dark(c) ? const Color(0xFFF5F5FD) : const Color(0xFF151B30);

Color _muted(BuildContext c) => _dark(c) ? const Color(0xFFABB3CB) : const Color(0xFF778098);

Color _border(BuildContext c) => _dark(c) ? const Color(0xFF30394B) : const Color(0xFFE7E9F2);

Color _tint(BuildContext c) => _accent(c).withValues(alpha: _dark(c) ? .19 : .095);

class DhanviqAppLock extends ChangeNotifier {

  DhanviqAppLock._();

  static final DhanviqAppLock instance = DhanviqAppLock._();

  static const _secretKey = 'dhanviq_app_lock_credential_v1';

  static const _prefsPrefix = 'dhanviq_lock_';

  final _secure = const FlutterSecureStorage();

  final _auth = LocalAuthentication();

  Future<void>? _loadFuture;

  bool enabled = false;

  bool hideContent = true;

  bool unlocked = false;

  bool authenticating = false;

  // App Lock only guards an authenticated in-app session.
  // It stays false during splash, onboarding, welcome and login.
  bool guardActive = false;

  String method = 'pin'; // pin, pattern, biometric

  String fallback = 'pin'; // biometric always retains a PIN/pattern fallback

  int autoLockMinutes = 1; // 0 = immediately

  int failedAttempts = 0;

  DateTime? blockedUntil;

  bool get locked => guardActive && enabled && !unlocked;

  Future<void> load() => _loadFuture ??= _readSettings();

  Future<void> _readSettings() async {

    final prefs = await SharedPreferences.getInstance();

    final wantsLock = prefs.getBool('${_prefsPrefix}enabled') ?? false;

    // Do not silently disable a configured lock if secure storage is unavailable.

    if (wantsLock && await _secure.read(key: _secretKey) == null) {

      throw StateError('App Lock credential is unavailable. Do not clear app data to bypass it.');

    }

    enabled = wantsLock;

    method = prefs.getString('${_prefsPrefix}method') ?? 'pin';

    fallback = prefs.getString('${_prefsPrefix}fallback') ?? 'pin';

    hideContent = prefs.getBool('${_prefsPrefix}hide') ?? true;

    autoLockMinutes = prefs.getInt('${_prefsPrefix}delay') ?? 1;

    unlocked = !enabled;

    await syncPrivacy();

    notifyListeners();

  }

  void beginAuthenticatedSession({required bool lockNow}) {

    guardActive = true;

    if (enabled && lockNow) {

      unlocked = false;

    } else {

      unlocked = true;

      failedAttempts = 0;

      blockedUntil = null;

    }

    notifyListeners();

  }

  void endAuthenticatedSession() {

    guardActive = false;

    unlocked = true;

    failedAttempts = 0;

    blockedUntil = null;

    notifyListeners();

  }

  Future<void> syncPrivacy() async {

    if (!Platform.isAndroid) return;

    await FlutterWindowManagerPlus.setSecure(enabled && hideContent);

  }

  Future<void> enable(String credential, {required String kind}) async {

    await _secure.write(key: _secretKey, value: '$kind:$credential');

    final prefs = await SharedPreferences.getInstance();

    fallback = kind;

    method = kind;

    await prefs.setString('${_prefsPrefix}fallback', kind);

    await prefs.setString('${_prefsPrefix}method', kind);

    await prefs.setBool('${_prefsPrefix}enabled', true);

    enabled = true;

    unlocked = true; // Do not immediately lock the user who just configured it.

    await syncPrivacy();

    notifyListeners();

  }

  Future<void> changeCredential(String credential, {required String kind}) async {

    await _secure.write(key: _secretKey, value: '$kind:$credential');

    fallback = kind;

    method = kind;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('${_prefsPrefix}fallback', kind);

    await prefs.setString('${_prefsPrefix}method', kind);

    notifyListeners();

  }

  Future<void> disable() async {

    // Change the preference before deleting the secret to avoid leaving an

    // enabled lock with no credential on a normal, successful disable.

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('${_prefsPrefix}enabled', false);

    enabled = false;

    unlocked = true;

    method = 'pin';

    await _secure.delete(key: _secretKey);

    await syncPrivacy();

    notifyListeners();

  }

  Future<void> setMethod(String value) async {

    method = value;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('${_prefsPrefix}method', value);

    notifyListeners();

  }

  Future<void> setHide(bool value) async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('${_prefsPrefix}hide', value);

    hideContent = value;

    await syncPrivacy();

    notifyListeners();

  }

  Future<void> setDelay(int value) async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('${_prefsPrefix}delay', value);

    autoLockMinutes = value;

    notifyListeners();

  }

  void lock() {

    if (guardActive && enabled && !locked) {

      unlocked = false;

      notifyListeners();

    }

  }

  void unlock() {

    unlocked = true;

    failedAttempts = 0;

    blockedUntil = null;

    notifyListeners();

  }

  Future<bool> verify(String value) async {

    final blocked = blockedUntil;

    if (blocked != null && DateTime.now().isBefore(blocked)) return false;

    final stored = await _secure.read(key: _secretKey);

    final valid = stored != null && stored == '$fallback:$value';

    if (valid) {

      failedAttempts = 0;

      blockedUntil = null;

    } else {

      failedAttempts++;

      if (failedAttempts >= 5) {

        blockedUntil = DateTime.now().add(const Duration(seconds: 30));

        failedAttempts = 0;

      }

    }

    notifyListeners();

    return valid;

  }

  Future<bool> canUseBiometric() async {

    try {

      return await _auth.canCheckBiometrics &&

          (await _auth.getAvailableBiometrics()).isNotEmpty;

    } catch (_) {

      return false;

    }

  }

  Future<bool> biometric({String reason = 'Unlock DHANVIQ'}) async {

    if (authenticating) return false;

    authenticating = true;

    notifyListeners();

    try {

      return await _auth.authenticate(

        localizedReason: reason,

        biometricOnly: true,

        persistAcrossBackgrounding: true,

      );

    } catch (_) {

      return false;

    } finally {

      authenticating = false;

      notifyListeners();

    }

  }

}

class AppLockScreen extends StatefulWidget {

  const AppLockScreen({super.key});

  @override

  State<AppLockScreen> createState() => _AppLockScreenState();

}

class _AppLockScreenState extends State<AppLockScreen> {

  final _lock = DhanviqAppLock.instance;

  bool _busy = false;

  String? _error;

  @override

  void initState() {

    super.initState();

    _lock.addListener(_refresh);

    _lock.load().then((_) {

      if (mounted) setState(() {});

    }).catchError((Object e) {

      if (mounted) setState(() => _error = e.toString());

    });

  }

  @override

  void dispose() {

    _lock.removeListener(_refresh);

    super.dispose();

  }

  void _refresh() { if (mounted) setState(() {}); }

  void _toast(String text) => ScaffoldMessenger.of(context)

      .showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));

  Future<void> _perform(Future<void> Function() action) async {

    if (_busy) return;

    setState(() => _busy = true);

    try {

      await action();

    } catch (e) {

      if (mounted) _toast('Could not update App Lock: $e');

    } finally {

      if (mounted) setState(() => _busy = false);

    }

  }

  Future<bool> _confirmExisting() async {

    if (!_lock.enabled) return true;

    final kind = _lock.fallback;

    final credential = await _credentialDialog(

      title: 'Confirm current ${kind == 'pin' ? 'PIN' : 'pattern'}',

      kind: kind, confirm: false,

    );

    if (credential == null || !mounted) return false;

    final ok = await _lock.verify(credential);

    if (mounted && !ok) {
      _toast('Incorrect ${kind == 'pin' ? 'PIN' : 'pattern'}.');
    }

    return ok;

  }

  Future<String?> _credentialDialog({

    required String title,

    required String kind,

    required bool confirm,

  }) async {

    String? first;

    do {

      if (!mounted) return null;

      final value = await showDialog<String>(

        context: context,

        barrierDismissible: false,

        builder: (_) => _CredentialDialog(title: first == null ? title : 'Confirm $title', kind: kind),

      );

      if (value == null || !mounted) return null;

      if (!confirm) return value;

      if (first == null) {

        first = value;

      } else if (first == value) {

        return value;

      } else {

        _toast('Codes did not match. Please try again.');

        first = null;

      }

    } while (true);

  }

  Future<void> _toggleEnabled(bool enable) => _perform(() async {

    if (enable) {

      final credential = await _credentialDialog(

        title: 'Create your PIN', kind: 'pin', confirm: true,

      );

      if (credential == null) return;

      await _lock.enable(credential, kind: 'pin');

      if (mounted) {
        _toast('App Lock enabled. Your PIN is required on next unlock.');
      }

    } else {

      if (!await _confirmExisting()) return;

      await _lock.disable();

      if (mounted) {
        _toast('App Lock disabled.');
      }

    }

  });

  Future<void> _chooseMethod(String kind) => _perform(() async {

    if (!_lock.enabled) {

      _toast('Enable App Lock first to choose a lock type.');

      return;

    }

    if (kind == _lock.method) return;

    if (kind == 'biometric') {

      if (!await _lock.canUseBiometric()) {

        _toast('No enrolled fingerprint/face authentication is available on this device.');

        return;

      }

      final ok = await _lock.biometric(reason: 'Enable biometric unlock for DHANVIQ');

      if (!ok) {

        if (mounted) _toast('Biometric authentication was not completed.');

        return;

      }

      await _lock.setMethod('biometric');

      if (mounted) _toast('Biometric enabled. Your existing code remains the fallback.');

      return;

    }

    if (!await _confirmExisting()) return;

    final code = await _credentialDialog(

      title: kind == 'pin' ? 'Create your PIN' : 'Draw a new pattern',

      kind: kind, confirm: true,

    );

    if (code == null) return;

    await _lock.changeCredential(code, kind: kind);

    if (mounted) _toast('Lock type updated.');

  });

  Future<void> _changeCode() => _perform(() async {

    if (!await _confirmExisting()) return;

    final kind = _lock.fallback;

    final newCode = await _credentialDialog(

      title: kind == 'pin' ? 'Create new PIN' : 'Draw a new pattern',

      kind: kind, confirm: true,

    );

    if (newCode == null) return;

    await _lock.changeCredential(newCode, kind: kind);

    if (mounted) _toast('Lock code updated.');

  });

  Future<void> _chooseDelay() async {

    if (!_lock.enabled || _busy) return;

    final delay = await showModalBottomSheet<int>(

      context: context,

      showDragHandle: true,

      backgroundColor: _card(context),

      builder: (sheet) => SafeArea(

        child: Padding(

          padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),

          child: Column(mainAxisSize: MainAxisSize.min, children: [

            Text('Auto Lock', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _ink(context))),

            for (final choice in const <(int, String)>[(0, 'Immediately'), (1, '1 Minute'), (5, '5 Minutes'), (15, '15 Minutes')])

              ListTile(

                title: Text(choice.$2, style: TextStyle(color: _ink(context))),

                trailing: Icon(_lock.autoLockMinutes == choice.$1 ? Icons.radio_button_checked : Icons.radio_button_unchecked,

                    color: _lock.autoLockMinutes == choice.$1 ? _accent(context) : _muted(context)),

                onTap: () => Navigator.pop(sheet, choice.$1),

              ),

          ]),

        ),

      ),

    );

    if (delay != null) await _perform(() => _lock.setDelay(delay));

  }

  @override

  Widget build(BuildContext context) {

    final accent = _accent(context);

    final dark = _dark(context);

    return Scaffold(

      backgroundColor: _bg(context),

      appBar: AppBar(

        backgroundColor: _bg(context),

        foregroundColor: _ink(context),

        scrolledUnderElevation: 0,

        titleSpacing: 0,

        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Text('App Lock', style: TextStyle(color: _ink(context), fontWeight: FontWeight.w800, fontSize: 19)),

          Text('Keep your app and data private', style: TextStyle(color: _muted(context), fontSize: 11)),

        ]),

      ),

      body: _error != null

          ? Center(child: Padding(padding: const EdgeInsets.all(22), child: Text(_error!, style: TextStyle(color: _ink(context)))))

          : AnimatedBuilder(

              animation: _lock,

              builder: (context, _) => AbsorbPointer(

                absorbing: _busy,

                child: ListView(

                  padding: const EdgeInsets.fromLTRB(18, 9, 18, 34),

                  children: [

                    Container(

                      height: 150,

                      padding: const EdgeInsets.all(16),

                      decoration: BoxDecoration(

                        borderRadius: BorderRadius.circular(17),

                        gradient: LinearGradient(

                          begin: Alignment.topLeft, end: Alignment.bottomRight,

                          colors: dark

                              ? [accent.withValues(alpha: .31), const Color(0xFF1C2034), _card(context)]

                              : [accent.withValues(alpha: .14), accent.withValues(alpha: .055), const Color(0xFFF4F5FF)],

                        ),

                        border: Border.all(color: accent.withValues(alpha: .15)),

                      ),

                      child: Row(children: [

                        Expanded(child: Column(

                          crossAxisAlignment: CrossAxisAlignment.start,

                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [

                            Text('Add an extra layer\nof security',

                                style: TextStyle(fontSize: 17, height: 1.16, fontWeight: FontWeight.w900, color: _ink(context))),

                            const SizedBox(height: 12),

                            Text('Protect your app from\nunauthorized access with a\nPIN, pattern or biometric lock.',

                                style: TextStyle(color: _muted(context), fontSize: 10.8, height: 1.35)),

                          ],

                        )),

                        Container(

                          width: 95, height: 95,

                          decoration: BoxDecoration(

                            shape: BoxShape.circle, color: accent.withValues(alpha: .12),

                          ),

                          child: Icon(Icons.shield_rounded, size: 79, color: accent),

                        ),

                      ]),

                    ),

                    const SizedBox(height: 10),

                    _panel(children: [

                      _row(Icons.lock_outline_rounded, 'Enable App Lock',

                        'Lock the app when you close it\nor switch to another app',

                        trailing: _switch(_lock.enabled, _toggleEnabled)),

                    ]),

                    const SizedBox(height: 13),

                    Text('Choose Lock Type', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _ink(context))),

                    const SizedBox(height: 6),

                    _panel(children: [

                      _row(Icons.dialpad_rounded, 'PIN', 'Enter a 4–6 digit PIN to unlock',

                        onTap: () => _chooseMethod('pin'),

                        trailing: _radio(_lock.method == 'pin')),

                      _row(Icons.gesture_rounded, 'Pattern', 'Draw a pattern to unlock',

                        onTap: () => _chooseMethod('pattern'),

                        trailing: _radio(_lock.method == 'pattern')),

                      _row(Icons.fingerprint_rounded, 'Biometric', 'Use your fingerprint or face to unlock',

                        onTap: () => _chooseMethod('biometric'),

                        trailing: _radio(_lock.method == 'biometric'), divider: false),

                    ]),

                    const SizedBox(height: 12),

                    _panel(children: [

                      _row(Icons.access_time_rounded, 'Auto Lock',

                        'Lock after a period of inactivity',

                        onTap: _chooseDelay,

                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [

                          Text(_lock.autoLockMinutes == 0 ? 'Immediately' : '${_lock.autoLockMinutes} Minute${_lock.autoLockMinutes == 1 ? '' : 's'}',

                              style: TextStyle(color: _muted(context), fontSize: 11)),

                          const SizedBox(width: 3), Icon(Icons.chevron_right_rounded, size: 19, color: _muted(context)),

                        ]),

                      ),

                      _row(Icons.shield_outlined, 'Hide App Content',

                        Platform.isAndroid ? 'Hide sensitive data in recent apps' : 'Available on Android only',

                        divider: false,

                        trailing: _switch(_lock.hideContent, (v) => _perform(() => _lock.setHide(v))),

                      ),

                    ]),

                    if (_lock.enabled) ...[

                      const SizedBox(height: 12),

                      OutlinedButton.icon(

                        onPressed: _changeCode,

                        icon: Icon(_lock.fallback == 'pin' ? Icons.pin_outlined : Icons.gesture_rounded),

                        label: Text(_lock.fallback == 'pin' ? 'Change PIN' : 'Change Pattern'),

                        style: OutlinedButton.styleFrom(foregroundColor: accent, side: BorderSide(color: _border(context))),

                      ),

                    ],

                    const SizedBox(height: 10),

                    Text('PIN / pattern settings are stored securely on this device. Biometric unlock requires an enrolled fingerprint or face. Android Hide App Content also blocks screenshots while enabled.',

                        style: TextStyle(color: _muted(context), fontSize: 10.5, height: 1.5)),

                  ],

                ),

              ),

            ),

    );

  }

  Widget _panel({required List<Widget> children}) => Container(

    decoration: BoxDecoration(color: _card(context), borderRadius: BorderRadius.circular(14),

        border: Border.all(color: _border(context).withValues(alpha: _dark(context) ? .7 : .45))),

    child: Column(children: children),

  );

  Widget _row(IconData icon, String title, String subtitle, {

    Widget? trailing, VoidCallback? onTap, bool divider = true,

  }) => Column(children: [

    Material(color: Colors.transparent, child: InkWell(

      onTap: onTap, borderRadius: BorderRadius.circular(12),

      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),

        child: Row(children: [

          Container(width: 36, height: 36,

            decoration: BoxDecoration(color: _tint(context), borderRadius: BorderRadius.circular(10)),

            child: Icon(icon, color: _accent(context), size: 20)),

          const SizedBox(width: 10),

          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: _ink(context))),

            const SizedBox(height: 2),

            Text(subtitle, style: TextStyle(color: _muted(context), fontSize: 10, height: 1.3)),

          ])),

          if (trailing != null) ...[const SizedBox(width: 4), trailing],

        ]),

      ),

    )),

    if (divider) Divider(height: 1, indent: 56, endIndent: 10, color: _border(context)),

  ]);

  Widget _radio(bool selected) => Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,

      color: selected ? _accent(context) : _muted(context), size: 20);

  Widget _switch(bool value, ValueChanged<bool> onChanged) => Transform.scale(

    scale: .82,

    child: Switch(value: value, onChanged: onChanged,

      activeThumbColor: Colors.white, activeTrackColor: _accent(context),

      inactiveThumbColor: _dark(context) ? const Color(0xFFB2BAD0) : Colors.white,

      inactiveTrackColor: _dark(context) ? const Color(0xFF485368) : const Color(0xFFD9DDE9),

      trackOutlineColor: WidgetStateProperty.all(Colors.transparent)),

  );

}

class _CredentialDialog extends StatefulWidget {

  const _CredentialDialog({required this.title, required this.kind});

  final String title;

  final String kind;

  @override

  State<_CredentialDialog> createState() => _CredentialDialogState();

}

class _CredentialDialogState extends State<_CredentialDialog> {

  final _controller = TextEditingController();

  String? _error;

  @override

  void dispose() { _controller.dispose(); super.dispose(); }

  @override

  Widget build(BuildContext context) => AlertDialog(

    backgroundColor: _card(context),

    title: Text(widget.title, style: TextStyle(color: _ink(context), fontSize: 18)),

    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [

      if (widget.kind == 'pin')

        TextField(

          controller: _controller, autofocus: true, obscureText: true,

          keyboardType: TextInputType.number, textAlign: TextAlign.center,

          maxLength: 6,

          inputFormatters: [FilteringTextInputFormatter.digitsOnly],

          decoration: InputDecoration(hintText: '4–6 digit PIN', errorText: _error),

        )

      else ...[

        Text('Connect at least 4 dots in one stroke.', style: TextStyle(color: _muted(context), fontSize: 12)),

        const SizedBox(height: 12),

        _PatternPad(onCompleted: (v) { setState(() { _controller.text = v; _error = null; }); }),

        if (_controller.text.isNotEmpty) Text('Pattern captured', style: TextStyle(color: _accent(context))),

        if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),

      ],

    ])),

    actions: [

      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),

      FilledButton(onPressed: () {

        final value = _controller.text;

        if (widget.kind == 'pin' && !RegExp(r'^\d{4,6}$').hasMatch(value)) {

          setState(() => _error = 'Enter 4–6 digits'); return;

        }

        if (widget.kind == 'pattern' && value.split('-').length < 4) {

          setState(() => _error = 'Connect at least 4 dots'); return;

        }

        Navigator.pop(context, value);

      }, child: const Text('Continue')),

    ],

  );

}

class _PatternPad extends StatefulWidget {

  const _PatternPad({required this.onCompleted});

  final ValueChanged<String> onCompleted;

  @override

  State<_PatternPad> createState() => _PatternPadState();

}

class _PatternPadState extends State<_PatternPad> {

  final _selected = <int>[];

  Offset? _pointer;

  static const double _size = 214;

  void _append(Offset local) {

    if (local.dx < 0 || local.dy < 0 || local.dx > _size || local.dy > _size) return;

    final col = (local.dx / _size * 3).floor().clamp(0, 2);

    final row = (local.dy / _size * 3).floor().clamp(0, 2);

    final i = row * 3 + col;

    final center = Offset((col + .5) * _size / 3, (row + .5) * _size / 3);

    if ((local - center).distance < 27 && !_selected.contains(i)) {

      setState(() => _selected.add(i));

    }

    setState(() => _pointer = local);

  }

  void _done() {

    final code = _selected.join('-');

    if (code.isNotEmpty) widget.onCompleted(code);

    setState(() { _pointer = null; _selected.clear(); });

  }

  @override

  Widget build(BuildContext context) => Center(child: GestureDetector(

    onPanStart: (d) { setState(_selected.clear); _append(d.localPosition); },

    onPanUpdate: (d) => _append(d.localPosition),

    onPanEnd: (_) => _done(),

    child: SizedBox(width: _size, height: _size,

      child: CustomPaint(painter: _PatternPainter(_selected, _pointer, _accent(context), _muted(context)))),

  ));

}

class _PatternPainter extends CustomPainter {

  _PatternPainter(this.selected, this.pointer, this.accent, this.muted);

  final List<int> selected;

  final Offset? pointer;

  final Color accent, muted;

  @override

  void paint(Canvas canvas, Size size) {

    Offset position(int i) => Offset((i % 3 + .5) * size.width / 3, (i ~/ 3 + .5) * size.height / 3);

    final paint = Paint()..color = accent..strokeWidth = 4..strokeCap = StrokeCap.round;

    for (var j = 1; j < selected.length; j++) {

      canvas.drawLine(position(selected[j - 1]), position(selected[j]), paint);

    }

    if (pointer != null && selected.isNotEmpty) canvas.drawLine(position(selected.last), pointer!, paint);

    for (var i = 0; i < 9; i++) {

      final selectedNode = selected.contains(i);

      canvas.drawCircle(position(i), selectedNode ? 12 : 9,

          Paint()..color = selectedNode ? accent.withValues(alpha: .24) : muted.withValues(alpha: .13));

      canvas.drawCircle(position(i), selectedNode ? 6 : 5, Paint()..color = selectedNode ? accent : muted);

    }

  }

  @override

  bool shouldRepaint(covariant _PatternPainter old) => old.pointer != pointer ||

      old.accent != accent || old.muted != muted || ! _same(old.selected, selected);

  bool _same(List<int> a, List<int> b) {

    if (a.length != b.length) return false;

    for (var i = 0; i < a.length; i++) { if (a[i] != b[i]) return false; }

    return true;

  }

}

// Integrate once at MaterialApp.builder. The navigator is hidden while locked.

class AppLockGate extends StatefulWidget {

  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override

  State<AppLockGate> createState() => _AppLockGateState();

}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {

  final _lock = DhanviqAppLock.instance;

  bool _loading = true;

  String? _error;

  DateTime? _backgroundedAt;

  @override

  void initState() {

    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _lock.addListener(_refresh);

    _lock.load().then((_) {

      if (mounted) setState(() => _loading = false);

    }).catchError((Object e) {

      if (mounted) setState(() { _error = e.toString(); _loading = false; });

    });

  }

  @override

  void dispose() {

    WidgetsBinding.instance.removeObserver(this);

    _lock.removeListener(_refresh);

    super.dispose();

  }

  void _refresh() { if (mounted) setState(() {}); }

  @override

  void didChangeAppLifecycleState(AppLifecycleState state) {

    _handleLifecycle(state);

  }

  Future<void> _handleLifecycle(AppLifecycleState state) async {

    if (!_lock.guardActive || !_lock.enabled || _lock.authenticating) return;

    final prefs = await SharedPreferences.getInstance();

    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (!isLoggedIn) {

      _backgroundedAt = null;

      _lock.endAuthenticatedSession();

      return;

    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {

      _backgroundedAt ??= DateTime.now();

      if (_lock.autoLockMinutes == 0) {

        _lock.lock();

      }

      return;

    }

    if (state == AppLifecycleState.resumed) {

      final start = _backgroundedAt;

      _backgroundedAt = null;

      if (start != null &&
          DateTime.now().difference(start) >=
              Duration(minutes: _lock.autoLockMinutes)) {

        _lock.lock();

      }

    }

  }

  @override

  Widget build(BuildContext context) {

    // Splash/onboarding/welcome/login always render normally.
    if (!_lock.guardActive) {

      return widget.child;

    }

    if (_loading || _error != null) {

      return Material(
        color: _bg(context),
        child: Center(
          child: _error == null
              ? CircularProgressIndicator(color: _accent(context))
              : Padding(
                  padding: const EdgeInsets.all(26),
                  child: Text(
                    'Could not load App Lock: $_error',
                    style: TextStyle(color: _ink(context)),
                  ),
                ),
        ),
      );

    }

    return Stack(
      children: [

        Offstage(
          offstage: _lock.locked,
          child: TickerMode(
            enabled: !_lock.locked,
            child: widget.child,
          ),
        ),

        if (_lock.locked)
          Positioned.fill(
            child: _UnlockScreen(lock: _lock),
          ),

      ],
    );

  }

}

class _UnlockScreen extends StatefulWidget {

  const _UnlockScreen({required this.lock});

  final DhanviqAppLock lock;

  @override

  State<_UnlockScreen> createState() => _UnlockScreenState();

}

class _UnlockScreenState extends State<_UnlockScreen> {
  final _pin = TextEditingController();

  String? _message;
  bool _checking = false;
  bool _showFallback = false;

  @override
  void initState() {
    super.initState();

    // PIN / Pattern mode opens directly.
    // Biometric mode starts with biometric only.
    _showFallback = widget.lock.method != 'biometric';

    if (widget.lock.method == 'biometric') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _bio();
        }
      });
    }
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _check(String code) async {
    if (_checking) return;

    if (code.trim().isEmpty) {
      setState(() => _message = 'Enter your backup code.');
      return;
    }

    setState(() {
      _checking = true;
      _message = null;
    });

    try {
      final valid = await widget.lock.verify(code);

      if (!mounted) return;

      if (valid) {
        widget.lock.unlock();
        return;
      }

      final until = widget.lock.blockedUntil;

      setState(() {
        _pin.clear();
        _message = until != null && DateTime.now().isBefore(until)
            ? 'Too many attempts. Try again after 30 seconds.'
            : 'Incorrect code. Try again.';
      });
    } catch (e) {
      if (mounted) {
        setState(() => _message = 'Unable to verify the code: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }

  Future<void> _bio() async {
    if (_checking) return;

    setState(() {
      _checking = true;
      _message = null;
    });

    final valid = await widget.lock.biometric();

    if (!mounted) return;

    setState(() => _checking = false);

    if (valid) {
      widget.lock.unlock();
      return;
    }

    setState(() {
      _message =
          'Fingerprint was not verified. Try again or use your backup code.';
    });
  }

  void _useFallback() {
    setState(() {
      _showFallback = true;
      _message = null;
    });
  }

  void _backToBiometric() {
    setState(() {
      _showFallback = false;
      _pin.clear();
      _message = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _bio();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lock = widget.lock;
    final biometricMode = lock.method == 'biometric';

    return Material(
      color: _bg(context),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _tint(context),
                    ),
                    child: Icon(
                      biometricMode && !_showFallback
                          ? Icons.fingerprint_rounded
                          : Icons.lock_rounded,
                      color: _accent(context),
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Unlock DHANVIQ',
                    style: TextStyle(
                      color: _ink(context),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    biometricMode && !_showFallback
                        ? 'Use your fingerprint to continue.'
                        : 'Enter your backup code to continue.',
                    style: TextStyle(
                      color: _muted(context),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 26),

                  if (biometricMode && !_showFallback) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _checking ? null : _bio,
                        icon: const Icon(Icons.fingerprint_rounded),
                        label: Text(
                          _checking
                              ? 'Checking fingerprint...'
                              : 'Unlock with Fingerprint',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _checking ? null : _useFallback,
                      child: Text(
                        lock.fallback == 'pin'
                            ? 'Use PIN instead'
                            : 'Use Pattern instead',
                      ),
                    ),
                  ],

                  if (!biometricMode || _showFallback) ...[
                    if (lock.fallback == 'pin') ...[
                      TextField(
                        controller: _pin,
                        obscureText: true,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onSubmitted: (_) => _check(_pin.text),
                        decoration: const InputDecoration(
                          hintText: 'Enter 4–6 digit PIN',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 9),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed:
                              _checking ? null : () => _check(_pin.text),
                          child: const Text('Unlock with PIN'),
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Draw your unlock pattern',
                        style: TextStyle(color: _ink(context)),
                      ),
                      const SizedBox(height: 12),
                      _PatternPad(onCompleted: _check),
                    ],

                    if (biometricMode) ...[
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: _checking ? null : _backToBiometric,
                        icon: const Icon(Icons.fingerprint_rounded),
                        label: const Text('Use Fingerprint instead'),
                      ),
                    ],
                  ],

                  if (_checking && !(biometricMode && !_showFallback))
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ),

                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFFF6475),
                          fontSize: 12,
                        ),
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
}
