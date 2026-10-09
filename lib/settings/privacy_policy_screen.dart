import 'package:flutter/material.dart';

// DHANVIQ's current, in-app data notice. This is not a published legal policy.
// All brand colors are read from MaterialApp's colorScheme so the Appearance
// setting controls them in Light, Dark and System Default modes.

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const List<_PrivacySection> _sections = [
    _PrivacySection(
      title: 'Information We Collect',
      preview: 'What information you enter and why',
      icon: Icons.description_rounded,
      details:
          'DHANVIQ is a personal finance management app. You can enter profile '
          'details, income, expenses, budgets and savings goals. These records '
          'are entered by you while using the app. The current version does not '
          'need access to your bank account to record a transaction.',
    ),
    _PrivacySection(
      title: 'How We Use Your Information',
      preview: 'How your data supports app features',
      icon: Icons.settings_rounded,
      details:
          'Your recorded amounts are used inside the app to show transaction '
          'history, spending summaries, budget progress and savings goals. '
          'Your profile details are used to display the profile you entered. '
          'The app does not treat these records as real bank transactions.',
    ),
    _PrivacySection(
      title: 'Data Storage',
      preview: 'Your current records are kept on this device',
      icon: Icons.storage_rounded,
      details:
          'In the current implementation, transaction and profile records are '
          'stored locally on your device. The transaction export feature '
          'copies a JSON backup to the clipboard; you must save that copy '
          'somewhere safe yourself. A local app backup may be lost if you '
          'uninstall the app or clear its data.',
    ),
    _PrivacySection(
      title: 'Data Sharing',
      preview: 'Understand what happens when you export data',
      icon: Icons.share_rounded,
      details:
          'This screen does not upload your financial records. If you copy '
          'a transaction backup and paste it into another app or service, '
          'that destination handles the copied information under its own '
          'terms. Other integrations, if added later, must be reviewed '
          'before making broader data-sharing claims.',
    ),
    _PrivacySection(
      title: 'Your Rights',
      preview: 'Manage the information you have entered',
      icon: Icons.shield_rounded,
      details:
          'You can review your records in the app, update profile details '
          'where editing is available and copy your transaction backup. '
          'Signing out changes your login state but does not remove locally '
          'saved financial records. A complete account-deletion or backup '
          'restore flow is not provided by this privacy screen.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = _PrivacyPalette.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      appBar: _PrivacyHeader(palette: palette),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _HeroCard(palette: palette),
            const SizedBox(height: 12),
            _SectionListCard(
              sections: _sections,
              palette: palette,
              onSelect: (index) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _PrivacyDetailsScreen(
                      sections: _sections,
                      initialSection: index,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Current on-device data information · Not a published legal privacy policy',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.muted, fontSize: 10.5, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyPalette {
  const _PrivacyPalette({
    required this.dark,
    required this.accent,
    required this.onAccent,
    required this.background,
    required this.card,
    required this.text,
    required this.muted,
    required this.border,
    required this.iconBackground,
    required this.heroBackground,
  });

  final bool dark;
  final Color accent;
  final Color onAccent;
  final Color background;
  final Color card;
  final Color text;
  final Color muted;
  final Color border;
  final Color iconBackground;
  final Color heroBackground;

  factory _PrivacyPalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    return _PrivacyPalette(
      dark: dark,
      accent: accent,
      onAccent: theme.colorScheme.onPrimary,
      background: dark ? const Color(0xFF10151F) : const Color(0xFFF8F9FF),
      card: dark ? const Color(0xFF1A2030) : Colors.white,
      text: dark ? const Color(0xFFF6F7FF) : const Color(0xFF151B30),
      muted: dark ? const Color(0xFFADB7C8) : const Color(0xFF727B90),
      border: dark ? const Color(0xFF2D3548) : const Color(0xFFEBEDFA),
      iconBackground: accent.withValues(alpha: dark ? 0.22 : 0.10),
      heroBackground: accent.withValues(alpha: dark ? 0.15 : 0.07),
    );
  }
}

class _PrivacyHeader extends StatelessWidget implements PreferredSizeWidget {
  const _PrivacyHeader({required this.palette, this.subtitle = 'Your privacy is important to us'});

  final _PrivacyPalette palette;
  final String subtitle;

  @override
  Size get preferredSize => const Size.fromHeight(65);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: palette.background,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      titleSpacing: 0,
      leadingWidth: 55,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () => Navigator.of(context).maybePop(),
        icon: Icon(Icons.arrow_back_rounded, color: palette.text, size: 23),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Privacy Policy',
              style: TextStyle(color: palette.text, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(color: palette.muted, fontSize: 11.5)),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.palette});
  final _PrivacyPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 19, 20, 19),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.dark
              ? [palette.accent.withValues(alpha: 0.24), palette.card, palette.card]
              : [palette.accent.withValues(alpha: 0.10), const Color(0xFFF9F8FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.accent.withValues(alpha: palette.dark ? .18 : .08)),
      ),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.accent.withValues(alpha: .09),
              boxShadow: [BoxShadow(
                color: palette.accent.withValues(alpha: .20),
                blurRadius: 26,
                spreadRadius: 1,
              )],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.shield_rounded, size: 78, color: palette.accent),
                Container(
                  width: 31,
                  height: 31,
                  decoration: BoxDecoration(
                    color: palette.onAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_rounded, size: 23, color: palette.accent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text('Your Data, Your Control',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.text, fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('See how DHANVIQ handles the information\nyou record in this version of the app.',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.muted, fontSize: 12.5, height: 1.4)),
        ],
      ),
    );
  }
}

class _PrivacySection {
  const _PrivacySection({
    required this.title,
    required this.preview,
    required this.icon,
    required this.details,
  });
  final String title;
  final String preview;
  final IconData icon;
  final String details;
}

class _SectionListCard extends StatelessWidget {
  const _SectionListCard({
    required this.sections,
    required this.palette,
    required this.onSelect,
  });

  final List<_PrivacySection> sections;
  final _PrivacyPalette palette;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          for (var index = 0; index < sections.length; index++) ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelect(index),
                borderRadius: BorderRadius.circular(13),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                  child: Row(
                    children: [
                      _SectionIcon(icon: sections[index].icon, palette: palette),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${index + 1}. ${sections[index].title}',
                                style: TextStyle(color: palette.text, fontSize: 12.5,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(sections[index].preview,
                                style: TextStyle(color: palette.muted, fontSize: 11,
                                    height: 1.35)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(Icons.chevron_right_rounded, color: palette.muted, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            if (index != sections.length - 1)
              Divider(height: 1, color: palette.border, indent: 51, endIndent: 5),
          ],
        ],
      ),
    );
  }
}

class _SectionIcon extends StatelessWidget {
  const _SectionIcon({required this.icon, required this.palette});
  final IconData icon;
  final _PrivacyPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: palette.iconBackground,
        borderRadius: BorderRadius.circular(11),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: palette.accent, size: 20),
    );
  }
}

class _PrivacyDetailsScreen extends StatefulWidget {
  const _PrivacyDetailsScreen({
    required this.sections,
    required this.initialSection,
  });
  final List<_PrivacySection> sections;
  final int initialSection;

  @override
  State<_PrivacyDetailsScreen> createState() => _PrivacyDetailsScreenState();
}

class _PrivacyDetailsScreenState extends State<_PrivacyDetailsScreen> {
  late final List<GlobalKey> _sectionKeys = List<GlobalKey>.generate(
    widget.sections.length, (_) => GlobalKey(),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.initialSection == 0) return;
      final sectionContext = _sectionKeys[widget.initialSection].currentContext;
      if (sectionContext != null) {
        Scrollable.ensureVisible(
          sectionContext,
          alignment: 0.06,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = _PrivacyPalette.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      appBar: _PrivacyHeader(palette: palette, subtitle: 'How your information is handled'),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Container(
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: palette.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 13),
              child: Column(
                children: [
                  for (var index = 0; index < widget.sections.length; index++) ...[
                    Padding(
                      key: _sectionKeys[index],
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionIcon(icon: widget.sections[index].icon, palette: palette),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${index + 1}. ${widget.sections[index].title}',
                                    style: TextStyle(color: palette.text, fontSize: 13,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 6),
                                Text(widget.sections[index].details,
                                    style: TextStyle(color: palette.muted,
                                        fontSize: 12.5, height: 1.55)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (index != widget.sections.length - 1)
                      Divider(height: 1, color: palette.border),
                  ],
                  Divider(height: 1, color: palette.border),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionIcon(icon: Icons.event_note_rounded, palette: palette),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('6. Changes to This Notice',
                                  style: TextStyle(color: palette.text, fontSize: 13,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 6),
                              Text('This in-app notice describes the current version. '
                                  'It should be reviewed whenever features or data '
                                  'handling change. A separate, accurate legal privacy '
                                  'policy is needed before public distribution.',
                                  style: TextStyle(color: palette.muted, fontSize: 12.5, height: 1.55)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: palette.heroBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Current app build · Informational draft',
                  style: TextStyle(color: palette.muted, fontSize: 11.5)),
            ),
          ],
        ),
      ),
    );
  }
}
