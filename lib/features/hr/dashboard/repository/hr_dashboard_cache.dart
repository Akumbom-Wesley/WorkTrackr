import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../../core/storage/app_database.dart';

/// DAO over the shared `dashboard_cache` table for HR dashboard stats.
///
/// Reuses the same table as the employee dashboard cache (one row per
/// scope), but is namespaced under its own scope key so it can never
/// collide with employee-side scopes ('me', 'status', 'today', 'week').
class HrDashboardCache {
  HrDashboardCache._();
  static final HrDashboardCache instance = HrDashboardCache._();

  static const scopeStats = 'hr_dashboard_stats';

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
