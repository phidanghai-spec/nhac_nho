// Định nghĩa các Riverpod providers kết nối các tầng.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/db/app_database.dart';
import '../data/notification_scheduler_impl.dart';
import '../data/reminder_repository_impl.dart';
import '../data/settings_repository_impl.dart';
import '../domain/entities/body_profile.dart';
import '../domain/entities/completion_log.dart';
import '../domain/entities/user_settings.dart';
import '../domain/logic/habit_stats_calculator.dart';
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

class SelectedHomeDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void selectDate(DateTime date) {
    state = DateTime(date.year, date.month, date.day);
  }
}

final selectedHomeDateProvider =
    NotifierProvider<SelectedHomeDateNotifier, DateTime>(
  SelectedHomeDateNotifier.new,
);

class WaterIntakeNotifier extends Notifier<int> {
  static String _keyForToday() {
    final dateKey = HabitStatsCalculator.formatDateKey(DateTime.now());
    return 'water_intake_ml_$dateKey';
  }

  @override
  int build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getInt(_keyForToday()) ?? 0;
  }

  Future<void> addWater(int ml) async {
    final next = (state + ml).clamp(0, 6000);
    state = next;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_keyForToday(), next);
  }

  Future<void> reset() async {
    state = 0;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_keyForToday(), 0);
  }
}

final waterIntakeMlProvider = NotifierProvider<WaterIntakeNotifier, int>(
  WaterIntakeNotifier.new,
);

final dateCompletionLogsProvider =
    FutureProvider.family<Map<int, CompletionStatus>, String>((ref, dateKey) async {
  // Theo dõi reminderControllerProvider để tự động làm mới khi markStatus chạy.
  ref.watch(reminderControllerProvider);
  final repo = ref.read(reminderRepositoryProvider);
  final logs = await repo.getCompletionLogsByDate(dateKey);
  return {for (final log in logs) log.reminderId: log.status};
});
