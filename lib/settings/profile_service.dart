import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService extends ChangeNotifier {
  ProfileService._();

  static final ProfileService instance = ProfileService._();

  static const String _nameKey = 'dhanviq_profile_name';
  static const String _emailKey = 'dhanviq_profile_email';
  static const String _phoneKey = 'dhanviq_profile_phone';
  static const String _dobKey = 'dhanviq_profile_dob';
  static const String _genderKey = 'dhanviq_profile_gender';
  static const String _aboutKey = 'dhanviq_profile_about';
  static const String _photoKey = 'dhanviq_profile_photo_path';

  String name = 'Utsav Singh';
  String email = 'utsavsingh@example.com';
  String phone = '';
  String dob = '';
  String gender = '';
  String about = '';
  String? photoPath;

  Future<void>? _loading;

  Future<void> load() => _loading ??= _read();

  Future<void> reload() async {
    _loading = null;
    await load();
  }

  Future<void> _read() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      name = prefs.getString(_nameKey) ?? name;
      email = prefs.getString(_emailKey) ?? email;
      phone = prefs.getString(_phoneKey) ?? '';
      dob = prefs.getString(_dobKey) ?? '';
      gender = prefs.getString(_genderKey) ?? '';
      about = prefs.getString(_aboutKey) ?? '';
      photoPath = prefs.getString(_photoKey);

      notifyListeners();
    } catch (error) {
      _loading = null;
      rethrow;
    }
  }

  Future<void> save({
    required String newName,
    required String newEmail,
    required String newPhone,
    required String newDob,
    required String newGender,
    required String newAbout,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final results = await Future.wait<bool>([
      prefs.setString(_nameKey, newName),
      prefs.setString(_emailKey, newEmail),
      prefs.setString(_phoneKey, newPhone),
      prefs.setString(_dobKey, newDob),
      prefs.setString(_genderKey, newGender),
      prefs.setString(_aboutKey, newAbout),
    ]);

    if (results.any((saved) => !saved)) {
      throw StateError('Unable to save profile details');
    }

    name = newName;
    email = newEmail;
    phone = newPhone;
    dob = newDob;
    gender = newGender;
    about = newAbout;

    notifyListeners();
  }

  Future<void> setPhotoPath(String? newPath) async {
    final prefs = await SharedPreferences.getInstance();

    bool saved;

    if (newPath == null || newPath.trim().isEmpty) {
      saved = await prefs.remove(_photoKey);
      photoPath = null;
    } else {
      saved = await prefs.setString(_photoKey, newPath.trim());
      photoPath = newPath.trim();
    }

    if (!saved) {
      throw StateError('Unable to save profile photo');
    }

    notifyListeners();
  }
}
