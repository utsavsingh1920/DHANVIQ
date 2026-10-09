import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/theme_controller.dart';

// ============================================================
// DHANVIQ ACCENT COLOR CONTROLLER
// ============================================================

class DhanviqAccentController extends ChangeNotifier {
  DhanviqAccentController._();

  static final DhanviqAccentController instance =
      DhanviqAccentController._();

  static const String _storageKey = 'dhanviq_accent_color';

  static const Color purple = Color(0xFF8838F5);
  static const Color blue = Color(0xFF2477F5);
  static const Color green = Color(0xFF0DC99C);
  static const Color yellow = Color(0xFFFFC83D);
  static const Color orange = Color(0xFFFF913D);
  static const Color red = Color(0xFFFF4D60);
  static const Color pink = Color(0xFFF46DA7);

  static const List<Color> availableColors = [
    purple,
    blue,
    green,
    yellow,
    orange,
    red,
    pink,
  ];

  Color _accentColor = purple;

  Color get accentColor => _accentColor;

  bool _initialized = false;
  bool _userChangedColor = false;

  // Load previously selected accent color.
  Future<void> initialize() async {
    if (_initialized) return;

    _initialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();

      final savedValue = prefs.getInt(_storageKey);

      if (savedValue == null || _userChangedColor) return;

      for (final color in availableColors) {
        if (color.toARGB32() == savedValue) {
          _accentColor = color;
          notifyListeners();
          break;
        }
      }
    } catch (e) {
      debugPrint('Accent color loading failed: $e');
    }
  }

  // Change accent color and save automatically.
  Future<void> setAccentColor(Color color) async {
    if (!availableColors.contains(color)) return;

    _userChangedColor = true;

    if (_accentColor != color) {
      _accentColor = color;
      notifyListeners();
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setInt(
        _storageKey,
        color.toARGB32(),
      );
    } catch (e) {
      debugPrint('Accent color saving failed: $e');
    }
  }
}

// ============================================================
// APPEARANCE SCREEN
// ============================================================

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  final ThemeController _themeController = ThemeController.instance;

  final DhanviqAccentController _accentController =
      DhanviqAccentController.instance;

  int _previewIndex = 0;

  @override
  void initState() {
    super.initState();

    _accentController.initialize();
  }

  // ----------------------------------------------------------
  // THEME COLORS
  // ----------------------------------------------------------

  bool _isDarkMode(BuildContext context) {
    final mode = _themeController.themeMode;

    if (mode == ThemeMode.dark) {
      return true;
    }

    if (mode == ThemeMode.light) {
      return false;
    }

    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  Color _background(bool dark) {
    return dark
        ? const Color(0xFF0E1420)
        : const Color(0xFFF5F7FB);
  }

  Color _cardBackground(bool dark) {
    return dark
        ? const Color(0xFF172131)
        : Colors.white;
  }

  Color _tileBackground(bool dark) {
    return dark
        ? const Color(0xFF192333)
        : const Color(0xFFF8F9FD);
  }

  Color _primaryText(bool dark) {
    return dark
        ? const Color(0xFFF5F6FB)
        : const Color(0xFF182233);
  }

  Color _secondaryText(bool dark) {
    return dark
        ? const Color(0xFFA5B0C5)
        : const Color(0xFF758096);
  }

  Color _borderColor(bool dark) {
    return dark
        ? const Color(0xFF2A364B)
        : const Color(0xFFE4E9F1);
  }

  Color _selectedBackground(Color accent, bool dark) {
    return Color.alphaBlend(
      accent.withValues(alpha: dark ? 0.15 : 0.08),
      _tileBackground(dark),
    );
  }

  // ----------------------------------------------------------
  // MAIN BUILD
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _themeController,
        _accentController,
      ]),
      builder: (context, child) {
        final bool dark = _isDarkMode(context);

        final Color accent = _accentController.accentColor;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                dark ? Brightness.light : Brightness.dark,
            statusBarBrightness:
                dark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: _background(dark),
            systemNavigationBarIconBrightness:
                dark ? Brightness.light : Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: _background(dark),

            appBar: AppBar(
              backgroundColor: _background(dark),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              automaticallyImplyLeading: false,
              toolbarHeight: 72,

              titleSpacing: 16,

              title: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: _primaryText(dark),
                      size: 27,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Text(
                    'Appearance',
                    style: TextStyle(
                      color: _primaryText(dark),
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                    ),
                  ),
                ],
              ),
            ),

            body: ListView(
              physics: const BouncingScrollPhysics(),

              padding: const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                32,
              ),

              children: [
                // DESCRIPTION
                Text(
                  'Choose how DHANVIQ looks. Your selection '
                  'is saved automatically.',
                  style: TextStyle(
                    color: _secondaryText(dark),
                    fontSize: 15,
                    height: 1.55,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 20),

                // THEME MODE
                _buildThemeCard(
                  dark: dark,
                  accent: accent,
                ),

                const SizedBox(height: 14),

                // ACCENT COLOR
                _buildAccentCard(
                  dark: dark,
                  accent: accent,
                ),

                const SizedBox(height: 14),

                // LIVE PREVIEW
                _buildPreviewCard(
                  dark: dark,
                  accent: accent,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // COMMON CARD
  // ==========================================================

  Widget _buildCard({
    required bool dark,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: _cardBackground(dark),

        borderRadius: BorderRadius.circular(20),

        border: Border.all(
          color: _borderColor(dark),
          width: 1,
        ),
      ),

      child: child,
    );
  }

  // ==========================================================
  // SECTION HEADING
  // ==========================================================

  Widget _buildSectionHeading({
    required bool dark,
    required Color accent,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Container(
          width: 46,
          height: 46,

          decoration: BoxDecoration(
            color: accent.withValues(
              alpha: dark ? 0.22 : 0.10,
            ),

            borderRadius: BorderRadius.circular(14),
          ),

          child: Icon(
            icon,
            color: accent,
            size: 27,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const SizedBox(height: 3),

              Text(
                title,
                style: TextStyle(
                  color: _primaryText(dark),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                subtitle,
                style: TextStyle(
                  color: _secondaryText(dark),
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // THEME MODE CARD
  // ==========================================================

  Widget _buildThemeCard({
    required bool dark,
    required Color accent,
  }) {
    return _buildCard(
      dark: dark,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          _buildSectionHeading(
            dark: dark,
            accent: accent,
            icon: Icons.dark_mode_rounded,
            title: 'Theme Mode',
            subtitle: 'Choose your preferred theme',
          ),

          const SizedBox(height: 17),

          Row(
            children: [
              Expanded(
                child: _buildThemeOption(
                  dark: dark,
                  accent: accent,
                  icon: Icons.light_mode_rounded,
                  title: 'Light',
                  mode: ThemeMode.light,
                  iconColor: const Color(0xFFFFC96A),
                ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: _buildThemeOption(
                  dark: dark,
                  accent: accent,
                  icon: Icons.dark_mode_rounded,
                  title: 'Dark',
                  mode: ThemeMode.dark,
                  iconColor: accent,
                ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: _buildThemeOption(
                  dark: dark,
                  accent: accent,
                  icon: Icons.desktop_windows_rounded,
                  title: 'System',
                  mode: ThemeMode.system,
                  iconColor: const Color(0xFFA6B6D5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // THEME OPTION
  // ==========================================================

  Widget _buildThemeOption({
    required bool dark,
    required Color accent,
    required IconData icon,
    required String title,
    required ThemeMode mode,
    required Color iconColor,
  }) {
    final bool selected = _themeController.themeMode == mode;

    return Material(
      color: Colors.transparent,

      child: InkWell(
        borderRadius: BorderRadius.circular(17),

        onTap: () {
          _themeController.setThemeMode(mode);
        },

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),

          curve: Curves.easeOut,

          height: 83,

          decoration: BoxDecoration(
            color: selected
                ? _selectedBackground(accent, dark)
                : _tileBackground(dark),

            borderRadius: BorderRadius.circular(17),

            border: Border.all(
              color: selected
                  ? accent
                  : _borderColor(dark),

              width: selected ? 1.7 : 1,
            ),

            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(
                        alpha: dark ? 0.18 : 0.10,
                      ),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),

          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    Icon(
                      icon,
                      size: 31,
                      color: iconColor,
                    ),

                    const SizedBox(height: 7),

                    Text(
                      title,
                      style: TextStyle(
                        color: _primaryText(dark),
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              if (selected)
                Positioned(
                  right: 5,
                  top: 5,

                  child: Container(
                    width: 21,
                    height: 21,

                    decoration: BoxDecoration(
                      color: dark
                          ? const Color(0xFFECE2FF)
                          : accent,

                      shape: BoxShape.circle,
                    ),

                    child: Icon(
                      Icons.check_rounded,
                      size: 15,

                      color: dark
                          ? accent
                          : Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // ACCENT COLOR CARD
  // ==========================================================

  Widget _buildAccentCard({
    required bool dark,
    required Color accent,
  }) {
    return _buildCard(
      dark: dark,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          _buildSectionHeading(
            dark: dark,
            accent: accent,
            icon: Icons.palette_rounded,
            title: 'Accent Color',
            subtitle:
                'Choose a color for navigation and key highlights.',
          ),

          const SizedBox(height: 17),

          GridView.count(
            crossAxisCount: 4,

            shrinkWrap: true,

            physics: const NeverScrollableScrollPhysics(),

            crossAxisSpacing: 7,

            mainAxisSpacing: 7,

            childAspectRatio: 0.83,

            children: [
              _buildAccentOption(
                dark: dark,
                color: DhanviqAccentController.purple,
                name: 'Purple',
              ),

              _buildAccentOption(
                dark: dark,
                color: DhanviqAccentController.blue,
                name: 'Blue',
              ),

              _buildAccentOption(
                dark: dark,
                color: DhanviqAccentController.green,
                name: 'Green',
              ),

              _buildAccentOption(
                dark: dark,
                color: DhanviqAccentController.yellow,
                name: 'Yellow',
              ),

              _buildAccentOption(
                dark: dark,
                color: DhanviqAccentController.orange,
                name: 'Orange',
              ),

              _buildAccentOption(
                dark: dark,
                color: DhanviqAccentController.red,
                name: 'Red',
              ),

              _buildAccentOption(
                dark: dark,
                color: DhanviqAccentController.pink,
                name: 'Pink',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ACCENT COLOR OPTION
  // ==========================================================

  Widget _buildAccentOption({
    required bool dark,
    required Color color,
    required String name,
  }) {
    final bool selected =
        _accentController.accentColor == color;

    return Material(
      color: Colors.transparent,

      child: InkWell(
        borderRadius: BorderRadius.circular(17),

        onTap: () {
          _accentController.setAccentColor(color);
        },

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),

          curve: Curves.easeOut,

          decoration: BoxDecoration(
            color: selected
                ? _selectedBackground(color, dark)
                : _tileBackground(dark),

            borderRadius: BorderRadius.circular(17),

            border: Border.all(
              color: selected
                  ? color
                  : _borderColor(dark),

              width: selected ? 1.7 : 1,
            ),

            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.12),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),

          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  Container(
                    width: 37,
                    height: 37,

                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),

                    child: selected
                        ? Icon(
                            Icons.check_rounded,
                            color: color ==
                                    DhanviqAccentController.yellow
                                ? const Color(0xFF483200)
                                : Colors.white,
                            size: 24,
                          )
                        : null,
                  ),

                  const SizedBox(height: 9),

                  Text(
                    name,

                    style: TextStyle(
                      color: _primaryText(dark),
                      fontSize: 12,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),

              if (selected)
                Positioned(
                  top: 5,
                  right: 5,

                  child: Container(
                    width: 20,
                    height: 20,

                    decoration: BoxDecoration(
                      color: dark
                          ? const Color(0xFFF0E9FF)
                          : Colors.white,

                      shape: BoxShape.circle,

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: 0.10,
                          ),
                          blurRadius: 4,
                        ),
                      ],
                    ),

                    child: Icon(
                      Icons.check_rounded,
                      color: color,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // LIVE PREVIEW CARD
  // ==========================================================

  Widget _buildPreviewCard({
    required bool dark,
    required Color accent,
  }) {
    return _buildCard(
      dark: dark,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          _buildSectionHeading(
            dark: dark,
            accent: accent,
            icon: Icons.visibility_outlined,
            title: 'Preview',
            subtitle:
                'See how the selected appearance looks in the app.',
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,

            padding: const EdgeInsets.symmetric(
              horizontal: 5,
              vertical: 10,
            ),

            decoration: BoxDecoration(
              color: _tileBackground(dark),

              borderRadius: BorderRadius.circular(23),

              border: Border.all(
                color: _borderColor(dark),
              ),
            ),

            child: Row(
              children: [
                _buildPreviewItem(
                  dark: dark,
                  accent: accent,
                  icon: Icons.home_rounded,
                  title: 'Home',
                  index: 0,
                ),

                _buildPreviewItem(
                  dark: dark,
                  accent: accent,
                  icon: Icons.swap_horiz_rounded,
                  title: 'Transactions',
                  index: 1,
                ),

                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        _showPreviewActionSheet(
                          context,
                          accent,
                          dark,
                        );
                      },

                      child: Container(
                        width: 51,
                        height: 51,

                        decoration: BoxDecoration(
                          color: accent,

                          shape: BoxShape.circle,

                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),

                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),

                _buildPreviewItem(
                  dark: dark,
                  accent: accent,
                  icon: Icons.bar_chart_rounded,
                  title: 'Insights',
                  index: 2,
                ),

                _buildPreviewItem(
                  dark: dark,
                  accent: accent,
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  index: 3,
                ),
              ],
            ),
          ),

          const SizedBox(height: 13),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,

            children: List.generate(
              4,

              (index) {
                final selected = _previewIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _previewIndex = index;
                    });
                  },

                  child: AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 200,
                    ),

                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                    ),

                    width: 7,
                    height: 7,

                    decoration: BoxDecoration(
                      color: selected
                          ? accent
                          : _secondaryText(dark).withValues(
                              alpha: 0.35,
                            ),

                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PREVIEW NAVIGATION ITEM
  // ==========================================================

  Widget _buildPreviewItem({
    required bool dark,
    required Color accent,
    required IconData icon,
    required String title,
    required int index,
  }) {
    final bool selected = _previewIndex == index;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(13),

        onTap: () {
          setState(() {
            _previewIndex = index;
          });
        },

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),

              width: 39,
              height: 33,

              decoration: BoxDecoration(
                color: selected
                    ? accent.withValues(alpha: 0.15)
                    : Colors.transparent,

                borderRadius: BorderRadius.circular(11),
              ),

              child: Icon(
                icon,
                size: 23,

                color: selected
                    ? accent
                    : _secondaryText(dark),
              ),
            ),

            const SizedBox(height: 4),

            FittedBox(
              fit: BoxFit.scaleDown,

              child: Text(
                title,

                maxLines: 1,

                style: TextStyle(
                  color: selected
                      ? accent
                      : _secondaryText(dark),

                  fontSize: 9,

                  fontWeight: selected
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // PREVIEW ADD BUTTON
  // ==========================================================

  void _showPreviewActionSheet(
    BuildContext context,
    Color accent,
    bool dark,
  ) {
    showModalBottomSheet<void>(
      context: context,

      backgroundColor: _cardBackground(dark),

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),

      builder: (sheetContext) {
        return SafeArea(
          top: false,

          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              15,
              20,
              25,
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                Container(
                  width: 35,
                  height: 4,

                  decoration: BoxDecoration(
                    color: _borderColor(dark),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Quick Actions Preview',

                  style: TextStyle(
                    color: _primaryText(dark),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 16),

                _buildPreviewActionRow(
                  context: sheetContext,
                  dark: dark,
                  accent: accent,
                  icon: Icons.arrow_downward_rounded,
                  title: 'Add Income',
                ),

                _buildPreviewActionRow(
                  context: sheetContext,
                  dark: dark,
                  accent: accent,
                  icon: Icons.arrow_upward_rounded,
                  title: 'Add Expense',
                ),

                _buildPreviewActionRow(
                  context: sheetContext,
                  dark: dark,
                  accent: accent,
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Set Budget',
                ),

                _buildPreviewActionRow(
                  context: sheetContext,
                  dark: dark,
                  accent: accent,
                  icon: Icons.flag_outlined,
                  title: 'Add Goal',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewActionRow({
    required BuildContext context,
    required bool dark,
    required Color accent,
    required IconData icon,
    required String title,
  }) {
    return ListTile(
      onTap: () {
        Navigator.pop(context);
      },

      contentPadding: EdgeInsets.zero,

      leading: Container(
        width: 42,
        height: 42,

        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),

        child: Icon(
          icon,
          color: accent,
          size: 23,
        ),
      ),

      title: Text(
        title,

        style: TextStyle(
          color: _primaryText(dark),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),

      trailing: Icon(
        Icons.chevron_right_rounded,
        color: _secondaryText(dark),
      ),
    );
  }
}