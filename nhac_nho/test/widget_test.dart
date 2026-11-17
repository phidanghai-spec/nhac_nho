// Smoke test khởi động NhacNhoApp.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nhac_nho/application/providers.dart';
import 'package:nhac_nho/domain/entities/body_profile.dart';
import 'package:nhac_nho/domain/entities/user_settings.dart';
import 'package:nhac_nho/domain/repositories/reminder_repository.dart';
import 'package:nhac_nho/domain/repositories/settings_repository.dart';
import 'package:nhac_nho/domain/services/notification_scheduler.dart';
import 'package:nhac_nho/main.dart';

class MockReminderRepository extends Mock implements ReminderRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockNotificationScheduler extends Mock implements NotificationScheduler {}

void main() {
  testWidgets('NhacNhoApp khởi động và hiển thị màn Hôm nay', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('vi');

    final reminderRepo = MockReminderRepository();
    final settingsRepo = MockSettingsRepository();
    final scheduler = MockNotificationScheduler();

    when(() => reminderRepo.getAllReminders()).thenAnswer((_) async => []);
    when(() => reminderRepo.getCompletionLogsByDate(any()))
        .thenAnswer((_) async => []);
    when(() => reminderRepo.getCompletionLogsInRange(any(), any()))
        .thenAnswer((_) async => []);
    when(() => settingsRepo.getUserSettings())
        .thenAnswer((_) async => const UserSettings());
    when(() => settingsRepo.getBodyProfile())
        .thenAnswer((_) async => const BodyProfile());
    when(() => settingsRepo.hasCompletedOnboarding())
        .thenAnswer((_) async => false);
    when(() => scheduler.rescheduleAll(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reminderRepositoryProvider.overrideWithValue(reminderRepo),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          notificationSchedulerProvider.overrideWithValue(scheduler),
        ],
        child: const NhacNhoApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() => GoogleFonts.pendingFonts());
    await tester.pumpAndSettle();

    expect(find.text('Hôm nay'), findsWidgets);
    expect(find.text('Ngủ & Ăn'), findsOneWidget);
    expect(find.text('Thống kê'), findsOneWidget);
    expect(find.text('Cài đặt'), findsOneWidget);
  });
}
