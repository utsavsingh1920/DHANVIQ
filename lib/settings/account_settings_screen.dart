import 'dart:io';

import 'package:flutter/material.dart';

import 'profile_screen.dart';
import 'profile_service.dart';
import 'settings_ui.dart';

class AccountDetailsScreen extends StatefulWidget {
  const AccountDetailsScreen({super.key});

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  final ProfileService _profile = ProfileService.instance;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _profile.addListener(_refresh);
    _load();
  }

  Future<void> _load() async {
    try {
      await _profile.load();
    } catch (error) {
      debugPrint('Account profile load failed: $error');
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _profile.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _editProfile() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const ProfileScreen(),
      ),
    );

    // Re-read once after returning. This also handles photo updates.
    try {
      await _profile.reload();
    } catch (error) {
      debugPrint('Account profile refresh failed: $error');
    }

    if (mounted) setState(() {});
  }

  File? get _photoFile {
    final path = _profile.photoPath;

    if (path == null || path.trim().isEmpty) return null;

    final file = File(path);
    return file.existsSync() ? file : null;
  }

  String _valueOrFallback(String value, String fallback) {
    final clean = value.trim();
    return clean.isEmpty ? fallback : clean;
  }

  @override
  Widget build(BuildContext context) {
    final accent = UI.accent(context);
    final dark = UI.dark(context);

    return Scaffold(
      backgroundColor: UI.bg(context),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: UI.bg(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 76,
        titleSpacing: 16,
        title: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icon(
                Icons.arrow_back_rounded,
                color: UI.ink(context),
                size: 26,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Settings',
                    style: TextStyle(
                      color: UI.ink(context),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.45,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Your profile and personal information',
                    style: TextStyle(
                      color: UI.sub(context),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: accent),
            )
          : SafeArea(
              top: false,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                children: [
                  _profileCard(context, accent, dark),
                  const SizedBox(height: 18),
                  _sectionTitle(
                    context,
                    'Personal Information',
                    'Edit any detail from the single Profile screen.',
                  ),
                  const SizedBox(height: 9),
                  SCard(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        _infoRow(
                          context,
                          icon: Icons.person_outline_rounded,
                          label: 'Full Name',
                          value: _valueOrFallback(
                            _profile.name,
                            'Add your full name',
                          ),
                        ),
                        _divider(context),
                        _infoRow(
                          context,
                          icon: Icons.mail_outline_rounded,
                          label: 'Email Address',
                          value: _valueOrFallback(
                            _profile.email,
                            'Add your email address',
                          ),
                        ),
                        _divider(context),
                        _infoRow(
                          context,
                          icon: Icons.phone_outlined,
                          label: 'Mobile Number',
                          value: _valueOrFallback(
                            _profile.phone,
                            'Add mobile number',
                          ),
                        ),
                        _divider(context),
                        _infoRow(
                          context,
                          icon: Icons.calendar_month_outlined,
                          label: 'Date of Birth',
                          value: _valueOrFallback(
                            _profile.dob,
                            'Add date of birth',
                          ),
                        ),
                        _divider(context),
                        _infoRow(
                          context,
                          icon: Icons.person_pin_outlined,
                          label: 'Gender',
                          value: _valueOrFallback(
                            _profile.gender,
                            'Not set',
                          ),
                        ),
                        _divider(context),
                        _infoRow(
                          context,
                          icon: Icons.description_outlined,
                          label: 'About',
                          value: _valueOrFallback(
                            _profile.about,
                            'Add something about yourself',
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: accent.withValues(
                        alpha: dark ? .12 : .06,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: accent.withValues(
                          alpha: dark ? .24 : .14,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.sync_rounded,
                          color: accent,
                          size: 19,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Account Settings and Profile now use the same saved data. '
                            'Change your name, email, phone, DOB, gender, about or photo '
                            'from Profile and it will update here automatically.',
                            style: TextStyle(
                              color: UI.sub(context),
                              fontSize: 10.8,
                              height: 1.45,
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

  Widget _profileCard(
    BuildContext context,
    Color accent,
    bool dark,
  ) {
    final photo = _photoFile;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accent.withValues(alpha: dark ? .10 : .05),
          UI.card(context),
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withValues(alpha: dark ? .28 : .18),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 76,
                height: 76,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accent,
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  backgroundColor: accent.withValues(alpha: .12),
                  foregroundImage:
                      photo == null ? null : FileImage(photo),
                  child: photo == null
                      ? Icon(
                          Icons.person_rounded,
                          color: accent,
                          size: 39,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _valueOrFallback(_profile.name, 'Your Name'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: UI.ink(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _valueOrFallback(
                        _profile.email,
                        'Add your email address',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: UI.sub(context),
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10C69E)
                            .withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'On-device profile',
                        style: TextStyle(
                          color: Color(0xFF10C69E),
                          fontSize: 9.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              onPressed: _editProfile,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: UI.onAccent(context),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: const Icon(
                Icons.edit_outlined,
                size: 18,
              ),
              label: const Text(
                'Edit Profile',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: UI.ink(context),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              color: UI.sub(context),
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 50,
      color: UI.border(context),
    );
  }

  Widget _infoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    int maxLines = 2,
  }) {
    final accent = UI.accent(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(
                alpha: UI.dark(context) ? .14 : .08,
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: accent,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: UI.sub(context),
                    fontSize: 10.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: UI.ink(context),
                    fontSize: 12.8,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
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

