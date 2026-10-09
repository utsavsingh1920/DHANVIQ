import 'package:flutter/material.dart';

import 'settings_ui.dart';

class AboutDhanviqScreen extends StatelessWidget {
  const AboutDhanviqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return SPage(
      title: 'About DHANVIQ',
      children: [
        const SizedBox(height: 10),

        // ─────────────────────────────────────────────
        // APP HERO
        // ─────────────────────────────────────────────
        Center(
          child: Column(
            children: [
              Container(
                width: 94,
                height: 94,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: accent.withValues(alpha: .30),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(
                        alpha: dark ? .20 : .12,
                      ),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    'assets/icon/dhanviq_icon.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) {
                      return Container(
                        color: accent.withValues(alpha: .12),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 45,
                          color: accent,
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Text(
                'DHANVIQ',
                style: TextStyle(
                  color: UI.ink(context),
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'Track • Plan • Grow',
                style: TextStyle(
                  color: accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 9),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'A simple personal finance companion designed to help '
                  'you understand your money, plan better and build '
                  'healthier financial habits.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: UI.sub(context),
                    fontSize: 12.5,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // ─────────────────────────────────────────────
        // WHAT YOU CAN DO
        // ─────────────────────────────────────────────
        _sectionTitle(context, 'WHAT YOU CAN DO'),

        const SizedBox(height: 9),

        SCard(
          child: Column(
            children: [
              const SRow(
                icon: Icons.swap_horiz_rounded,
                title: 'Income & Expenses',
                subtitle: 'Record and organize everyday transactions',
                trailing: SizedBox.shrink(),
              ),

              Divider(color: UI.border(context)),

              const SRow(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Monthly Budgets',
                subtitle: 'Set spending limits for different categories',
                trailing: SizedBox.shrink(),
              ),

              Divider(color: UI.border(context)),

              const SRow(
                icon: Icons.track_changes_rounded,
                title: 'Savings Goals',
                subtitle: 'Create goals and monitor your progress',
                trailing: SizedBox.shrink(),
              ),

              Divider(color: UI.border(context)),

              const SRow(
                icon: Icons.insights_rounded,
                title: 'Insights & Reports',
                subtitle: 'Understand where your money is going',
                trailing: SizedBox.shrink(),
              ),

              Divider(color: UI.border(context)),

              const SRow(
                icon: Icons.event_note_rounded,
                title: 'Upcoming Expenses',
                subtitle: 'Plan future bills and scheduled payments',
                trailing: SizedBox.shrink(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // ─────────────────────────────────────────────
        // PRIVACY & SECURITY
        // ─────────────────────────────────────────────
        _sectionTitle(context, 'PRIVACY & SECURITY'),

        const SizedBox(height: 9),

        SCard(
          child: Column(
            children: [
              const SRow(
                icon: Icons.lock_outline_rounded,
                title: 'App Lock',
                subtitle: 'Protect access using PIN, pattern or biometrics',
                trailing: SizedBox.shrink(),
              ),

              Divider(color: UI.border(context)),

              const SRow(
                icon: Icons.backup_outlined,
                title: 'Data Backup',
                subtitle: 'Backup and restore your locally stored data',
                trailing: SizedBox.shrink(),
              ),

              Divider(color: UI.border(context)),

              const SRow(
                icon: Icons.shield_outlined,
                title: 'Your Data, Your Control',
                subtitle: 'Designed around local personal finance tracking',
                trailing: SizedBox.shrink(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // ─────────────────────────────────────────────
        // APP INFORMATION
        // ─────────────────────────────────────────────
        _sectionTitle(context, 'APP INFORMATION'),

        const SizedBox(height: 9),

        SCard(
          child: Column(
            children: [
              _infoRow(
                context,
                icon: Icons.apps_rounded,
                title: 'App Name',
                value: 'DHANVIQ',
              ),

              Divider(color: UI.border(context)),

              _infoRow(
                context,
                icon: Icons.category_outlined,
                title: 'Category',
                value: 'Personal Finance',
              ),

              Divider(color: UI.border(context)),

              _infoRow(
                context,
                icon: Icons.info_outline_rounded,
                title: 'Version',
                value: '1.0.0',
              ),

              Divider(color: UI.border(context)),

              _infoRow(
                context,
                icon: Icons.devices_rounded,
                title: 'Platform',
                value: 'Flutter',
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // ─────────────────────────────────────────────
        // DISCLAIMER
        // ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: accent.withValues(
              alpha: dark ? .11 : .07,
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: accent.withValues(alpha: .16),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: accent,
                size: 21,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  'DHANVIQ is designed for personal money tracking and '
                  'financial planning. It does not process real payments '
                  'or replace banking or professional financial services.',
                  style: TextStyle(
                    color: UI.sub(context),
                    fontSize: 11.5,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 27),

        Center(
          child: Column(
            children: [
              Text(
                'Built for smarter everyday money management',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: UI.sub(context),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '© 2026 DHANVIQ',
                style: TextStyle(
                  color: UI.sub(context).withValues(alpha: .72),
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  static Widget _sectionTitle(
    BuildContext context,
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 3),
      child: Text(
        title,
        style: TextStyle(
          color: UI.sub(context),
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: .8,
        ),
      ),
    );
  }

  static Widget _infoRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final accent = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 13,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: accent,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: UI.ink(context),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          Text(
            value,
            style: TextStyle(
              color: UI.sub(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
