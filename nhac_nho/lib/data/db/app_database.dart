// Cấu hình và khởi tạo SQLite (sqflite) cho bảng reminders và completion_logs.

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase({
    DatabaseFactory? factory,
    String? dbPath,
  })  : _factory = factory ?? databaseFactory,
        _customPath = dbPath;

  static const String _dbName = 'nhac_nho.db';
  static const int _dbVersion = 1;

  static const String remindersTable = 'reminders';
  static const String completionLogsTable = 'completion_logs';

  final DatabaseFactory _factory;
  final String? _customPath;
  Database? _database;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final path = _customPath ?? p.join(await _factory.getDatabasesPath(), _dbName);
    return _factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _dbVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $remindersTable (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              note TEXT,
              category TEXT NOT NULL,
              isRoutine INTEGER NOT NULL DEFAULT 0,
              priority INTEGER NOT NULL DEFAULT 2,
              hour INTEGER NOT NULL,
              minute INTEGER NOT NULL,
              repeat TEXT NOT NULL,
              intervalMinutes INTEGER,
              endHour INTEGER,
              endMinute INTEGER,
              weekdaysMask INTEGER NOT NULL DEFAULT 0,
              date TEXT,
              enabled INTEGER NOT NULL DEFAULT 1,
              createdAt TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE $completionLogsTable (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              reminderId INTEGER NOT NULL,
              date TEXT NOT NULL,
              status TEXT NOT NULL,
              completedAt TEXT NOT NULL,
              UNIQUE(reminderId, date),
              FOREIGN KEY(reminderId) REFERENCES $remindersTable(id) ON DELETE CASCADE
            )
          ''');
        },
      ),
    );
  }

  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
    }
    _database = null;
  }
}
