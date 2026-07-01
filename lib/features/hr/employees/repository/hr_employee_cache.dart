import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../../core/storage/app_database.dart';

/// DAO over the shared `dashboard_cache` table for all HR employee-related
/// scopes: the full list, per-employee detail, per-employee per-range
/// history, and per-employee last audit. Same table, same read/write shape
/// as DashboardCache / HrDashboardCache / HistoryCache — only the scope
/// strings differ.
class HrEmployeeCache {
  HrEmployeeCache._();
  static final HrEmployeeCache instance = HrEmployeeCache._();

  static const scopeList = 'hr_employee_list';

  static String scopeDetail(int id) => 'hr_employee_detail:$id';
  static String scopeHistory(int id, String dateFrom, String dateTo) =>
      'hr_employee_history:$id:$dateFrom:$dateTo';
  static String scopeAudit(int id) => 'hr_employee_audit:$id';

  /// The list endpoint returns a JSON array, not an object, so it's stored
  /// wrapped under a single 'items' key to fit the Map-shaped table schema
  /// (same trick will be reused by HrFlaggedCache for its array response).
  Future<List<dynamic>?> readList(String scope) async {
    final json = await read(scope);
    if (json == null) return null;
    return json['items'] as List<dynamic>;
  }

  Future<void> writeList(String scope, List<dynamic> items) =>
      write(scope, {'items': items});

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

  /// Deletes a single scope. Used to evict a stale audit/history entry
  /// without affecting other cached scopes.
  Future<void> delete(String scope) async {
    final db = await AppDatabase.instance.database;
    await db.delete('dashboard_cache', where: 'scope = ?', whereArgs: [scope]);
  }
}
