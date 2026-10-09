import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../welcome/welcome_screen.dart';

import 'settings_ui.dart';

import 'account_settings_screen.dart';

import 'data_backup_screen.dart';

import 'appearance_screen.dart';

import 'currency_region_screen.dart';

import 'notifications_screen.dart';

import 'app_lock_screen.dart';

import 'privacy_policy_screen.dart';

import 'help_support_screen.dart';

import 'about_dhanviq_screen.dart';

// Keep this export: Home and other screens may import ProfileScreen

// through settings_screen.dart.

export 'profile_screen.dart' show ProfileScreen;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loggingOut = false;

  Color _accent(BuildContext context) => UI.accent(context);

  // A section title followed by one consistent card containing its options.

  Widget _section(
    BuildContext context, {

    required String title,

    required IconData icon,

    required List<Widget> children,
  }) {
    final accent = _accent(context);

    return Padding(
      padding: const EdgeInsets.only(top: 22),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),

            child: Row(
              children: [
                Container(
                  height: 29,

                  width: 29,

                  alignment: Alignment.center,

                  decoration: BoxDecoration(
                    color: accent.withValues(
                      alpha: UI.dark(context) ? 0.19 : 0.09,
                    ),

                    borderRadius: BorderRadius.circular(9),
                  ),

                  child: Icon(icon, color: accent, size: 17),
                ),

                const SizedBox(width: 10),

                Text(
                  title,

                  style: TextStyle(
                    color: UI.ink(context),

                    fontSize: 15,

                    fontWeight: FontWeight.w800,

                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),

          SCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),

            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, indent: 52, color: UI.border(context)),

                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _link({
    required IconData icon,

    required String title,

    required String subtitle,

    required Widget screen,
  }) {
    return SRow(
      icon: icon,

      title: title,

      subtitle: subtitle,

      onTap: () => UI.go(context, screen),
    );
  }

  Future<void> _logout() async {
    if (_loggingOut) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: !_loggingOut,
      builder: (dialogContext) {
        const red = Color(0xFFE54862);
        final accent = UI.accent(dialogContext);

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            decoration: BoxDecoration(
              color: UI.card(dialogContext),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: UI.border(dialogContext).withValues(alpha: .85),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: UI.dark(dialogContext) ? .34 : .12,
                  ),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: red.withValues(
                      alpha: UI.dark(dialogContext) ? .18 : .09,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_rounded, color: red, size: 29),
                ),
                const SizedBox(height: 16),
                Text(
                  'Log out of DHANVIQ?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: UI.ink(dialogContext),
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You’ll return to the welcome screen. Your saved financial '
                  'records will stay safely on this device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: UI.sub(dialogContext),
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 21),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 47,
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: UI.ink(dialogContext),
                            side: BorderSide(color: UI.border(dialogContext)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: SizedBox(
                        height: 47,
                        child: FilledButton.icon(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: red,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text(
                            'Log out',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'You can sign in again anytime.',
                  style: TextStyle(
                    color: accent.withValues(alpha: .78),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _loggingOut = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      final saved = await prefs.setBool('isLoggedIn', false);

      if (!saved) throw StateError('Logout preference could not be saved');

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),

        (_) => false,
      );
    } catch (error) {
      debugPrint('Logout failed: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not log out. Please try again.')),
      );

      setState(() => _loggingOut = false);
    }
  }

  Widget _logoutCard(BuildContext context) {
    const red = Color(0xFFE54862);

    return Padding(
      padding: const EdgeInsets.only(top: 24),

      child: Material(
        color: UI.card(context),

        borderRadius: BorderRadius.circular(18),

        child: InkWell(
          onTap: _loggingOut ? null : _logout,

          borderRadius: BorderRadius.circular(18),

          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),

              border: Border.all(color: UI.border(context)),
            ),

            child: Row(
              children: [
                Container(
                  width: 42,

                  height: 42,

                  alignment: Alignment.center,

                  decoration: BoxDecoration(
                    color: red.withValues(
                      alpha: UI.dark(context) ? 0.17 : 0.08,
                    ),

                    borderRadius: BorderRadius.circular(12),
                  ),

                  child: const Icon(Icons.logout_rounded, color: red, size: 21),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        'Log out',

                        style: TextStyle(
                          color: red,

                          fontSize: 13,

                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        'Sign out on this device',

                        style: TextStyle(color: UI.sub(context), fontSize: 11),
                      ),
                    ],
                  ),
                ),

                if (_loggingOut)
                  const SizedBox(
                    width: 19,

                    height: 19,

                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: red,
                    ),
                  )
                else
                  Icon(Icons.chevron_right_rounded, color: UI.sub(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UI.bg(context),

      body: SafeArea(
        bottom: false,

        child: Column(
          children: [
            // Clean fixed header. No decorative settings icon on the right.

            Container(
              width: double.infinity,

              padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),

              decoration: BoxDecoration(
                color: UI.bg(context),

                border: Border(
                  bottom: BorderSide(
                    color: UI.border(context).withValues(alpha: 0.65),
                  ),
                ),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    'Settings',

                    style: TextStyle(
                      color: UI.ink(context),

                      fontSize: 28,

                      fontWeight: FontWeight.w900,

                      letterSpacing: -0.8,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),

                padding: const EdgeInsets.fromLTRB(18, 2, 18, 118),

                children: [
                  // Profile card removed: account details already has the profile.

                  _section(
                    context,

                    title: 'Account',

                    icon: Icons.person_outline_rounded,

                    children: [
                      _link(
                        icon: Icons.manage_accounts_outlined,

                        title: 'Account Settings',

                        subtitle: 'Profile, name, email and phone',

                        screen: const AccountDetailsScreen(),
                      ),

                      _link(
                        icon: Icons.cloud_outlined,

                        title: 'Data & Backup',

                        subtitle: 'Manage your saved records',

                        screen: const DataBackupScreen(),
                      ),
                    ],
                  ),

                  _section(
                    context,

                    title: 'General',

                    icon: Icons.tune_rounded,

                    children: [
                      _link(
                        icon: Icons.palette_outlined,

                        title: 'Appearance',

                        subtitle: 'Theme mode and accent color',

                        screen: const AppearanceScreen(),
                      ),

                      _link(
                        icon: Icons.currency_rupee_rounded,

                        title: 'Currency & Region',

                        subtitle: 'Display preferences',

                        screen: const CurrencyRegionScreen(),
                      ),
                    ],
                  ),

                  _section(
                    context,

                    title: 'Notifications',

                    icon: Icons.notifications_none_rounded,

                    children: [
                      _link(
                        icon: Icons.notifications_active_outlined,

                        title: 'Notification Settings',

                        subtitle: 'Reminders and alert preferences',

                        screen: const NotificationsScreen(),
                      ),
                    ],
                  ),

                  _section(
                    context,

                    title: 'Privacy & Security',

                    icon: Icons.shield_outlined,

                    children: [
                      _link(
                        icon: Icons.lock_outline_rounded,

                        title: 'App Lock',

                        subtitle: 'App access and security',

                        screen: const AppLockScreen(),
                      ),

                      _link(
                        icon: Icons.privacy_tip_outlined,

                        title: 'Privacy Policy',

                        subtitle: 'How your local data is handled',

                        screen: const PrivacyPolicyScreen(),
                      ),
                    ],
                  ),

                  _section(
                    context,

                    title: 'Support & About',

                    icon: Icons.info_outline_rounded,

                    children: [
                      _link(
                        icon: Icons.help_outline_rounded,

                        title: 'Help & Support',

                        subtitle: 'FAQs and feedback',

                        screen: const HelpSupportScreen(),
                      ),

                      _link(
                        icon: Icons.info_outline_rounded,

                        title: 'About DHANVIQ',

                        subtitle: 'App information',

                        screen: const AboutDhanviqScreen(),
                      ),
                    ],
                  ),

                  _logoutCard(context),

                  const SizedBox(height: 22),

                  Center(
                    child: Text(
                      'DHANVIQ  •  Track. Save. Grow.',

                      style: TextStyle(
                        color: UI.sub(context),

                        fontSize: 11,

                        fontWeight: FontWeight.w500,
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
}