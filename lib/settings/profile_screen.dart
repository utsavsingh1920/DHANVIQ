import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:image_cropper/image_cropper.dart';

import 'package:image_picker/image_picker.dart';

import 'package:path_provider/path_provider.dart';

import 'profile_service.dart';

/// Shared profile editor for Home and Settings navigation.

class DhanviqProfileScreen extends StatefulWidget {
  const DhanviqProfileScreen({super.key});

  @override
  State<DhanviqProfileScreen> createState() => _DhanviqProfileScreenState();
}

/// Compatibility for existing Home, Account Settings and Settings routes.

class ProfileScreen extends DhanviqProfileScreen {
  const ProfileScreen({super.key});
}

class _DhanviqProfileScreenState extends State<DhanviqProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();

  final _email = TextEditingController();

  final _phone = TextEditingController();

  final _dob = TextEditingController();

  final _about = TextEditingController();

  String? _gender;

  String? _photoPath;

  bool _loading = true;

  bool _saving = false;

  bool _pickingPhoto = false;

  DateTime? _selectedDob;

  bool get _dark => Theme.of(context).brightness == Brightness.dark;

  Color get _accent => Theme.of(context).colorScheme.primary;

  Color get _onAccent =>
      ThemeData.estimateBrightnessForColor(_accent) == Brightness.dark
      ? Colors.white
      : const Color(0xFF101936);

  Color get _bg => _dark ? const Color(0xFF0F1424) : const Color(0xFFF9FAFF);

  Color get _surface => _dark ? const Color(0xFF1A2338) : Colors.white;

  Color get _text => _dark ? const Color(0xFFF6F7FF) : const Color(0xFF111A37);

  Color get _muted => _dark ? const Color(0xFFADB8CF) : const Color(0xFF66718C);

  Color get _border =>
      _dark ? const Color(0xFF35405A) : const Color(0xFFE2E6F3);

  Color get _iconBg => _accent.withValues(alpha: _dark ? .16 : .09);

  @override
  void initState() {
    super.initState();

    _load();
  }

  @override
  void dispose() {
    _name.dispose();

    _email.dispose();

    _phone.dispose();

    _dob.dispose();

    _about.dispose();

    super.dispose();
  }

  DateTime? _parseDate(String input) {
    final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(input);

    if (match == null) {
      return null;
    }

    final day = int.parse(match.group(1)!);

    final month = int.parse(match.group(2)!);

    final year = int.parse(match.group(3)!);

    final date = DateTime(year, month, day);

    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }

    if (date.isAfter(DateTime.now()) || year < 1900) {
      return null;
    }

    return date;
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Future<void> _load() async {
    try {
      await ProfileService.instance.load();

      final service = ProfileService.instance;

      if (!mounted) {
        return;
      }

      _name.text = service.name;

      _email.text = service.email;

      _phone.text = service.phone;

      final dob = service.dob;

      _selectedDob = _parseDate(dob);

      _dob.text = _selectedDob == null ? '' : _formatDate(_selectedDob!);

      _gender =
          const [
            'Male',

            'Female',

            'Other',

            'Prefer not to say',
          ].contains(service.gender)
          ? service.gender
          : null;

      _about.text = service.about;

      final photo = service.photoPath;

      _photoPath =
          photo != null && photo.isNotEmpty && await File(photo).exists()
          ? photo
          : null;
    } catch (_) {
      _message('Profile load nahi ho paya. Dobara try karein.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _message(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _chooseDate() async {
    FocusScope.of(context).unfocus();

    final picked = await showDatePicker(
      context: context,

      initialDate: _selectedDob ?? DateTime(2000, 1, 1),

      firstDate: DateTime(1900),

      lastDate: DateTime.now(),

      helpText: 'Select date of birth',
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDob = picked;

      _dob.text = _formatDate(picked);
    });
  }

  Future<void> _choosePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,

      showDragHandle: true,

      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),

                title: const Text('Choose from gallery'),

                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),

              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),

                title: const Text('Take a photo'),

                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted || _pickingPhoto) {
      return;
    }

    setState(() => _pickingPhoto = true);

    try {
      final picked = await ImagePicker().pickImage(
        source: source,

        imageQuality: 95,

        maxWidth: 2400,

        maxHeight: 2400,
      );

      if (picked == null || !mounted) {
        return;
      }

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,

        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),

        compressFormat: ImageCompressFormat.jpg,

        compressQuality: 90,

        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop profile photo',

            toolbarColor: const Color(0xFF171D30),

            toolbarWidgetColor: Colors.white,

            activeControlsWidgetColor: _accent,

            lockAspectRatio: true,

            hideBottomControls: false,
          ),

          IOSUiSettings(
            title: 'Crop profile photo',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (cropped == null || !mounted) {
        return;
      }

      final support = await getApplicationSupportDirectory();

      final folder = Directory('${support.path}/dhanviq_profile');

      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      final newPath =
          '${folder.path}/avatar_${DateTime.now().microsecondsSinceEpoch}.jpg';

      await File(cropped.path).copy(newPath);

      await ProfileService.instance.setPhotoPath(newPath);

      if (!mounted) {
        return;
      }

      final previous = _photoPath;

      setState(() => _photoPath = newPath);

      if (previous != null && previous != newPath) {
        try {
          final oldFile = File(previous);

          if (await oldFile.exists()) {
            await oldFile.delete();
          }
        } catch (_) {
          // New image is already stored; failing to clean old cache is harmless.
        }
      }

      _message('Profile photo updated');
    } on PlatformException catch (error) {
      _message('Photo permission / crop error: ${error.message ?? error.code}');
    } catch (_) {
      _message('Photo save nahi ho payi. Dobara try karein.');
    } finally {
      if (mounted) {
        setState(() => _pickingPhoto = false);
      }
    }
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => _saving = true);

    try {
      await ProfileService.instance.save(
        newName: _name.text.trim(),

        newEmail: _email.text.trim(),

        newPhone: _phone.text.trim(),

        newDob: _selectedDob == null ? '' : _formatDate(_selectedDob!),

        newGender: _gender ?? '',

        newAbout: _about.text.trim(),
      );

      _message('Profile saved successfully');

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      _message('Profile save nahi ho paya. Dobara try karein.');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  // Compact rows keep the Save button visible on a typical phone. Smaller

  // screens and the open keyboard can still scroll without hiding fields.

  Widget _field({
    required String label,

    required TextEditingController controller,

    required IconData icon,

    required String? Function(String?) validator,

    TextInputType? keyboard,

    List<TextInputFormatter>? formatters,

    int maxLines = 1,

    bool readOnly = false,

    VoidCallback? onTap,

    String? hint,
  }) {
    final multiline = maxLines > 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 7),

      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

      decoration: BoxDecoration(
        color: _surface,

        borderRadius: BorderRadius.circular(13),

        border: Border.all(color: _border),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,

        children: [
          Container(
            width: 35,

            height: 35,

            alignment: Alignment.center,

            decoration: BoxDecoration(
              color: _iconBg,

              borderRadius: BorderRadius.circular(10),
            ),

            child: Icon(icon, color: _accent, size: 19),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              mainAxisSize: MainAxisSize.min,

              children: [
                Text(
                  label,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(color: _muted, fontSize: 10.5),
                ),

                const SizedBox(height: 2),

                TextFormField(
                  controller: controller,

                  readOnly: readOnly,

                  onTap: onTap,

                  keyboardType: keyboard,

                  inputFormatters: formatters,

                  maxLines: maxLines,

                  minLines: multiline ? 2 : null,

                  style: TextStyle(
                    color: _text,

                    fontSize: 13.5,

                    fontWeight: FontWeight.w600,
                  ),

                  validator: validator,

                  decoration: InputDecoration(
                    isDense: true,

                    hintText: hint,

                    hintStyle: TextStyle(color: _muted, fontSize: 12),

                    suffixIcon: readOnly
                        ? Icon(
                            Icons.calendar_month_outlined,

                            color: _muted,
                            size: 18,
                          )
                        : (!multiline
                              ? Icon(
                                  Icons.edit_outlined,
                                  color: _muted,
                                  size: 16,
                                )
                              : null),

                    suffixIconConstraints: const BoxConstraints(
                      minHeight: 22,
                      minWidth: 25,
                    ),

                    contentPadding: const EdgeInsets.symmetric(vertical: 4),

                    border: InputBorder.none,

                    errorMaxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _genderField() => Container(
    margin: const EdgeInsets.only(bottom: 7),

    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

    decoration: BoxDecoration(
      color: _surface,

      borderRadius: BorderRadius.circular(13),

      border: Border.all(color: _border),
    ),

    child: Row(
      children: [
        Container(
          width: 35,

          height: 35,

          alignment: Alignment.center,

          decoration: BoxDecoration(
            color: _iconBg,

            borderRadius: BorderRadius.circular(10),
          ),

          child: Icon(Icons.person_pin_outlined, color: _accent, size: 19),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            mainAxisSize: MainAxisSize.min,

            children: [
              Text(
                'Gender (Optional)',

                style: TextStyle(color: _muted, fontSize: 10.5),
              ),

              DropdownButtonFormField<String>(
                key: ValueKey(_gender),

                initialValue: _gender,

                isExpanded: true,

                dropdownColor: _surface,

                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,

                  color: _muted,
                  size: 20,
                ),

                style: TextStyle(
                  color: _text,

                  fontSize: 13.5,

                  fontWeight: FontWeight.w600,
                ),

                decoration: const InputDecoration(
                  isDense: true,

                  contentPadding: EdgeInsets.symmetric(vertical: 2),

                  border: InputBorder.none,
                ),

                hint: Text(
                  'Select gender',

                  style: TextStyle(color: _muted, fontSize: 12),
                ),

                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),

                  DropdownMenuItem(value: 'Female', child: Text('Female')),

                  DropdownMenuItem(value: 'Other', child: Text('Other')),

                  DropdownMenuItem(
                    value: 'Prefer not to say',

                    child: Text('Prefer not to say'),
                  ),
                ],

                onChanged: (value) => setState(() => _gender = value),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _avatar() => Center(
    child: InkWell(
      onTap: _pickingPhoto ? null : _choosePhoto,

      customBorder: const CircleBorder(),

      child: Stack(
        clipBehavior: Clip.none,

        children: [
          Container(
            width: 88,

            height: 88,

            padding: const EdgeInsets.all(3),

            decoration: BoxDecoration(
              shape: BoxShape.circle,

              border: Border.all(
                color: _accent.withValues(alpha: .48),
                width: 1.5,
              ),
            ),

            child: CircleAvatar(
              backgroundColor: _iconBg,

              foregroundImage: _photoPath == null
                  ? null
                  : FileImage(File(_photoPath!)),

              child: _pickingPhoto
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : Icon(Icons.person_rounded, color: _accent, size: 43),
            ),
          ),

          Positioned(
            right: -2,

            bottom: 1,

            child: Container(
              padding: const EdgeInsets.all(6),

              decoration: BoxDecoration(
                color: _accent,

                shape: BoxShape.circle,

                border: Border.all(color: _bg, width: 2.5),
              ),

              child: const Icon(
                Icons.photo_camera_rounded,

                color: Colors.white,
                size: 17,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,

      statusBarIconBrightness: _dark ? Brightness.light : Brightness.dark,

      statusBarBrightness: _dark ? Brightness.dark : Brightness.light,

      systemNavigationBarColor: _bg,

      systemNavigationBarIconBrightness: _dark
          ? Brightness.light
          : Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,

      child: Scaffold(
        backgroundColor: _bg,

        resizeToAvoidBottomInset: true,

        appBar: AppBar(
          toolbarHeight: 48,

          backgroundColor: _bg,

          foregroundColor: _text,

          surfaceTintColor: Colors.transparent,

          centerTitle: true,

          title: const Text(
            'Profile',

            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ),

        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,

                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // The button belongs to the form, not a docked bottom bar.

                      // On taller phones, distribute a little extra breathing room

                      // between the avatar and fields. On small phones / with the

                      // keyboard open, the entire form remains scrollable.

                      final roomy = constraints.maxHeight >= 720;

                      final avatarGap = roomy ? 19.0 : 12.0;

                      final buttonGap = roomy ? 26.0 : 19.0;

                      return SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,

                        padding: const EdgeInsets.fromLTRB(17, 5, 17, 24),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,

                          children: [
                            _avatar(),

                            SizedBox(height: avatarGap),

                            _field(
                              label: 'Full Name',

                              controller: _name,

                              icon: Icons.person_outline_rounded,

                              validator: (value) => (value ?? '').trim().isEmpty
                                  ? 'Enter your full name'
                                  : null,
                            ),

                            _field(
                              label: 'Email Address',

                              controller: _email,

                              icon: Icons.mail_outline_rounded,

                              keyboard: TextInputType.emailAddress,

                              validator: (value) =>
                                  RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                      .hasMatch((value ?? '').trim())
                                  ? null
                                  : 'Enter a valid email',
                            ),

                            _field(
                              label: 'Mobile Number',

                              controller: _phone,

                              icon: Icons.phone_outlined,

                              keyboard: TextInputType.phone,

                              formatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9+ ]'),
                                ),

                                LengthLimitingTextInputFormatter(16),
                              ],

                              validator: (value) {
                                final phone = (value ?? '').replaceAll(
                                  RegExp(r'\D'),
                                  '',
                                );

                                return phone.isEmpty ||
                                        (phone.length >= 10 &&
                                            phone.length <= 15)
                                    ? null
                                    : 'Enter a valid mobile number';
                              },
                            ),

                            _field(
                              label: 'Date of Birth (Optional) • DD/MM/YYYY',

                              controller: _dob,

                              icon: Icons.calendar_month_outlined,

                              readOnly: true,

                              onTap: _chooseDate,

                              hint: 'DD/MM/YYYY',

                              validator: (_) => null,
                            ),

                            _genderField(),

                            _field(
                              label: 'About Me (Optional)',

                              controller: _about,

                              icon: Icons.description_outlined,

                              keyboard: TextInputType.multiline,

                              maxLines: 2,

                              validator: (_) => null,

                              hint: 'Tell us a little about yourself',
                            ),

                            SizedBox(height: buttonGap),

                            SizedBox(
                              height: 51,

                              child: FilledButton.icon(
                                onPressed: _saving || _pickingPhoto
                                    ? null
                                    : _save,

                                style: FilledButton.styleFrom(
                                  backgroundColor: _accent,

                                  foregroundColor: _onAccent,

                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),

                                icon: _saving
                                    ? const SizedBox(
                                        width: 17,

                                        height: 17,

                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,

                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.save_outlined, size: 19),

                                label: Text(
                                  _saving ? 'Saving...' : 'Save Changes',

                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,

                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
      ),
    );
  }
}
