// Interface SettingsRepository lưu/đọc UserSettings và BodyProfile.

import '../entities/body_profile.dart';
import '../entities/user_settings.dart';

abstract class SettingsRepository {
  Future<UserSettings> getUserSettings();
  Future<void> saveUserSettings(UserSettings settings);

  Future<BodyProfile> getBodyProfile();
  Future<void> saveBodyProfile(BodyProfile profile);

  Future<bool> hasCompletedOnboarding();
  Future<void> setOnboardingCompleted(bool completed);
}
