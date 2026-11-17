// Entity UserSettings lưu cấu hình mặc định của người dùng.

class UserSettings {
  const UserSettings({
    this.selectedPreset = 'office_coder',
    this.wakeTime = '06:30',
    this.sleepHours = 7.5,
    this.fallAsleepBufferMin = 15,
    this.breakfastTime = '07:00',
    this.lunchTime = '12:00',
    this.afternoonSnackTime = '16:00',
    this.dinnerTime = '18:30',
    this.dinnerCutoffHours = 3.0,
    this.caffeineCutoffHours = 8.0,
    this.windDownMin = 45,
    this.waterIntervalMin = 120,
  });

  final String selectedPreset;
  final String wakeTime;
  final double sleepHours;
  final int fallAsleepBufferMin;
  final String breakfastTime;
  final String lunchTime;
  final String afternoonSnackTime;
  final String dinnerTime;
  final double dinnerCutoffHours;
  final double caffeineCutoffHours;
  final int windDownMin;
  final int waterIntervalMin;

  UserSettings copyWith({
    String? selectedPreset,
    String? wakeTime,
    double? sleepHours,
    int? fallAsleepBufferMin,
    String? breakfastTime,
    String? lunchTime,
    String? afternoonSnackTime,
    String? dinnerTime,
    double? dinnerCutoffHours,
    double? caffeineCutoffHours,
    int? windDownMin,
    int? waterIntervalMin,
  }) {
    return UserSettings(
      selectedPreset: selectedPreset ?? this.selectedPreset,
      wakeTime: wakeTime ?? this.wakeTime,
      sleepHours: sleepHours ?? this.sleepHours,
      fallAsleepBufferMin: fallAsleepBufferMin ?? this.fallAsleepBufferMin,
      breakfastTime: breakfastTime ?? this.breakfastTime,
      lunchTime: lunchTime ?? this.lunchTime,
      afternoonSnackTime: afternoonSnackTime ?? this.afternoonSnackTime,
      dinnerTime: dinnerTime ?? this.dinnerTime,
      dinnerCutoffHours: dinnerCutoffHours ?? this.dinnerCutoffHours,
      caffeineCutoffHours: caffeineCutoffHours ?? this.caffeineCutoffHours,
      windDownMin: windDownMin ?? this.windDownMin,
      waterIntervalMin: waterIntervalMin ?? this.waterIntervalMin,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'selectedPreset': selectedPreset,
      'wakeTime': wakeTime,
      'sleepHours': sleepHours,
      'fallAsleepBufferMin': fallAsleepBufferMin,
      'breakfastTime': breakfastTime,
      'lunchTime': lunchTime,
      'afternoonSnackTime': afternoonSnackTime,
      'dinnerTime': dinnerTime,
      'dinnerCutoffHours': dinnerCutoffHours,
      'caffeineCutoffHours': caffeineCutoffHours,
      'windDownMin': windDownMin,
      'waterIntervalMin': waterIntervalMin,
    };
  }

  factory UserSettings.fromMap(Map<String, Object?> map) {
    return UserSettings(
      selectedPreset: map['selectedPreset'] as String? ?? 'office_coder',
      wakeTime: map['wakeTime'] as String? ?? '06:30',
      sleepHours: (map['sleepHours'] as num?)?.toDouble() ?? 7.5,
      fallAsleepBufferMin: map['fallAsleepBufferMin'] as int? ?? 15,
      breakfastTime: map['breakfastTime'] as String? ?? '07:00',
      lunchTime: map['lunchTime'] as String? ?? '12:00',
      afternoonSnackTime: map['afternoonSnackTime'] as String? ?? '16:00',
      dinnerTime: map['dinnerTime'] as String? ?? '18:30',
      dinnerCutoffHours: (map['dinnerCutoffHours'] as num?)?.toDouble() ?? 3.0,
      caffeineCutoffHours:
          (map['caffeineCutoffHours'] as num?)?.toDouble() ?? 8.0,
      windDownMin: map['windDownMin'] as int? ?? 45,
      waterIntervalMin: map['waterIntervalMin'] as int? ?? 120,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserSettings &&
        other.selectedPreset == selectedPreset &&
        other.wakeTime == wakeTime &&
        other.sleepHours == sleepHours &&
        other.fallAsleepBufferMin == fallAsleepBufferMin &&
        other.breakfastTime == breakfastTime &&
        other.lunchTime == lunchTime &&
        other.afternoonSnackTime == afternoonSnackTime &&
        other.dinnerTime == dinnerTime &&
        other.dinnerCutoffHours == dinnerCutoffHours &&
        other.caffeineCutoffHours == caffeineCutoffHours &&
        other.windDownMin == windDownMin &&
        other.waterIntervalMin == waterIntervalMin;
  }

  @override
  int get hashCode => Object.hash(
    selectedPreset,
    wakeTime,
    sleepHours,
    fallAsleepBufferMin,
    breakfastTime,
    lunchTime,
    afternoonSnackTime,
    dinnerTime,
    dinnerCutoffHours,
    caffeineCutoffHours,
    windDownMin,
    waterIntervalMin,
  );
}
