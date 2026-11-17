// Unit test cho WorkMealGuide: 4 Bộ lịch mẫu (Presets) và lịch sinh hoạt cá nhân hóa.

import 'package:flutter_test/flutter_test.dart';
import 'package:nhac_nho/domain/entities/body_profile.dart';
import 'package:nhac_nho/domain/entities/preset_profile.dart';
import 'package:nhac_nho/domain/entities/reminder.dart';
import 'package:nhac_nho/domain/entities/user_settings.dart';
import 'package:nhac_nho/domain/logic/work_meal_guide.dart';

void main() {
  group('WorkMealGuide Presets', () {
    test('cung cấp đủ 4 bộ lịch mẫu với cả công việc và thói quen ăn/nước/ngủ', () {
      final presets = WorkMealGuide.getAllPresets();
      expect(presets.map((p) => p.id), [
        PresetId.officeCoder,
        PresetId.student,
        PresetId.freelancer,
        PresetId.seniorHealth,
      ]);

      for (final preset in presets) {
        expect(preset.reminders, isNotEmpty);
        expect(
          preset.reminders.any((r) => r.category == ReminderCategory.meal),
          isTrue,
        );
        expect(
          preset.reminders.any((r) => r.category == ReminderCategory.hydration),
          isTrue,
        );
        expect(
          preset.reminders.any((r) => r.category == ReminderCategory.sleep),
          isTrue,
        );
        expect(
          preset.reminders.any((r) => r.category == ReminderCategory.task),
          isTrue,
        );
      }
    });

    test('buildPersonalizedRoutineReminders sinh đủ bữa ăn, uống nước chu kỳ và ngủ', () {
      const settings = UserSettings(wakeTime: '06:30', sleepHours: 7.5);
      const profile = BodyProfile(
        dietType: DietType.vegetarian,
        isGymGoer: true,
        workoutHour: 17,
        workoutMinute: 30,
      );

      final routines = WorkMealGuide.buildPersonalizedRoutineReminders(
        settings: settings,
        profile: profile,
        createdAt: '2026-11-17T06:00:00Z',
      );

      expect(routines.every((r) => r.isRoutine), isTrue);
      expect(
        routines.any((r) => r.repeat == RepeatType.interval),
        isTrue,
      );
      expect(
        routines.any((r) => r.title.contains('Pre-workout')),
        isTrue,
      );
      expect(
        routines.any((r) => r.title.contains('Đi ngủ')),
        isTrue,
      );
    });
  });
}
