// Triển khai SettingsRepository sử dụng SharedPreferences.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../domain/entities/body_profile.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<UserSettings> getUserSettings() async {
    final raw = _prefs.getString(StorageKeys.userSettings);
    if (raw == null || raw.isEmpty) {
      return const UserSettings();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return UserSettings.fromMap(decoded);
      }
    } catch (_) {
      // Fallback safely to defaults if stored payload is malformed.
    }
    return const UserSettings();
  }

  @override
  Future<void> saveUserSettings(UserSettings settings) async {
    await _prefs.setString(
      StorageKeys.userSettings,
      jsonEncode(settings.toMap()),
    );
  }

  @override
  Future<BodyProfile> getBodyProfile() async {
    final raw = _prefs.getString(StorageKeys.bodyProfile);
    if (raw == null || raw.isEmpty) {
      return const BodyProfile();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return BodyProfile.fromMap(decoded);
      }
    } catch (_) {
      // Fallback safely to defaults if stored payload is malformed.
    }
    return const BodyProfile();
  }

  @override
  Future<void> saveBodyProfile(BodyProfile profile) async {
    await _prefs.setString(
      StorageKeys.bodyProfile,
      jsonEncode(profile.toMap()),
    );
  }

  @override
  Future<bool> hasCompletedOnboarding() async {
    return _prefs.getBool(StorageKeys.onboardingCompleted) ?? false;
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs.setBool(StorageKeys.onboardingCompleted, completed);
  }
}
