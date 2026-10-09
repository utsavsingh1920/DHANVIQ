import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../navigation/main_navigation_screen.dart';

import '../onboarding/onboarding_screen.dart';

import '../welcome/welcome_screen.dart';

import '../settings/app_lock_screen.dart';

// Uses the accent color selected in Settings > Appearance.

Color _splashAccent(BuildContext context) =>
    Theme.of(context).colorScheme.primary;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Color _navy = Color(0xFF061533);

  late final AnimationController _controller;

  late final Animation<double> _fadeAnimation;

  late final Animation<double> _scaleAnimation;

  late final Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,

      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,

      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.82,

      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _slideAnimation = Tween<double>(
      begin: 24,

      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    Timer(const Duration(milliseconds: 2600), () async {
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();

      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      final onboardingCompleted = prefs.getBool('onboardingCompleted') ?? false;

      final appLock = DhanviqAppLock.instance;

      await appLock.load();

      if (!mounted) return;

      if (isLoggedIn) {
        // Android splash -> DHANVIQ custom splash -> App Lock -> Home.

        // The lock is armed only after this custom splash has completed.

        appLock.beginAuthenticatedSession(lockNow: appLock.enabled);
      } else {
        // Fresh install / logout: App Lock must not cover onboarding/login.

        appLock.endAuthenticatedSession();
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 450),

          pageBuilder: (context, animation, secondaryAnimation) {
            return isLoggedIn
                ? const MainNavigationScreen()
                : onboardingCompleted
                ? const WelcomeScreen()
                : const OnboardingScreen();
          },

          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,

                curve: Curves.easeOut,
              ),

              child: child,
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,

        statusBarIconBrightness: Brightness.light,

        statusBarBrightness: Brightness.dark,

        systemNavigationBarColor: _navy,

        systemNavigationBarIconBrightness: Brightness.light,
      ),

      child: Scaffold(
        backgroundColor: _navy,

        body: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;

            final screenWidth = constraints.maxWidth;

            return Stack(
              fit: StackFit.expand,

              children: [
                const _BackgroundGlow(),

                const Positioned(top: 54, left: 28, child: _TopLeftText()),

                const Positioned(top: 48, right: 24, child: _TopRightText()),

                Positioned(
                  left: 0,

                  right: 0,

                  bottom: 0,

                  height: screenHeight * 0.40,

                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _FinanceBackgroundPainter(
                        accent: _splashAccent(context),
                      ),
                    ),
                  ),
                ),

                const Positioned(left: -2, top: 405, child: _DotGrid()),

                const Positioned(right: -2, top: 430, child: _DotGrid()),

                const Positioned(left: 18, top: 505, child: _GlowOrb(size: 20)),

                const Positioned(
                  left: 28,
                  bottom: 126,
                  child: _GlowOrb(size: 18, dim: true),
                ),

                const Positioned(
                  right: 16,
                  bottom: 78,
                  child: _GlowOrb(size: 16, dim: true),
                ),

                SafeArea(
                  child: FadeTransition(
                    opacity: _fadeAnimation,

                    child: AnimatedBuilder(
                      animation: _slideAnimation,

                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _slideAnimation.value),

                          child: child,
                        );
                      },

                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: 24,

                            right: 24,

                            bottom: screenHeight * 0.105,
                          ),

                          child: Column(
                            mainAxisSize: MainAxisSize.min,

                            children: [
                              ScaleTransition(
                                scale: _scaleAnimation,

                                child: _AppLogo(
                                  size: screenWidth.clamp(320, 500) * 0.44,
                                ),
                              ),

                              const SizedBox(height: 22),

                              const _DhanviqTitle(),

                              const SizedBox(height: 8),

                              const _BrandSubtitle(),

                              const SizedBox(height: 20),

                              const _GradientDivider(),

                              const SizedBox(height: 24),

                              const _Tagline(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,

      height: size,

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.24),

        boxShadow: [
          BoxShadow(
            color: _splashAccent(context).withValues(alpha: .34),

            blurRadius: 34,

            spreadRadius: 1.5,
          ),

          const BoxShadow(
            color: Color(0x3316E0B5),

            blurRadius: 36,

            spreadRadius: 1,
          ),
        ],
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.24),

        child: Image.asset(
          'assets/icon/dhanviq_icon.png',

          width: size,

          height: size,

          fit: BoxFit.cover,

          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFF0B286D),

              alignment: Alignment.center,

              child: const Text(
                'D',

                style: TextStyle(
                  color: Colors.white,

                  fontSize: 72,

                  fontWeight: FontWeight.w900,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DhanviqTitle extends StatelessWidget {
  const _DhanviqTitle();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,

      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment.centerLeft,

          end: Alignment.centerRight,

          colors: [
            Colors.white,

            Colors.white,

            _splashAccent(context),

            const Color(0xFF16E0B5),
          ],

          stops: const [0, 0.64, 0.83, 1],
        ).createShader(bounds);
      },

      child: const Text(
        'DHANVIQ',

        textAlign: TextAlign.center,

        style: TextStyle(
          color: Colors.white,

          fontSize: 40,

          fontWeight: FontWeight.w900,

          letterSpacing: 1.5,

          height: 1,
        ),
      ),
    );
  }
}

class _BrandSubtitle extends StatelessWidget {
  const _BrandSubtitle();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'Track'),

          TextSpan(
            text: '  •  ',

            style: TextStyle(color: Color(0xFF16E0B5)),
          ),

          TextSpan(text: 'Save'),

          TextSpan(
            text: '  •  ',

            style: TextStyle(color: Color(0xFF16E0B5)),
          ),

          TextSpan(text: 'Grow'),
        ],
      ),

      textAlign: TextAlign.center,

      style: TextStyle(
        color: Color(0xFFB5BED5),

        fontSize: 14.5,

        fontWeight: FontWeight.w500,

        letterSpacing: 2,
      ),
    );
  }
}

class _GradientDivider extends StatelessWidget {
  const _GradientDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,

      height: 3,

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),

        gradient: LinearGradient(
          colors: [_splashAccent(context), const Color(0xFF16E0B5)],
        ),

        boxShadow: [
          BoxShadow(
            color: _splashAccent(context).withValues(alpha: .38),

            blurRadius: 10,
          ),
        ],
      ),
    );
  }
}

class _Tagline extends StatelessWidget {
  const _Tagline();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'A Smarter You,',

          textAlign: TextAlign.center,

          style: TextStyle(
            color: Color(0xFFF1F3FA),

            fontSize: 20,

            height: 1.35,

            fontWeight: FontWeight.w500,

            fontStyle: FontStyle.italic,
          ),
        ),

        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Brighter ',

                style: TextStyle(color: _splashAccent(context)),
              ),

              const TextSpan(
                text: 'Tomorrow.',

                style: TextStyle(color: Color(0xFF37D8F1)),
              ),
            ],
          ),

          textAlign: TextAlign.center,

          style: const TextStyle(
            fontSize: 21,

            height: 1.35,

            fontWeight: FontWeight.w600,

            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _TopLeftText extends StatelessWidget {
  const _TopLeftText();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: .82,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Small Steps',
            style: TextStyle(
              color: Color(0xFFD8E1F4),
              fontSize: 12.5,
              height: 1.15,
              letterSpacing: .35,
              fontWeight: FontWeight.w500,
            ),
          ),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => LinearGradient(
              colors: [_splashAccent(context), const Color(0xFF4FB8FF)],
            ).createShader(bounds),
            child: const Text(
              'Bigger Dreams',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.2,
                height: 1.2,
                fontWeight: FontWeight.w700,
                letterSpacing: .2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 46,
            height: 2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [_splashAccent(context), const Color(0xFF35DAEE)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopRightText extends StatelessWidget {
  const _TopRightText();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.08,
      child: const Opacity(
        opacity: .10,
        child: Text(
          'Better\nMoney\nBrighter\nYou',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF7992C0),
            fontSize: 16.5,
            height: 1.02,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
            letterSpacing: .15,
          ),
        ),
      ),
    );
  }
}

class _DotGrid extends StatelessWidget {
  const _DotGrid();

  @override
  Widget build(BuildContext context) {
    final color = _splashAccent(context);
    return Opacity(
      opacity: .55,
      child: SizedBox(
        width: 26,
        height: 42,
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(
            12,
            (_) => Container(
              width: 3.3,
              height: 3.3,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: .35), blurRadius: 6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, this.dim = false});

  final double size;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final accent = _splashAccent(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: dim ? .45 : .90),
            const Color(0xFF2C66FF).withValues(alpha: dim ? .22 : .72),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: dim ? .14 : .28),
            blurRadius: dim ? 10 : 18,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 130,

          left: -120,

          child: Container(
            width: 280,

            height: 280,

            decoration: BoxDecoration(
              shape: BoxShape.circle,

              gradient: RadialGradient(
                colors: [
                  _splashAccent(context).withValues(alpha: .13),

                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 100,

          right: -130,

          child: Container(
            width: 330,

            height: 330,

            decoration: const BoxDecoration(
              shape: BoxShape.circle,

              gradient: RadialGradient(
                colors: [Color(0x1A16E0B5), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FinanceBackgroundPainter extends CustomPainter {
  const _FinanceBackgroundPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    _drawBars(canvas, size);

    _drawGrowthLine(canvas, size);

    _drawBackWave(canvas, size);

    _drawFrontWave(canvas, size);
  }

  void _drawBars(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,

        end: Alignment.topCenter,

        colors: [accent.withValues(alpha: 0), accent.withValues(alpha: .34)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final barWidth = size.width * 0.052;

    final gap = size.width * 0.035;

    final startingX = size.width * 0.52;

    final baseY = size.height * 0.72;

    final heights = [
      size.height * 0.18,

      size.height * 0.25,

      size.height * 0.36,

      size.height * 0.49,
    ];

    for (var index = 0; index < heights.length; index++) {
      final x = startingX + index * (barWidth + gap);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, baseY - heights[index], barWidth, heights[index]),

        const Radius.circular(4),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  void _drawGrowthLine(Canvas canvas, Size size) {
    final linePath = Path()
      ..moveTo(size.width * 0.08, size.height * 0.67)
      ..cubicTo(
        size.width * 0.22,

        size.height * 0.61,

        size.width * 0.28,

        size.height * 0.34,

        size.width * 0.44,

        size.height * 0.32,
      )
      ..cubicTo(
        size.width * 0.57,

        size.height * 0.30,

        size.width * 0.62,

        size.height * 0.48,

        size.width * 0.74,

        size.height * 0.35,
      )
      ..cubicTo(
        size.width * 0.84,

        size.height * 0.25,

        size.width * 0.87,

        size.height * 0.10,

        size.width * 0.94,

        size.height * 0.07,
      );

    final glowPaint = Paint()
      ..color = accent.withValues(alpha: .34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final linePaint = Paint()
      ..shader = LinearGradient(colors: [accent, const Color(0xFF24C8FF)])
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(linePath, glowPaint);

    canvas.drawPath(linePath, linePaint);

    final point = Offset(size.width * 0.94, size.height * 0.07);

    canvas.drawCircle(
      point,

      17,

      Paint()
        ..color = accent.withValues(alpha: .33)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    canvas.drawCircle(
      point,

      9,

      Paint()
        ..shader = LinearGradient(colors: [accent, const Color(0xFF42E0ED)])
            .createShader(Rect.fromCircle(center: point, radius: 9)),
    );

    canvas.drawCircle(
      point,

      9,

      Paint()
        ..color = const Color(0xFFDDFBFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawBackWave(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.62)
      ..cubicTo(
        size.width * 0.18,

        size.height * 0.44,

        size.width * 0.36,

        size.height * 0.49,

        size.width * 0.53,

        size.height * 0.67,
      )
      ..cubicTo(
        size.width * 0.70,

        size.height * 0.85,

        size.width * 0.84,

        size.height * 0.69,

        size.width,

        size.height * 0.57,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,

        end: Alignment.bottomRight,

        colors: [
          accent,

          Color.lerp(accent, const Color(0xFF071536), .43)!,

          const Color(0xFF153981),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final glowPaint = Paint()
      ..color = accent.withValues(alpha: .33)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawPath(path, glowPaint);

    canvas.drawPath(path, paint);
  }

  void _drawFrontWave(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.77)
      ..cubicTo(
        size.width * 0.18,

        size.height * 0.67,

        size.width * 0.28,

        size.height * 0.48,

        size.width * 0.45,

        size.height * 0.48,
      )
      ..cubicTo(
        size.width * 0.62,

        size.height * 0.48,

        size.width * 0.72,

        size.height * 0.72,

        size.width * 0.87,

        size.height * 0.75,
      )
      ..cubicTo(
        size.width * 0.92,

        size.height * 0.76,

        size.width * 0.96,

        size.height * 0.72,

        size.width,

        size.height * 0.70,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,

        end: Alignment.bottomRight,

        colors: [Color(0xFF244EB1), Color(0xFF102E70), Color(0xFF071536)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final topBorderPath = Path()
      ..moveTo(0, size.height * 0.77)
      ..cubicTo(
        size.width * 0.18,

        size.height * 0.67,

        size.width * 0.28,

        size.height * 0.48,

        size.width * 0.45,

        size.height * 0.48,
      )
      ..cubicTo(
        size.width * 0.62,

        size.height * 0.48,

        size.width * 0.72,

        size.height * 0.72,

        size.width * 0.87,

        size.height * 0.75,
      )
      ..cubicTo(
        size.width * 0.92,

        size.height * 0.76,

        size.width * 0.96,

        size.height * 0.72,

        size.width,

        size.height * 0.70,
      );

    final borderPaint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF42BDFF), accent, const Color(0xFF1B65D8)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(path, paint);

    canvas.drawPath(topBorderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _FinanceBackgroundPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}
