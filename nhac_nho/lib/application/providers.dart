// Định nghĩa các Riverpod providers kết nối các tầng.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/db/app_database.dart';
import '../data/notification_scheduler_impl.dart';
import '../data/reminder_repository_impl.dart';
import '../data/settings_repository_impl.dart';
import '../domain/entities/body_profile.dart';
import '../domain/entities/user_settings.dart';
import '../domain/repositories/reminder_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/services/notification_scheduler.dart';
import 'reminder_controller.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider phải được override trong main.dart');
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() {
    db.close();
  });
  return db;
});

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepositoryImpl(ref.watch(appDatabaseProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(ref.watch(sharedPreferencesProvider));
});

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  return NotificationSchedulerImpl();
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class UserSettingsController extends AsyncNotifier<UserSettings> {
  @override
  Future<UserSettings> build() async {
    return ref.watch(settingsRepositoryProvider).getUserSettings();
  }

  Future<void> save(UserSettings settings) async {
    await ref.read(settingsRepositoryProvider).saveUserSettings(settings);
    state = AsyncData(settings);
  }
}

final userSettingsProvider =
    AsyncNotifierProvider<UserSettingsController, UserSettings>(
  UserSettingsController.new,
);

class BodyProfileController extends AsyncNotifier<BodyProfile> {
  @override
  Future<BodyProfile> build() async {
    return ref.watch(settingsRepositoryProvider).getBodyProfile();
  }

  Future<void> save(BodyProfile profile) async {
    await ref.read(settingsRepositoryProvider).saveBodyProfile(profile);
    state = AsyncData(profile);
  }
}

final bodyProfileProvider =
    AsyncNotifierProvider<BodyProfileController, BodyProfile>(
  BodyProfileController.new,
);

final reminderControllerProvider =
    AsyncNotifierProvider<ReminderController, ReminderState>(
  ReminderController.new,
);
