import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../../core/storage/app_database.dart';

/// DAO over the shared `dashboard_cache` table for Analytics scopes.
/// Same read/write shape as HrEmployeeCache/DashboardCache — only the
/// scope strings differ. Scope keys include the resolved date range (not
/// just the raw `period` string) so a cached July result is never shown
/// while the user is viewing a June query — see scopeFor().
class HrAnalyticsCache {
  HrAnalyticsCache._();
  static final HrAnalyticsCache instance = HrAnalyticsCache._();

  static String scopeFor(
    String endpoint, {
    String? period,
    required String dateFrom,
    required String dateTo,
  }) =>
      'hr_analytics_$endpoint:${period ?? "custom"}:$dateFrom:$dateTo';

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
