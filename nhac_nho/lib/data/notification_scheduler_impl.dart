// Triển khai NotificationScheduler sử dụng flutter_local_notifications.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../core/constants.dart';
import '../../core/time_utils.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/services/notification_scheduler.dart';

typedef TimezoneLookup = Future<String> Function();

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  if (response.actionId != NotificationSchedulerImpl.snoozeActionId) return;
  final payload = response.payload ?? '';
  if (!payload.startsWith('reminder:')) return;
  final parts = payload.split(':');
  if (parts.length < 4) return;
  final reminderId = int.tryParse(parts[1]);
  final categoryId = parts[2];
  final title = parts.sublist(3).join(':');
  if (reminderId == null) return;

  final scheduler = NotificationSchedulerImpl();
  unawaited(
    scheduler.scheduleSnooze(
      reminderId: reminderId,
      title: title,
      body: 'Đã hoãn 10 phút',
      categoryId: categoryId,
    ),
  );
}

class NotificationSchedulerImpl implements NotificationScheduler {
  NotificationSchedulerImpl({
    FlutterLocalNotificationsPlugin? plugin,
    TimezoneLookup? timezoneLookup,
    DateTime Function()? nowProvider,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _timezoneLookup = timezoneLookup ?? _defaultTimezoneLookup,
        _nowProvider = nowProvider ?? DateTime.now;

  static const String snoozeActionId = 'snooze_10m';

  final FlutterLocalNotificationsPlugin _plugin;
  final TimezoneLookup _timezoneLookup;
  final DateTime Function() _nowProvider;
  bool _initialized = false;

  static Future<String> _defaultTimezoneLookup() async {
    final info = await FlutterTimezone.getLocalTimezone();
    return info.identifier;
  }

  Future<void> _refreshTimezone() async {
    try {
      final zoneName = await _timezoneLookup();
      tz.setLocalLocation(tz.getLocation(zoneName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    }
  }

  @override
  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    await _refreshTimezone();

    const androidInit = AndroidInitializationSettings('ic_notification');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await _createChannels(androidPlugin);
    }

    _initialized = true;
  }

  Future<void> _createChannels(
    AndroidFlutterLocalNotificationsPlugin androidPlugin,
  ) async {
    const channels = [
      AndroidNotificationChannel(
        NotificationChannelConfig.taskId,
        NotificationChannelConfig.taskName,
        description: NotificationChannelConfig.taskDescription,
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        NotificationChannelConfig.mealId,
        NotificationChannelConfig.mealName,
        description: NotificationChannelConfig.mealDescription,
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        NotificationChannelConfig.hydrationId,
        NotificationChannelConfig.hydrationName,
        description: NotificationChannelConfig.hydrationDescription,
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        NotificationChannelConfig.sleepId,
        NotificationChannelConfig.sleepName,
        description: NotificationChannelConfig.sleepDescription,
        importance: Importance.high,
      ),
    ];

    for (final channel in channels) {
      await androidPlugin.createNotificationChannel(channel);
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    if (response.actionId != snoozeActionId) return;
    final payload = response.payload ?? '';
    if (!payload.startsWith('reminder:')) return;
    final parts = payload.split(':');
    if (parts.length < 4) return;
    final reminderId = int.tryParse(parts[1]);
    final categoryId = parts[2];
    final title = parts.sublist(3).join(':');
    if (reminderId == null) return;
    unawaited(
      scheduleSnooze(
        reminderId: reminderId,
        title: title,
        body: 'Đã hoãn 10 phút',
        categoryId: categoryId,
      ),
    );
  }

  @override
  Future<bool> requestPermissions() async {
    await init();
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidPlugin?.requestNotificationsPermission();
        return granted ?? false;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (_) {
      return false;
    }
    return true;
  }

  @override
  Future<bool> canScheduleExactAlarms() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return (await androidPlugin?.canScheduleExactNotifications()) ?? false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> scheduleReminder(Reminder reminder) async {
    await init();
    final id = reminder.id;
    if (id == null) return;

    await cancelReminder(id);
    if (!reminder.enabled) return;

    final scheduleMode = await _resolveScheduleMode();
    final now = tz.TZDateTime.from(_nowProvider(), tz.local);
    final entries = buildScheduleEntries(reminder, now: now);

    for (final entry in entries) {
      await _zonedScheduleWithFallback(
        id: entry.notificationId,
        title: reminder.title,
        body: (reminder.note != null && reminder.note!.isNotEmpty)
            ? reminder.note
            : 'Đã đến giờ: ${reminder.title}',
        scheduledDate: entry.scheduledDate,
        notificationDetails: _detailsForCategory(reminder.category.name),
        androidScheduleMode: scheduleMode,
        matchDateTimeComponents: entry.matchComponents,
        payload: 'reminder:$id:${reminder.category.name}:${reminder.title}',
      );
    }
  }

  @override
  Future<void> cancelReminder(int reminderId) async {
    for (var slot = 0; slot < AppLimits.slotsPerReminder; slot++) {
      await _plugin.cancel(
        id: TimeUtils.notificationIdFor(reminderId, slot),
      );
    }
  }

  @override
  Future<void> rescheduleAll(List<Reminder> reminders) async {
    await init();
    await _refreshTimezone();
    await _plugin.cancelAllPendingNotifications();

    final scheduleMode = await _resolveScheduleMode();
    final now = tz.TZDateTime.from(_nowProvider(), tz.local);

    final allEntries = <_ScheduledEntry>[];
    for (final reminder in reminders) {
      if (!reminder.enabled || reminder.id == null) continue;
      allEntries.addAll(buildScheduleEntries(reminder, now: now));
    }

    allEntries.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    final isApple = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final entriesToSchedule = isApple
        ? allEntries.take(AppLimits.maxScheduledWindowNotifications)
        : allEntries;

    for (final entry in entriesToSchedule) {
      await _zonedScheduleWithFallback(
        id: entry.notificationId,
        title: entry.reminder.title,
        body: (entry.reminder.note != null && entry.reminder.note!.isNotEmpty)
            ? entry.reminder.note
            : 'Đã đến giờ: ${entry.reminder.title}',
        scheduledDate: entry.scheduledDate,
        notificationDetails: _detailsForCategory(entry.reminder.category.name),
        androidScheduleMode: scheduleMode,
        matchDateTimeComponents: entry.matchComponents,
        payload:
            'reminder:${entry.reminder.id}:${entry.reminder.category.name}:${entry.reminder.title}',
      );
    }
  }

  @override
  Future<void> scheduleSnooze({
    required int reminderId,
    required String title,
    String? body,
    required String categoryId,
    Duration delay = const Duration(minutes: 10),
  }) async {
    await init();
    final scheduleMode = await _resolveScheduleMode();
    final snoozeTime = tz.TZDateTime.from(_nowProvider().add(delay), tz.local);
    final snoozeId =
        TimeUtils.notificationIdFor(reminderId, AppLimits.snoozeSlot);

    await _zonedScheduleWithFallback(
      id: snoozeId,
      title: 'Nhắc lại: $title',
      body: body ?? 'Đã hoãn 10 phút',
      scheduledDate: snoozeTime,
      notificationDetails: _detailsForCategory(categoryId),
      androidScheduleMode: scheduleMode,
      payload: 'reminder:$reminderId:$categoryId:$title',
    );
  }

  @override
  Future<int> getPendingNotificationsCount() async {
    await init();
    try {
      final pending = await _plugin.pendingNotificationRequests();
      return pending.length;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<void> showInstantTestNotification({
    String? title,
    String? body,
    ReminderCategory? category,
  }) async {
    await init();
    final cat = category ?? ReminderCategory.meal;
    final resolvedTitle = title ?? 'Thử chuông báo Nhắc Nhở';
    final resolvedBody = body ??
        'Thông báo hoạt động bình thường! Bạn có thể bấm "Hoãn 10 phút" ngay bên dưới.';
    await _plugin.show(
      id: 999999,
      title: resolvedTitle,
      body: resolvedBody,
      notificationDetails: _detailsForCategory(cat.name),
      payload: 'reminder:9999:${cat.name}:$resolvedTitle',
    );
  }

  Future<void> _zonedScheduleWithFallback({
    required int id,
    required String title,
    String? body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    DateTimeComponents? matchDateTimeComponents,
    String? payload,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: androidScheduleMode,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: payload,
      );
    } on PlatformException {
      if (androidScheduleMode == AndroidScheduleMode.exactAllowWhileIdle) {
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: matchDateTimeComponents,
          payload: payload,
        );
      } else {
        rethrow;
      }
    }
  }

  Future<AndroidScheduleMode> _resolveScheduleMode() async {
    final exactAllowed = await canScheduleExactAlarms();
    return exactAllowed
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  NotificationDetails _detailsForCategory(String categoryId) {
    final (channelId, channelName, channelDesc) = switch (categoryId) {
      NotificationChannelConfig.mealId => (
        NotificationChannelConfig.mealId,
        NotificationChannelConfig.mealName,
        NotificationChannelConfig.mealDescription,
      ),
      NotificationChannelConfig.hydrationId => (
        NotificationChannelConfig.hydrationId,
        NotificationChannelConfig.hydrationName,
        NotificationChannelConfig.hydrationDescription,
      ),
      NotificationChannelConfig.sleepId => (
        NotificationChannelConfig.sleepId,
        NotificationChannelConfig.sleepName,
        NotificationChannelConfig.sleepDescription,
      ),
      _ => (
        NotificationChannelConfig.taskId,
        NotificationChannelConfig.taskName,
        NotificationChannelConfig.taskDescription,
      ),
    };

    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_notification',
        actions: const [
          AndroidNotificationAction(
            snoozeActionId,
            'Hoãn 10 phút',
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ],
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  @visibleForTesting
  List<ScheduledNotificationSpec> buildScheduleEntries(
    Reminder reminder, {
    required tz.TZDateTime now,
  }) {
    final reminderId = reminder.id;
    if (reminderId == null) return const [];

    switch (reminder.repeat) {
      case RepeatType.once:
        final dt = TimeUtils.parseDateAtTime(
          reminder.date,
          reminder.hour,
          reminder.minute,
          location: now.location,
        );
        if (dt == null || !dt.isAfter(now)) return const [];
        return [
          _ScheduledEntry(
            reminder: reminder,
            notificationId: TimeUtils.notificationIdFor(reminderId, 0),
            scheduledDate: dt,
            matchComponents: null,
          ),
        ];

      case RepeatType.daily:
        return [
          _ScheduledEntry(
            reminder: reminder,
            notificationId: TimeUtils.notificationIdFor(reminderId, 0),
            scheduledDate: TimeUtils.nextInstanceOf(
              reminder.hour,
              reminder.minute,
              now: now,
              location: now.location,
            ),
            matchComponents: DateTimeComponents.time,
          ),
        ];

      case RepeatType.weekly:
        final entries = <_ScheduledEntry>[];
        for (var bit = 0; bit < 7; bit++) {
          if ((reminder.weekdaysMask & (1 << bit)) == 0) continue;
          final weekday = bit + 1;
          entries.add(
            _ScheduledEntry(
              reminder: reminder,
              notificationId: TimeUtils.notificationIdFor(reminderId, weekday),
              scheduledDate: TimeUtils.nextInstanceOfWeekday(
                weekday,
                reminder.hour,
                reminder.minute,
                now: now,
                location: now.location,
              ),
              matchComponents: DateTimeComponents.dayOfWeekAndTime,
            ),
          );
        }
        return entries;

      case RepeatType.interval:
        final intervalMin = reminder.intervalMinutes;
        final endHour = reminder.endHour;
        final endMinute = reminder.endMinute;
        if (intervalMin == null || endHour == null || endMinute == null) {
          return const [];
        }
        final slots = TimeUtils.generateIntervalSlots(
          startHour: reminder.hour,
          startMinute: reminder.minute,
          endHour: endHour,
          endMinute: endMinute,
          intervalMinutes: intervalMin,
        );
        final entries = <_ScheduledEntry>[];
        for (var i = 0; i < slots.length; i++) {
          final slot = slots[i];
          entries.add(
            _ScheduledEntry(
              reminder: reminder,
              notificationId: TimeUtils.notificationIdFor(
                reminderId,
                AppLimits.intervalSlotStart + i,
              ),
              scheduledDate: TimeUtils.nextInstanceOf(
                slot.hour,
                slot.minute,
                now: now,
                location: now.location,
              ),
              matchComponents: DateTimeComponents.time,
            ),
          );
        }
        return entries;
    }
  }
}

class ScheduledNotificationSpec {
  const ScheduledNotificationSpec({
    required this.reminder,
    required this.notificationId,
    required this.scheduledDate,
    required this.matchComponents,
  });

  final Reminder reminder;
  final int notificationId;
  final tz.TZDateTime scheduledDate;
  final DateTimeComponents? matchComponents;
}

typedef _ScheduledEntry = ScheduledNotificationSpec;
