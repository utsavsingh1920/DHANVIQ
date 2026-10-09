import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/services.dart';

import '../welcome/welcome_screen.dart';

// The accent is set by the shared MaterialApp theme in main.dart.

Color _accent(BuildContext context) => Theme.of(context).colorScheme.primary;

// Keep the arrow readable when the user selects a light accent (e.g. yellow).

Color _onAccent(Color accent) =>
    ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
    ? Colors.white
    : const Color(0xFF101936);

Color _accentShade(Color accent, {required bool lighter}) => Color.lerp(
  accent,
  lighter ? Colors.white : Colors.black,
  lighter ? .12 : .15,
)!;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();

  int _page = 0;

  static const List<_OnboardingItem> _items = [
    _OnboardingItem(
      title: 'Take Control\nof Your Money',

      description: 'Track your income, expenses and\nspending habits easily.',

      asset: 'assets/images/onboarding_control.png',

      note: 'Track\nAnalyze\nImprove',

      noteAlignment: Alignment(-.70, .80),

      imageScale: 1.42,

      imageOffset: Offset(0, 8),
    ),

    _OnboardingItem(
      title: 'Plan Smarter\nBudgets',

      description:
          'Set monthly budgets and stay on track\nwith your financial plans.',

      asset: 'assets/images/onboarding_budget.png',

      note: 'Plan Today\nSpend Better\nLive Freely',

      noteAlignment: Alignment(.57, .81),

      imageScale: 1.38,

      imageOffset: Offset(0, 4),
    ),

    _OnboardingItem(
      title: 'Save for\nWhat Matters',

      description:
          'Create meaningful goals and turn your\ndreams into reality.',

      asset: 'assets/images/onboarding_goals.png',

      note: 'Small Steps\nBig Dreams',

      noteAlignment: Alignment(.52, .82),

      imageScale: 1.10,

      imageOffset: Offset(-2, 2),
    ),

    _OnboardingItem(
      title: 'Build a\nBrighter Future',

      description:
          'Understand your finances and make\nsmarter money decisions.',

      asset: 'assets/images/onboarding_growth.png',

      note: 'Better Money\nBrighter You',

      noteAlignment: Alignment(.63, .81),

      imageScale: 1.42,

      imageOffset: Offset(0, 5),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  Future<void> _openWelcome() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('onboardingCompleted', true);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),

        pageBuilder: (context, animation, secondaryAnimation) {
          return const WelcomeScreen();
        },

        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _next() {
    if (_page == _items.length - 1) {
      _openWelcome();

      return;
    }

    _controller.nextPage(
      duration: const Duration(milliseconds: 380),

      curve: Curves.easeInOutCubic,
    );
  }

  void _back() {
    if (_page == 0) return;

    _controller.previousPage(
      duration: const Duration(milliseconds: 380),

      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final background = Theme.of(context).scaffoldBackgroundColor;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,

        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,

        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,

        systemNavigationBarColor: background,

        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,

        systemNavigationBarDividerColor: background,
      ),

      child: Scaffold(
        resizeToAvoidBottomInset: false,

        backgroundColor: background,

        body: Stack(
          children: [
            Positioned.fill(child: _PageBackground(page: _page)),

            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),

                  child: Column(
                    children: [
                      _TopBar(
                        showBack: _page > 0,

                        onBack: _back,

                        onSkip: _openWelcome,
                      ),

                      Expanded(
                        child: PageView.builder(
                          controller: _controller,

                          itemCount: _items.length,

                          physics: const BouncingScrollPhysics(),

                          onPageChanged: (value) =>
                              setState(() => _page = value),

                          itemBuilder: (context, index) {
                            return _OnboardingPage(item: _items[index]);
                          },
                        ),
                      ),

                      _BottomBar(
                        currentPage: _page,

                        pageCount: _items.length,

                        onNext: _next,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingItem {
  const _OnboardingItem({
    required this.title,

    required this.description,

    required this.asset,

    required this.note,

    required this.noteAlignment,

    required this.imageScale,

    required this.imageOffset,
  });

  final String title;

  final String description;

  final String asset;

  final String note;

  final Alignment noteAlignment;

  final double imageScale;

  final Offset imageOffset;
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.showBack,

    required this.onBack,

    required this.onSkip,
  });

  final bool showBack;

  final VoidCallback onBack;

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,

      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),

        child: Row(
          children: [
            AnimatedOpacity(
              opacity: showBack ? 1 : 0,

              duration: const Duration(milliseconds: 200),

              child: IgnorePointer(
                ignoring: !showBack,

                child: IconButton(
                  onPressed: onBack,

                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,

                    color: Theme.of(context).colorScheme.onSurface,

                    size: 21,
                  ),
                ),
              ),
            ),

            const Spacer(),

            TextButton(
              onPressed: onSkip,

              child: Text(
                'Skip',

                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,

                  fontSize: 15,

                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.item});

  final _OnboardingItem item;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 600;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),

            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 22 : 25),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  SizedBox(height: compact ? 2 : 7),

                  Text(
                    item.title,

                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,

                      fontSize: compact ? 28 : 32,

                      height: 1.10,

                      letterSpacing: -0.7,

                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  SizedBox(height: compact ? 8 : 11),

                  Text(
                    item.description,

                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,

                      fontSize: compact ? 13 : 14,

                      height: 1.45,
                    ),
                  ),

                  SizedBox(height: compact ? 0 : 2),

                  Expanded(
                    child: ClipRect(
                      child: Stack(
                        alignment: Alignment.center,

                        children: [
                          Positioned.fill(
                            left: 0,

                            right: 0,

                            child: Transform.translate(
                              offset: item.imageOffset,

                              child: Transform.scale(
                                scale: item.imageScale,

                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  child: Image.asset(
                                    item.asset,
                                    fit: BoxFit.contain,
                                    alignment: const Alignment(0, -.05),
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          Align(
                            alignment: item.noteAlignment,

                            child: Transform.rotate(
                              angle: -.11,

                              child: Text(
                                item.note,

                                textAlign: TextAlign.center,

                                style: TextStyle(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? _accent(context)
                                      : Color.lerp(
                                          _accent(context),

                                          const Color(0xFF101936),
                                          .32,
                                        )!,

                                  fontFamily: 'cursive',

                                  fontSize: compact ? 11.5 : 12.5,

                                  height: 1.0,

                                  fontStyle: FontStyle.italic,

                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PageBackground extends StatelessWidget {
  const _PageBackground({required this.page});

  final int page;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _accent(context);
    const mint = Color(0xFF22D3B6);

    final topColor = page == 1 || page == 3 ? mint : accent;
    final middleColor = page == 0 || page == 2 ? mint : accent;
    final bottomColor = page == 3 ? mint : accent;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [
                      Color(0xFF0B1020),
                      Color(0xFF0F1628),
                      Color(0xFF10192A),
                    ]
                  : const [
                      Color(0xFFFBFBFF),
                      Color(0xFFF7F8FF),
                      Color(0xFFF4FAFC),
                    ],
            ),
          ),
        ),
        Positioned(
          top: -95,
          left: -80,
          child: Transform.rotate(
            angle: -.28,
            child: Container(
              width: 220,
              height: 165,
              decoration: BoxDecoration(
                color: topColor.withValues(alpha: isDark ? .075 : .10),
                borderRadius: BorderRadius.circular(88),
              ),
            ),
          ),
        ),
        Positioned(
          top: page == 0 ? 150 : 175,
          right: -105,
          child: Container(
            width: 245,
            height: 245,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  middleColor.withValues(alpha: isDark ? .075 : .12),
                  middleColor.withValues(alpha: isDark ? .025 : .045),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -85,
          left: page.isEven ? -75 : 45,
          child: Transform.rotate(
            angle: page.isEven ? -.20 : .20,
            child: Container(
              width: 275,
              height: 165,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    bottomColor.withValues(alpha: isDark ? .070 : .11),
                    mint.withValues(alpha: isDark ? .035 : .060),
                  ],
                ),
                borderRadius: BorderRadius.circular(92),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.currentPage,

    required this.pageCount,

    required this.onNext,
  });

  final int currentPage;

  final int pageCount;

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(29, 7, 24, 18),

      child: Row(
        children: [
          ...List.generate(pageCount, (index) {
            final selected = currentPage == index;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),

              width: selected ? 28 : 7,

              height: 7,

              margin: const EdgeInsets.only(right: 7),

              decoration: BoxDecoration(
                color: selected
                    ? accent
                    : (Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF45516B)
                          : const Color(0xFFDDE1EE)),

                borderRadius: BorderRadius.circular(20),
              ),
            );
          }),

          const Spacer(),

          Container(
            width: 58,

            height: 58,

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(29),

              gradient: LinearGradient(
                colors: [
                  _accentShade(accent, lighter: true),

                  _accentShade(accent, lighter: false),
                ],
              ),

              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: .28),

                  blurRadius: 22,

                  offset: const Offset(0, 9),
                ),
              ],
            ),

            child: Material(
              color: Colors.transparent,

              child: InkWell(
                onTap: onNext,

                borderRadius: BorderRadius.circular(29),

                child: Center(
                  child: Icon(
                    Icons.arrow_forward_rounded,

                    color: _onAccent(accent),

                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
