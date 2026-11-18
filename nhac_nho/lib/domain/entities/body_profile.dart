// Entity BodyProfile lưu thông tin thể trạng, chế độ ăn, ca làm việc và tập gym.

enum Gender {
  male,
  female;

  static Gender fromString(String value) {
    return Gender.values.firstWhere(
      (e) => e.name == value,
      orElse: () => Gender.male,
    );
  }
}

enum ActivityLevel {
  sedentary(1.2),
  light(1.375),
  moderate(1.55),
  active(1.725);

  const ActivityLevel(this.multiplier);
  final double multiplier;

  static ActivityLevel fromString(String value) {
    return ActivityLevel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ActivityLevel.sedentary,
    );
  }
}

enum FitnessGoal {
  loseWeight,
  maintain,
  gainWeight;

  static FitnessGoal fromString(String value) {
    return FitnessGoal.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FitnessGoal.maintain,
    );
  }
}

enum HealthCondition {
  none,
  stomachReflux,
  bloodSugar,
  seniorCardio;

  static HealthCondition fromString(String value) {
    return HealthCondition.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HealthCondition.none,
    );
  }
}

enum DietType {
  omnivore,
  vegetarian,
  vegan;

  static DietType fromString(String value) {
    return DietType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DietType.omnivore,
    );
  }
}

enum WorkShift {
  dayShift,
  nightShift,
  rotatingShift;

  static WorkShift fromString(String value) {
    return WorkShift.values.firstWhere(
      (e) => e.name == value,
      orElse: () => WorkShift.dayShift,
    );
  }
}

enum DailyFocusMode {
  brainFocus('Tỉnh táo trí não'),
  staminaPhysical('Bền sức / Vận động'),
  leanAntiBloat('Nhẹ bụng / Giữ dáng'),
  digestiveComfort('Êm dịu tiêu hóa'),
  quickBudget('Nhanh gọn & Tiết kiệm');

  const DailyFocusMode(this.displayName);
  final String displayName;

  static DailyFocusMode fromString(String value) {
    return DailyFocusMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DailyFocusMode.brainFocus,
    );
  }
}

class BodyProfile {
  const BodyProfile({
    this.age = 25,
    this.gender = Gender.male,
    this.heightCm = 168.0,
    this.weightKg = 62.0,
    this.activityLevel = ActivityLevel.sedentary,
    this.goal = FitnessGoal.maintain,
    this.condition = HealthCondition.none,
    this.dietType = DietType.omnivore,
    this.workShift = WorkShift.dayShift,
    this.dailyFocusMode = DailyFocusMode.brainFocus,
    this.isGymGoer = false,
    this.workoutHour = 17,
    this.workoutMinute = 0,
  });

  final int age;
  final Gender gender;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activityLevel;
  final FitnessGoal goal;
  final HealthCondition condition;
  final DietType dietType;
  final WorkShift workShift;
  final DailyFocusMode dailyFocusMode;
  final bool isGymGoer;
  final int workoutHour;
  final int workoutMinute;

  BodyProfile copyWith({
    int? age,
    Gender? gender,
    double? heightCm,
    double? weightKg,
    ActivityLevel? activityLevel,
    FitnessGoal? goal,
    HealthCondition? condition,
    DietType? dietType,
    WorkShift? workShift,
    DailyFocusMode? dailyFocusMode,
    bool? isGymGoer,
    int? workoutHour,
    int? workoutMinute,
  }) {
    return BodyProfile(
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      condition: condition ?? this.condition,
      dietType: dietType ?? this.dietType,
      workShift: workShift ?? this.workShift,
      dailyFocusMode: dailyFocusMode ?? this.dailyFocusMode,
      isGymGoer: isGymGoer ?? this.isGymGoer,
      workoutHour: workoutHour ?? this.workoutHour,
      workoutMinute: workoutMinute ?? this.workoutMinute,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'age': age,
      'gender': gender.name,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'activityLevel': activityLevel.name,
      'goal': goal.name,
      'condition': condition.name,
      'dietType': dietType.name,
      'workShift': workShift.name,
      'dailyFocusMode': dailyFocusMode.name,
      'isGymGoer': isGymGoer,
      'workoutHour': workoutHour,
      'workoutMinute': workoutMinute,
    };
  }

  factory BodyProfile.fromMap(Map<String, Object?> map) {
    return BodyProfile(
      age: map['age'] as int? ?? 25,
      gender: Gender.fromString(map['gender'] as String? ?? 'male'),
      heightCm: (map['heightCm'] as num?)?.toDouble() ?? 168.0,
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 62.0,
      activityLevel: ActivityLevel.fromString(
        map['activityLevel'] as String? ?? 'sedentary',
      ),
      goal: FitnessGoal.fromString(map['goal'] as String? ?? 'maintain'),
      condition: HealthCondition.fromString(
        map['condition'] as String? ?? 'none',
      ),
      dietType: DietType.fromString(map['dietType'] as String? ?? 'omnivore'),
      workShift: WorkShift.fromString(
        map['workShift'] as String? ?? 'dayShift',
      ),
      dailyFocusMode: DailyFocusMode.fromString(
        map['dailyFocusMode'] as String? ?? 'brainFocus',
      ),
      isGymGoer: map['isGymGoer'] as bool? ?? false,
      workoutHour: map['workoutHour'] as int? ?? 17,
      workoutMinute: map['workoutMinute'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BodyProfile &&
        other.age == age &&
        other.gender == gender &&
        other.heightCm == heightCm &&
        other.weightKg == weightKg &&
        other.activityLevel == activityLevel &&
        other.goal == goal &&
        other.condition == condition &&
        other.dietType == dietType &&
        other.workShift == workShift &&
        other.dailyFocusMode == dailyFocusMode &&
        other.isGymGoer == isGymGoer &&
        other.workoutHour == workoutHour &&
        other.workoutMinute == workoutMinute;
  }

  @override
  int get hashCode => Object.hash(
    age,
    gender,
    heightCm,
    weightKg,
    activityLevel,
    goal,
    condition,
    dietType,
    workShift,
    dailyFocusMode,
    isGymGoer,
    workoutHour,
    workoutMinute,
  );
}
