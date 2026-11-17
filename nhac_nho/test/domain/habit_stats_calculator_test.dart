// Unit test cho HabitStatsCalculator (mục 6.4).

import 'package:flutter_test/flutter_test.dart';
import 'package:nhac_nho/domain/entities/completion_log.dart';
import 'package:nhac_nho/domain/entities/reminder.dart';
import 'package:nhac_nho/domain/logic/habit_stats_calculator.dart';

void main() {
  Reminder routine(int id, {String title = 'Thói quen'}) => Reminder(
        id: id,
        title: title,
        category: ReminderCategory.meal,
        isRoutine: true,
        hour: 7,
        minute: 0,
        repeat: RepeatType.daily,
        createdAt: '2026-11-01T00:00:00.000Z',
      );

  Reminder workTask(int id) => Reminder(
        id: id,
        title: 'Công việc',
        category: ReminderCategory.task,
        isRoutine: false,
        hour: 9,
        minute: 0,
        repeat: RepeatType.daily,
        createdAt: '2026-11-01T00:00:00.000Z',
      );

  CompletionLog doneLog(int reminderId, String date) => CompletionLog(
        reminderId: reminderId,
        date: date,
        status: CompletionStatus.done,
        completedAt: '${date}T08:00:00.000Z',
      );

  group('HabitStatsCalculator', () {
    final today = DateTime(2026, 11, 17);

    test('tính streak đúng khi các ngày đạt >= 80% các mục isRoutine', () {
      // 5 routine => cần >= 4 done (80%) mỗi ngày
      final reminders = [
        routine(1),
        routine(2),
        routine(3),
        routine(4),
        routine(5),
        workTask(99), // Không tính vào streak routine
      ];

      final logs = <CompletionLog>[
        // Hôm nay (17): 4/5 = 80% -> đạt
        doneLog(1, '2026-11-17'),
        doneLog(2, '2026-11-17'),
        doneLog(3, '2026-11-17'),
        doneLog(4, '2026-11-17'),
        // Hôm qua (16): 5/5 = 100% -> đạt
        doneLog(1, '2026-11-16'),
        doneLog(2, '2026-11-16'),
        doneLog(3, '2026-11-16'),
        doneLog(4, '2026-11-16'),
        doneLog(5, '2026-11-16'),
        // Ngày 15: 4/5 = 80% -> đạt
        doneLog(1, '2026-11-15'),
        doneLog(2, '2026-11-15'),
        doneLog(3, '2026-11-15'),
        doneLog(4, '2026-11-15'),
        // Ngày 14: 3/5 = 60% -> đứt chuỗi
        doneLog(1, '2026-11-14'),
        doneLog(2, '2026-11-14'),
        doneLog(3, '2026-11-14'),
      ];

      final streak = HabitStatsCalculator.calculateCurrentStreak(
        reminders: reminders,
        logs: logs,
        today: today,
      );

      expect(streak, 3);
    });

    test('vẫn giữ streak từ hôm qua nếu hôm nay đang trong ngày và chưa đủ 80%', () {
      final reminders = [routine(1), routine(2)];
      final logs = [
        // Hôm nay mới xong 1/2 = 50%
        doneLog(1, '2026-11-17'),
        // Hôm qua & hôm kia xong 2/2
        doneLog(1, '2026-11-16'),
        doneLog(2, '2026-11-16'),
        doneLog(1, '2026-11-15'),
        doneLog(2, '2026-11-15'),
      ];

      final streak = HabitStatsCalculator.calculateCurrentStreak(
        reminders: reminders,
        logs: logs,
        today: today,
      );

      expect(streak, 2);
    });

    test('tính Map tỷ lệ hoàn thành 7 ngày gần nhất theo đúng thứ tự ngày', () {
      final reminders = [routine(1), routine(2), workTask(3)];
      final logs = [
        doneLog(1, '2026-11-17'),
        doneLog(2, '2026-11-17'),
        doneLog(1, '2026-11-15'),
        doneLog(3, '2026-11-15'),
      ];

      final routineRates = HabitStatsCalculator.calculateLast7DaysRates(
        reminders: reminders,
        logs: logs,
        today: today,
        isRoutine: true,
      );

      expect(routineRates.keys.toList(), [
        '2026-11-11',
        '2026-11-12',
        '2026-11-13',
        '2026-11-14',
        '2026-11-15',
        '2026-11-16',
        '2026-11-17',
      ]);
      expect(routineRates['2026-11-17'], 1.0);
      expect(routineRates['2026-11-16'], 0.0);
      expect(routineRates['2026-11-15'], 0.5);
    });
  });
}
