// Widget test kiểm tra HomeScreen không tràn (overflow) ở textScaler = 2.0 và cả theme sáng/tối.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nhac_nho/application/providers.dart';
import 'package:nhac_nho/domain/entities/body_profile.dart';
import 'package:nhac_nho/domain/entities/reminder.dart';
import 'package:nhac_nho/domain/entities/user_settings.dart';
import 'package:nhac_nho/domain/repositories/reminder_repository.dart';
import 'package:nhac_nho/domain/repositories/settings_repository.dart';
import 'package:nhac_nho/domain/services/notification_scheduler.dart';
import 'package:nhac_nho/presentation/screens/home_screen.dart';
import 'package:nhac_nho/presentation/screens/sleep_planner_screen.dart';
import 'package:nhac_nho/presentation/screens/stats_screen.dart';
import 'package:nhac_nho/presentation/theme/app_theme.dart';

class MockReminderRepository extends Mock implements ReminderRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockNotificationScheduler extends Mock implements NotificationScheduler {}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('vi');
  });

  final sampleReminders = [
    const Reminder(
      id: 1,
      title: 'Deep Work: Hoàn thành báo cáo tổng hợp quý',
      note: 'Tắt thông báo để tập trung 50 phút liên tục.',
      category: ReminderCategory.task,
      isRoutine: false,
      priority: 1,
      hour: 8,
      minute: 30,
      repeat: RepeatType.daily,
      createdAt: '2026-11-17T00:00:00Z',
    ),
    const Reminder(
      id: 2,
      title: 'Bữa sáng giàu đạm & tinh bột chậm',
      note: 'Trứng, yến mạch, bánh mì nguyên cám hoặc phở ít béo thêm rau.',
      category: ReminderCategory.meal,
      isRoutine: true,
      hour: 7,
      minute: 0,
      repeat: RepeatType.daily,
      createdAt: '2026-11-17T00:00:00Z',
    ),
    const Reminder(
      id: 3,
      title: 'Uống nước định kỳ',
      note: 'Uống 200ml nước và nhìn xa 6 mét bảo vệ mắt.',
      category: ReminderCategory.hydration,
      isRoutine: true,
      hour: 8,
      minute: 0,
      repeat: RepeatType.interval,
      intervalMinutes: 90,
      endHour: 20,
      endMinute: 0,
      createdAt: '2026-11-17T00:00:00Z',
    ),
  ];

  Future<void> pumpScaledHome(
    WidgetTester tester, {
    required Brightness brightness,
  }) async {
    final reminderRepo = MockReminderRepository();
    final settingsRepo = MockSettingsRepository();
    final scheduler = MockNotificationScheduler();

    when(() => reminderRepo.getAllReminders())
        .thenAnswer((_) async => sampleReminders);
    when(() => reminderRepo.getCompletionLogsByDate(any()))
        .thenAnswer((_) async => []);
    when(() => reminderRepo.getCompletionLogsInRange(any(), any()))
        .thenAnswer((_) async => []);
    when(() => settingsRepo.getUserSettings())
        .thenAnswer((_) async => const UserSettings());
    when(() => settingsRepo.getBodyProfile())
        .thenAnswer((_) async => const BodyProfile());
    when(() => settingsRepo.hasCompletedOnboarding())
        .thenAnswer((_) async => true);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          reminderRepositoryProvider.overrideWithValue(reminderRepo),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          notificationSchedulerProvider.overrideWithValue(scheduler),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode:
              brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2.0),
              ),
              child: child!,
            );
          },
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() => GoogleFonts.pendingFonts());
    await tester.pumpAndSettle();
  }

  testWidgets('HomeScreen không overflow với textScaler = 2.0 ở theme sáng', (tester) async {
    await pumpScaledHome(tester, brightness: Brightness.light);
    await tester.scrollUntilVisible(
      find.textContaining('Deep Work'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Deep Work'), findsOneWidget);
  });

  testWidgets('HomeScreen không overflow với textScaler = 2.0 ở theme tối', (tester) async {
    await pumpScaledHome(tester, brightness: Brightness.dark);
    await tester.scrollUntilVisible(
      find.textContaining('Bữa sáng'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Bữa sáng'), findsOneWidget);
  });

  testWidgets('StatsScreen và SleepPlannerScreen không overflow với textScaler = 2.0 và highContrast', (tester) async {
    final reminderRepo = MockReminderRepository();
    final settingsRepo = MockSettingsRepository();
    final scheduler = MockNotificationScheduler();

    when(() => reminderRepo.getAllReminders())
        .thenAnswer((_) async => sampleReminders);
    when(() => reminderRepo.getCompletionLogsByDate(any()))
        .thenAnswer((_) async => []);
    when(() => reminderRepo.getCompletionLogsInRange(any(), any()))
        .thenAnswer((_) async => []);
    when(() => settingsRepo.getUserSettings())
        .thenAnswer((_) async => const UserSettings());
    when(() => settingsRepo.getBodyProfile())
        .thenAnswer((_) async => const BodyProfile());
    when(() => settingsRepo.hasCompletedOnboarding())
        .thenAnswer((_) async => true);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          reminderRepositoryProvider.overrideWithValue(reminderRepo),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          notificationSchedulerProvider.overrideWithValue(scheduler),
        ],
        child: MaterialApp(
          theme: AppTheme.light(highContrast: true),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2.0),
              highContrast: true,
            ),
            child: child!,
          ),
          home: const StatsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          reminderRepositoryProvider.overrideWithValue(reminderRepo),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          notificationSchedulerProvider.overrideWithValue(scheduler),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(highContrast: true),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2.0),
              highContrast: true,
            ),
            child: child!,
          ),
          home: const SleepPlannerScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
