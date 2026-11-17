// Logic thuần Dart tính chuỗi ngày duy trì (Streak) và tỷ lệ hoàn thành 7 ngày.

import '../entities/completion_log.dart';
import '../entities/reminder.dart';

class HabitStatsCalculator {
  const HabitStatsCalculator._();

  static String formatDateKey(DateTime date) {
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  /// Tính chuỗi ngày liên tiếp hoàn thành >= 80% các mục thói quen (isRoutine == true).
  /// Nếu hôm nay chưa đạt 80% nhưng hôm qua đạt (và các ngày trước liên tiếp),
  /// chuỗi vẫn tính tiếp từ hôm qua cho tới hết ngày hôm nay.
  static int calculateCurrentStreak({
    required List<Reminder> reminders,
    required List<CompletionLog> logs,
    required DateTime today,
    double threshold = 0.8,
  }) {
    final routineReminders =
        reminders.where((r) => r.isRoutine && r.enabled && r.id != null).toList();
    if (routineReminders.isEmpty) return 0;

    final logsByDate = <String, Map<int, CompletionStatus>>{};
    for (final log in logs) {
      logsByDate.putIfAbsent(log.date, () => <int, CompletionStatus>{})[
          log.reminderId] = log.status;
    }

    final normalizedToday = DateTime(today.year, today.month, today.day);
    final todayRate = _completionRateForDay(
      date: normalizedToday,
      reminders: routineReminders,
      logsByDate: logsByDate,
    );

    var cursor = normalizedToday;
    var streak = 0;

    if (todayRate != null && todayRate >= threshold) {
      streak = 1;
      cursor = normalizedToday.subtract(const Duration(days: 1));
    } else {
      cursor = normalizedToday.subtract(const Duration(days: 1));
    }

    // Look back up to 365 days max to guarantee bounded execution.
    for (var i = 0; i < 365; i++) {
      final rate = _completionRateForDay(
        date: cursor,
        reminders: routineReminders,
        logsByDate: logsByDate,
      );
      if (rate == null || rate < threshold) {
        break;
      }
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  /// Trả về Map<yyyy-MM-dd, double (0.0..1.0)> cho 7 ngày gần nhất (từ cũ đến mới).
  static Map<String, double> calculateLast7DaysRates({
    required List<Reminder> reminders,
    required List<CompletionLog> logs,
    required DateTime today,
    bool? isRoutine,
  }) {
    final filtered = reminders.where((r) {
      if (!r.enabled || r.id == null) return false;
      if (isRoutine != null && r.isRoutine != isRoutine) return false;
      return true;
    }).toList();

    final logsByDate = <String, Map<int, CompletionStatus>>{};
    for (final log in logs) {
      logsByDate.putIfAbsent(log.date, () => <int, CompletionStatus>{})[
          log.reminderId] = log.status;
    }

    final normalizedToday = DateTime(today.year, today.month, today.day);
    final result = <String, double>{};

    for (var offset = 6; offset >= 0; offset--) {
      final day = normalizedToday.subtract(Duration(days: offset));
      final key = formatDateKey(day);
      final rate = _completionRateForDay(
        date: day,
        reminders: filtered,
        logsByDate: logsByDate,
      );
      result[key] = rate ?? 0.0;
    }

    return result;
  }

  static double? _completionRateForDay({
    required DateTime date,
    required List<Reminder> reminders,
    required Map<String, Map<int, CompletionStatus>> logsByDate,
  }) {
    final scheduled =
        reminders.where((r) => r.isScheduledForDate(date)).toList();
    if (scheduled.isEmpty) return null;

    final dateKey = formatDateKey(date);
    final dayLogs = logsByDate[dateKey] ?? const {};
    var doneCount = 0;
    for (final r in scheduled) {
      if (dayLogs[r.id] == CompletionStatus.done) {
        doneCount++;
      }
    }
    return doneCount / scheduled.length;
  }
}
