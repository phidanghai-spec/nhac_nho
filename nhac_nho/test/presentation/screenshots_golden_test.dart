// Xuất ảnh PNG tham khảo cho 5 màn hình chính ở cả chế độ Sáng và Tối vào docs/screenshots/.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nhac_nho/application/providers.dart';
import 'package:nhac_nho/domain/entities/body_profile.dart';
import 'package:nhac_nho/domain/entities/completion_log.dart';
import 'package:nhac_nho/domain/entities/preset_profile.dart';
import 'package:nhac_nho/domain/logic/habit_stats_calculator.dart';
import 'package:nhac_nho/domain/logic/work_meal_guide.dart';
import 'package:nhac_nho/domain/repositories/reminder_repository.dart';
import 'package:nhac_nho/domain/repositories/settings_repository.dart';
import 'package:nhac_nho/domain/services/notification_scheduler.dart';
import 'package:nhac_nho/presentation/screens/home_screen.dart';
import 'package:nhac_nho/presentation/screens/reminder_form_screen.dart';
import 'package:nhac_nho/presentation/screens/settings_screen.dart';
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
    final iconFile = File(
      'D:/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (iconFile.existsSync()) {
      final bytes = await iconFile.readAsBytes();
      final loader = FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
    }
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    required Widget screen,
    required Brightness brightness,
    required String goldenName,
  }) async {
    tester.view.physicalSize = const Size(412 * 2, 915 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final reminderRepo = MockReminderRepository();
    final settingsRepo = MockSettingsRepository();
    final scheduler = MockNotificationScheduler();

    final preset = WorkMealGuide.getPreset(PresetId.officeCoder);
    final reminders = [
      for (var i = 0; i < preset.reminders.length; i++)
        preset.reminders[i].copyWith(id: i + 1),
    ];

    final today = DateTime.now();
    final logs = <CompletionLog>[];
    for (var d = 0; d < 7; d++) {
      final key = HabitStatsCalculator.formatDateKey(
        today.subtract(Duration(days: d)),
      );
      final targetCount = reminders.length - (d % 3);
      for (var j = 0; j < targetCount; j++) {
        logs.add(
          CompletionLog(
            id: d * 100 + j,
            reminderId: reminders[j].id!,
            date: key,
            status: CompletionStatus.done,
            completedAt: '${key}T10:00:00.000Z',
          ),
        );
      }
    }

    when(() => reminderRepo.getAllReminders())
        .thenAnswer((_) async => reminders);
    when(() => reminderRepo.getCompletionLogsByDate(any())).thenAnswer(
      (_) async => logs
          .where((l) => l.date == HabitStatsCalculator.formatDateKey(today))
          .toList(),
    );
    when(() => reminderRepo.getCompletionLogsInRange(any(), any()))
        .thenAnswer((_) async => logs);
    when(() => settingsRepo.getUserSettings())
        .thenAnswer((_) async => preset.defaultSettings);
    when(() => settingsRepo.getBodyProfile())
        .thenAnswer((_) async => const BodyProfile(isGymGoer: true));
    when(() => settingsRepo.hasCompletedOnboarding())
        .thenAnswer((_) async => true);
    when(() => scheduler.canScheduleExactAlarms())
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
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode:
              brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    await tester.runAsync(() => GoogleFonts.pendingFonts());
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../docs/screenshots/$goldenName.png'),
    );
  }

  final screens = <String, Widget Function()>{
    '01_home': () => const HomeScreen(),
    '02_reminder_form': () => const ReminderFormScreen(),
    '03_sleep_nutrition': () => const SleepPlannerScreen(),
    '04_stats': () => const StatsScreen(),
    '05_settings': () => const SettingsScreen(),
  };

  for (final entry in screens.entries) {
    testWidgets('golden ${entry.key} light', (tester) async {
      await pumpScreen(
        tester,
        screen: entry.value(),
        brightness: Brightness.light,
        goldenName: '${entry.key}_light',
      );
    });

    testWidgets('golden ${entry.key} dark', (tester) async {
      await pumpScreen(
        tester,
        screen: entry.value(),
        brightness: Brightness.dark,
        goldenName: '${entry.key}_dark',
      );
    });
  }
}
