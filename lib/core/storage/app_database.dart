import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Single SQLite database for the whole app's local persistence.
///
/// Replaces Hive entirely. Two tables:
///   - dashboard_cache : last-known-good API responses, keyed by scope
///   - checkin_queue   : offline-submitted check-ins awaiting sync
///
/// Opens lazily on first access — no explicit init() call needed in main().
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'worktrackr.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;
    final opened = await _open();
    _db = opened;
    return opened;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE dashboard_cache (
            scope      TEXT PRIMARY KEY,
            json       TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE checkin_queue (
            id         TEXT PRIMARY KEY,
            payload    TEXT NOT NULL,
            queued_at  TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE app_settings (
            key   TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );
  }
}
