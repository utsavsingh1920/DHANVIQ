import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../navigation/main_navigation_screen.dart';

import '../settings/app_lock_screen.dart';

import 'signup_screen.dart';

const _navy = Color(0xFF101936);

const _muted = Color(0xFF747D94);

const _background = Color(0xFFF8F9FE);

// The app's MaterialApp.themeMode controls the effective brightness here.

// Light, Dark and System Default therefore need no separate preference read.

Color _accent(BuildContext context) => Theme.of(context).colorScheme.primary;

Color _onAccent(BuildContext context) =>
    ThemeData.estimateBrightnessForColor(_accent(context)) == Brightness.dark
    ? Colors.white
    : const Color(0xFF101936);

bool _dark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _ink(BuildContext context) =>
    _dark(context) ? const Color(0xFFF4F3FF) : _navy;

Color _secondary(BuildContext context) =>
    _dark(context) ? const Color(0xFFABB2CB) : _muted;

Color _surface(BuildContext context) =>
    _dark(context) ? const Color(0xFF1A2038) : Colors.white;

Color _canvas(BuildContext context) =>
    _dark(context) ? const Color(0xFF090E20) : _background;

Color _line(BuildContext context) =>
    _dark(context) ? const Color(0xFF343B55) : const Color(0xFFCFD4E2);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();

  bool _hidePassword = true;

  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();

    _passwordController.dispose();

    super.dispose();
  }

  void _openSignUp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const SignUpScreen()),
    );
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      _message('Please correct the highlighted fields.');
      return;
    }

    // DEMO ONLY: form validation, not credential authentication.

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('onboardingCompleted', true);

    await prefs.setBool('isLoggedIn', true);

    final appLock = DhanviqAppLock.instance;

    await appLock.load();

    // A successful login goes straight to Home.

    // App Lock protects later background/reopen events and future cold starts.

    appLock.beginAuthenticatedSession(lockNow: false);

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const MainNavigationScreen()),

      (route) => false,
    );
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,

        statusBarIconBrightness: _dark(context)
            ? Brightness.light
            : Brightness.dark,

        statusBarBrightness: _dark(context)
            ? Brightness.dark
            : Brightness.light,

        systemNavigationBarColor: _canvas(context),

        systemNavigationBarIconBrightness: _dark(context)
            ? Brightness.light
            : Brightness.dark,

        systemNavigationBarDividerColor: _canvas(context),
      ),

      child: Scaffold(
        resizeToAvoidBottomInset: false,

        backgroundColor: _canvas(context),

        body: Stack(
          children: [
            Positioned.fill(child: _Background()),

            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,

                      alignment: Alignment.center,

                      child: SizedBox(
                        width: constraints.maxWidth,

                        height: 760,

                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(25, 6, 25, 10),

                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,

                            children: [
                              _topBar(),

                              Expanded(
                                child: Form(
                                  key: _formKey,

                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,

                                    children: [
                                      _Brand(),

                                      const SizedBox(height: 12),

                                      Text(
                                        'Welcome Back',

                                        style: TextStyle(
                                          color: _ink(context),

                                          fontSize: 26,

                                          fontWeight: FontWeight.w800,

                                          letterSpacing: -.5,
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      Text(
                                        'Sign in to continue your financial journey.',

                                        textAlign: TextAlign.center,

                                        style: TextStyle(
                                          color: _secondary(context),

                                          fontSize: 13,
                                        ),
                                      ),

                                      const SizedBox(height: 17),

                                      _field(
                                        controller: _emailController,

                                        label: 'Email Address',

                                        hint: 'you@example.com',

                                        icon: Icons.mail_outline_rounded,

                                        keyboardType:
                                            TextInputType.emailAddress,

                                        validator: (value) {
                                          final email = value?.trim() ?? '';
                                          if (email.isEmpty) {
                                            return 'Email address is required';
                                          }
                                          final validEmail = RegExp(
                                            r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                          ).hasMatch(email);
                                          return validEmail
                                              ? null
                                              : 'Enter a valid email address';
                                        },
                                      ),

                                      const SizedBox(height: 9),

                                      _field(
                                        controller: _passwordController,

                                        label: 'Password',

                                        hint: 'Enter your password',

                                        icon: Icons.lock_outline_rounded,

                                        obscureText: _hidePassword,

                                        suffix: IconButton(
                                          onPressed: () => setState(
                                            () =>
                                                _hidePassword = !_hidePassword,
                                          ),

                                          icon: Icon(
                                            _hidePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,

                                            color: _secondary(context),
                                          ),
                                        ),

                                        validator: (value) {
                                          final password = value ?? '';
                                          if (password.isEmpty) {
                                            return 'Password is required';
                                          }
                                          if (password.length < 6) {
                                            return 'Minimum 6 characters required';
                                          }
                                          return null;
                                        },
                                      ),

                                      const SizedBox(height: 9),

                                      Row(
                                        children: [
                                          _checkBox(
                                            _rememberMe,

                                            () => setState(
                                              () => _rememberMe = !_rememberMe,
                                            ),
                                          ),

                                          const SizedBox(width: 8),

                                          Text(
                                            'Remember me',

                                            style: TextStyle(
                                              color: _secondary(context),

                                              fontSize: 12.5,
                                            ),
                                          ),

                                          const Spacer(),

                                          TextButton(
                                            onPressed: () =>
                                                _message('Forgot Password'),

                                            style: TextButton.styleFrom(
                                              foregroundColor: _accent(context),

                                              padding: EdgeInsets.zero,

                                              minimumSize: const Size(0, 32),

                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),

                                            child: Text(
                                              'Forgot Password?',

                                              style: TextStyle(
                                                fontSize: 12.5,

                                                fontWeight: FontWeight.w600,

                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 12),

                                      _primaryButton('Login', _login),

                                      const SizedBox(height: 13),

                                      _divider('or continue with'),

                                      const SizedBox(height: 10),

                                      _socialRow(),

                                      const SizedBox(height: 14),

                                      _infoCard(),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return SizedBox(
      height: 44,

      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),

            padding: EdgeInsets.zero,

            alignment: Alignment.centerLeft,

            icon: Icon(
              Icons.arrow_back_ios_new_rounded,

              color: _ink(context),

              size: 21,
            ),
          ),

          const Spacer(),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,

            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Text(
                "Don't have an account?",

                style: TextStyle(color: _secondary(context), fontSize: 11.5),
              ),

              GestureDetector(
                onTap: _openSignUp,

                child: Text(
                  'Sign Up',

                  style: TextStyle(
                    color: _accent(context),

                    fontSize: 12.5,

                    fontWeight: FontWeight.w700,

                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,

    required String label,

    required String hint,

    required IconData icon,

    TextInputType? keyboardType,

    bool obscureText = false,

    Widget? suffix,

    String? Function(String?)? validator,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),

      decoration: BoxDecoration(
        color: _surface(context).withValues(alpha: _dark(context) ? 1 : .94),

        borderRadius: BorderRadius.circular(17),

        boxShadow: [
          BoxShadow(
            color: _accent(context).withValues(alpha: .07),

            blurRadius: 16,

            offset: Offset(0, 7),
          ),
        ],
      ),

      child: TextFormField(
        controller: controller,

        keyboardType: keyboardType,

        obscureText: obscureText,

        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,

        style: TextStyle(
          color: _ink(context),

          fontSize: 13.5,

          fontWeight: FontWeight.w600,
        ),

        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: _dark(context)
                ? const Color(0xFFABB2CB)
                : const Color(0xFF5E6987),
            size: 23,
          ),

          suffixIcon: suffix,

          labelText: label,

          hintText: hint,

          labelStyle: TextStyle(
            color: _dark(context)
                ? const Color(0xFFD5D9ED)
                : const Color(0xFF43506F),

            fontSize: 12,

            fontWeight: FontWeight.w600,
          ),

          hintStyle: TextStyle(color: _secondary(context), fontSize: 12.5),

          errorStyle: const TextStyle(
            fontSize: 10.5,
            height: 1.1,
            fontWeight: FontWeight.w600,
          ),

          border: InputBorder.none,

          contentPadding: const EdgeInsets.symmetric(vertical: 9),
        ),
      ),
    );
  }

  Widget _checkBox(bool value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        width: 22,

        height: 22,

        decoration: BoxDecoration(
          color: value ? _accent(context) : _surface(context),

          borderRadius: BorderRadius.circular(6),

          border: Border.all(color: value ? _accent(context) : _line(context)),
        ),

        child: value
            ? Icon(Icons.check_rounded, color: Colors.white, size: 16)
            : null,
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback onTap) {
    return Container(
      width: double.infinity,

      height: 51,

      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(_accent(context), Colors.white, .11)!,

            _accent(context),
          ],
        ),

        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: _accent(context).withValues(alpha: .23),

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

          child: Row(
            children: [
              const SizedBox(width: 42),

              Expanded(
                child: Text(
                  label,

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    color: _onAccent(context),

                    fontSize: 14,

                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(right: 18),

                child: Icon(
                  Icons.arrow_forward_rounded,

                  color: _onAccent(context),

                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider(String text) {
    return Row(
      children: [
        Expanded(child: Divider(color: _line(context))),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),

          child: Text(
            text,

            style: TextStyle(color: _secondary(context), fontSize: 11.5),
          ),
        ),

        Expanded(child: Divider(color: _line(context))),
      ],
    );
  }

  Widget _socialRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,

      children: [
        _socialButton(
          Text(
            'G',

            style: TextStyle(
              color: Color(0xFF4285F4),

              fontSize: 21,

              fontWeight: FontWeight.w900,
            ),
          ),

          'Google Sign In',
        ),

        const SizedBox(width: 20),

        _socialButton(
          Icon(Icons.apple_rounded, color: _ink(context), size: 27),

          'Apple Sign In',
        ),

        const SizedBox(width: 20),

        _socialButton(
          Icon(Icons.mail_rounded, color: _ink(context), size: 23),

          'Email Sign In',
        ),
      ],
    );
  }

  Widget _socialButton(Widget child, String message) {
    return Material(
      color: _surface(context),

      elevation: 2,

      shadowColor: _accent(context).withValues(alpha: .13),

      borderRadius: BorderRadius.circular(17),

      child: InkWell(
        onTap: () => _message(message),

        borderRadius: BorderRadius.circular(17),

        child: SizedBox(width: 52, height: 48, child: Center(child: child)),
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),

      decoration: BoxDecoration(
        color: _surface(context).withValues(alpha: _dark(context) ? 1 : .72),

        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: _dark(context)
              ? _line(context)
              : Colors.white.withValues(alpha: .8),
        ),
      ),

      child: Row(
        children: [
          Icon(Icons.verified_user_rounded, color: _accent(context), size: 26),

          SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  'Your data is safe with us.',

                  style: TextStyle(
                    color: _ink(context),

                    fontSize: 12,

                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 3),

                Text(
                  'Your financial records are stored locally on this device.',

                  style: TextStyle(
                    color: _secondary(context),
                    fontSize: 10.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 80,

          height: 80,

          child: Image.asset(
            'assets/icon/dhanviq_icon.png',

            fit: BoxFit.contain,

            filterQuality: FilterQuality.high,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          'DHANVIQ',

          style: TextStyle(
            color: _ink(context),

            fontSize: 24,

            fontWeight: FontWeight.w900,

            letterSpacing: 1.3,
          ),
        ),

        Text(
          'Track  •  Save  •  Grow',

          style: TextStyle(
            color: _secondary(context),
            fontSize: 10.5,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    final dark = _dark(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: dark
                  ? const [
                      Color(0xFF0B1020),
                      Color(0xFF0F1628),
                      Color(0xFF10192A),
                    ]
                  : const [
                      Color(0xFFFBFBFF),
                      Color(0xFFF7F9FF),
                      Color(0xFFF4FAFC),
                    ],
            ),
          ),
        ),
        Positioned(
          top: -92,
          left: -72,
          child: _blob(210, _accent(context), dark ? .085 : .055, -.30),
        ),
        Positioned(
          top: 165,
          right: -105,
          child: _blob(235, const Color(0xFF19D7B0), dark ? .065 : .045, .28),
        ),
        Positioned(
          bottom: -92,
          left: -72,
          child: _blob(245, const Color(0xFF5A8DFF), dark ? .075 : .065, .40),
        ),
        Positioned(
          bottom: -74,
          right: -72,
          child: _blob(220, _accent(context), dark ? .070 : .055, -.34),
        ),
      ],
    );
  }

  static Widget _blob(double size, Color color, double opacity, double angle) {
    return Transform.rotate(
      angle: angle + math.pi / 18,
      child: Container(
        width: size,
        height: size * .62,
        decoration: BoxDecoration(
          color: color.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(size * .31),
        ),
      ),
    );
  }
}
