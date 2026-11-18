// Unit test cho UniversalDayScheduler (Wake-anchored auto-fit, tránh xung đột bữa ăn & chèn nghỉ).

import 'package:flutter_test/flutter_test.dart';
import 'package:nhac_nho/domain/entities/body_profile.dart';
import 'package:nhac_nho/domain/entities/reminder.dart';
import 'package:nhac_nho/domain/entities/user_settings.dart';
import 'package:nhac_nho/domain/entities/user_task_input.dart';
import 'package:nhac_nho/domain/logic/universal_day_scheduler.dart';

void main() {
  group('UniversalDayScheduler', () {
    test('tự động xếp việc Tập trung cao vào đỉnh năng lượng buổi sáng và chèn nghỉ sau việc >= 60p', () {
      const settings = UserSettings(wakeTime: '06:30', sleepHours: 7.5);
      const profile = BodyProfile(dailyFocusMode: DailyFocusMode.brainFocus);

      final plan = UniversalDayScheduler.schedule(
        tasks: const [
          UserTaskInput(
            id: 't1',
            title: 'Học kiến trúc hệ thống',
            estimatedMinutes: 90,
            energyDemand: TaskEnergyDemand.highFocus,
          ),
          UserTaskInput(
            id: 't2',
            title: 'Dọn dẹp hộp thư & việc nhà',
            estimatedMinutes: 45,
            energyDemand: TaskEnergyDemand.lightChore,
          ),
        ],
        profile: profile,
        settings: settings,
      );

      final deepTask = plan.reminders.firstWhere(
        (r) => r.title == 'Học kiến trúc hệ thống',
      );
      final lightTask = plan.reminders.firstWhere(
        (r) => r.title == 'Dọn dẹp hộp thư & việc nhà',
      );

      // Việc tập trung cao được xếp vào buổi sáng (08:00 - 11:30), trước việc nhẹ buổi chiều
      expect(deepTask.hour, greaterThanOrEqualTo(8));
      expect(deepTask.hour, lessThan(12));
      expect(lightTask.hour, greaterThanOrEqualTo(11));
      expect(
        plan.reminders.any(
          (r) =>
              r.category == ReminderCategory.hydration &&
              r.title.contains('Nghỉ mắt & Uống nước sau'),
        ),
        isTrue,
      );
    });

    test('tự động dịch chuyển bữa trưa khi công việc cố định trùng vào 12:00', () {
      const settings = UserSettings(wakeTime: '06:30', sleepHours: 7.5);
      const profile = BodyProfile();

      final plan = UniversalDayScheduler.schedule(
        tasks: const [
          UserTaskInput(
            id: 'fixed_event',
            title: 'Chụp hình sự kiện / Họp khách hàng',
            estimatedMinutes: 90,
            energyDemand: TaskEnergyDemand.physicalOrEvent,
            fixedHour: 11,
            fixedMinute: 30, // 11:30 -> 13:00 đè lên bữa trưa 12:00
          ),
        ],
        profile: profile,
        settings: settings,
      );

      final lunch = plan.reminders.firstWhere(
        (r) => r.category == ReminderCategory.meal && r.title.contains('trưa'),
      );
      final lunchMin = lunch.hour * 60 + lunch.minute;
      // Không được nằm trong [11:30, 13:00)
      expect(lunchMin < 11 * 60 + 30 || lunchMin >= 13 * 60, isTrue);
    });

    test('hỗ trợ hoàn hảo người làm ca đêm (thức 16:00, ngủ 08:00)', () {
      const settings = UserSettings(wakeTime: '16:00', sleepHours: 7.75);
      const profile = BodyProfile(workShift: WorkShift.nightShift);

      final plan = UniversalDayScheduler.schedule(
        tasks: const [
          UserTaskInput(
            id: 'night_task',
            title: 'Làm việc ca đêm',
            estimatedMinutes: 90,
            energyDemand: TaskEnergyDemand.highFocus,
          ),
        ],
        profile: profile,
        settings: settings,
      );

      final task = plan.reminders.firstWhere(
        (r) => r.title == 'Làm việc ca đêm',
      );
      // Xếp trong đỉnh năng lượng 1 của ca đêm (khoảng 17:30 - 21:00)
      expect(task.hour, greaterThanOrEqualTo(17));
      expect(task.hour, lessThanOrEqualTo(22));
      expect(plan.sleepPlan.bedtime.format24h(), '08:00');
    });
  });
}
