import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../../core/storage/app_database.dart';

/// DAO over the `dashboard_cache` table.
///
/// Stores raw API JSON per scope so the existing fromJson()/fromAttendance()
/// parsers in dashboard_models.dart work unchanged whether the JSON came
/// from the network or from this cache.
class DashboardCache {
  DashboardCache._();
  static final DashboardCache instance = DashboardCache._();

  static const scopeMe = 'me';
  static const scopeStatus = 'status';
  static const scopeToday = 'today';
  static const scopeWeek = 'week';

  /// Returns the decoded JSON map for [scope], or null if nothing cached.
  Future<Map<String, dynamic>?> read(String scope) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'dashboard_cache',
      columns: ['json'],
      where: 'scope = ?',
      whereArgs: [scope],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['json'] as String) as Map<String, dynamic>;
  }

  /// Upserts [data] under [scope].
  Future<void> write(String scope, Map<String, dynamic> data) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'dashboard_cache',
      {
        'scope': scope,
        'json': jsonEncode(data),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
