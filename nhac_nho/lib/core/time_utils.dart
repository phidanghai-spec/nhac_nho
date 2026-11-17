// Tiện ích tính nextInstanceOf, intervalSlots và định dạng giờ 24h.

import 'package:timezone/timezone.dart' as tz;

import 'constants.dart';

class TimeSlot {
  const TimeSlot(this.hour, this.minute);

  final int hour;
  final int minute;

  String format24h() => TimeUtils.format24h(hour, minute);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeSlot && other.hour == hour && other.minute == minute;
  }

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => format24h();
}

class TimeUtils {
  const TimeUtils._();

  static String format24h(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static int notificationIdFor(int reminderId, int slot) {
    return reminderId * AppLimits.slotsPerReminder + slot;
  }

  /// Trả về thời điểm [hour]:[minute] kế tiếp tính từ [now] (hoặc hiện tại).
  /// Tự động cộng 1 ngày nếu mốc giờ hôm nay đã qua hoặc trùng hiện tại,
  /// không bị lỗi khi qua cuối tháng hoặc cuối năm.
  static tz.TZDateTime nextInstanceOf(
    int hour,
    int minute, {
    tz.TZDateTime? now,
    tz.Location? location,
  }) {
    final loc = location ?? tz.local;
    final current = now ?? tz.TZDateTime.now(loc);
    var scheduled = tz.TZDateTime(
      loc,
      current.year,
      current.month,
      current.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(current)) {
      scheduled = tz.TZDateTime(
        loc,
        current.year,
        current.month,
        current.day + 1,
        hour,
        minute,
      );
    }
    return scheduled;
  }

  /// Trả về thời điểm kế tiếp khớp với [weekday] (1 = Thứ 2 .. 7 = Chủ nhật).
  static tz.TZDateTime nextInstanceOfWeekday(
    int weekday,
    int hour,
    int minute, {
    tz.TZDateTime? now,
    tz.Location? location,
  }) {
    var scheduled = nextInstanceOf(
      hour,
      minute,
      now: now,
      location: location,
    );
    while (scheduled.weekday != weekday) {
      scheduled = tz.TZDateTime(
        scheduled.location,
        scheduled.year,
        scheduled.month,
        scheduled.day + 1,
        hour,
        minute,
      );
    }
    return scheduled;
  }

  /// Phân tích ngày `yyyy-MM-dd` kết hợp [hour]:[minute].
  static tz.TZDateTime? parseDateAtTime(
    String? yyyyMmDd,
    int hour,
    int minute, {
    tz.Location? location,
  }) {
    if (yyyyMmDd == null || yyyyMmDd.isEmpty) return null;
    final parts = yyyyMmDd.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    final loc = location ?? tz.local;
    return tz.TZDateTime(loc, year, month, day, hour, minute);
  }

  /// Sinh danh sách các mốc (hour, minute) cho kiểu lặp chu kỳ [intervalMinutes]
  /// từ [startHour]:[startMinute] đến [endHour]:[endMinute].
  /// Hỗ trợ cả khung giờ qua nửa đêm (VD: ca đêm 16:15 -> 06:30), tối đa [maxSlots] mốc.
  static List<TimeSlot> generateIntervalSlots({
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
    required int intervalMinutes,
    int maxSlots = AppLimits.maxIntervalSlots,
  }) {
    if (intervalMinutes <= 0 || maxSlots <= 0) return const [];

    final startTotal = startHour * 60 + startMinute;
    var endTotal = endHour * 60 + endMinute;
    if (endTotal < startTotal) {
      endTotal += 24 * 60;
    }

    final slots = <TimeSlot>[];
    var current = startTotal;
    while (current <= endTotal && slots.length < maxSlots) {
      final normalized = current % (24 * 60);
      slots.add(TimeSlot(normalized ~/ 60, normalized % 60));
      current += intervalMinutes;
    }
    return slots;
  }
}
