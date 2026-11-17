// Entity Reminder bất biến đại diện cho một mục nhắc nhở.

enum ReminderCategory {
  task,
  meal,
  hydration,
  sleep;

  static ReminderCategory fromString(String value) {
    return ReminderCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReminderCategory.task,
    );
  }
}

enum RepeatType {
  once,
  daily,
  weekly,
  interval;

  static RepeatType fromString(String value) {
    return RepeatType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RepeatType.daily,
    );
  }
}

class Reminder {
  const Reminder({
    this.id,
    required this.title,
    this.note,
    required this.category,
    required this.isRoutine,
    this.priority = 2,
    required this.hour,
    required this.minute,
    required this.repeat,
    this.intervalMinutes,
    this.endHour,
    this.endMinute,
    this.weekdaysMask = 0,
    this.date,
    this.enabled = true,
    required this.createdAt,
  });

  final int? id;
  final String title;
  final String? note;
  final ReminderCategory category;
  final bool isRoutine;

  /// 1 = Quan trọng nhất (MIT), 2 = Bình thường, 3 = Nhẹ nhàng.
  final int priority;
  final int hour;
  final int minute;
  final RepeatType repeat;
  final int? intervalMinutes;
  final int? endHour;
  final int? endMinute;

  /// Bit 0 = Thứ 2 .. Bit 6 = Chủ nhật.
  final int weekdaysMask;

  /// Định dạng yyyy-MM-dd, dùng khi repeat == RepeatType.once.
  final String? date;
  final bool enabled;
  final String createdAt;

  Reminder copyWith({
    int? id,
    bool clearId = false,
    String? title,
    String? note,
    bool clearNote = false,
    ReminderCategory? category,
    bool? isRoutine,
    int? priority,
    int? hour,
    int? minute,
    RepeatType? repeat,
    int? intervalMinutes,
    bool clearIntervalMinutes = false,
    int? endHour,
    bool clearEndHour = false,
    int? endMinute,
    bool clearEndMinute = false,
    int? weekdaysMask,
    String? date,
    bool clearDate = false,
    bool? enabled,
    String? createdAt,
  }) {
    return Reminder(
      id: clearId ? null : (id ?? this.id),
      title: title ?? this.title,
      note: clearNote ? null : (note ?? this.note),
      category: category ?? this.category,
      isRoutine: isRoutine ?? this.isRoutine,
      priority: priority ?? this.priority,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      repeat: repeat ?? this.repeat,
      intervalMinutes: clearIntervalMinutes
          ? null
          : (intervalMinutes ?? this.intervalMinutes),
      endHour: clearEndHour ? null : (endHour ?? this.endHour),
      endMinute: clearEndMinute ? null : (endMinute ?? this.endMinute),
      weekdaysMask: weekdaysMask ?? this.weekdaysMask,
      date: clearDate ? null : (date ?? this.date),
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'note': note,
      'category': category.name,
      'isRoutine': isRoutine ? 1 : 0,
      'priority': priority,
      'hour': hour,
      'minute': minute,
      'repeat': repeat.name,
      'intervalMinutes': intervalMinutes,
      'endHour': endHour,
      'endMinute': endMinute,
      'weekdaysMask': weekdaysMask,
      'date': date,
      'enabled': enabled ? 1 : 0,
      'createdAt': createdAt,
    };
  }

  factory Reminder.fromMap(Map<String, Object?> map) {
    return Reminder(
      id: map['id'] as int?,
      title: map['title'] as String,
      note: map['note'] as String?,
      category: ReminderCategory.fromString(map['category'] as String),
      isRoutine: (map['isRoutine'] as int? ?? 0) == 1,
      priority: map['priority'] as int? ?? 2,
      hour: map['hour'] as int,
      minute: map['minute'] as int,
      repeat: RepeatType.fromString(map['repeat'] as String),
      intervalMinutes: map['intervalMinutes'] as int?,
      endHour: map['endHour'] as int?,
      endMinute: map['endMinute'] as int?,
      weekdaysMask: map['weekdaysMask'] as int? ?? 0,
      date: map['date'] as String?,
      enabled: (map['enabled'] as int? ?? 1) == 1,
      createdAt: map['createdAt'] as String,
    );
  }

  bool isScheduledForDate(DateTime targetDate) {
    switch (repeat) {
      case RepeatType.daily:
      case RepeatType.interval:
        return true;
      case RepeatType.once:
        final yyyy = targetDate.year.toString().padLeft(4, '0');
        final mm = targetDate.month.toString().padLeft(2, '0');
        final dd = targetDate.day.toString().padLeft(2, '0');
        return date == '$yyyy-$mm-$dd';
      case RepeatType.weekly:
        final bit = 1 << (targetDate.weekday - 1);
        return (weekdaysMask & bit) != 0;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Reminder &&
        other.id == id &&
        other.title == title &&
        other.note == note &&
        other.category == category &&
        other.isRoutine == isRoutine &&
        other.priority == priority &&
        other.hour == hour &&
        other.minute == minute &&
        other.repeat == repeat &&
        other.intervalMinutes == intervalMinutes &&
        other.endHour == endHour &&
        other.endMinute == endMinute &&
        other.weekdaysMask == weekdaysMask &&
        other.date == date &&
        other.enabled == enabled &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    note,
    category,
    isRoutine,
    priority,
    hour,
    minute,
    repeat,
    intervalMinutes,
    endHour,
    endMinute,
    weekdaysMask,
    date,
    enabled,
    createdAt,
  );
}
