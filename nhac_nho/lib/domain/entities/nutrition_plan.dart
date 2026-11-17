// Entity NutritionPlan chứa kết quả phân tích BMI, TDEE, đạm, nước và lịch ăn.

import 'reminder.dart';

class MealRecommendation {
  const MealRecommendation({
    required this.hour,
    required this.minute,
    required this.title,
    required this.foodAdvice,
    this.category = ReminderCategory.meal,
  });

  final int hour;
  final int minute;
  final String title;
  final String foodAdvice;
  final ReminderCategory category;

  MealRecommendation copyWith({
    int? hour,
    int? minute,
    String? title,
    String? foodAdvice,
    ReminderCategory? category,
  }) {
    return MealRecommendation(
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      title: title ?? this.title,
      foodAdvice: foodAdvice ?? this.foodAdvice,
      category: category ?? this.category,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'hour': hour,
      'minute': minute,
      'title': title,
      'foodAdvice': foodAdvice,
      'category': category.name,
    };
  }

  factory MealRecommendation.fromMap(Map<String, Object?> map) {
    return MealRecommendation(
      hour: map['hour'] as int,
      minute: map['minute'] as int,
      title: map['title'] as String,
      foodAdvice: map['foodAdvice'] as String,
      category: ReminderCategory.fromString(
        map['category'] as String? ?? 'meal',
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MealRecommendation &&
        other.hour == hour &&
        other.minute == minute &&
        other.title == title &&
        other.foodAdvice == foodAdvice &&
        other.category == category;
  }

  @override
  int get hashCode => Object.hash(hour, minute, title, foodAdvice, category);
}

class NutritionPlan {
  const NutritionPlan({
    required this.bmi,
    required this.bmiCategory,
    required this.bmr,
    required this.tdee,
    required this.targetCalories,
    required this.dailyProteinGramsMin,
    required this.dailyProteinGramsMax,
    required this.plateRatioText,
    required this.dailyWaterMl,
    required this.waterIntervalMin,
    required this.waterStartHour,
    required this.waterStartMinute,
    required this.waterEndHour,
    required this.waterEndMinute,
    required this.recommendedDinnerCutoffHours,
    required this.recommendedCaffeineCutoffHours,
    required this.sleepAdviceNote,
    required this.mealScheduleRecommendations,
  });

  final double bmi;
  final String bmiCategory;
  final int bmr;
  final int tdee;
  final int targetCalories;
  final int dailyProteinGramsMin;
  final int dailyProteinGramsMax;
  final String plateRatioText;
  final int dailyWaterMl;
  final int waterIntervalMin;
  final int waterStartHour;
  final int waterStartMinute;
  final int waterEndHour;
  final int waterEndMinute;
  final double recommendedDinnerCutoffHours;
  final double recommendedCaffeineCutoffHours;
  final String sleepAdviceNote;
  final List<MealRecommendation> mealScheduleRecommendations;

  NutritionPlan copyWith({
    double? bmi,
    String? bmiCategory,
    int? bmr,
    int? tdee,
    int? targetCalories,
    int? dailyProteinGramsMin,
    int? dailyProteinGramsMax,
    String? plateRatioText,
    int? dailyWaterMl,
    int? waterIntervalMin,
    int? waterStartHour,
    int? waterStartMinute,
    int? waterEndHour,
    int? waterEndMinute,
    double? recommendedDinnerCutoffHours,
    double? recommendedCaffeineCutoffHours,
    String? sleepAdviceNote,
    List<MealRecommendation>? mealScheduleRecommendations,
  }) {
    return NutritionPlan(
      bmi: bmi ?? this.bmi,
      bmiCategory: bmiCategory ?? this.bmiCategory,
      bmr: bmr ?? this.bmr,
      tdee: tdee ?? this.tdee,
      targetCalories: targetCalories ?? this.targetCalories,
      dailyProteinGramsMin: dailyProteinGramsMin ?? this.dailyProteinGramsMin,
      dailyProteinGramsMax: dailyProteinGramsMax ?? this.dailyProteinGramsMax,
      plateRatioText: plateRatioText ?? this.plateRatioText,
      dailyWaterMl: dailyWaterMl ?? this.dailyWaterMl,
      waterIntervalMin: waterIntervalMin ?? this.waterIntervalMin,
      waterStartHour: waterStartHour ?? this.waterStartHour,
      waterStartMinute: waterStartMinute ?? this.waterStartMinute,
      waterEndHour: waterEndHour ?? this.waterEndHour,
      waterEndMinute: waterEndMinute ?? this.waterEndMinute,
      recommendedDinnerCutoffHours:
          recommendedDinnerCutoffHours ?? this.recommendedDinnerCutoffHours,
      recommendedCaffeineCutoffHours:
          recommendedCaffeineCutoffHours ??
          this.recommendedCaffeineCutoffHours,
      sleepAdviceNote: sleepAdviceNote ?? this.sleepAdviceNote,
      mealScheduleRecommendations:
          mealScheduleRecommendations ?? this.mealScheduleRecommendations,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'bmi': bmi,
      'bmiCategory': bmiCategory,
      'bmr': bmr,
      'tdee': tdee,
      'targetCalories': targetCalories,
      'dailyProteinGramsMin': dailyProteinGramsMin,
      'dailyProteinGramsMax': dailyProteinGramsMax,
      'plateRatioText': plateRatioText,
      'dailyWaterMl': dailyWaterMl,
      'waterIntervalMin': waterIntervalMin,
      'waterStartHour': waterStartHour,
      'waterStartMinute': waterStartMinute,
      'waterEndHour': waterEndHour,
      'waterEndMinute': waterEndMinute,
      'recommendedDinnerCutoffHours': recommendedDinnerCutoffHours,
      'recommendedCaffeineCutoffHours': recommendedCaffeineCutoffHours,
      'sleepAdviceNote': sleepAdviceNote,
      'mealScheduleRecommendations': mealScheduleRecommendations
          .map((e) => e.toMap())
          .toList(),
    };
  }

  factory NutritionPlan.fromMap(Map<String, Object?> map) {
    final rawMeals = map['mealScheduleRecommendations'] as List<dynamic>? ?? [];
    return NutritionPlan(
      bmi: (map['bmi'] as num).toDouble(),
      bmiCategory: map['bmiCategory'] as String,
      bmr: map['bmr'] as int,
      tdee: map['tdee'] as int,
      targetCalories: map['targetCalories'] as int,
      dailyProteinGramsMin: map['dailyProteinGramsMin'] as int,
      dailyProteinGramsMax: map['dailyProteinGramsMax'] as int,
      plateRatioText: map['plateRatioText'] as String,
      dailyWaterMl: map['dailyWaterMl'] as int,
      waterIntervalMin: map['waterIntervalMin'] as int,
      waterStartHour: map['waterStartHour'] as int,
      waterStartMinute: map['waterStartMinute'] as int,
      waterEndHour: map['waterEndHour'] as int,
      waterEndMinute: map['waterEndMinute'] as int,
      recommendedDinnerCutoffHours:
          (map['recommendedDinnerCutoffHours'] as num).toDouble(),
      recommendedCaffeineCutoffHours:
          (map['recommendedCaffeineCutoffHours'] as num).toDouble(),
      sleepAdviceNote: map['sleepAdviceNote'] as String,
      mealScheduleRecommendations: rawMeals
          .map((e) => MealRecommendation.fromMap(Map<String, Object?>.from(e as Map)))
          .toList(),
    );
  }
}
