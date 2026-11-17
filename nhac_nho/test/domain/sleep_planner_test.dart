// Unit test cho SleepPlanner (mục 6.3).

import 'package:flutter_test/flutter_test.dart';
import 'package:nhac_nho/domain/logic/sleep_planner.dart';

void main() {
  group('SleepPlanner.calculate', () {
    test('ca chuẩn: thức 06:30, ngủ 7.5h, đệm 15p', () {
      final result = SleepPlanner.calculate(
        wakeTime: const ClockTime(6, 30),
        sleepHours: 7.5,
        fallAsleepBufferMin: 15,
        dinnerCutoffHours: 3.0,
        caffeineCutoffHours: 8.0,
        windDownMin: 45,
      );

      expect(result.bedtime.format24h(), '22:45');
      expect(result.dinnerStop.format24h(), '19:45');
      expect(result.caffeineCutoff.format24h(), '14:45');
      expect(result.windDown.format24h(), '22:00');
      expect(result.sleepDurationWarning, isNull);
    });

    test('ca dậy sớm: thức 05:00, ngủ 7.5h, đệm 15p', () {
      final result = SleepPlanner.calculate(
        wakeTime: const ClockTime(5, 0),
        sleepHours: 7.5,
        fallAsleepBufferMin: 15,
      );

      expect(result.bedtime.format24h(), '21:15');
      expect(result.dinnerStop.format24h(), '18:15');
      expect(result.caffeineCutoff.format24h(), '13:15');
      expect(result.windDown.format24h(), '20:30');
    });

    test('ca thức muộn vượt nửa đêm: thức 10:00, ngủ 7.5h, đệm 15p', () {
      final result = SleepPlanner.calculate(
        wakeTime: const ClockTime(10, 0),
        sleepHours: 7.5,
        fallAsleepBufferMin: 15,
      );

      expect(result.bedtime.format24h(), '02:15');
      expect(result.dinnerStop.format24h(), '23:15');
      expect(result.caffeineCutoff.format24h(), '18:15');
      expect(result.windDown.format24h(), '01:30');
    });

    test('ca đêm ngủ ban ngày: thức 16:00, ngủ 7.75h, đệm 15p => ngủ 08:00', () {
      final result = SleepPlanner.calculate(
        wakeTime: const ClockTime(16, 0),
        sleepHours: 7.75,
        fallAsleepBufferMin: 15,
        dinnerCutoffHours: 3.0,
        caffeineCutoffHours: 7.0,
        windDownMin: 45,
      );

      expect(result.bedtime.format24h(), '08:00');
      expect(result.dinnerStop.format24h(), '05:00');
      expect(result.caffeineCutoff.format24h(), '01:00');
      expect(result.windDown.format24h(), '07:15');
    });

    test('hiện cảnh báo nhẹ khi ngủ ngoài khoảng 7-9h và ăn tối muộn hơn dinnerStop', () {
      final result = SleepPlanner.calculate(
        wakeTime: const ClockTime(6, 30),
        sleepHours: 6.0,
        fallAsleepBufferMin: 15,
        dinnerTime: const ClockTime(22, 0),
      );

      expect(result.sleepDurationWarning, isNotNull);
      expect(result.dinnerTooLateWarning, isNotNull);
    });
  });
}
