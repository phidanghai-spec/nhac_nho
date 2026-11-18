// Controller quản lý trạng thái danh sách nhắc nhở và điều phối rescheduleAll.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/body_profile.dart';
import '../domain/entities/completion_log.dart';
import '../domain/entities/preset_profile.dart';
import '../domain/entities/reminder.dart';
import '../domain/entities/user_settings.dart';
import '../domain/logic/adaptive_food_catalog.dart';
import '../domain/logic/habit_stats_calculator.dart';
import '../domain/logic/universal_day_scheduler.dart';
import '../domain/logic/work_meal_guide.dart';
import 'providers.dart';

class ReminderState {
  const ReminderState({
    required this.allReminders,
    required this.todayReminders,
    required this.todayLogs,
    required this.currentStreak,
    required this.routineRates7Days,
    required this.taskRates7Days,
    required this.hasCompletedOnboarding,
  });

  final List<Reminder> allReminders;
  final List<Reminder> todayReminders;
  final Map<int, CompletionStatus> todayLogs;
  final int currentStreak;
  final Map<String, double> routineRates7Days;
  final Map<String, double> taskRates7Days;
  final bool hasCompletedOnboarding;

  List<Reminder> get todayTasks =>
      todayReminders.where((r) => !r.isRoutine).toList();

  List<Reminder> get todayRoutines =>
      todayReminders.where((r) => r.isRoutine).toList();

  int get todayTotalEnabled =>
      todayReminders.where((r) => r.enabled).length;

  int get todayDoneCount {
    var count = 0;
    for (final r in todayReminders) {
      if (!r.enabled || r.id == null) continue;
      if (todayLogs[r.id] == CompletionStatus.done) {
        count++;
      }
    }
    return count;
  }

  double get todayProgress {
    final total = todayTotalEnabled;
    if (total == 0) return 0.0;
    return todayDoneCount / total;
  }
}

class ReminderController extends AsyncNotifier<ReminderState> {
  DateTime Function() get _now => DateTime.now;

  @override
  Future<ReminderState> build() async {
    return _loadState();
  }

  Future<ReminderState> _loadState() async {
    final reminderRepo = ref.read(reminderRepositoryProvider);
    final settingsRepo = ref.read(settingsRepositoryProvider);

    final now = _now();
    final todayKey = HabitStatsCalculator.formatDateKey(now);
    final startKey = HabitStatsCalculator.formatDateKey(
      now.subtract(const Duration(days: 365)),
    );

    final all = await reminderRepo.getAllReminders();
    final todayList = all.where((r) => r.isScheduledForDate(now)).toList()
      ..sort(_sortReminders);

    final todayLogList = await reminderRepo.getCompletionLogsByDate(todayKey);
    final todayLogs = <int, CompletionStatus>{
      for (final log in todayLogList) log.reminderId: log.status,
    };

    final rangeLogs =
        await reminderRepo.getCompletionLogsInRange(startKey, todayKey);
    final streak = HabitStatsCalculator.calculateCurrentStreak(
      reminders: all,
      logs: rangeLogs,
      today: now,
    );
    final routineRates = HabitStatsCalculator.calculateLast7DaysRates(
      reminders: all,
      logs: rangeLogs,
      today: now,
      isRoutine: true,
    );
    final taskRates = HabitStatsCalculator.calculateLast7DaysRates(
      reminders: all,
      logs: rangeLogs,
      today: now,
      isRoutine: false,
    );
    final onboarded = await settingsRepo.hasCompletedOnboarding();

    return ReminderState(
      allReminders: all,
      todayReminders: todayList,
      todayLogs: todayLogs,
      currentStreak: streak,
      routineRates7Days: routineRates,
      taskRates7Days: taskRates,
      hasCompletedOnboarding: onboarded,
    );
  }

  static int _sortReminders(Reminder a, Reminder b) {
    final hourCmp = a.hour.compareTo(b.hour);
    if (hourCmp != 0) return hourCmp;
    final minCmp = a.minute.compareTo(b.minute);
    if (minCmp != 0) return minCmp;
    final prioCmp = a.priority.compareTo(b.priority);
    if (prioCmp != 0) return prioCmp;
    return (a.id ?? 0).compareTo(b.id ?? 0);
  }

  Future<void> _requestPermissionSafely() async {
    try {
      await ref.read(notificationSchedulerProvider).requestPermissions();
    } catch (_) {
      // Không crash khi người dùng từ chối hoặc nền tảng test không hỗ trợ.
    }
  }

  Future<void> _refreshAndReschedule() async {
    final reminderRepo = ref.read(reminderRepositoryProvider);
    final scheduler = ref.read(notificationSchedulerProvider);
    final all = await reminderRepo.getAllReminders();
    try {
      await scheduler.rescheduleAll(all);
    } catch (_) {
      // Bỏ qua lỗi plugin trên môi trường không hỗ trợ thông báo.
    }
    state = AsyncData(await _loadState());
  }

  Future<void> addReminder(Reminder reminder) async {
    final currentCount = state.value?.allReminders.length ?? 0;
    if (currentCount == 0) {
      await _requestPermissionSafely();
    }
    final reminderRepo = ref.read(reminderRepositoryProvider);
    final settingsRepo = ref.read(settingsRepositoryProvider);
    await reminderRepo.insertReminder(reminder);
    await settingsRepo.setOnboardingCompleted(true);
    await _refreshAndReschedule();
  }

  Future<void> updateReminder(Reminder reminder) async {
    final reminderRepo = ref.read(reminderRepositoryProvider);
    await reminderRepo.updateReminder(reminder);
    await _refreshAndReschedule();
  }

  Future<void> toggleEnabled(Reminder reminder) async {
    await updateReminder(reminder.copyWith(enabled: !reminder.enabled));
  }

  Future<void> deleteReminder(int id) async {
    final reminderRepo = ref.read(reminderRepositoryProvider);
    final scheduler = ref.read(notificationSchedulerProvider);
    try {
      await scheduler.cancelReminder(id);
    } catch (_) {}
    await reminderRepo.deleteReminder(id);
    await _refreshAndReschedule();
  }

  Future<void> markStatus(int reminderId, CompletionStatus status) async {
    await markStatusForDate(reminderId, status, _now());
  }

  Future<void> markStatusForDate(
    int reminderId,
    CompletionStatus status,
    DateTime date,
  ) async {
    final reminderRepo = ref.read(reminderRepositoryProvider);
    final now = _now();
    final dateKey = HabitStatsCalculator.formatDateKey(date);
    final todayKey = HabitStatsCalculator.formatDateKey(now);

    CompletionStatus? currentStatus;
    if (dateKey == todayKey) {
      currentStatus = state.value?.todayLogs[reminderId];
    } else {
      final logs = await reminderRepo.getCompletionLogsByDate(dateKey);
      for (final log in logs) {
        if (log.reminderId == reminderId) {
          currentStatus = log.status;
          break;
        }
      }
    }

    if (currentStatus == status) {
      await reminderRepo.deleteCompletionLogForDate(reminderId, dateKey);
    } else {
      await reminderRepo.upsertCompletionLog(
        CompletionLog(
          reminderId: reminderId,
          date: dateKey,
          status: status,
          completedAt: now.toIso8601String(),
        ),
      );
    }
    state = AsyncData(await _loadState());
  }

  Future<void> applyPreset(PresetId presetId) async {
    await _requestPermissionSafely();
    final preset = WorkMealGuide.getPreset(
      presetId,
      createdAt: _now().toIso8601String(),
    );
    final reminderRepo = ref.read(reminderRepositoryProvider);
    final settingsRepo = ref.read(settingsRepositoryProvider);

    await settingsRepo.saveUserSettings(preset.defaultSettings);
    await settingsRepo.setOnboardingCompleted(true);
    await reminderRepo.replaceAllReminders(preset.reminders);
    ref.invalidate(userSettingsProvider);
    await _refreshAndReschedule();
  }

  Future<void> applyNutritionAndSleepPlan({
    required UserSettings settings,
    required BodyProfile profile,
  }) async {
    await _requestPermissionSafely();
    final reminderRepo = ref.read(reminderRepositoryProvider);
    final settingsRepo = ref.read(settingsRepositoryProvider);

    await settingsRepo.saveUserSettings(settings);
    await settingsRepo.saveBodyProfile(profile);
    await settingsRepo.setOnboardingCompleted(true);

    final personalizedRoutines = WorkMealGuide.buildPersonalizedRoutineReminders(
      settings: settings,
      profile: profile,
      createdAt: _now().toIso8601String(),
    );

    await reminderRepo.replaceRoutineReminders(personalizedRoutines);
    ref.invalidate(userSettingsProvider);
    ref.invalidate(bodyProfileProvider);
    await _refreshAndReschedule();
  }

  Future<void> applyUniversalDayPlan({
    required ScheduledDayPlan plan,
    required UserSettings settings,
    required BodyProfile profile,
    bool replaceExistingTasks = false,
  }) async {
    await _requestPermissionSafely();
    final reminderRepo = ref.read(reminderRepositoryProvider);
    final settingsRepo = ref.read(settingsRepositoryProvider);

    await settingsRepo.saveUserSettings(settings);
    await settingsRepo.saveBodyProfile(profile);
    await settingsRepo.setOnboardingCompleted(true);

    final routineReminders = plan.reminders.where((r) => r.isRoutine).toList();
    final taskReminders = plan.reminders.where((r) => !r.isRoutine).toList();

    await reminderRepo.replaceRoutineReminders(routineReminders);
    if (replaceExistingTasks) {
      final existing = await reminderRepo.getAllReminders();
      for (final r in existing) {
        if (!r.isRoutine && r.id != null) {
          await reminderRepo.deleteReminder(r.id!);
        }
      }
    }
    for (final taskReminder in taskReminders) {
      await reminderRepo.insertReminder(taskReminder);
    }

    ref.invalidate(userSettingsProvider);
    ref.invalidate(bodyProfileProvider);
    await _refreshAndReschedule();
  }

  Future<void> swapMealReminderVariant({
    required Reminder reminder,
    required BodyProfile profile,
    required int nextVariantIndex,
  }) async {
    final slot = AdaptiveFoodCatalog.inferSlotFromTitle(reminder.title);
    final suggestion = AdaptiveFoodCatalog.swapMealOption(
      slot: slot,
      profile: profile,
      focusMode: profile.dailyFocusMode,
      variantIndex: nextVariantIndex,
    );
    final newNote = AdaptiveFoodCatalog.formatNote(suggestion);
    await updateReminder(reminder.copyWith(note: newNote));
  }

  Future<void> rescheduleAll() async {
    final reminderRepo = ref.read(reminderRepositoryProvider);
    final scheduler = ref.read(notificationSchedulerProvider);
    final all = await reminderRepo.getAllReminders();
    try {
      await scheduler.rescheduleAll(all);
    } catch (_) {}
    state = AsyncData(await _loadState());
  }
}
