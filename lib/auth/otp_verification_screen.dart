import 'dart:async';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../navigation/main_navigation_screen.dart';

const _navy = Color(0xFF101936);

const _mint = Color(0xFF19D7B0);

const _muted = Color(0xFF747D94);

const _background = Color(0xFFF8F9FE);

// ThemeMode.light / dark / system is resolved by MaterialApp's ThemeMode.

// Read the effective brightness here so all three modes work automatically.

class _OtpColors {
  static bool dark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) =>
      dark(context) ? const Color(0xFF0B1020) : _background;

  static Color text(BuildContext context) =>
      dark(context) ? const Color(0xFFF2F4FF) : _navy;

  static Color muted(BuildContext context) =>
      dark(context) ? const Color(0xFFADB6CE) : _muted;

  static Color card(BuildContext context) =>
      dark(context) ? const Color(0xFF19233A) : Colors.white;

  static Color border(BuildContext context) =>
      dark(context) ? const Color(0xFF34415B) : const Color(0xFFE1E4EF);

  static Color accent(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
}

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,

    required this.phoneNumber,

    this.destination,
  });

  final String phoneNumber;

  /// Tests या किसी alternate flow में custom destination pass कर सकते हैं।

  final Widget? destination;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(
    6,

    (_) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  late final AnimationController _pulseController;

  Timer? _resendTimer;

  int _secondsRemaining = 30;

  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,

      duration: const Duration(milliseconds: 1100),

      lowerBound: .92,

      upperBound: 1.06,
    );

    _startResendTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();

    _pulseController.dispose();

    for (final controller in _controllers) {
      controller.dispose();
    }

    for (final node in _focusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();

    setStateIfMounted(() => _secondsRemaining = 30);

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();

        return;
      }

      if (_secondsRemaining <= 1) {
        timer.cancel();

        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  void setStateIfMounted(VoidCallback callback) {
    if (mounted) setState(callback);
  }

  String get _otp => _controllers.map((controller) => controller.text).join();

  void _onDigitChanged(int index, String value) {
    if (_isVerifying) return;

    if (value.isNotEmpty && index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    if (_otp.length == 6) {
      FocusScope.of(context).unfocus();

      _verifyOtp();
    }
  }

  Future<void> _verifyOtp() async {
    if (_isVerifying) return;

    if (_otp.length != 6 || !RegExp(r'^\d{6}$').hasMatch(_otp)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Enter the complete 6-digit OTP.')),
        );
      return;
    }

    _resendTimer?.cancel();

    setState(() => _isVerifying = true);

    _pulseController.repeat(reverse: true);

    // DEMO ONLY: any six digits are accepted; no SMS is sent or verified.

    await Future<void>.delayed(const Duration(milliseconds: 1900));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('onboardingCompleted', true);

    await prefs.setBool('isLoggedIn', true);

    if (!mounted) return;

    _pulseController.stop();

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),

        pageBuilder: (_, animation, secondaryAnimation) =>
            widget.destination ?? const MainNavigationScreen(),

        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),

      (route) => false,
    );
  }

  void _resendOtp() {
    if (_secondsRemaining != 0 || _isVerifying) return;

    for (final controller in _controllers) {
      controller.clear();
    }

    _focusNodes.first.requestFocus();

    _startResendTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Demo mode: no SMS is sent. Enter any 6 digits.'),
      ),
    );
  }

  String get _timerText {
    final seconds = _secondsRemaining.toString().padLeft(2, '0');

    return '00:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final dark = _OtpColors.dark(context);

    final background = _OtpColors.background(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,

        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,

        statusBarBrightness: dark ? Brightness.dark : Brightness.light,

        systemNavigationBarColor: background,

        systemNavigationBarIconBrightness: dark
            ? Brightness.light
            : Brightness.dark,

        systemNavigationBarDividerColor: background,
      ),

      child: Scaffold(
        resizeToAvoidBottomInset: false,

        backgroundColor: background,

        body: Stack(
          children: [
            Positioned.fill(child: _OtpBackground()),

            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,

                      alignment: Alignment.center,

                      child: SizedBox(
                        width: constraints.maxWidth,

                        height: 748,

                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(22, 6, 22, 14),

                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 380),

                            switchInCurve: Curves.easeOutCubic,

                            switchOutCurve: Curves.easeInCubic,

                            child: _isVerifying
                                ? _buildVerifyingContent()
                                : _buildOtpContent(),
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

  Widget _buildOtpContent() {
    return Column(
      key: const ValueKey('otp'),

      children: [
        _topBar(),

        _BrandHeader(),

        const SizedBox(height: 46),

        Text(
          'Verify Your Account',

          textAlign: TextAlign.center,

          style: TextStyle(
            color: _OtpColors.text(context),

            fontSize: 29,

            fontWeight: FontWeight.w800,

            letterSpacing: -.45,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          "Demo mode: enter any 6 digits to continue.\nPhone: ${widget.phoneNumber} (no SMS sent)",

          textAlign: TextAlign.center,

          style: TextStyle(
            color: _OtpColors.muted(context),
            fontSize: 14.5,
            height: 1.45,
          ),
        ),

        const SizedBox(height: 30),

        _otpFields(),

        const SizedBox(height: 24),

        _resendRow(),

        const Spacer(),

        _BottomInfoCard(
          icon: Icons.verified_user_rounded,

          title: 'Your financial records stay on this device.',

          subtitle:
              'This demo uses local storage; no SMS verification is performed.',
        ),
      ],
    );
  }

  Widget _buildVerifyingContent() {
    return Column(
      key: const ValueKey('verifying'),

      children: [
        _topBar(showBack: false),

        _BrandHeader(),

        const SizedBox(height: 34),

        ScaleTransition(scale: _pulseController, child: _VerificationBadge()),

        const SizedBox(height: 24),

        Text(
          'Verifying your account...',

          textAlign: TextAlign.center,

          style: TextStyle(
            color: _OtpColors.text(context),

            fontSize: 25,

            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          "Please wait, we're confirming\nyour details.",

          textAlign: TextAlign.center,

          style: TextStyle(
            color: _OtpColors.muted(context),
            fontSize: 14,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: 165,

          child: LinearProgressIndicator(
            minHeight: 5,

            borderRadius: BorderRadius.all(Radius.circular(10)),

            color: _OtpColors.accent(context),

            backgroundColor: _OtpColors.border(context),
          ),
        ),

        const Spacer(),

        _BottomInfoCard(
          icon: Icons.lock_rounded,

          title: 'Almost there!',

          subtitle: 'Preparing your local DHANVIQ session.',
        ),
      ],
    );
  }

  Widget _topBar({bool showBack = true}) {
    return SizedBox(
      height: 44,

      child: Align(
        alignment: Alignment.centerLeft,

        child: AnimatedOpacity(
          opacity: showBack ? 1 : 0,

          duration: const Duration(milliseconds: 180),

          child: IgnorePointer(
            ignoring: !showBack,

            child: IconButton(
              onPressed: () => Navigator.maybePop(context),

              padding: EdgeInsets.zero,

              alignment: Alignment.centerLeft,

              icon: Icon(
                Icons.arrow_back_ios_new_rounded,

                color: _OtpColors.text(context),

                size: 21,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _otpFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,

      children: List.generate(6, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 5 ? 0 : 7),

            child: SizedBox(
              height: 62,

              child: TextField(
                controller: _controllers[index],

                focusNode: _focusNodes[index],

                enabled: !_isVerifying,

                autofocus: index == 0,

                textAlign: TextAlign.center,

                keyboardType: TextInputType.number,

                textInputAction: index == 5
                    ? TextInputAction.done
                    : TextInputAction.next,

                autofillHints: index == 0
                    ? const [AutofillHints.oneTimeCode]
                    : null,

                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,

                  LengthLimitingTextInputFormatter(1),
                ],

                style: TextStyle(
                  color: _OtpColors.text(context),

                  fontSize: 24,

                  fontWeight: FontWeight.w700,
                ),

                cursorColor: _OtpColors.accent(context),

                onChanged: (value) => _onDigitChanged(index, value),

                onTap: () {
                  _controllers[index].selection = TextSelection(
                    baseOffset: 0,

                    extentOffset: _controllers[index].text.length,
                  );
                },

                decoration: InputDecoration(
                  counterText: '',

                  filled: true,

                  fillColor: _OtpColors.card(context).withValues(alpha: .96),

                  contentPadding: EdgeInsets.zero,

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),

                    borderSide: BorderSide(color: _OtpColors.border(context)),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),

                    borderSide: BorderSide(
                      color: _OtpColors.accent(context),
                      width: 1.6,
                    ),
                  ),

                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),

                    borderSide: BorderSide(color: _OtpColors.border(context)),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _resendRow() {
    return Wrap(
      alignment: WrapAlignment.center,

      crossAxisAlignment: WrapCrossAlignment.center,

      spacing: 5,

      children: [
        Text(
          "Didn't receive the code?",

          style: TextStyle(color: _OtpColors.muted(context), fontSize: 13),
        ),

        GestureDetector(
          onTap: _resendOtp,

          child: Text(
            _secondsRemaining == 0 ? 'Resend now' : 'Resend in $_timerText',

            style: TextStyle(
              color: _OtpColors.accent(context),

              fontSize: 13,

              fontWeight: FontWeight.w700,

              decoration: _secondsRemaining == 0
                  ? TextDecoration.underline
                  : TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 92,

          height: 92,

          child: Image.asset(
            'assets/icon/dhanviq_icon.png',

            fit: BoxFit.contain,

            filterQuality: FilterQuality.high,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          'DHANVIQ',

          style: TextStyle(
            color: _OtpColors.text(context),

            fontSize: 28,

            fontWeight: FontWeight.w900,

            letterSpacing: 1.3,
          ),
        ),

        Text(
          'Track  •  Save  •  Grow',

          style: TextStyle(
            color: _OtpColors.muted(context),
            fontSize: 11.5,
            letterSpacing: 1.15,
          ),
        ),
      ],
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,

      height: 200,

      child: Stack(
        alignment: Alignment.center,

        children: [
          Container(
            width: 200,

            height: 200,

            decoration: BoxDecoration(
              shape: BoxShape.circle,

              color: Color(0x1219D7B0),
            ),
          ),

          Container(
            width: 142,

            height: 142,

            decoration: BoxDecoration(
              shape: BoxShape.circle,

              color: Color(0x2619D7B0),
            ),
          ),

          Container(
            width: 96,

            height: 96,

            decoration: BoxDecoration(
              shape: BoxShape.circle,

              gradient: LinearGradient(
                begin: Alignment.topLeft,

                end: Alignment.bottomRight,

                colors: [Color(0xFF31E1B9), Color(0xFF0BBE8E)],
              ),

              boxShadow: [
                BoxShadow(
                  color: Color(0x4019D7B0),

                  blurRadius: 24,

                  offset: Offset(0, 10),
                ),
              ],
            ),

            child: Icon(Icons.check_rounded, color: Colors.white, size: 55),
          ),

          for (final alignment in const [
            Alignment(-.92, -.72),

            Alignment(.88, -.64),

            Alignment(-.88, .70),

            Alignment(.92, .64),
          ])
            Align(
              alignment: alignment,

              child: Container(
                width: 9,

                height: 9,

                decoration: const BoxDecoration(
                  color: _mint,

                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomInfoCard extends StatelessWidget {
  const _BottomInfoCard({
    required this.icon,

    required this.title,

    required this.subtitle,
  });

  final IconData icon;

  final String title;

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

      decoration: BoxDecoration(
        color: _OtpColors.card(context).withValues(alpha: .90),

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: _OtpColors.border(context)),
      ),

      child: Row(
        children: [
          Container(
            width: 44,

            height: 44,

            decoration: BoxDecoration(
              color: _OtpColors.accent(context).withValues(alpha: .07),

              borderRadius: BorderRadius.circular(12),
            ),

            child: Icon(icon, color: _OtpColors.accent(context), size: 26),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style: TextStyle(
                    color: _OtpColors.text(context),

                    fontSize: 13,

                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  subtitle,

                  style: TextStyle(
                    color: _OtpColors.muted(context),

                    fontSize: 11.5,

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

class _OtpBackground extends StatelessWidget {
  const _OtpBackground();

  @override
  Widget build(BuildContext context) {
    final dark = _OtpColors.dark(context);

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
          child: _blob(
            210,
            _OtpColors.accent(context),
            dark ? .085 : .055,
            -.30,
          ),
        ),
        Positioned(
          top: 165,
          right: -105,
          child: _blob(235, _mint, dark ? .065 : .045, .28),
        ),
        Positioned(
          bottom: -92,
          left: -72,
          child: _blob(245, const Color(0xFF5A8DFF), dark ? .075 : .065, .40),
        ),
        Positioned(
          bottom: -74,
          right: -72,
          child: _blob(
            220,
            _OtpColors.accent(context),
            dark ? .070 : .055,
            -.34,
          ),
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
