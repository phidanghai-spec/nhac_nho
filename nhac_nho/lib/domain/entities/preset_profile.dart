// Entity PresetProfile mô tả cấu hình 4 bộ lịch mẫu theo đối tượng.

import 'reminder.dart';
import 'user_settings.dart';

enum PresetId {
  officeCoder('office_coder', 'Văn phòng / IT'),
  student('student', 'Học sinh / Sinh viên'),
  freelancer('freelancer', 'Tự do / Sáng tạo'),
  modelAesthetic('model_aesthetic', 'Người mẫu / Giữ dáng / Sự kiện'),
  homemakerParent('homemaker_parent', 'Nội trợ / Chăm sóc gia đình'),
  activeWorker('active_worker', 'Tài xế / Lao động thể chất'),
  seniorHealth('senior_health', 'Người lớn tuổi / Dưỡng sinh');

  const PresetId(this.id, this.displayName);
  final String id;
  final String displayName;

  static PresetId fromString(String value) {
    return PresetId.values.firstWhere(
      (e) => e.id == value || e.name == value,
      orElse: () => PresetId.officeCoder,
    );
  }
}

class PresetProfile {
  const PresetProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.defaultSettings,
    required this.reminders,
  });

  final PresetId id;
  final String name;
  final String description;
  final UserSettings defaultSettings;
  final List<Reminder> reminders;

  PresetProfile copyWith({
    PresetId? id,
    String? name,
    String? description,
    UserSettings? defaultSettings,
    List<Reminder>? reminders,
  }) {
    return PresetProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      defaultSettings: defaultSettings ?? this.defaultSettings,
      reminders: reminders ?? this.reminders,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id.id,
      'name': name,
      'description': description,
      'defaultSettings': defaultSettings.toMap(),
      'reminders': reminders.map((e) => e.toMap()).toList(),
    };
  }

  factory PresetProfile.fromMap(Map<String, Object?> map) {
    final rawReminders = map['reminders'] as List<dynamic>? ?? [];
    return PresetProfile(
      id: PresetId.fromString(map['id'] as String? ?? 'office_coder'),
      name: map['name'] as String,
      description: map['description'] as String,
      defaultSettings: UserSettings.fromMap(
        Map<String, Object?>.from(map['defaultSettings'] as Map),
      ),
      reminders: rawReminders
          .map((e) => Reminder.fromMap(Map<String, Object?>.from(e as Map)))
          .toList(),
    );
  }
}
