// Logic thuần Dart tính giờ đi ngủ, ngừng ăn tối, ngừng caffeine và chuẩn bị ngủ.

class ClockTime {
  const ClockTime(this.hour, this.minute);

  final int hour;
  final int minute;

  static const int minutesPerDay = 24 * 60;

  int toMinutes() => hour * 60 + minute;

  static ClockTime fromMinutes(int totalMinutes) {
    final normalized =
        ((totalMinutes % minutesPerDay) + minutesPerDay) % minutesPerDay;
    return ClockTime(normalized ~/ 60, normalized % 60);
  }

  static ClockTime parse(String hhmm) {
    final parts = hhmm.trim().split(':');
    if (parts.length != 2) {
      throw FormatException('Định dạng giờ không hợp lệ: $hhmm');
    }
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    if (h < 0 || h > 23 || m < 0 || m > 59) {
      throw FormatException('Giá trị giờ/phút ngoài phạm vi: $hhmm');
    }
    return ClockTime(h, m);
  }

  ClockTime addMinutes(int delta) => fromMinutes(toMinutes() + delta);

  ClockTime subtractMinutes(int delta) => fromMinutes(toMinutes() - delta);

  String format24h() {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  String toString() => format24h();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClockTime && other.hour == hour && other.minute == minute;
  }

  @override
  int get hashCode => Object.hash(hour, minute);
}

class SleepPlanResult {
  const SleepPlanResult({
    required this.wakeTime,
    required this.bedtime,
    required this.dinnerStop,
    required this.caffeineCutoff,
    required this.windDown,
    this.sleepDurationWarning,
    this.dinnerTooLateWarning,
  });

  final ClockTime wakeTime;
  final ClockTime bedtime;
  final ClockTime dinnerStop;
  final ClockTime caffeineCutoff;
  final ClockTime windDown;
  final String? sleepDurationWarning;
  final String? dinnerTooLateWarning;
}

class SleepPlanner {
  const SleepPlanner._();

  static SleepPlanResult calculate({
    required ClockTime wakeTime,
    double sleepHours = 7.5,
    int fallAsleepBufferMin = 15,
    double dinnerCutoffHours = 3.0,
    double caffeineCutoffHours = 8.0,
    int windDownMin = 45,
    ClockTime? dinnerTime,
  }) {
    final sleepMinutes = (sleepHours * 60).round();
    final bedtime = wakeTime.subtractMinutes(sleepMinutes + fallAsleepBufferMin);
    final dinnerStop = bedtime.subtractMinutes((dinnerCutoffHours * 60).round());
    final caffeineCutoff =
        bedtime.subtractMinutes((caffeineCutoffHours * 60).round());
    final windDown = bedtime.subtractMinutes(windDownMin);

    String? sleepWarning;
    if (sleepHours < 7.0 || sleepHours > 9.0) {
      sleepWarning =
          'Khuyến nghị ngủ cho người trưởng thành là 7–9 giờ mỗi ngày.';
    }

    String? dinnerWarning;
    if (dinnerTime != null &&
        isDinnerAfterCutoff(
          wakeTime: wakeTime,
          dinnerTime: dinnerTime,
          dinnerStop: dinnerStop,
        )) {
      dinnerWarning =
          'Giờ ăn tối (${dinnerTime.format24h()}) muộn hơn mốc ngừng ăn (${dinnerStop.format24h()}); '
          'nên ăn sớm hơn hoặc chọn món nhẹ dễ tiêu.';
    }

    return SleepPlanResult(
      wakeTime: wakeTime,
      bedtime: bedtime,
      dinnerStop: dinnerStop,
      caffeineCutoff: caffeineCutoff,
      windDown: windDown,
      sleepDurationWarning: sleepWarning,
      dinnerTooLateWarning: dinnerWarning,
    );
  }

  /// So sánh vị trí bữa tối và mốc ngừng ăn dọc theo chu kỳ thức tính từ [wakeTime].
  static bool isDinnerAfterCutoff({
    required ClockTime wakeTime,
    required ClockTime dinnerTime,
    required ClockTime dinnerStop,
  }) {
    final wakeMin = wakeTime.toMinutes();
    final dinnerElapsed = (dinnerTime.toMinutes() - wakeMin + 1440) % 1440;
    final stopElapsed = (dinnerStop.toMinutes() - wakeMin + 1440) % 1440;
    return dinnerElapsed > stopElapsed;
  }
}
