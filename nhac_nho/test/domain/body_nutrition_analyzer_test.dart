// Unit test cho BodyNutritionAnalyzer (mục 6.5).

import 'package:flutter_test/flutter_test.dart';
import 'package:nhac_nho/domain/entities/body_profile.dart';
import 'package:nhac_nho/domain/logic/body_nutrition_analyzer.dart';
import 'package:nhac_nho/domain/logic/sleep_planner.dart';

void main() {
  group('BodyNutritionAnalyzer', () {
    test('ca giảm cân: trừ 400 kcal (min 1200), dinnerCutoff 3.5h, ăn ngược & đi bộ sau tối', () {
      const profile = BodyProfile(
        age: 28,
        gender: Gender.male,
        heightCm: 170,
        weightKg: 74, // BMI = 25.6 (Béo phì chuẩn Châu Á)
        activityLevel: ActivityLevel.light,
        goal: FitnessGoal.loseWeight,
        condition: HealthCondition.none,
      );

      final plan = BodyNutritionAnalyzer.analyze(
        profile,
        wakeTime: const ClockTime(6, 30),
        bedtime: const ClockTime(22, 45),
      );

      expect(plan.bmi, 25.6);
      expect(plan.bmiCategory, 'Béo phì');
      // BMR = 10*74 + 6.25*170 - 5*28 + 5 = 740 + 1062.5 - 140 + 5 = 1667.5 -> 1668
      expect(plan.bmr, 1668);
      // TDEE = round(1667.5 * 1.375) = 2293
      expect(plan.tdee, 2293);
      expect(plan.targetCalories, 1893);
      expect(plan.recommendedDinnerCutoffHours, 3.5);
      expect(
        plan.mealScheduleRecommendations.any(
          (m) => m.title.contains('Đi bộ nhẹ'),
        ),
        isTrue,
      );
      expect(
        plan.mealScheduleRecommendations.any(
          (m) => m.foodAdvice.contains('Quy tắc ăn ngược'),
        ),
        isTrue,
      );
    });

    test('ca tăng cân: cộng 350 kcal và có bữa phụ sáng/chiều giàu năng lượng', () {
      const profile = BodyProfile(
        age: 22,
        gender: Gender.female,
        heightCm: 162,
        weightKg: 46, // BMI = 17.5 (Thiếu cân)
        activityLevel: ActivityLevel.sedentary,
        goal: FitnessGoal.gainWeight,
      );

      final plan = BodyNutritionAnalyzer.analyze(
        profile,
        wakeTime: const ClockTime(7, 0),
        bedtime: const ClockTime(23, 0),
      );

      expect(plan.bmiCategory, 'Thiếu cân');
      expect(plan.targetCalories, plan.tdee + 350);
      expect(
        plan.mealScheduleRecommendations.any(
          (m) => m.hour == 9 && m.minute == 30,
        ),
        isTrue,
      );
      expect(
        plan.mealScheduleRecommendations.any(
          (m) => m.hour == 15 && m.minute == 30,
        ),
        isTrue,
      );
    });

    test('ca đau dạ dày trào ngược: dinnerCutoff 4.0h, sáng ấm mềm và 2 bữa phụ', () {
      const profile = BodyProfile(
        age: 35,
        gender: Gender.male,
        heightCm: 168,
        weightKg: 62,
        condition: HealthCondition.stomachReflux,
      );

      final plan = BodyNutritionAnalyzer.analyze(
        profile,
        wakeTime: const ClockTime(6, 30),
        bedtime: const ClockTime(22, 45),
      );

      expect(plan.recommendedDinnerCutoffHours, 4.0);
      final breakfast = plan.mealScheduleRecommendations.first;
      expect(breakfast.foodAdvice, contains('ấm mềm'));
      expect(
        plan.mealScheduleRecommendations.any(
          (m) => m.hour == 10 && m.minute == 0,
        ),
        isTrue,
      );
      expect(
        plan.mealScheduleRecommendations.any(
          (m) => m.hour == 15 && m.minute == 30,
        ),
        isTrue,
      );
    });

    test('ca kiểm soát đường huyết: dinnerCutoff 3.5h, ăn ngược & đi bộ sau tối', () {
      const profile = BodyProfile(
        age: 50,
        gender: Gender.female,
        heightCm: 158,
        weightKg: 58,
        condition: HealthCondition.bloodSugar,
      );

      final plan = BodyNutritionAnalyzer.analyze(
        profile,
        wakeTime: const ClockTime(6, 0),
        bedtime: const ClockTime(22, 0),
      );

      expect(plan.recommendedDinnerCutoffHours, 3.5);
      expect(
        plan.mealScheduleRecommendations.any(
          (m) => m.title.contains('Đi bộ nhẹ'),
        ),
        isTrue,
      );
    });

    test('ca người lớn tuổi: ăn tối sớm, ngừng uống nước 19:30 tránh tiểu đêm', () {
      const profile = BodyProfile(
        age: 68,
        gender: Gender.male,
        heightCm: 165,
        weightKg: 60,
        condition: HealthCondition.seniorCardio,
      );

      final plan = BodyNutritionAnalyzer.analyze(
        profile,
        wakeTime: const ClockTime(5, 30),
        bedtime: const ClockTime(21, 30),
      );

      expect(plan.waterEndHour, 19);
      expect(plan.waterEndMinute, 30);
      final dinner = plan.mealScheduleRecommendations.firstWhere(
        (m) => m.title.contains('Bữa tối'),
      );
      expect(dinner.hour, 17);
      expect(dinner.minute, 45);
      expect(dinner.foodAdvice, contains('giảm muối'));
    });

    test('ca ăn thuần chay (vegan): chỉ dùng đạm thực vật và nhắc Vitamin C', () {
      const profile = BodyProfile(
        dietType: DietType.vegan,
      );

      final plan = BodyNutritionAnalyzer.analyze(
        profile,
        wakeTime: const ClockTime(6, 30),
        bedtime: const ClockTime(22, 45),
      );

      final joinedAdvice = plan.mealScheduleRecommendations
          .map((m) => m.foodAdvice.toLowerCase())
          .join(' ');
      expect(joinedAdvice, contains('đậu phụ'));
      expect(joinedAdvice, contains('vitamin c'));
      expect(joinedAdvice, isNot(contains('ức gà')));
      expect(joinedAdvice, isNot(contains('trứng')));
    });

    test('ca tập gym: +600ml nước, đạm 1.6-2.2g/kg, thêm Pre & Post workout', () {
      const profile = BodyProfile(
        weightKg: 70,
        activityLevel: ActivityLevel.moderate,
        isGymGoer: true,
        workoutHour: 17,
        workoutMinute: 30,
      );

      final plan = BodyNutritionAnalyzer.analyze(
        profile,
        wakeTime: const ClockTime(6, 30),
        bedtime: const ClockTime(22, 45),
      );

      // 70*35 + 400 + 600 = 2450 + 1000 = 3450ml
      expect(plan.dailyWaterMl, 3450);
      expect(plan.dailyProteinGramsMin, (70 * 1.6).round());
      expect(plan.dailyProteinGramsMax, (70 * 2.2).round());

      final pre = plan.mealScheduleRecommendations.firstWhere(
        (m) => m.title.contains('Pre-workout'),
      );
      final post = plan.mealScheduleRecommendations.firstWhere(
        (m) => m.title.contains('Post-workout'),
      );
      // 17:30 - 75p = 16:15; 17:30 + 75p = 18:45
      expect(ClockTime(pre.hour, pre.minute).format24h(), '16:15');
      expect(ClockTime(post.hour, post.minute).format24h(), '18:45');
    });

    test('ca đêm thức lúc 16:00 ngủ lúc 08:00: tính giờ ăn neo theo wakeTime/bedtime vượt nửa đêm', () {
      const profile = BodyProfile(
        workShift: WorkShift.nightShift,
      );

      final plan = BodyNutritionAnalyzer.analyze(
        profile,
        wakeTime: const ClockTime(16, 0),
        bedtime: const ClockTime(8, 0),
      );

      expect(plan.recommendedCaffeineCutoffHours, 7.0);
      expect(plan.sleepAdviceNote, contains('Ca đêm'));
      expect(plan.waterStartHour, 16);
      expect(plan.waterStartMinute, 15);
      expect(plan.waterEndHour, 6);
      expect(plan.waterEndMinute, 30);

      final times = plan.mealScheduleRecommendations
          .map((m) => ClockTime(m.hour, m.minute).format24h())
          .toList();
      // 16:00+45p=16:45; 16:00+5h30=21:30; 16:00+9h=01:00; 08:00-2h30=05:30
      expect(times, ['16:45', '21:30', '01:00', '05:30']);
    });
  });
}
