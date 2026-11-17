// Unit test cho NotificationSchedulerImpl bằng mocktail.

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nhac_nho/data/notification_scheduler_impl.dart';
import 'package:nhac_nho/domain/entities/reminder.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class MockAndroidPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    registerFallbackValue(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
    );
    registerFallbackValue(
      tz.TZDateTime(tz.getLocation('Asia/Ho_Chi_Minh'), 2026, 11, 17, 8, 0),
    );
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
    registerFallbackValue(
      const AndroidNotificationChannel('id', 'name'),
    );
  });

  late MockFlutterLocalNotificationsPlugin mockPlugin;
  late MockAndroidPlugin mockAndroidPlugin;
  late NotificationSchedulerImpl scheduler;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    mockPlugin = MockFlutterLocalNotificationsPlugin();
    mockAndroidPlugin = MockAndroidPlugin();

    when(
      () => mockPlugin.initialize(
        settings: any(named: 'settings'),
        onDidReceiveNotificationResponse: any(
          named: 'onDidReceiveNotificationResponse',
        ),
        onDidReceiveBackgroundNotificationResponse: any(
          named: 'onDidReceiveBackgroundNotificationResponse',
        ),
      ),
    ).thenAnswer((_) async => true);

    when(
      () => mockPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>(),
    ).thenReturn(mockAndroidPlugin);

    when(() => mockAndroidPlugin.createNotificationChannel(any()))
        .thenAnswer((_) async {});
    when(() => mockAndroidPlugin.canScheduleExactNotifications())
        .thenAnswer((_) async => true);

    when(() => mockPlugin.cancel(id: any(named: 'id')))
        .thenAnswer((_) async {});
    when(() => mockPlugin.cancelAllPendingNotifications())
        .thenAnswer((_) async {});
    when(
      () => mockPlugin.zonedSchedule(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
        matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});

    scheduler = NotificationSchedulerImpl(
      plugin: mockPlugin,
      timezoneLookup: () async => 'Asia/Ho_Chi_Minh',
      nowProvider: () => DateTime(2026, 11, 17, 7, 0),
    );
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('init tạo đủ 4 notification channels', () async {
    await scheduler.init();
    verify(() => mockAndroidPlugin.createNotificationChannel(any())).called(4);
  });

  test('scheduleReminder kiểu daily dùng slot 0 và matchDateTimeComponents.time', () async {
    const reminder = Reminder(
      id: 3,
      title: 'Bữa sáng',
      note: 'Trứng và yến mạch',
      category: ReminderCategory.meal,
      isRoutine: true,
      hour: 7,
      minute: 30,
      repeat: RepeatType.daily,
      createdAt: '2026-11-17T00:00:00Z',
    );

    await scheduler.scheduleReminder(reminder);

    verify(() => mockPlugin.cancel(id: any(named: 'id'))).called(100);
    verify(
      () => mockPlugin.zonedSchedule(
        id: 300,
        title: 'Bữa sáng',
        body: 'Trứng và yến mạch',
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'reminder:3:meal:Bữa sáng',
      ),
    ).called(1);
  });

  test('scheduleReminder kiểu weekly lên lịch vào slot 1..7 và dayOfWeekAndTime', () async {
    // Thứ 2 (bit 0 -> slot 1) và Thứ 5 (bit 3 -> slot 4)
    const reminder = Reminder(
      id: 4,
      title: 'Họp tuần',
      category: ReminderCategory.task,
      isRoutine: false,
      hour: 9,
      minute: 0,
      repeat: RepeatType.weekly,
      weekdaysMask: (1 << 0) | (1 << 3),
      createdAt: '2026-11-17T00:00:00Z',
    );

    await scheduler.scheduleReminder(reminder);

    verify(
      () => mockPlugin.zonedSchedule(
        id: 401,
        title: 'Họp tuần',
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: any(named: 'payload'),
      ),
    ).called(1);

    verify(
      () => mockPlugin.zonedSchedule(
        id: 404,
        title: 'Họp tuần',
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: any(named: 'payload'),
      ),
    ).called(1);
  });

  test('scheduleReminder kiểu interval đặt vào slot 10..29 và rơi về inexact khi không có quyền exact', () async {
    when(() => mockAndroidPlugin.canScheduleExactNotifications())
        .thenAnswer((_) async => false);

    const reminder = Reminder(
      id: 7,
      title: 'Uống nước',
      category: ReminderCategory.hydration,
      isRoutine: true,
      hour: 8,
      minute: 0,
      repeat: RepeatType.interval,
      intervalMinutes: 120,
      endHour: 12,
      endMinute: 0,
      createdAt: '2026-11-17T00:00:00Z',
    );

    await scheduler.scheduleReminder(reminder);

    // 08:00, 10:00, 12:00 => slot 10, 11, 12 => IDs 710, 711, 712
    for (final expectedId in [710, 711, 712]) {
      verify(
        () => mockPlugin.zonedSchedule(
          id: expectedId,
          title: 'Uống nước',
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: any(named: 'payload'),
        ),
      ).called(1);
    }
  });
}
