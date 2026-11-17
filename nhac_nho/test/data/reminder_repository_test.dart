// Unit test cho ReminderRepository với sqflite_common_ffi.

import 'package:flutter_test/flutter_test.dart';
import 'package:nhac_nho/data/db/app_database.dart';
import 'package:nhac_nho/data/reminder_repository_impl.dart';
import 'package:nhac_nho/domain/entities/completion_log.dart';
import 'package:nhac_nho/domain/entities/reminder.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase appDatabase;
  late ReminderRepositoryImpl repository;

  setUp(() async {
    appDatabase = AppDatabase(
      factory: databaseFactoryFfi,
      dbPath: inMemoryDatabasePath,
    );
    repository = ReminderRepositoryImpl(appDatabase);
  });

  tearDown(() async {
    await appDatabase.close();
  });

  Reminder buildReminder({
    String title = 'Deep Work: Học code',
    ReminderCategory category = ReminderCategory.task,
    bool isRoutine = false,
    int priority = 1,
    int hour = 8,
    int minute = 30,
    RepeatType repeat = RepeatType.daily,
    int? intervalMinutes,
    int? endHour,
    int? endMinute,
    int weekdaysMask = 0,
    String? date,
    bool enabled = true,
  }) {
    return Reminder(
      title: title,
      note: 'Ghi chú test',
      category: category,
      isRoutine: isRoutine,
      priority: priority,
      hour: hour,
      minute: minute,
      repeat: repeat,
      intervalMinutes: intervalMinutes,
      endHour: endHour,
      endMinute: endMinute,
      weekdaysMask: weekdaysMask,
      date: date,
      enabled: enabled,
      createdAt: '2026-11-17T08:00:00.000Z',
    );
  }

  test('thêm, liệt kê, tìm theo id, sửa và xóa nhắc nhở', () async {
    final id = await repository.insertReminder(buildReminder());
    expect(id, greaterThan(0));

    final fetched = await repository.getReminderById(id);
    expect(fetched, isNotNull);
    expect(fetched!.title, 'Deep Work: Học code');
    expect(fetched.priority, 1);

    final updated = fetched.copyWith(
      title: 'Deep Work: Đọc tài liệu',
      hour: 9,
      enabled: false,
    );
    await repository.updateReminder(updated);

    final afterUpdate = await repository.getReminderById(id);
    expect(afterUpdate!.title, 'Deep Work: Đọc tài liệu');
    expect(afterUpdate.hour, 9);
    expect(afterUpdate.enabled, isFalse);

    final all = await repository.getAllReminders();
    expect(all, hasLength(1));

    await repository.deleteReminder(id);
    expect(await repository.getReminderById(id), isNull);
    expect(await repository.getAllReminders(), isEmpty);
  });

  test('lọc theo ngày với các kiểu lặp once, daily, weekly, interval và isRoutine', () async {
    // 2026-11-17 là Thứ Ba (weekday == 2 => bit 1 = 1 << 1 = 2)
    final tuesday = DateTime(2026, 11, 17);
    final wednesday = DateTime(2026, 11, 18);

    await repository.insertReminder(
      buildReminder(
        title: 'Việc chỉ hôm nay',
        isRoutine: false,
        repeat: RepeatType.once,
        date: '2026-11-17',
      ),
    );
    await repository.insertReminder(
      buildReminder(
        title: 'Ăn sáng',
        category: ReminderCategory.meal,
        isRoutine: true,
        hour: 7,
        minute: 0,
        repeat: RepeatType.daily,
      ),
    );
    await repository.insertReminder(
      buildReminder(
        title: 'Họp Thứ Ba',
        isRoutine: false,
        hour: 10,
        minute: 0,
        repeat: RepeatType.weekly,
        weekdaysMask: 1 << (DateTime.tuesday - 1),
      ),
    );
    await repository.insertReminder(
      buildReminder(
        title: 'Uống nước',
        category: ReminderCategory.hydration,
        isRoutine: true,
        hour: 8,
        minute: 0,
        repeat: RepeatType.interval,
        intervalMinutes: 90,
        endHour: 20,
        endMinute: 0,
      ),
    );

    final tuesdayAll = await repository.getRemindersForDate(tuesday);
    expect(tuesdayAll.map((e) => e.title), [
      'Ăn sáng',
      'Uống nước',
      'Việc chỉ hôm nay',
      'Họp Thứ Ba',
    ]);

    final tuesdayRoutines = await repository.getRemindersForDate(
      tuesday,
      isRoutine: true,
    );
    expect(tuesdayRoutines.map((e) => e.title), ['Ăn sáng', 'Uống nước']);

    final tuesdayTasks = await repository.getRemindersForDate(
      tuesday,
      isRoutine: false,
    );
    expect(tuesdayTasks.map((e) => e.title), ['Việc chỉ hôm nay', 'Họp Thứ Ba']);

    final wednesdayAll = await repository.getRemindersForDate(wednesday);
    expect(wednesdayAll.map((e) => e.title), ['Ăn sáng', 'Uống nước']);
  });

  test('lưu và cập nhật CompletionLog, tự xóa theo reminder (cascade)', () async {
    final reminderId = await repository.insertReminder(
      buildReminder(title: 'Uống nước ấm', isRoutine: true),
    );

    await repository.upsertCompletionLog(
      CompletionLog(
        reminderId: reminderId,
        date: '2026-11-17',
        status: CompletionStatus.skipped,
        completedAt: '2026-11-17T06:40:00.000Z',
      ),
    );

    // Upsert lại cùng ngày sang done
    await repository.upsertCompletionLog(
      CompletionLog(
        reminderId: reminderId,
        date: '2026-11-17',
        status: CompletionStatus.done,
        completedAt: '2026-11-17T06:45:00.000Z',
      ),
    );

    final logs = await repository.getCompletionLogsByDate('2026-11-17');
    expect(logs, hasLength(1));
    expect(logs.first.status, CompletionStatus.done);

    await repository.deleteReminder(reminderId);
    final afterDelete = await repository.getCompletionLogsByDate('2026-11-17');
    expect(afterDelete, isEmpty);
  });
}
