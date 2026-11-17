// Widget test cho ReminderFormScreen (kiểm tra validation mục 6.5).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nhac_nho/application/providers.dart';
import 'package:nhac_nho/domain/entities/body_profile.dart';
import 'package:nhac_nho/domain/entities/reminder.dart';
import 'package:nhac_nho/domain/entities/user_settings.dart';
import 'package:nhac_nho/domain/repositories/reminder_repository.dart';
import 'package:nhac_nho/domain/repositories/settings_repository.dart';
import 'package:nhac_nho/domain/services/notification_scheduler.dart';
import 'package:nhac_nho/presentation/screens/reminder_form_screen.dart';
import 'package:nhac_nho/presentation/theme/app_theme.dart';

class MockReminderRepository extends Mock implements ReminderRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockNotificationScheduler extends Mock implements NotificationScheduler {}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('vi');
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
  });

  late MockReminderRepository reminderRepo;
  late MockSettingsRepository settingsRepo;
  late MockNotificationScheduler scheduler;

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
    when(() => settingsRepo.getUserSettings())
        .thenAnswer((_) async => const UserSettings());
    when(() => settingsRepo.getBodyProfile())
        .thenAnswer((_) async => const BodyProfile());
    when(() => settingsRepo.hasCompletedOnboarding())
        .thenAnswer((_) async => false);
    when(() => settingsRepo.setOnboardingCompleted(any()))
        .thenAnswer((_) async {});
    when(() => scheduler.requestPermissions()).thenAnswer((_) async => true);
    when(() => scheduler.rescheduleAll(any())).thenAnswer((_) async {});
  });

  Widget wrapForm([Reminder? initial]) {
    return ProviderScope(
      overrides: [
        reminderRepositoryProvider.overrideWithValue(reminderRepo),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        notificationSchedulerProvider.overrideWithValue(scheduler),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: ReminderFormScreen(initialReminder: initial),
      ),
    );
  }

  testWidgets('báo lỗi khi tên nhắc rỗng', (tester) async {
    await tester.pumpWidget(wrapForm());
    await tester.pumpAndSettle();
    await tester.runAsync(() => GoogleFonts.pendingFonts());
    await tester.pumpAndSettle();

    final saveBtn = find.text('Lưu nhắc nhở');
    await tester.ensureVisible(saveBtn);
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    expect(find.text('Tên nhắc không được để trống.'), findsOneWidget);
  });

  testWidgets('báo lỗi khi chọn lặp theo thứ nhưng chưa chọn ngày nào', (tester) async {
    await tester.pumpWidget(wrapForm());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Họp tuần');
    final weeklyChip = find.text('Theo thứ');
    await tester.ensureVisible(weeklyChip);
    await tester.tap(weeklyChip);
    await tester.pumpAndSettle();

    final saveBtn = find.text('Lưu nhắc nhở');
    await tester.ensureVisible(saveBtn);
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    expect(
      find.text('Vui lòng chọn ít nhất 1 ngày trong tuần.'),
      findsOneWidget,
    );
  });

  testWidgets('báo lỗi khi chu kỳ lặp interval nhỏ hơn 30 phút và khi giờ kết thúc <= bắt đầu', (tester) async {
    await tester.pumpWidget(
      wrapForm(
        const Reminder(
          id: 10,
          title: 'Uống nước',
          category: ReminderCategory.hydration,
          isRoutine: true,
          hour: 20,
          minute: 0,
          repeat: RepeatType.interval,
          intervalMinutes: 15,
          endHour: 18,
          endMinute: 0,
          createdAt: '2026-11-17T00:00:00Z',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final saveBtn = find.text('Lưu thay đổi');
    await tester.ensureVisible(saveBtn);
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    expect(find.text('Chu kỳ lặp phải từ 30 phút trở lên.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(1), '60');
    await tester.ensureVisible(saveBtn);
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    expect(find.text('Giờ kết thúc phải sau giờ bắt đầu.'), findsOneWidget);
  });
}
