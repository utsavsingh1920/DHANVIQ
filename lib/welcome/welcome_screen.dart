import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import '../auth/login_screen.dart';

import '../auth/signup_screen.dart';

class _WelcomeColors {
  static bool dark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) =>
      dark(context) ? const Color(0xFF090B17) : const Color(0xFFF8F9FE);

  static Color title(BuildContext context) =>
      dark(context) ? const Color(0xFFF4F2FF) : const Color(0xFF101936);

  static Color muted(BuildContext context) =>
      dark(context) ? const Color(0xFFAAB2CB) : const Color(0xFF747D94);

  static Color surface(BuildContext context) =>
      dark(context) ? const Color(0xFF1A1D30) : Colors.white;

  static Color border(BuildContext context) =>
      dark(context) ? const Color(0xFF34384F) : const Color(0xFFE2E4EE);

  // Accent is provided by MaterialApp and follows the saved Appearance setting.

  static Color accent(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  static Color onAccent(BuildContext context) =>
      ThemeData.estimateBrightnessForColor(accent(context)) == Brightness.dark
      ? Colors.white
      : const Color(0xFF101936);
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  // Income/growth remains mint; the app-brand accent is theme-driven.

  static const _mint = Color(0xFF19D7B0);

  void _comingSoon(BuildContext context, String screen) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$screen screen अगला बनाएँगे।')));
  }

  void _openLogin(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const LoginScreen()));
  }

  void _openSignUp(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SignUpScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final dark = _WelcomeColors.dark(context);

    final background = _WelcomeColors.background(context);

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
            const Positioned.fill(child: _WelcomeBackground()),

            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 720;

                  return Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,

                      alignment: Alignment.center,

                      child: SizedBox(
                        width: constraints.maxWidth,

                        height: compact ? 704 : 744,

                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            25,

                            compact ? 4 : 8,

                            25,

                            compact ? 6 : 10,
                          ),

                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,

                            children: [
                              Transform.translate(
                                offset: Offset.zero,

                                child: Column(
                                  children: [
                                    SizedBox(
                                      width: compact ? 96 : 106,

                                      height: compact ? 96 : 106,

                                      child: Image.asset(
                                        'assets/icon/dhanviq_icon.png',

                                        fit: BoxFit.contain,

                                        filterQuality: FilterQuality.high,
                                      ),
                                    ),

                                    const SizedBox(height: 5),

                                    const _BrandName(),

                                    const SizedBox(height: 3),

                                    Text(
                                      'Track  •  Save  •  Grow',

                                      style: TextStyle(
                                        color: _WelcomeColors.muted(context),

                                        fontSize: 13,

                                        fontWeight: FontWeight.w500,

                                        letterSpacing: 1.15,
                                      ),
                                    ),

                                    SizedBox(height: compact ? 9 : 12),

                                    Text(
                                      "Let's Get Started",

                                      style: TextStyle(
                                        color: _WelcomeColors.title(context),

                                        fontSize: compact ? 24 : 25,

                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),

                                    const SizedBox(height: 5),

                                    Text(
                                      'Manage your money, achieve your goals\n'
                                      'and live a smarter life.',

                                      textAlign: TextAlign.center,

                                      style: TextStyle(
                                        color: _WelcomeColors.muted(context),

                                        fontSize: 13,

                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: compact ? 3 : 5),

                              SizedBox(
                                height: compact ? 168 : 185,

                                width: double.infinity,

                                child: const _FinanceIllustration(),
                              ),

                              SizedBox(height: compact ? 5 : 7),

                              _PrimaryButton(
                                label: 'Create Account',

                                leading: Icons.person_add_alt_1_rounded,

                                onTap: () => _openSignUp(context),
                              ),

                              const SizedBox(height: 9),

                              _SecondaryButton(
                                label: 'Login',

                                leading: Icons.login_rounded,

                                onTap: () => _openLogin(context),
                              ),

                              SizedBox(height: compact ? 8 : 11),

                              const _OrDivider(),

                              SizedBox(height: compact ? 7 : 10),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,

                                children: [
                                  _SocialButton(
                                    child: const Text(
                                      'G',

                                      style: TextStyle(
                                        color: Color(0xFF4285F4),

                                        fontSize: 20,

                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),

                                    onTap: () =>
                                        _comingSoon(context, 'Google Sign In'),
                                  ),

                                  const SizedBox(width: 18),

                                  _SocialButton(
                                    child: Icon(
                                      Icons.apple_rounded,

                                      color: _WelcomeColors.title(context),

                                      size: 25,
                                    ),

                                    onTap: () =>
                                        _comingSoon(context, 'Apple Sign In'),
                                  ),

                                  const SizedBox(width: 18),

                                  _SocialButton(
                                    child: Icon(
                                      Icons.mail_rounded,

                                      color: _WelcomeColors.title(context),

                                      size: 22,
                                    ),

                                    onTap: () =>
                                        _comingSoon(context, 'Email Sign In'),
                                  ),
                                ],
                              ),

                              SizedBox(height: compact ? 8 : 11),

                              const _TermsText(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const Positioned(
              left: 24,

              top: 74,

              child: IgnorePointer(child: _HandwrittenNote()),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandName extends StatelessWidget {
  const _BrandName();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        stops: const [.0, .72, 1],

        colors: [
          _WelcomeColors.title(context),

          _WelcomeColors.title(context),

          _WelcomeColors.accent(context),
        ],
      ).createShader(bounds),

      child: const Text(
        'DHANVIQ',

        style: TextStyle(
          color: Colors.white,

          fontSize: 32,

          fontWeight: FontWeight.w900,

          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _FinanceIllustration extends StatelessWidget {
  const _FinanceIllustration();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,

          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _GrowthPainter(accent: _WelcomeColors.accent(context)),
              ),
            ),

            const Positioned(
              left: 0,

              top: 7,

              child: _BenefitCard(
                icon: Icons.bar_chart_rounded,

                iconColor: WelcomeScreen._mint,

                text: 'Better\nMoney Habits',
              ),
            ),

            Positioned(
              left: 0,

              bottom: 10,

              child: _BenefitCard(
                icon: Icons.track_changes_rounded,

                iconColor: _WelcomeColors.accent(context),

                text: 'Achieve\nYour Goals',
              ),
            ),

            const Positioned(
              right: 0,

              top: 10,

              child: _BenefitCard(
                icon: Icons.monetization_on_rounded,

                iconColor: Color(0xFFFFB33C),

                text: 'Financial\nFreedom',
              ),
            ),

            Positioned(
              right: constraints.maxWidth * .01,

              bottom: 6,

              child: Transform.rotate(
                angle: -.09,

                child: Text(
                  'A Brighter\nTomorrow',

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    color: _WelcomeColors.accent(context),

                    fontFamily: 'cursive',

                    fontStyle: FontStyle.italic,

                    fontSize: 13,

                    height: 1.05,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GrowthPainter extends CustomPainter {
  const _GrowthPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.width / 2;

    final baseline = size.height * .96;

    final barWidth = size.width * .075;

    final gap = size.width * .022;

    final heights = [
      size.height * .24,

      size.height * .38,

      size.height * .55,

      size.height * .73,
    ];

    final startX = center - (barWidth * 2 + gap * 1.5);

    final gradient = LinearGradient(
      begin: Alignment.bottomCenter,

      end: Alignment.topCenter,

      colors: [accent, WelcomeScreen._mint],
    );

    for (var i = 0; i < heights.length; i++) {
      final rect = Rect.fromLTWH(
        startX + i * (barWidth + gap),

        baseline - heights[i],

        barWidth,

        heights[i],
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(9)),

        Paint()..shader = gradient.createShader(rect),
      );
    }

    final path = Path()
      ..moveTo(startX - 18, baseline - heights[0] * .72)
      ..cubicTo(
        center - 39,

        baseline - heights[1],

        center + 30,

        baseline - heights[2] * 1.15,

        startX + 3 * (barWidth + gap) + barWidth * .82,

        baseline - heights[3] - 18,
      );

    final arrowPaint = Paint()
      ..color = WelcomeScreen._mint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, arrowPaint);

    final end = Offset(
      startX + 3 * (barWidth + gap) + barWidth * .82,

      baseline - heights[3] - 18,
    );

    final arrow = Path()
      ..moveTo(end.dx - 17, end.dy + 3)
      ..lineTo(end.dx + 3, end.dy - 3)
      ..lineTo(end.dx - 2, end.dy + 18)
      ..close();

    canvas.drawPath(arrow, Paint()..color = WelcomeScreen._mint);

    final leafPaint = Paint()..color = const Color(0x5528C59D);

    canvas.save();

    canvas.translate(center - 45, baseline - 52);

    canvas.rotate(-.5);

    canvas.drawOval(const Rect.fromLTWH(0, 0, 26, 55), leafPaint);

    canvas.restore();

    canvas.save();

    canvas.translate(center + 92, baseline - 40);

    canvas.rotate(.48);

    canvas.drawOval(const Rect.fromLTWH(0, 0, 25, 52), leafPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GrowthPainter oldDelegate) =>
      oldDelegate.accent != accent;
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({
    required this.icon,

    required this.iconColor,

    required this.text,
  });

  final IconData icon;

  final Color iconColor;

  final String text;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -.025,

      child: Container(
        width: 110,

        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),

        decoration: BoxDecoration(
          color: _WelcomeColors.surface(context).withValues(alpha: .94),

          borderRadius: BorderRadius.circular(14),

          boxShadow: [
            BoxShadow(
              color: _WelcomeColors.accent(context).withValues(alpha: .11),

              blurRadius: 15,

              offset: Offset(0, 7),
            ),
          ],
        ),

        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 23),

            const SizedBox(width: 6),

            Expanded(
              child: Text(
                text,

                style: TextStyle(
                  color: _WelcomeColors.title(context),

                  fontSize: 9.8,

                  height: 1.1,

                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HandwrittenNote extends StatelessWidget {
  const _HandwrittenNote();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -.12,

      child: Text(
        'Smarter\nFinances\nHappier\nYou',

        textAlign: TextAlign.center,

        style: TextStyle(
          color: _WelcomeColors.accent(context)
              .withValues(alpha: _WelcomeColors.dark(context) ? .78 : .65),

          fontFamily: 'cursive',

          fontStyle: FontStyle.italic,

          fontSize: 11.5,

          height: 1.05,
        ),
      ),
    );
  }
}

class _WelcomeBackground extends StatelessWidget {
  const _WelcomeBackground();

  @override
  Widget build(BuildContext context) {
    final dark = _WelcomeColors.dark(context);

    return Stack(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: dark
                  ? const [Color(0xFF0B1020), Color(0xFF101729)]
                  : const [Color(0xFFF8F7FF), Color(0xFFF7FCFF)],
            ),
          ),
          child: const SizedBox.expand(),
        ),
        Positioned(
          top: -55,
          left: -58,
          child: _blob(
            170,
            _WelcomeColors.accent(context)
                .withValues(alpha: dark ? .085 : .055),
          ),
        ),
        Positioned(
          top: 145,
          right: -72,
          child: _blob(
            190,
            dark ? const Color(0x1216DAB0) : const Color(0x1016DAB0),
          ),
        ),
        Positioned(
          bottom: -68,
          left: -65,
          child: _blob(
            205,
            dark ? const Color(0x1556A7FF) : const Color(0x1456A7FF),
          ),
        ),
        Positioned(
          bottom: -52,
          right: -55,
          child: _blob(
            175,
            _WelcomeColors.accent(context)
                .withValues(alpha: dark ? .080 : .055),
          ),
        ),
      ],
    );
  }

  static Widget _blob(double size, Color color) {
    return Transform.rotate(
      angle: math.pi / 7,
      child: Container(
        width: size,
        height: size * .66,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size * .33),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,

    required this.leading,

    required this.onTap,
  });

  final String label;

  final IconData leading;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _WelcomeColors.accent(context);

    final foreground = _WelcomeColors.onAccent(context);

    return Container(
      height: 52,

      width: double.infinity,

      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, Color.lerp(accent, Colors.black, .10)!],
        ),

        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: .24),

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

          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),

            child: Row(
              children: [
                Icon(leading, color: foreground, size: 21),

                Expanded(
                  child: Text(
                    label,

                    textAlign: TextAlign.center,

                    style: TextStyle(
                      color: foreground,

                      fontSize: 14,

                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                Icon(Icons.arrow_forward_rounded, color: foreground, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,

    required this.leading,

    required this.onTap,
  });

  final String label;

  final IconData leading;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,

      height: 50,

      child: OutlinedButton(
        onPressed: onTap,

        style: OutlinedButton.styleFrom(
          backgroundColor: _WelcomeColors.surface(context),

          foregroundColor: _WelcomeColors.title(context),

          side: BorderSide(color: _WelcomeColors.border(context)),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),

        child: Row(
          children: [
            Icon(leading, color: _WelcomeColors.muted(context), size: 21),

            Expanded(
              child: Text(
                label,

                textAlign: TextAlign.center,

                style: const TextStyle(
                  fontSize: 14,

                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            Icon(
              Icons.arrow_forward_rounded,

              color: _WelcomeColors.muted(context),

              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: _WelcomeColors.border(context))),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),

          child: Text(
            'or continue with',

            style: TextStyle(
              color: _WelcomeColors.muted(context),
              fontSize: 11,
            ),
          ),
        ),

        Expanded(child: Divider(color: _WelcomeColors.border(context))),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.child, required this.onTap});

  final Widget child;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _WelcomeColors.surface(context),

      borderRadius: BorderRadius.circular(18),

      elevation: 2,

      shadowColor: _WelcomeColors.accent(context).withValues(alpha: .12),

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(18),

        child: SizedBox(width: 52, height: 50, child: Center(child: child)),
      ),
    );
  }
}

class _TermsText extends StatelessWidget {
  const _TermsText();

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'By continuing, you agree to our\n'),

          TextSpan(
            text: 'Terms of Service',

            style: TextStyle(
              color: _WelcomeColors.accent(context),

              decoration: TextDecoration.underline,

              fontWeight: FontWeight.w600,
            ),
          ),

          TextSpan(text: ' and '),

          TextSpan(
            text: 'Privacy Policy.',

            style: TextStyle(
              color: _WelcomeColors.accent(context),

              decoration: TextDecoration.underline,

              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),

      textAlign: TextAlign.center,

      style: TextStyle(
        color: _WelcomeColors.muted(context),

        fontSize: 10.5,

        height: 1.4,
      ),
    );
  }
}
