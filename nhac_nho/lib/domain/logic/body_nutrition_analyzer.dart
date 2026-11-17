// Logic thuần Dart phân tích thể trạng, chế độ ăn, ca làm việc và lịch tập gym.

import 'dart:math' as math;

import '../entities/body_profile.dart';
import '../entities/nutrition_plan.dart';
import '../entities/reminder.dart';
import 'sleep_planner.dart';

class BodyNutritionAnalyzer {
  const BodyNutritionAnalyzer._();

  static NutritionPlan analyze(
    BodyProfile profile, {
    required ClockTime wakeTime,
    required ClockTime bedtime,
  }) {
    final heightM = profile.heightCm / 100.0;
    final bmiRaw = profile.weightKg / (heightM * heightM);
    final bmi = double.parse(bmiRaw.toStringAsFixed(1));
    final bmiCategory = _classifyAsianBmi(bmi);

    final bmrRaw = profile.gender == Gender.male
        ? (10 * profile.weightKg +
            6.25 * profile.heightCm -
            5 * profile.age +
            5)
        : (10 * profile.weightKg +
            6.25 * profile.heightCm -
            5 * profile.age -
            161);
    final bmr = bmrRaw.round();
    final tdee = (bmrRaw * profile.activityLevel.multiplier).round();

    final targetCalories = switch (profile.goal) {
      FitnessGoal.loseWeight => math.max(1200, tdee - 400),
      FitnessGoal.maintain => tdee,
      FitnessGoal.gainWeight => tdee + 350,
    };

    final proteinMin =
        ((profile.isGymGoer ? 1.6 : 1.0) * profile.weightKg).round();
    final proteinMax =
        ((profile.isGymGoer ? 2.2 : 1.3) * profile.weightKg).round();

    final plateRatioText = _buildPlateRatioText(profile);

    final activityWaterBonus =
        (profile.activityLevel == ActivityLevel.moderate ||
                profile.activityLevel == ActivityLevel.active)
            ? 400
            : 0;
    final gymWaterBonus = profile.isGymGoer ? 600 : 0;
    final dailyWaterMl =
        (profile.weightKg * 35).round() + activityWaterBonus + gymWaterBonus;

    final timesPerDay = (dailyWaterMl / 220.0).clamp(6.0, 12.0);
    final rawInterval = ((780.0 / timesPerDay) / 15.0).round() * 15;
    final adjustedInterval =
        profile.isGymGoer ? rawInterval - 15 : rawInterval;
    final waterIntervalMin = adjustedInterval.clamp(45, 150);

    final isNightSchedule = profile.workShift == WorkShift.nightShift ||
        (profile.workShift == WorkShift.rotatingShift &&
            wakeTime.hour >= 13 &&
            wakeTime.hour <= 21);

    final waterStart = wakeTime.addMinutes(isNightSchedule ? 15 : 5);
    var waterEnd = bedtime.subtractMinutes(isNightSchedule ? 90 : 120);
    if (!isNightSchedule &&
        (profile.condition == HealthCondition.seniorCardio ||
            profile.age >= 60)) {
      waterEnd = const ClockTime(19, 30);
    }

    final recommendedDinnerCutoffHours = _resolveDinnerCutoff(profile);
    final recommendedCaffeineCutoffHours = isNightSchedule ? 7.0 : 8.0;
    final sleepAdviceNote = _buildSleepAdviceNote(profile, isNightSchedule);

    final recommendations = _buildMealRecommendations(
      profile: profile,
      wakeTime: wakeTime,
      bedtime: bedtime,
      isNightSchedule: isNightSchedule,
      dinnerCutoffHours: recommendedDinnerCutoffHours,
    );

    return NutritionPlan(
      bmi: bmi,
      bmiCategory: bmiCategory,
      bmr: bmr,
      tdee: tdee,
      targetCalories: targetCalories,
      dailyProteinGramsMin: proteinMin,
      dailyProteinGramsMax: proteinMax,
      plateRatioText: plateRatioText,
      dailyWaterMl: dailyWaterMl,
      waterIntervalMin: waterIntervalMin,
      waterStartHour: waterStart.hour,
      waterStartMinute: waterStart.minute,
      waterEndHour: waterEnd.hour,
      waterEndMinute: waterEnd.minute,
      recommendedDinnerCutoffHours: recommendedDinnerCutoffHours,
      recommendedCaffeineCutoffHours: recommendedCaffeineCutoffHours,
      sleepAdviceNote: sleepAdviceNote,
      mealScheduleRecommendations: recommendations,
    );
  }

  static String _classifyAsianBmi(double bmi) {
    if (bmi < 18.5) return 'Thiếu cân';
    if (bmi < 23.0) return 'Cân đối';
    if (bmi < 25.0) return 'Thừa cân';
    return 'Béo phì';
  }

  static double _resolveDinnerCutoff(BodyProfile profile) {
    if (profile.condition == HealthCondition.stomachReflux) {
      return 4.0;
    }
    if (profile.goal == FitnessGoal.loseWeight ||
        profile.condition == HealthCondition.bloodSugar) {
      return 3.5;
    }
    return 3.0;
  }

  static String _buildPlateRatioText(BodyProfile profile) {
    if (profile.goal == FitnessGoal.loseWeight ||
        profile.condition == HealthCondition.bloodSugar) {
      return '1/2 rau xanh · 1/4 đạm · 1/4 tinh bột chậm (ăn rau trước)';
    }
    if (profile.goal == FitnessGoal.gainWeight) {
      return '1/3 rau củ · 1/3 đạm · 1/3 tinh bột phức hợp';
    }
    return '1/2 rau xanh & củ quả · 1/4 đạm · 1/4 tinh bột vừa phải';
  }

  static String _buildSleepAdviceNote(
    BodyProfile profile,
    bool isNightSchedule,
  ) {
    if (isNightSchedule) {
      return 'Ca đêm ngủ ban ngày: Đeo kính râm khi tan ca tránh nắng gắt, '
          'kéo rèm cản sáng tuyệt đối (Blackout) và giữ phòng mát 24–26°C.';
    }
    if (profile.condition == HealthCondition.stomachReflux) {
      return 'Kê cao gối đầu nhẹ 10–15 cm nếu dễ trào ngược, không nằm ngay sau ăn.';
    }
    return 'Tắt màn hình xanh trước ngủ 45 phút, giữ phòng tối và yên tĩnh.';
  }

  static List<MealRecommendation> _buildMealRecommendations({
    required BodyProfile profile,
    required ClockTime wakeTime,
    required ClockTime bedtime,
    required bool isNightSchedule,
    required double dinnerCutoffHours,
  }) {
    final items = <MealRecommendation>[];
    final proteinFood = _proteinSources(profile.dietType);
    final veganIronTip = profile.dietType == DietType.vegan
        ? ' Kết hợp thực phẩm giàu Vitamin C (ớt chuông, bông cải xanh, ổi, cam) để hấp thu sắt tốt hơn; hạn chế uống trà đậm ngay sau ăn.'
        : '';

    if (isNightSchedule) {
      final meal1 = wakeTime.addMinutes(45);
      final meal2 = wakeTime.addMinutes(5 * 60 + 30);
      final lateSnack = wakeTime.addMinutes(9 * 60);
      final beforeSleepMin = dinnerCutoffHours > 3.0
          ? (dinnerCutoffHours * 60).round()
          : 150;
      final meal3 = bedtime.subtractMinutes(beforeSleepMin);

      final meal1Advice = profile.condition == HealthCondition.stomachReflux
          ? _breakfastAdvice(profile, proteinFood)
          : 'Bữa chính đủ năng lượng trước ca: Tinh bột chậm (gạo lứt, khoai lang, yến mạch) + '
              '$proteinFood + rau xanh.$veganIronTip';

      final meal2Prefix = (profile.goal == FitnessGoal.loseWeight ||
              profile.condition == HealthCondition.bloodSugar)
          ? 'Quy tắc ăn ngược: Rau xanh trước -> Đạm ($proteinFood) -> Tinh bột chậm sau cùng. '
          : '';

      items.addAll([
        MealRecommendation(
          hour: meal1.hour,
          minute: meal1.minute,
          title: 'Bữa 1 – Khởi đầu ca làm việc',
          foodAdvice: meal1Advice,
        ),
        MealRecommendation(
          hour: meal2.hour,
          minute: meal2.minute,
          title: 'Bữa 2 – Bữa chính giữa ca đêm',
          foodAdvice:
              '$meal2PrefixĂn bữa ấm nóng vừa bụng: Cơm mềm/súp + $proteinFood + rau củ luộc. '
              'Tránh đồ chiên rán nhiều dầu mỡ gây nặng bụng.$veganIronTip',
        ),
        MealRecommendation(
          hour: lateSnack.hour,
          minute: lateSnack.minute,
          title: profile.goal == FitnessGoal.gainWeight
              ? 'Bữa phụ rạng sáng tăng năng lượng'
              : 'Bữa phụ rạng sáng (Dưới 200 kcal)',
          foodAdvice: profile.goal == FitnessGoal.gainWeight
              ? _gainSnackAdvice(profile.dietType)
              : _lightSnackAdvice(profile.dietType),
        ),
        MealRecommendation(
          hour: meal3.hour,
          minute: meal3.minute,
          title: 'Bữa 3 – Bữa nhẹ trước khi ngủ ban ngày',
          foodAdvice: _beforeDaySleepAdvice(profile.dietType),
        ),
      ]);

      if (profile.goal == FitnessGoal.loseWeight ||
          profile.condition == HealthCondition.bloodSugar) {
        final walkTime = meal3.addMinutes(30);
        items.add(
          MealRecommendation(
            hour: walkTime.hour,
            minute: walkTime.minute,
            title: 'Đi bộ nhẹ 10–15 phút sau bữa cuối ca',
            foodAdvice:
                'Vận động nhẹ giúp ổn định đường huyết trước khi về nghỉ.',
            category: ReminderCategory.hydration,
          ),
        );
      }
    } else {
      final breakfast = wakeTime.addMinutes(30);
      final isSenior = profile.condition == HealthCondition.seniorCardio ||
          profile.age >= 60;
      final lunch =
          isSenior ? const ClockTime(11, 30) : const ClockTime(12, 0);
      var dinner =
          isSenior ? const ClockTime(17, 45) : const ClockTime(18, 30);

      // Ensure dinner respects dinnerStop on the daytime timeline.
      final dinnerStop =
          bedtime.subtractMinutes((dinnerCutoffHours * 60).round());
      if (SleepPlanner.isDinnerAfterCutoff(
        wakeTime: wakeTime,
        dinnerTime: dinner,
        dinnerStop: dinnerStop,
      )) {
        dinner = dinnerStop;
      }

      items.add(
        MealRecommendation(
          hour: breakfast.hour,
          minute: breakfast.minute,
          title: 'Bữa sáng cân bằng',
          foodAdvice: _breakfastAdvice(profile, proteinFood) + veganIronTip,
        ),
      );

      if (profile.condition == HealthCondition.stomachReflux) {
        items.add(
          MealRecommendation(
            hour: 10,
            minute: 0,
            title: 'Bữa phụ sáng dịu dạ dày',
            foodAdvice: _stomachSnackAdvice(profile.dietType),
          ),
        );
      } else if (profile.goal == FitnessGoal.gainWeight) {
        items.add(
          MealRecommendation(
            hour: 9,
            minute: 30,
            title: 'Bữa phụ sáng tăng năng lượng',
            foodAdvice: _gainSnackAdvice(profile.dietType),
          ),
        );
      }

      items.add(
        MealRecommendation(
          hour: lunch.hour,
          minute: lunch.minute,
          title: 'Bữa trưa chuẩn đĩa ăn',
          foodAdvice: _mainMealAdvice(profile, proteinFood, isDinner: false) +
              veganIronTip,
        ),
      );

      if (profile.condition == HealthCondition.stomachReflux) {
        items.add(
          MealRecommendation(
            hour: 15,
            minute: 30,
            title: 'Bữa phụ chiều trung hòa axit',
            foodAdvice: _stomachSnackAdvice(profile.dietType),
          ),
        );
      } else if (profile.goal == FitnessGoal.gainWeight) {
        items.add(
          MealRecommendation(
            hour: 15,
            minute: 30,
            title: 'Bữa phụ chiều giàu dinh dưỡng',
            foodAdvice: _gainSnackAdvice(profile.dietType),
          ),
        );
      } else {
        items.add(
          MealRecommendation(
            hour: 16,
            minute: 0,
            title: 'Bữa phụ chiều nhẹ',
            foodAdvice: _afternoonSnackAdvice(profile.dietType),
          ),
        );
      }

      items.add(
        MealRecommendation(
          hour: dinner.hour,
          minute: dinner.minute,
          title: 'Bữa tối nhẹ bụng',
          foodAdvice: _mainMealAdvice(profile, proteinFood, isDinner: true) +
              veganIronTip,
        ),
      );

      if (profile.goal == FitnessGoal.loseWeight ||
          profile.condition == HealthCondition.bloodSugar) {
        final walkTime = dinner.addMinutes(30);
        items.add(
          MealRecommendation(
            hour: walkTime.hour,
            minute: walkTime.minute,
            title: 'Đi bộ nhẹ 10–15 phút sau ăn tối',
            foodAdvice:
                'Vận động nhẹ giúp ổn định đường huyết sau ăn và hỗ trợ tiêu hóa.',
            category: ReminderCategory.hydration,
          ),
        );
      }
    }

    if (profile.isGymGoer) {
      final workoutTime = ClockTime(profile.workoutHour, profile.workoutMinute);
      final preWorkout = workoutTime.subtractMinutes(75);
      final postWorkout = workoutTime.addMinutes(75);

      items.addAll([
        MealRecommendation(
          hour: preWorkout.hour,
          minute: preWorkout.minute,
          title: 'Bữa phụ trước tập (Pre-workout)',
          foodAdvice: _preWorkoutAdvice(profile.dietType),
        ),
        MealRecommendation(
          hour: postWorkout.hour,
          minute: postWorkout.minute,
          title: 'Bổ sung Đạm & Nước sau tập (Post-workout)',
          foodAdvice: _postWorkoutAdvice(profile.dietType),
        ),
      ]);
    }

    return items;
  }

  static String _proteinSources(DietType dietType) {
    return switch (dietType) {
      DietType.omnivore => 'ức gà, cá hồi/cá thu, thịt nạc, trứng hoặc đậu phụ',
      DietType.vegetarian =>
        'đậu phụ, nấm đùi gà/nấm hương, đậu lăng, đậu gà, trứng gà hoặc sữa chua Hy Lạp',
      DietType.vegan =>
        'đậu phụ, tempeh, đậu gà, đậu lăng, đậu đen, nấm kết hợp gạo lứt/ngũ cốc nguyên cám',
    };
  }

  static String _breakfastAdvice(BodyProfile profile, String proteinFood) {
    if (profile.condition == HealthCondition.stomachReflux) {
      return switch (profile.dietType) {
        DietType.omnivore =>
          'Ăn đồ ấm mềm trong 30–45p sau khi thức (cháo yến mạch, súp ấm, bánh mì kèm trứng). '
              'Tránh đồ chua cay và cà phê lúc bụng đói.',
        DietType.vegetarian =>
          'Ăn đồ ấm mềm (cháo yến mạch, súp nấm, bánh mì nguyên cám kèm trứng mềm). '
              'Tránh đồ chua cay và cà phê lúc bụng đói.',
        DietType.vegan =>
          'Ăn đồ ấm mềm (cháo yến mạch đậu lăng, súp bí đỏ nấm, sữa đậu nành ấm). '
              'Tránh đồ chua cay và cà phê lúc bụng đói.',
      };
    }

    return switch (profile.dietType) {
      DietType.omnivore =>
        'Tinh bột chậm + Đạm + Chất xơ: Trứng, yến mạch, khoai lang, bánh mì nguyên cám hoặc phở/bún ít béo thêm rau.',
      DietType.vegetarian =>
        'Yến mạch nấu sữa hoặc sữa chua Hy Lạp, trứng luộc, bánh mì nguyên cám cùng hạt điều/óc chó và trái cây ít ngọt.',
      DietType.vegan =>
        'Yến mạch với sữa đậu nành không đường, hạt chia, bơ đậu phộng và bánh mì nguyên cám kèm rau củ.',
    };
  }

  static String _mainMealAdvice(
    BodyProfile profile,
    String proteinFood, {
    required bool isDinner,
  }) {
    final prefix = (profile.goal == FitnessGoal.loseWeight ||
            profile.condition == HealthCondition.bloodSugar)
        ? 'Quy tắc ăn ngược: Ăn rau xanh trước -> Đạm ($proteinFood) -> Tinh bột chậm ăn cuối cùng. '
        : '';

    if (profile.condition == HealthCondition.seniorCardio ||
        profile.age >= 60) {
      final base =
          'Ăn nhạt, giảm muối và dầu mỡ; ưu tiên $proteinFood, rau củ luộc mềm, canh ấm.';
      return isDinner
          ? '$prefix$base Hạn chế uống nhiều nước sau 19:30 để tránh tiểu đêm.'
          : '$prefix$base';
    }

    if (isDinner) {
      return '$prefixƯu tiên nhẹ bụng, dễ tiêu: $proteinFood kèm rau luộc/canh ấm, ít cơm; tránh đồ chiên rán hoặc quá no.';
    }
    return '$prefixĐĩa ăn cân bằng: 1/2 rau xanh củ quả, 1/4 đạm ($proteinFood), 1/4 cơm gạo lứt/tinh bột chậm.';
  }

  static String _stomachSnackAdvice(DietType dietType) {
    return switch (dietType) {
      DietType.omnivore =>
        'Bánh quy lạt, chuối chín, cháo loãng hoặc sữa chua ít chua để êm dạ dày.',
      DietType.vegetarian =>
        'Bánh quy yến mạch lạt, chuối chín hoặc sữa chua Hy Lạp ít đường.',
      DietType.vegan =>
        'Chuối chín, bánh mì yến mạch lạt hoặc sữa hạnh nhân/đậu nành ấm.',
    };
  }

  static String _gainSnackAdvice(DietType dietType) {
    return switch (dietType) {
      DietType.omnivore =>
        'Sữa tươi/sữa hạt, chuối, quả bơ, khoai lang, trứng luộc hoặc các loại hạt.',
      DietType.vegetarian =>
        'Sữa chua Hy Lạp, phô mai ít béo, chuối, bơ, trứng luộc và hạt óc chó/hạnh nhân.',
      DietType.vegan =>
        'Sinh tố chuối bơ đậu phộng với sữa đậu nành, khoai lang, hạt chia và hạt điều.',
    };
  }

  static String _afternoonSnackAdvice(DietType dietType) {
    return switch (dietType) {
      DietType.omnivore =>
        '1 hũ sữa chua không đường, 1 nắm hạt (hạnh nhân, óc chó) hoặc trái cây ít ngọt (táo, ổi).',
      DietType.vegetarian =>
        'Sữa chua Hy Lạp không đường, 1 nắm hạt điều/óc chó hoặc trái cây ít ngọt.',
      DietType.vegan =>
        'Sữa đậu nành không đường, 1 nắm hạt (hạnh nhân, hạt bí, óc chó) hoặc ổi/táo.',
    };
  }

  static String _lightSnackAdvice(DietType dietType) {
    return switch (dietType) {
      DietType.omnivore || DietType.vegetarian =>
        'Chống đói nhẹ dưới 200 kcal (01:00–04:00 hạn chế tiêu hóa): 1 nắm hạt nhỏ, sữa chua ấm hoặc nửa quả táo.',
      DietType.vegan =>
        'Chống đói nhẹ dưới 200 kcal: 1 nắm hạt óc chó/hạnh nhân nhỏ, nửa quả táo hoặc sữa hạt ấm.',
    };
  }

  static String _beforeDaySleepAdvice(DietType dietType) {
    return switch (dietType) {
      DietType.omnivore =>
        'Ăn nhẹ dễ tiêu trước khi ngủ ban ngày: Cháo ấm, yến mạch, sữa ấm hoặc 1 quả chuối.',
      DietType.vegetarian =>
        'Ăn nhẹ dễ tiêu: Cháo yến mạch ấm, sữa ấm hoặc chuối chín.',
      DietType.vegan =>
        'Ăn nhẹ dễ tiêu: Cháo yến mạch ấm, sữa đậu nành/hạnh nhân ấm và chuối.',
    };
  }

  static String _preWorkoutAdvice(DietType dietType) {
    return switch (dietType) {
      DietType.omnivore =>
        'Trước tập 60–90p: Tinh bột tiêu hóa vừa + đạm nhẹ (khoai lang, chuối, yến mạch hoặc bánh mì kèm trứng) để giữ sức bền.',
      DietType.vegetarian =>
        'Trước tập 60–90p: Chuối, yến mạch, khoai lang hoặc bánh mì nguyên cám kèm trứng/sữa chua.',
      DietType.vegan =>
        'Trước tập 60–90p: Chuối, khoai lang, yến mạch kèm bơ đậu phộng hoặc sữa đậu nành để ổn định đường huyết.',
    };
  }

  static String _postWorkoutAdvice(DietType dietType) {
    return switch (dietType) {
      DietType.omnivore =>
        'Sau tập: Bù nước điện giải + đạm phục hồi cơ (ức gà, cá, trứng, sữa chua Hy Lạp) kèm tinh bột vừa phải.',
      DietType.vegetarian =>
        'Sau tập: Bù nước + đạm phục hồi cơ (trứng, sữa chua Hy Lạp, đậu phụ áp chảo, nấm, đậu lăng).',
      DietType.vegan =>
        'Sau tập: Bù nước + đạm thực vật hoàn chỉnh (đậu phụ/tempeh + cơm gạo lứt, đậu gà, sữa đậu nành giàu đạm).',
    };
  }
}
