import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../../core/storage/app_database.dart';

/// DAO over the shared `dashboard_cache` table for flagged records.
///
/// Two scope keys — one per filter state — so pending and all-records
/// lists are cached independently and the correct list is served
/// immediately on screen open regardless of which filter was last active.
class HrFlaggedCache {
  HrFlaggedCache._();
  static final HrFlaggedCache instance = HrFlaggedCache._();

  static const scopePending = 'hr_flagged_pending';
  static const scopeAll     = 'hr_flagged_all';

  String scopeFor({required bool showResolved}) =>
      showResolved ? scopeAll : scopePending;

  Future<List<Map<String, dynamic>>?> read(String scope) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'dashboard_cache',
      columns: ['json'],
      where: 'scope = ?',
      whereArgs: [scope],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final decoded = jsonDecode(rows.first['json'] as String);
    return (decoded as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> write(String scope, List<Map<String, dynamic>> data) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'dashboard_cache',
      {
        'scope':      scope,
        'json':       jsonEncode(data),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
