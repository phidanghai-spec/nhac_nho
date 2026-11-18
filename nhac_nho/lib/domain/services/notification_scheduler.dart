// Interface NotificationScheduler trừu tượng hóa việc lập lịch thông báo cục bộ.

import '../entities/reminder.dart';

abstract class NotificationScheduler {
  Future<void> init();
  Future<bool> requestPermissions();
  Future<bool> canScheduleExactAlarms();
  Future<void> scheduleReminder(Reminder reminder);
  Future<void> cancelReminder(int reminderId);
  Future<void> rescheduleAll(List<Reminder> reminders);
  Future<void> scheduleSnooze({
    required int reminderId,
    required String title,
    String? body,
    required String categoryId,
    Duration delay = const Duration(minutes: 10),
  });
  Future<int> getPendingNotificationsCount();
  Future<void> showInstantTestNotification({
    String? title,
    String? body,
    ReminderCategory? category,
  });
}
