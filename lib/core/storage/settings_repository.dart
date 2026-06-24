import 'package:sqflite/sqflite.dart';
import 'app_database.dart';

/// Persists user preferences (theme, locale) in the `app_settings`
/// SQLite table. Keys are defined as constants below.
/// Reads return null when no value has been saved yet — callers supply defaults.
class SettingsRepository {
  SettingsRepository._();
  static final SettingsRepository instance = SettingsRepository._();

  static const keyDarkMode = 'dark_mode';   // value: '0' | '1'
  static const keyLocale   = 'locale';      // value: 'en' | 'fr'

  Future<String?> read(String key) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  Future<void> write(String key, String value) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
