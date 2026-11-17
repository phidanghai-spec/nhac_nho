// Triển khai ReminderRepository sử dụng AppDatabase (sqflite).

import 'package:sqflite/sqflite.dart';

import '../../domain/entities/completion_log.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';
import 'db/app_database.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  ReminderRepositoryImpl(this._appDatabase);

  final AppDatabase _appDatabase;

  @override
  Future<int> insertReminder(Reminder reminder) async {
    final db = await _appDatabase.database;
    final map = reminder.toMap()..remove('id');
    return db.insert(
      AppDatabase.remindersTable,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateReminder(Reminder reminder) async {
    if (reminder.id == null) {
      throw ArgumentError('Reminder id cannot be null on update');
    }
    final db = await _appDatabase.database;
    await db.update(
      AppDatabase.remindersTable,
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  @override
  Future<void> deleteReminder(int id) async {
    final db = await _appDatabase.database;
    await db.delete(
      AppDatabase.remindersTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<Reminder?> getReminderById(int id) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      AppDatabase.remindersTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Reminder.fromMap(rows.first);
  }

  @override
  Future<List<Reminder>> getAllReminders() async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      AppDatabase.remindersTable,
      orderBy: 'hour ASC, minute ASC, priority ASC, id ASC',
    );
    return rows.map(Reminder.fromMap).toList();
  }

  @override
  Future<List<Reminder>> getRemindersForDate(
    DateTime date, {
    bool? isRoutine,
  }) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      AppDatabase.remindersTable,
      where: isRoutine == null ? null : 'isRoutine = ?',
      whereArgs: isRoutine == null ? null : [isRoutine ? 1 : 0],
      orderBy: 'hour ASC, minute ASC, priority ASC, id ASC',
    );
    return rows
        .map(Reminder.fromMap)
        .where((r) => r.isScheduledForDate(date))
        .toList();
  }

  @override
  Future<void> replaceAllReminders(List<Reminder> reminders) async {
    final db = await _appDatabase.database;
    await db.transaction((txn) async {
      await txn.delete(AppDatabase.remindersTable);
      for (final reminder in reminders) {
        final map = reminder.toMap()..remove('id');
        await txn.insert(AppDatabase.remindersTable, map);
      }
    });
  }

  @override
  Future<int> upsertCompletionLog(CompletionLog log) async {
    final db = await _appDatabase.database;
    final existing = await db.query(
      AppDatabase.completionLogsTable,
      where: 'reminderId = ? AND date = ?',
      whereArgs: [log.reminderId, log.date],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      final existingId = existing.first['id'] as int;
      await db.update(
        AppDatabase.completionLogsTable,
        {
          'status': log.status.name,
          'completedAt': log.completedAt,
        },
        where: 'id = ?',
        whereArgs: [existingId],
      );
      return existingId;
    }
    final map = log.toMap()..remove('id');
    return db.insert(AppDatabase.completionLogsTable, map);
  }

  @override
  Future<List<CompletionLog>> getCompletionLogsByDate(String date) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      AppDatabase.completionLogsTable,
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'id ASC',
    );
    return rows.map(CompletionLog.fromMap).toList();
  }

  @override
  Future<List<CompletionLog>> getCompletionLogsInRange(
    String startDate,
    String endDate,
  ) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      AppDatabase.completionLogsTable,
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC, id ASC',
    );
    return rows.map(CompletionLog.fromMap).toList();
  }

  @override
  Future<void> deleteCompletionLogForDate(int reminderId, String date) async {
    final db = await _appDatabase.database;
    await db.delete(
      AppDatabase.completionLogsTable,
      where: 'reminderId = ? AND date = ?',
      whereArgs: [reminderId, date],
    );
  }
}
