// Tên notification channel, khóa lưu cài đặt và hằng số dùng chung toàn app.

class NotificationChannelConfig {
  const NotificationChannelConfig._();

  static const String taskId = 'task';
  static const String taskName = 'Công việc';
  static const String taskDescription = 'Nhắc nhở công việc trong ngày';

  static const String mealId = 'meal';
  static const String mealName = 'Ăn uống';
  static const String mealDescription = 'Nhắc giờ ăn và gợi ý thực phẩm';

  static const String hydrationId = 'hydration';
  static const String hydrationName = 'Uống nước & Giải lao';
  static const String hydrationDescription =
      'Nhắc uống nước định kỳ, nghỉ mắt và ngừng caffeine';

  static const String sleepId = 'sleep';
  static const String sleepName = 'Giấc ngủ';
  static const String sleepDescription = 'Nhắc ngừng ăn tối, chuẩn bị ngủ và đi ngủ';
}

class StorageKeys {
  const StorageKeys._();

  static const String userSettings = 'user_settings_v1';
  static const String bodyProfile = 'body_profile_v1';
  static const String onboardingCompleted = 'onboarding_completed_v1';
}

class AppLimits {
  const AppLimits._();

  static const int maxIntervalSlots = 20;
  static const int intervalSlotStart = 10;
  static const int snoozeSlot = 99;
  static const int slotsPerReminder = 100;
  static const int maxScheduledWindowNotifications = 50;
}

class HealthDisclaimer {
  const HealthDisclaimer._();

  static const String text =
      'Nội dung chỉ mang tính tham khảo chung về lối sống lành mạnh cho người khỏe mạnh, '
      'không thay thế tư vấn của bác sĩ hay chuyên gia dinh dưỡng; người có bệnh nền, '
      'đang dùng thuốc hoặc có vấn đề giấc ngủ nên hỏi ý kiến chuyên gia y tế.';
}
