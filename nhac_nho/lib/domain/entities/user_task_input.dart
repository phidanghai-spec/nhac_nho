// Entity UserTaskInput mô tả đầu việc người dùng nhập để thuật toán tự xếp lịch thông minh.

enum TaskEnergyDemand {
  highFocus('Tập trung cao'),
  mediumTask('Việc vừa / Giao tiếp'),
  lightChore('Việc nhẹ / Việc nhà'),
  physicalOrEvent('Vận động / Sự kiện');

  const TaskEnergyDemand(this.displayName);
  final String displayName;

  static TaskEnergyDemand fromString(String value) {
    return TaskEnergyDemand.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TaskEnergyDemand.mediumTask,
    );
  }
}

class UserTaskInput {
  const UserTaskInput({
    required this.id,
    required this.title,
    this.note,
    this.estimatedMinutes = 60,
    this.energyDemand = TaskEnergyDemand.mediumTask,
    this.fixedHour,
    this.fixedMinute,
  });

  final String id;
  final String title;
  final String? note;
  final int estimatedMinutes;
  final TaskEnergyDemand energyDemand;
  final int? fixedHour;
  final int? fixedMinute;

  bool get isFixed => fixedHour != null && fixedMinute != null;

  UserTaskInput copyWith({
    String? id,
    String? title,
    String? note,
    bool clearNote = false,
    int? estimatedMinutes,
    TaskEnergyDemand? energyDemand,
    int? fixedHour,
    int? fixedMinute,
    bool clearFixedTime = false,
  }) {
    return UserTaskInput(
      id: id ?? this.id,
      title: title ?? this.title,
      note: clearNote ? null : (note ?? this.note),
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      energyDemand: energyDemand ?? this.energyDemand,
      fixedHour: clearFixedTime ? null : (fixedHour ?? this.fixedHour),
      fixedMinute: clearFixedTime ? null : (fixedMinute ?? this.fixedMinute),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'estimatedMinutes': estimatedMinutes,
      'energyDemand': energyDemand.name,
      'fixedHour': fixedHour,
      'fixedMinute': fixedMinute,
    };
  }

  factory UserTaskInput.fromMap(Map<String, Object?> map) {
    return UserTaskInput(
      id: map['id'] as String,
      title: map['title'] as String,
      note: map['note'] as String?,
      estimatedMinutes: map['estimatedMinutes'] as int? ?? 60,
      energyDemand: TaskEnergyDemand.fromString(
        map['energyDemand'] as String? ?? 'mediumTask',
      ),
      fixedHour: map['fixedHour'] as int?,
      fixedMinute: map['fixedMinute'] as int?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserTaskInput &&
        other.id == id &&
        other.title == title &&
        other.note == note &&
        other.estimatedMinutes == estimatedMinutes &&
        other.energyDemand == energyDemand &&
        other.fixedHour == fixedHour &&
        other.fixedMinute == fixedMinute;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    note,
    estimatedMinutes,
    energyDemand,
    fixedHour,
    fixedMinute,
  );
}
