// Unit test cho ReminderController với mocktail.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nhac_nho/application/providers.dart';
import 'package:nhac_nho/domain/entities/body_profile.dart';
import 'package:nhac_nho/domain/entities/completion_log.dart';
import 'package:nhac_nho/domain/entities/preset_profile.dart';
import 'package:nhac_nho/domain/entities/reminder.dart';
import 'package:nhac_nho/domain/entities/user_settings.dart';
import 'package:nhac_nho/domain/entities/user_task_input.dart';
import 'package:nhac_nho/domain/logic/adaptive_food_catalog.dart';
import 'package:nhac_nho/domain/logic/universal_day_scheduler.dart';
import 'package:nhac_nho/domain/repositories/reminder_repository.dart';
import 'package:nhac_nho/domain/repositories/settings_repository.dart';
import 'package:nhac_nho/domain/services/notification_scheduler.dart';

class MockReminderRepository extends Mock implements ReminderRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockNotificationScheduler extends Mock implements NotificationScheduler {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const Reminder(
        title: 'fallback',
        category: ReminderCategory.task,
        isRoutine: false,
        hour: 8,
        minute: 0,
        repeat: RepeatType.daily,
        createdAt: '2026-11-17T00:00:00Z',
      ),
    );
    registerFallbackValue(const UserSettings());
    registerFallbackValue(const BodyProfile());
    registerFallbackValue(
      const CompletionLog(
        reminderId: 1,
        date: '2026-11-17',
        status: CompletionStatus.done,
        completedAt: '2026-11-17T08:00:00Z',
      ),
    );
  });

  late MockReminderRepository reminderRepo;
  late MockSettingsRepository settingsRepo;
  late MockNotificationScheduler scheduler;
  late ProviderContainer container;

  setUp(() {
    reminderRepo = MockReminderRepository();
    settingsRepo = MockSettingsRepository();
    scheduler = MockNotificationScheduler();

    when(() => reminderRepo.getAllReminders()).thenAnswer((_) async => []);
    when(() => reminderRepo.getCompletionLogsByDate(any()))
        .thenAnswer((_) async => []);
    when(() => reminderRepo.getCompletionLogsInRange(any(), any()))
        .thenAnswer((_) async => []);
    when(() => reminderRepo.insertReminder(any())).thenAnswer((_) async => 1);
    when(() => reminderRepo.deleteReminder(any())).thenAnswer((_) async {});
    when(() => reminderRepo.replaceAllReminders(any()))
        .thenAnswer((_) async {});
    when(() => reminderRepo.replaceRoutineReminders(any()))
        .thenAnswer((_) async {});
    when(() => reminderRepo.updateReminder(any())).thenAnswer((_) async {});
    when(() => reminderRepo.upsertCompletionLog(any()))
        .thenAnswer((_) async => 1);

    when(() => settingsRepo.getUserSettings())
        .thenAnswer((_) async => const UserSettings());
    when(() => settingsRepo.saveUserSettings(any())).thenAnswer((_) async {});
    when(() => settingsRepo.getBodyProfile())
        .thenAnswer((_) async => const BodyProfile());
    when(() => settingsRepo.saveBodyProfile(any())).thenAnswer((_) async {});
    when(() => settingsRepo.hasCompletedOnboarding())
        .thenAnswer((_) async => false);
    when(() => settingsRepo.setOnboardingCompleted(any()))
        .thenAnswer((_) async {});

    when(() => scheduler.requestPermissions()).thenAnswer((_) async => true);
    when(() => scheduler.rescheduleAll(any())).thenAnswer((_) async {});
    when(() => scheduler.cancelReminder(any())).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        reminderRepositoryProvider.overrideWithValue(reminderRepo),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        notificationSchedulerProvider.overrideWithValue(scheduler),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('addReminder xin quyền khi là nhắc đầu tiên và gọi rescheduleAll', () async {
    await container.read(reminderControllerProvider.future);
    final controller = container.read(reminderControllerProvider.notifier);

    const r = Reminder(
      title: 'Deep Work',
      category: ReminderCategory.task,
      isRoutine: false,
      hour: 8,
      minute: 30,
      repeat: RepeatType.daily,
      createdAt: '2026-11-17T08:00:00Z',
    );
    await controller.addReminder(r);

    verify(() => scheduler.requestPermissions()).called(1);
    verify(() => reminderRepo.insertReminder(r)).called(1);
    verify(() => settingsRepo.setOnboardingCompleted(true)).called(1);
    verify(() => scheduler.rescheduleAll(any())).called(1);
  });

  test('applyPreset lưu cài đặt, tạo bộ nhắc và rescheduleAll', () async {
    await container.read(reminderControllerProvider.future);
    final controller = container.read(reminderControllerProvider.notifier);

    await controller.applyPreset(PresetId.student);

    verify(() => scheduler.requestPermissions()).called(1);
    verify(() => settingsRepo.saveUserSettings(any())).called(1);
    verify(() => reminderRepo.replaceAllReminders(any())).called(1);
    verify(() => scheduler.rescheduleAll(any())).called(1);
  });

  test('deleteReminder hủy thông báo trước khi xóa DB và rescheduleAll', () async {
    await container.read(reminderControllerProvider.future);
    final controller = container.read(reminderControllerProvider.notifier);

    await controller.deleteReminder(42);

    verify(() => scheduler.cancelReminder(42)).called(1);
    verify(() => reminderRepo.deleteReminder(42)).called(1);
    verify(() => scheduler.rescheduleAll(any())).called(1);
  });

  test('applyUniversalDayPlan lưu hồ sơ, cập nhật thói quen & thêm việc mới', () async {
    await container.read(reminderControllerProvider.future);
    final controller = container.read(reminderControllerProvider.notifier);

    const settings = UserSettings();
    const profile = BodyProfile(dailyFocusMode: DailyFocusMode.brainFocus);
    final plan = UniversalDayScheduler.schedule(
      tasks: const [
        UserTaskInput(
          id: 't1',
          title: 'Viết đặc tả kỹ thuật',
          estimatedMinutes: 60,
          energyDemand: TaskEnergyDemand.highFocus,
        ),
      ],
      profile: profile,
      settings: settings,
    );

    await controller.applyUniversalDayPlan(
      plan: plan,
      settings: settings,
      profile: profile,
    );

    verify(() => settingsRepo.saveUserSettings(settings)).called(1);
    verify(() => settingsRepo.saveBodyProfile(profile)).called(1);
    verify(() => reminderRepo.replaceRoutineReminders(any())).called(1);
    verify(() => reminderRepo.insertReminder(any())).called(greaterThanOrEqualTo(1));
    verify(() => scheduler.rescheduleAll(any())).called(1);
  });

  test('swapMealReminderVariant cập nhật ghi chú món ăn mới và rescheduleAll', () async {
    await container.read(reminderControllerProvider.future);
    final controller = container.read(reminderControllerProvider.notifier);

    const mealReminder = Reminder(
      id: 10,
      title: 'Bữa trưa cân bằng',
      note: 'Món cũ',
      category: ReminderCategory.meal,
      isRoutine: true,
      hour: 12,
      minute: 0,
      repeat: RepeatType.daily,
      createdAt: '2026-11-18T00:00:00Z',
    );

    await controller.swapMealReminderVariant(
      reminder: mealReminder,
      profile: const BodyProfile(),
      nextVariantIndex: 1,
    );

    final captured = verify(() => reminderRepo.updateReminder(captureAny())).captured;
    final updated = captured.single as Reminder;
    expect(updated.note, isNot('Món cũ'));
    expect(AdaptiveFoodCatalog.parseFoodItemsFromNote(updated.note), isNotEmpty);
    verify(() => scheduler.rescheduleAll(any())).called(1);
  });
}
