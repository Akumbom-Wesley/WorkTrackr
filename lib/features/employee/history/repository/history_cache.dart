import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../../core/storage/app_database.dart';

/// DAO over the `dashboard_cache` table for history scopes.
/// Reuses the same table — scopes keep them separate.
class HistoryCache {
  HistoryCache._();
  static final HistoryCache instance = HistoryCache._();

  /// Scope for the current-month history response.
  static const scopeHistory = 'history';

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
