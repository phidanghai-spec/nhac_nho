// Unit test cho TimeUtils: notificationIdFor, nextInstanceOf và generateIntervalSlots.

import 'package:flutter_test/flutter_test.dart';
import 'package:nhac_nho/core/time_utils.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  tz_data.initializeTimeZones();

  group('TimeUtils.notificationIdFor', () {
    test('tính đúng ID theo quy tắc reminderId * 100 + slot', () {
      expect(TimeUtils.notificationIdFor(5, 0), 500);
      expect(TimeUtils.notificationIdFor(5, 7), 507);
      expect(TimeUtils.notificationIdFor(5, 10), 510);
      expect(TimeUtils.notificationIdFor(5, 29), 529);
      expect(TimeUtils.notificationIdFor(5, 99), 599);
    });
  });

  group('TimeUtils.nextInstanceOf', () {
    final location = tz.getLocation('Asia/Ho_Chi_Minh');

    test('trả về cùng ngày nếu mốc giờ chưa qua', () {
      final now = tz.TZDateTime(location, 2026, 11, 17, 7, 0);
      final next = TimeUtils.nextInstanceOf(8, 30, now: now, location: location);
      expect(next, tz.TZDateTime(location, 2026, 11, 17, 8, 30));
    });

    test('sang ngày hôm sau khi mốc giờ đã qua và xử lý đúng cuối tháng', () {
      final now = tz.TZDateTime(location, 2026, 11, 30, 22, 30);
      final next = TimeUtils.nextInstanceOf(6, 30, now: now, location: location);
      expect(next, tz.TZDateTime(location, 2026, 12, 1, 6, 30));
    });

    test('sang năm mới đúng khi ở đêm giao thừa', () {
      final now = tz.TZDateTime(location, 2026, 12, 31, 23, 0);
      final next = TimeUtils.nextInstanceOf(23, 0, now: now, location: location);
      expect(next, tz.TZDateTime(location, 2027, 1, 1, 23, 0));
    });
  });

  group('TimeUtils.generateIntervalSlots', () {
    test('sinh đủ các mốc trong khung giờ ban ngày', () {
      final slots = TimeUtils.generateIntervalSlots(
        startHour: 8,
        startMinute: 0,
        endHour: 14,
        endMinute: 0,
        intervalMinutes: 120,
      );
      expect(
        slots.map((s) => s.format24h()).toList(),
        ['08:00', '10:00', '12:00', '14:00'],
      );
    });

    test('hỗ trợ khung giờ qua nửa đêm (ca đêm 21:00 -> 03:00)', () {
      final slots = TimeUtils.generateIntervalSlots(
        startHour: 21,
        startMinute: 0,
        endHour: 3,
        endMinute: 0,
        intervalMinutes: 120,
      );
      expect(
        slots.map((s) => s.format24h()).toList(),
        ['21:00', '23:00', '01:00', '03:00'],
      );
    });

    test('giới hạn tối đa 20 mốc (slot 10..29)', () {
      final slots = TimeUtils.generateIntervalSlots(
        startHour: 6,
        startMinute: 0,
        endHour: 23,
        endMinute: 0,
        intervalMinutes: 30,
      );
      expect(slots.length, 20);
    });
  });
}
