import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// DHANVIQ • Help & Support
// Uses MaterialApp.themeMode and the selected ThemeData.colorScheme.primary.
// No extra packages, backend, email address or remote support API required.

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HColors {
  const _HColors(this.context);

  final BuildContext context;

  bool get dark => Theme.of(context).brightness == Brightness.dark;
  Color get accent => Theme.of(context).colorScheme.primary;
  Color get onAccent => Theme.of(context).colorScheme.onPrimary;
  Color get background =>
      dark ? const Color(0xFF10141E) : const Color(0xFFFAFBFF);
  Color get card => dark ? const Color(0xFF1B2030) : Colors.white;
  Color get text => dark ? const Color(0xFFF5F6FC) : const Color(0xFF111827);
  Color get secondary =>
      dark ? const Color(0xFFA7AFC2) : const Color(0xFF697386);
  Color get border =>
      dark ? const Color(0xFF2D3445) : const Color(0xFFE9ECF5);
  Color get tint => accent.withValues(alpha: dark ? .18 : .09);
  Color get hero => Color.alphaBlend(
        accent.withValues(alpha: dark ? .18 : .075),
        card,
      );
  Color get field => dark ? const Color(0xFF222939) : const Color(0xFFF1F4FF);
}

class _Faq {
  const _Faq(this.question, this.answer);
  final String question;
  final String answer;
}

const List<_Faq> _faqs = [
  _Faq(
    'How to add income or expense?',
    'Open DHANVIQ and tap the + button in the bottom navigation. '
        'Choose Add Income or Add Expense, enter the amount and other details, '
        'then save. Open Transactions to see your recorded entries.',
  ),
  _Faq(
    'How to set a monthly budget?',
    'On Home, tap Set Budget. Choose a category, enter its monthly spending '
        'limit and confirm the budget. Your progress will appear in Budget '
        'Progress and Insights as you record expenses.',
  ),
  _Faq(
    'How to create a goal?',
    'Open Goals from Home or the quick actions, then tap Add Goal or '
        'Create Your First Goal. Enter a target amount and save the goal. '
        'You can track its progress from the Goals screen.',
  ),
  _Faq(
    'Can I backup my data?',
    'Open Settings → Data & Backup. You can keep a local backup and copy '
        'your transaction data as JSON for safekeeping. Check the information '
        'shown on that screen: backup coverage is limited and importing or '
        'restoring a backup is not available in this version.',
  ),
  _Faq(
    'Is my data stored online?',
    'The current finance records and profile preferences used by this app '
        'are stored on your device. DHANVIQ does not currently provide a '
        'cloud account or cloud sync for these records. If you copy or share '
        'a backup, keep that exported information private.',
  ),
  _Faq(
    'How to change currency or region?',
    'Open Settings → Currency & Region and select your preferred options. '
        'These preferences are saved locally. Amounts elsewhere in the app '
        'may still display in their existing format until currency formatting '
        'has been connected to those screens; selecting USD, for example, '
        'does not convert the value of your recorded transactions.',
  ),
  _Faq(
    'How to reset the app?',
    'This version does not include a complete in-app data-reset and '
        'backup-restore flow. Do not clear app storage or uninstall the app '
        'assuming your records can be restored. If you only want to sign '
        'out, use Settings → Logout; signing out does not delete local '
        'financial records.',
  ),
];

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openFaq({String? initiallyExpanded}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FaqScreen(initiallyExpanded: initiallyExpanded),
      ),
    );
  }

  void _openComposer(_ComposerKind kind) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _SupportComposer(kind: kind)),
    );
  }

  void _openGuide() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const _AppGuideScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _HColors(context);
    final results = _query.trim().isEmpty
        ? const <_Faq>[]
        : _faqs.where((faq) {
            final q = _query.trim().toLowerCase();
            return faq.question.toLowerCase().contains(q) ||
                faq.answer.toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      backgroundColor: p.background,
      appBar: _helpBar(context, subtitle: "We're here to help you"),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
              children: [
                _hero(context),
                const SizedBox(height: 13),
                _searchBox(context),
                const SizedBox(height: 14),
                if (_query.trim().isNotEmpty) ...[
                  Text(
                    'Search results',
                    style: TextStyle(
                      color: p.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 9),
                  if (results.isEmpty)
                    _infoPanel(
                      context,
                      icon: Icons.search_off_rounded,
                      title: 'No matching answers',
                      message: 'Try a different search or contact support.',
                    )
                  else
                    _panel(
                      context,
                      child: Column(
                        children: [
                          for (int i = 0; i < results.length; i++) ...[
                            if (i > 0) _line(context),
                            _menuItem(
                              context,
                              icon: Icons.help_outline_rounded,
                              iconColor: p.accent,
                              title: results[i].question,
                              subtitle: 'Tap to read the answer',
                              onTap: () => _openFaq(
                                initiallyExpanded: results[i].question,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => _openFaq(),
                    child: Text(
                      'View all frequently asked questions',
                      style: TextStyle(color: p.accent),
                    ),
                  ),
                ] else
                  _panel(
                    context,
                    child: Column(
                      children: [
                        _menuItem(
                          context,
                          icon: Icons.help_rounded,
                          iconColor: p.accent,
                          title: 'Frequently Asked Questions',
                          subtitle: 'Find answers to common questions',
                          onTap: () => _openFaq(),
                        ),
                        _line(context),
                        _menuItem(
                          context,
                          icon: Icons.chat_bubble_outline_rounded,
                          iconColor: const Color(0xFF10B899),
                          title: 'Contact Support',
                          subtitle: 'Prepare a message for our support team',
                          onTap: () => _openComposer(_ComposerKind.contact),
                        ),
                        _line(context),
                        _menuItem(
                          context,
                          icon: Icons.rate_review_outlined,
                          iconColor: const Color(0xFFFFA51E),
                          title: 'Send Feedback',
                          subtitle: 'Help us improve DHANVIQ',
                          onTap: () => _openComposer(_ComposerKind.feedback),
                        ),
                        _line(context),
                        _menuItem(
                          context,
                          icon: Icons.report_problem_rounded,
                          iconColor: const Color(0xFFEF466B),
                          title: 'Report an Issue',
                          subtitle: 'Facing a problem? Let us know',
                          onTap: () => _openComposer(_ComposerKind.issue),
                        ),
                        _line(context),
                        _menuItem(
                          context,
                          icon: Icons.auto_stories_rounded,
                          iconColor: const Color(0xFF2888EA),
                          title: 'App Guide',
                          subtitle: 'Learn how to use DHANVIQ',
                          onTap: _openGuide,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero(BuildContext context) {
    final p = _HColors(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 20),
      decoration: BoxDecoration(
        color: p.hero,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.accent.withValues(alpha: .07)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 112,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 42,
                  top: 13,
                  child: _halo(p.accent, 75, .07),
                ),
                Positioned(
                  right: 26,
                  top: 6,
                  child: _halo(p.accent, 90, .09),
                ),
                Container(
                  width: 94,
                  height: 94,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        p.accent.withValues(alpha: .18),
                        p.accent.withValues(alpha: .045),
                      ],
                    ),
                  ),
                ),
                Icon(
                  Icons.support_agent_rounded,
                  color: p.accent,
                  size: 87,
                  shadows: [
                    Shadow(
                      color: p.accent.withValues(alpha: .25),
                      blurRadius: 17,
                    ),
                  ],
                ),
                Positioned(
                  right: MediaQuery.sizeOf(context).width < 365 ? 50 : 80,
                  top: 38,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: p.card,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.more_horiz_rounded, size: 17, color: p.accent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'How can we help you?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: p.text,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Find answers, get support or reach out\nto us anytime.',
            textAlign: TextAlign.center,
            style: TextStyle(color: p.secondary, fontSize: 12, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _halo(Color color, double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: alpha),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _searchBox(BuildContext context) {
    final p = _HColors(context);
    return TextField(
      controller: _search,
      onChanged: (value) => setState(() => _query = value),
      textInputAction: TextInputAction.search,
      style: TextStyle(color: p.text, fontSize: 13),
      decoration: InputDecoration(
        filled: true,
        fillColor: p.field,
        hintText: 'Search for help...',
        hintStyle: TextStyle(color: p.secondary, fontSize: 12),
        prefixIcon: Icon(Icons.search_rounded, color: p.secondary, size: 21),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _search.clear();
                  setState(() => _query = '');
                },
                icon: Icon(Icons.close_rounded, color: p.secondary, size: 19),
              ),
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: p.accent.withValues(alpha: .55)),
        ),
      ),
    );
  }
}

class _FaqScreen extends StatefulWidget {
  const _FaqScreen({this.initiallyExpanded});

  final String? initiallyExpanded;

  @override
  State<_FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<_FaqScreen> {
  int? _expanded;

  @override
  void initState() {
    super.initState();
    if (widget.initiallyExpanded != null) {
      final i = _faqs.indexWhere(
        (faq) => faq.question == widget.initiallyExpanded,
      );
      if (i >= 0) _expanded = i;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _HColors(context);
    return Scaffold(
      backgroundColor: p.background,
      appBar: _helpBar(context),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
              children: [
                Text(
                  'Frequently Asked Questions',
                  style: TextStyle(
                    color: p.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                _panel(
                  context,
                  child: Column(
                    children: [
                      for (int i = 0; i < _faqs.length; i++) ...[
                        if (i > 0) _line(context),
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            setState(() => _expanded = _expanded == i ? null : i);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _faqs[i].question,
                                        style: TextStyle(
                                          color: _expanded == i ? p.accent : p.text,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Icon(
                                      _expanded == i
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      color: p.secondary,
                                      size: 19,
                                    ),
                                  ],
                                ),
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 200),
                                  alignment: Alignment.topCenter,
                                  child: _expanded == i
                                      ? Padding(
                                          padding: const EdgeInsets.only(top: 11, right: 14),
                                          child: Text(
                                            _faqs[i].answer,
                                            style: TextStyle(
                                              color: p.secondary,
                                              fontSize: 12.5,
                                              height: 1.5,
                                            ),
                                          ),
                                        )
                                      : const SizedBox(width: double.infinity),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _panel(
                  context,
                  color: p.hero,
                  child: Column(
                    children: [
                      _supportPrompt(context),
                      const SizedBox(height: 13),
                      _accentButton(
                        context,
                        label: 'Contact Support',
                        icon: Icons.add_circle_outline_rounded,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const _SupportComposer(
                              kind: _ComposerKind.contact,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _panel(
                  context,
                  color: p.hero,
                  child: _menuItem(
                    context,
                    icon: Icons.send_rounded,
                    iconColor: p.accent,
                    title: 'Share your feedback',
                    subtitle: 'Help us make DHANVIQ better.',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const _SupportComposer(
                          kind: _ComposerKind.feedback,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _ComposerKind { contact, feedback, issue }

class _SupportComposer extends StatefulWidget {
  const _SupportComposer({required this.kind});

  final _ComposerKind kind;

  @override
  State<_SupportComposer> createState() => _SupportComposerState();
}

class _SupportComposerState extends State<_SupportComposer> {
  final _form = GlobalKey<FormState>();
  final _topic = TextEditingController();
  final _details = TextEditingController();

  @override
  void dispose() {
    _topic.dispose();
    _details.dispose();
    super.dispose();
  }

  String get _title => switch (widget.kind) {
        _ComposerKind.contact => 'Contact Support',
        _ComposerKind.feedback => 'Send Feedback',
        _ComposerKind.issue => 'Report an Issue',
      };

  String get _description => switch (widget.kind) {
        _ComposerKind.contact => 'Describe what you need help with.',
        _ComposerKind.feedback => 'Tell us what you would like to improve.',
        _ComposerKind.issue => 'Describe the problem and how it happened.',
      };

  Future<void> _copyMessage() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final message = 'DHANVIQ • $_title\n'
        'Topic: ${_topic.text.trim()}\n'
        'Details: ${_details.text.trim()}\n'
        'Device / app version (optional): ';
    await Clipboard.setData(ClipboardData(text: message));
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Message copied'),
        content: const Text(
          'Your message was copied to the clipboard. It has NOT been sent '
          'automatically. Paste it into your preferred email or messaging '
          'app to share it with the appropriate support contact.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _HColors(context);
    return Scaffold(
      backgroundColor: p.background,
      appBar: _helpBar(context, title: _title),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
              children: [
                _infoPanel(
                  context,
                  icon: widget.kind == _ComposerKind.issue
                      ? Icons.report_problem_rounded
                      : Icons.chat_bubble_outline_rounded,
                  title: _title,
                  message: _description,
                ),
                const SizedBox(height: 16),
                _panel(
                  context,
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Topic',
                          style: TextStyle(
                            color: p.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _input(
                          context,
                          controller: _topic,
                          hint: widget.kind == _ComposerKind.issue
                              ? 'e.g. Budget screen does not open'
                              : 'Enter a short topic',
                          validator: (v) => (v?.trim().isEmpty ?? true)
                              ? 'Please enter a topic'
                              : null,
                        ),
                        const SizedBox(height: 17),
                        Text(
                          'Details',
                          style: TextStyle(
                            color: p.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _input(
                          context,
                          controller: _details,
                          hint: _description,
                          maxLines: 6,
                          validator: (v) => (v?.trim().length ?? 0) < 10
                              ? 'Please provide at least 10 characters'
                              : null,
                        ),
                        const SizedBox(height: 18),
                        _accentButton(
                          context,
                          label: 'Copy Message',
                          icon: Icons.copy_rounded,
                          onPressed: _copyMessage,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'DHANVIQ has no connected support inbox in this version. '
                          'Copying creates a message for you to share yourself.',
                          style: TextStyle(
                            color: p.secondary,
                            height: 1.4,
                            fontSize: 11.5,
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
      ),
    );
  }
}

class _AppGuideScreen extends StatelessWidget {
  const _AppGuideScreen();

  @override
  Widget build(BuildContext context) {
    final p = _HColors(context);
    const steps = <(IconData, String, String)>[
      (
        Icons.add_circle_outline_rounded,
        '1. Record income and expenses',
        'Tap + on the bottom navigation, choose Income or Expense, fill in the details and save.',
      ),
      (
        Icons.receipt_long_outlined,
        '2. Review your transactions',
        'Open Transactions to search, filter or edit your recorded entries.',
      ),
      (
        Icons.pie_chart_outline_rounded,
        '3. Plan your spending',
        'Open Set Budget from Home and choose a category with a monthly limit.',
      ),
      (
        Icons.flag_outlined,
        '4. Track goals and insights',
        'Create a savings goal, then use Goals and Insights to review your progress.',
      ),
    ];
    return Scaffold(
      backgroundColor: p.background,
      appBar: _helpBar(context, title: 'App Guide'),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 17, 20, 30),
              children: [
                _infoPanel(
                  context,
                  icon: Icons.auto_stories_rounded,
                  title: 'Getting started with DHANVIQ',
                  message: 'Track your money, set budgets and review your progress.',
                ),
                const SizedBox(height: 16),
                _panel(
                  context,
                  child: Column(
                    children: [
                      for (int i = 0; i < steps.length; i++) ...[
                        if (i > 0) _line(context),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _iconBox(context, steps[i].$1, p.accent),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      steps[i].$2,
                                      style: TextStyle(
                                        color: p.text,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      steps[i].$3,
                                      style: TextStyle(
                                        color: p.secondary,
                                        height: 1.5,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                _accentButton(
                  context,
                  label: 'View FAQs',
                  icon: Icons.help_outline_rounded,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const _FaqScreen()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Shared visual components. Keeping them here makes this a single-file drop-in.
PreferredSizeWidget _helpBar(
  BuildContext context, {
  String title = 'Help & Support',
  String? subtitle,
}) {
  final p = _HColors(context);
  return AppBar(
    toolbarHeight: subtitle == null ? 58 : 66,
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: p.background,
    foregroundColor: p.text,
    surfaceTintColor: Colors.transparent,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_rounded, size: 22),
      onPressed: () => Navigator.of(context).maybePop(),
    ),
    titleSpacing: 0,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            color: p.text,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(color: p.secondary, fontSize: 11),
          ),
        ],
      ],
    ),
  );
}

Widget _panel(BuildContext context, {required Widget child, Color? color}) {
  final p = _HColors(context);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
    decoration: BoxDecoration(
      color: color ?? p.card,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: p.border),
    ),
    child: child,
  );
}

Widget _line(BuildContext context) => Divider(
      height: 1,
      indent: 50,
      thickness: .65,
      color: _HColors(context).border,
    );

Widget _iconBox(BuildContext context, IconData icon, Color color) {
  final p = _HColors(context);
  return Container(
    width: 37,
    height: 37,
    decoration: BoxDecoration(
      color: color == p.accent ? p.tint : color.withValues(alpha: p.dark ? .19 : .11),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, size: 20, color: color),
  );
}

Widget _menuItem(
  BuildContext context, {
  required IconData icon,
  required Color iconColor,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  final p = _HColors(context);
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            _iconBox(context, icon, iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: p.text,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: p.secondary,
                      fontSize: 11,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Icon(Icons.chevron_right_rounded, size: 18, color: p.secondary),
          ],
        ),
      ),
    ),
  );
}

Widget _supportPrompt(BuildContext context) {
  final p = _HColors(context);
  return Row(
    children: [
      _iconBox(context, Icons.chat_bubble_outline_rounded, p.accent),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Still need help?',
              style: TextStyle(
                color: p.text,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Prepare a message for support.',
              style: TextStyle(color: p.secondary, fontSize: 11.5),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _accentButton(
  BuildContext context, {
  required String label,
  required IconData icon,
  required VoidCallback onPressed,
}) {
  final p = _HColors(context);
  return SizedBox(
    width: double.infinity,
    height: 46,
    child: FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    ),
  );
}

Widget _infoPanel(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
}) {
  final p = _HColors(context);
  return _panel(
    context,
    color: p.hero,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          _iconBox(context, icon, p.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: p.text, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(color: p.secondary, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _input(
  BuildContext context, {
  required TextEditingController controller,
  required String hint,
  String? Function(String?)? validator,
  int maxLines = 1,
}) {
  final p = _HColors(context);
  return TextFormField(
    controller: controller,
    validator: validator,
    maxLines: maxLines,
    keyboardType: maxLines > 1 ? TextInputType.multiline : TextInputType.text,
    style: TextStyle(color: p.text, fontSize: 13),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: p.secondary, fontSize: 12),
      filled: true,
      fillColor: p.field,
      contentPadding: const EdgeInsets.all(13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.accent, width: 1.4),
      ),
    ),
  );
}
