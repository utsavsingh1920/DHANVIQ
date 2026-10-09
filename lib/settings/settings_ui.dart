import 'package:flutter/material.dart';

// ============================================================
// DHANVIQ SETTINGS UI
// ============================================================

class UI {
  // ----------------------------------------------------------
  // DEFAULT COLORS
  // ----------------------------------------------------------

  // Keep this constant for compatibility with existing screens.
  static const Color purple = Color(0xFF6C3BFF);

  static const Color navy = Color(0xFF071536);

  // ----------------------------------------------------------
  // DYNAMIC ACCENT COLOR
  // ----------------------------------------------------------

  // Returns the color selected in Appearance Screen.
  static Color accent(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  // Suitable foreground color for the selected accent.
  static Color onAccent(BuildContext context) {
    final color = accent(context);

    return ThemeData.estimateBrightnessForColor(color) ==
            Brightness.dark
        ? Colors.white
        : const Color(0xFF111827);
  }

  // ----------------------------------------------------------
  // THEME CHECK
  // ----------------------------------------------------------

  static bool dark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  // ----------------------------------------------------------
  // BACKGROUND
  // ----------------------------------------------------------

  static Color bg(BuildContext context) {
    return dark(context)
        ? const Color(0xFF090F20)
        : const Color(0xFFF7F8FD);
  }

  // ----------------------------------------------------------
  // CARD
  // ----------------------------------------------------------

  static Color card(BuildContext context) {
    return dark(context)
        ? const Color(0xFF172138)
        : Colors.white;
  }

  // ----------------------------------------------------------
  // PRIMARY TEXT
  // ----------------------------------------------------------

  static Color ink(BuildContext context) {
    return dark(context)
        ? Colors.white
        : navy;
  }

  // ----------------------------------------------------------
  // SECONDARY TEXT
  // ----------------------------------------------------------

  static Color sub(BuildContext context) {
    return dark(context)
        ? const Color(0xFFADB7CD)
        : const Color(0xFF77839A);
  }

  // ----------------------------------------------------------
  // BORDER
  // ----------------------------------------------------------

  static Color border(BuildContext context) {
    return dark(context)
        ? const Color(0xFF303B53)
        : const Color(0xFFE8EBF3);
  }

  // ----------------------------------------------------------
  // ACCENT BACKGROUND
  // ----------------------------------------------------------

  static Color accentBackground(BuildContext context) {
    return accent(context).withValues(
      alpha: dark(context) ? 0.18 : 0.10,
    );
  }

  // ----------------------------------------------------------
  // NAVIGATION
  // ----------------------------------------------------------

  static void go(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => screen,
      ),
    );
  }

  // ----------------------------------------------------------
  // SNACKBAR
  // ----------------------------------------------------------

  static void toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}

// ============================================================
// SETTINGS PAGE
// ============================================================

class SPage extends StatelessWidget {
  const SPage({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;

  final String? subtitle;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UI.bg(context),

      appBar: AppBar(
        centerTitle: true,

        backgroundColor: UI.bg(context),

        foregroundColor: UI.ink(context),

        surfaceTintColor: Colors.transparent,

        elevation: 0,

        scrolledUnderElevation: 0,

        title: Text(
          title,

          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            18,
            12,
            18,
            36,
          ),

          children: [
            if (subtitle != null) ...[
              Text(
                subtitle!,

                style: TextStyle(
                  color: UI.sub(context),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 16),
            ],

            ...children,
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SETTINGS CARD
// ============================================================

class SCard extends StatelessWidget {
  const SCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(15),
  });

  final Widget child;

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,

      decoration: BoxDecoration(
        color: UI.card(context),

        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: UI.border(context),
        ),
      ),

      child: child,
    );
  }
}

// ============================================================
// SETTINGS SECTION TITLE
// ============================================================

class STitle extends StatelessWidget {
  const STitle(
    this.value, {
    super.key,
  });

  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        3,
        18,
        0,
        10,
      ),

      child: Text(
        value,

        style: TextStyle(
          color: UI.ink(context),

          fontSize: 14,

          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ============================================================
// SETTINGS ROW
// ============================================================

class SRow extends StatelessWidget {
  const SRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;

  final String title;

  final String? subtitle;

  final VoidCallback? onTap;

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    // Selected accent color.
    final Color accentColor = UI.accent(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 2,
      ),

      // ------------------------------------------------------
      // ICON
      // ------------------------------------------------------

      leading: Container(
        width: 40,

        height: 40,

        decoration: BoxDecoration(
          color: UI.accentBackground(context),

          borderRadius: BorderRadius.circular(12),
        ),

        child: Icon(
          icon,

          color: accentColor,

          size: 21,
        ),
      ),

      // ------------------------------------------------------
      // TITLE
      // ------------------------------------------------------

      title: Text(
        title,

        style: TextStyle(
          color: UI.ink(context),

          fontWeight: FontWeight.w700,

          fontSize: 13,
        ),
      ),

      // ------------------------------------------------------
      // SUBTITLE
      // ------------------------------------------------------

      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,

              style: TextStyle(
                color: UI.sub(context),

                fontSize: 11,
              ),
            ),

      // ------------------------------------------------------
      // TRAILING ICON
      // ------------------------------------------------------

      trailing: trailing ??
          Icon(
            Icons.chevron_right_rounded,

            color: UI.sub(context),
          ),

      // ------------------------------------------------------
      // CLICK
      // ------------------------------------------------------

      onTap: onTap,
    );
  }
}

// ============================================================
// SETTINGS BUTTON
// ============================================================

class SButton extends StatelessWidget {
  const SButton(
    this.label,
    this.onTap, {
    super.key,
    this.icon = Icons.check_rounded,
  });

  final String label;

  final VoidCallback? onTap;

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    // Selected accent color.
    final Color accentColor = UI.accent(context);

    return SizedBox(
      width: double.infinity,

      height: 52,

      child: FilledButton.icon(
        onPressed: onTap,

        icon: Icon(icon),

        label: Text(label),

        style: FilledButton.styleFrom(
          // Dynamic button background.
          backgroundColor: accentColor,

          // Maintain readable text for every accent color.
          foregroundColor: UI.onAccent(context),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}