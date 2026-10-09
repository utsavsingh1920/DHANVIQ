import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_screen.dart';
import 'otp_verification_screen.dart';
const _navy = Color(0xFF101936);
const _muted = Color(0xFF747D94);
const _background = Color(0xFFF8F9FE);
Color _accent(BuildContext context) => Theme.of(context).colorScheme.primary;
Color _onAccent(BuildContext context) =>
    ThemeData.estimateBrightnessForColor(_accent(context)) == Brightness.dark
    ? Colors.white
    : const Color(0xFF101936);
class _Palette {
  const _Palette(this.dark);
  final bool dark;
  Color get background => dark ? const Color(0xFF090D1B) : _background;
  Color get heading => dark ? const Color(0xFFF5F6FF) : _navy;
  Color get muted => dark ? const Color(0xFFA8B2CA) : _muted;
  Color get field =>
      dark ? const Color(0xFF1B2338) : Colors.white.withValues(alpha: .94);
  Color get border => dark ? const Color(0xFF39415B) : const Color(0xFFC8CDDA);
  Color get fieldLabel =>
      dark ? const Color(0xFFC6CEE0) : const Color(0xFF43506F);
  Color get fieldIcon =>
      dark ? const Color(0xFFAEB8D0) : const Color(0xFF5E6987);
  Color get divider => dark ? const Color(0xFF384158) : const Color(0xFFCFD4E2);
  Color get card =>
      dark ? const Color(0xFF1B2338) : Colors.white.withValues(alpha: .72);
  Color get cardBorder =>
      dark ? const Color(0xFF35405B) : Colors.white.withValues(alpha: .8);
}
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}
class _SignUpScreenState extends State<SignUpScreen> {
  _Palette get _p => _Palette(Theme.of(context).brightness == Brightness.dark);
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;
  bool _accepted = true;
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  void _openLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, _, _) => const LoginScreen(),
      ),
    );
  }
  void _createAccount() {
    FocusScope.of(context).unfocus();
    if (!_accepted) {
      _message('Please accept the Terms of Service and Privacy Policy.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      _message('Please correct the highlighted fields.');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OtpVerificationScreen(
          phoneNumber: '+91 ${_phoneController.text.trim()}',
        ),
      ),
    );
  }
  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
  @override
  Widget build(BuildContext context) {
    final p = _p;
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: p.dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: p.dark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: p.background,
        systemNavigationBarIconBrightness: p.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: p.background,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: p.background,
        body: Stack(
          children: [
            const Positioned.fill(child: _Background()),
            SafeArea(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(25, 6, 25, 22 + keyboardHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _topBar(),
                          const SizedBox(height: 8),
                          const _Brand(),
                          const SizedBox(height: 5),
                          Text(
                            'Create Account',
                            style: TextStyle(
                              color: p.heading,
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.4,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Start your journey towards a smarter\nfinancial future.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: p.muted,
                              fontSize: 12.3,
                              height: 1.28,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _field(
                            controller: _nameController,
                            label: 'Full Name',
                            hint: 'Enter your full name',
                            icon: Icons.person_outline_rounded,
                            capitalization: TextCapitalization.words,
                            validator: (value) {
                              final name = value?.trim() ?? '';
                              if (name.isEmpty) {
                                return 'Full name is required';
                              }
                              if (name.length < 3) {
                                return 'Enter at least 3 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 6),
                          _field(
                            controller: _emailController,
                            label: 'Email Address',
                            hint: 'you@example.com',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
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
                          const SizedBox(height: 6),
                          _field(
                            controller: _phoneController,
                            label: 'Mobile Number',
                            hint: '+91 98765 43210',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            validator: (value) {
                              final phone = value?.trim() ?? '';
                              if (phone.isEmpty) {
                                return 'Mobile number is required';
                              }
                              if (!RegExp(r'^[6-9]\d{9}$')
                                  .hasMatch(phone)) {
                                return 'Enter a valid 10-digit mobile number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 6),
                          _field(
                            controller: _passwordController,
                            label: 'Create Password',
                            hint: 'Minimum 6 characters',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _hidePassword,
                            suffix: IconButton(
                              onPressed: () => setState(
                                () => _hidePassword = !_hidePassword,
                              ),
                              icon: Icon(
                                _hidePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: _p.muted,
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
                              if (!RegExp(r'[A-Za-z]')
                                      .hasMatch(password) ||
                                  !RegExp(r'\d').hasMatch(password)) {
                                return 'Use at least one letter and one number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 7),
                          _termsRow(),
                          const SizedBox(height: 8),
                          _primaryButton(),
                          const SizedBox(height: 8),
                          _divider(),
                          const SizedBox(height: 8),
                          _socialRow(),
                          const SizedBox(height: 8),
                          _infoCard(),
                        ],
                      ),
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
              color: _p.heading,
              size: 21,
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account?',
                style: TextStyle(color: _p.muted, fontSize: 11.5),
              ),
              GestureDetector(
                onTap: _openLogin,
                child: Text(
                  'Login',
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
    TextCapitalization capitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: capitalization,
        inputFormatters: inputFormatters,
        obscureText: obscureText,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: TextStyle(
          color: _p.heading,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: _p.fieldIcon, size: 22),
          suffixIcon: suffix,
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            color: _p.fieldLabel,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
          hintStyle: TextStyle(color: _p.muted, fontSize: 12),
          errorStyle: const TextStyle(
            fontSize: 9.8,
            height: 1.05,
            fontWeight: FontWeight.w600,
          ),
          errorMaxLines: 1,
          isDense: true,
          filled: true,
          fillColor: _p.field,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: BorderSide(color: _p.border.withValues(alpha: .20)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: BorderSide(
              color: _accent(context).withValues(alpha: .55),
              width: 1.2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: const BorderSide(color: Color(0xFFFF7B7B), width: 1.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: const BorderSide(color: Color(0xFFFF7B7B), width: 1.2),
          ),
        ),
      ),
    );
  }
  Widget _termsRow() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => setState(() => _accepted = !_accepted),
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _accepted ? _accent(context) : _p.field,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _accepted ? _accent(context) : _p.border,
              ),
            ),
            child: _accepted
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(
                    color: _accent(context),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
                TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy.',
                  style: TextStyle(
                    color: _accent(context),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
            style: TextStyle(color: _p.muted, fontSize: 10.5),
          ),
        ),
      ],
    );
  }
  Widget _primaryButton() {
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
          onTap: _createAccount,
          borderRadius: BorderRadius.circular(18),
          child: Row(
            children: [
              const SizedBox(width: 42),
              Expanded(
                child: Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _onAccent(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: 18),
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
  Widget _divider() {
    return Row(
      children: [
        Expanded(child: Divider(color: _p.divider)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or sign up with',
            style: TextStyle(color: _p.muted, fontSize: 11.5),
          ),
        ),
        Expanded(child: Divider(color: _p.divider)),
      ],
    );
  }
  Widget _socialRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _socialButton(
          const Text(
            'G',
            style: TextStyle(
              color: Color(0xFF4285F4),
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          'Google Sign Up',
        ),
        const SizedBox(width: 20),
        _socialButton(
          Icon(Icons.apple_rounded, color: _p.heading, size: 27),
          'Apple Sign Up',
        ),
        const SizedBox(width: 20),
        _socialButton(
          Icon(Icons.mail_rounded, color: _p.heading, size: 23),
          'Email Sign Up',
        ),
      ],
    );
  }
  Widget _socialButton(Widget child, String message) {
    return Material(
      color: _p.field,
      elevation: 2,
      shadowColor: _accent(context).withValues(alpha: .13),
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: () => _message(message),
        borderRadius: BorderRadius.circular(17),
        child: SizedBox(width: 50, height: 46, child: Center(child: child)),
      ),
    );
  }
  Widget _infoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: _p.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _p.cardBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.group_rounded, color: _accent(context), size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Build a smarter financial future.',
                  style: TextStyle(
                    color: _p.heading,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Start recording income, expenses, budgets, and savings goals.',
                  style: TextStyle(
                    color: _p.muted,
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
          width: 70,
          height: 70,
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
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFF5F6FF)
                : _navy,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
          ),
        ),
        Text(
          'Track  •  Save  •  Grow',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFA8B2CA)
                : _muted,
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
    final dark = Theme.of(context).brightness == Brightness.dark;
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
