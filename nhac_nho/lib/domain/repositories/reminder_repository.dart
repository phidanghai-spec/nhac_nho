// Interface ReminderRepository cho thao tác CRUD nhắc nhở và completion logs.

import '../entities/completion_log.dart';
import '../entities/reminder.dart';

abstract class ReminderRepository {
  Future<int> insertReminder(Reminder reminder);
  Future<void> updateReminder(Reminder reminder);
  Future<void> deleteReminder(int id);
  Future<Reminder?> getReminderById(int id);
  Future<List<Reminder>> getAllReminders();
  Future<List<Reminder>> getRemindersForDate(
    DateTime date, {
    bool? isRoutine,
  });
  Future<void> replaceAllReminders(List<Reminder> reminders);

  Future<int> upsertCompletionLog(CompletionLog log);
  Future<List<CompletionLog>> getCompletionLogsByDate(String date);
  Future<List<CompletionLog>> getCompletionLogsInRange(
    String startDate,
    String endDate,
  );
  Future<void> deleteCompletionLogForDate(int reminderId, String date);
}
