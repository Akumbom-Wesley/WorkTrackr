import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/storage/app_database.dart';
import '../models/queued_checkin.dart';

/// Thin DAO over the `checkin_queue` SQLite table.
/// No init() call needed — AppDatabase opens lazily on first access.
class CheckinQueue {
  CheckinQueue._();
  static final CheckinQueue instance = CheckinQueue._();

  static const _table = 'checkin_queue';

  /// Appends a [QueuedCheckin] to the local queue.
  Future<void> enqueue(QueuedCheckin item) async {
    final db = await AppDatabase.instance.database;
    final payloadJson = jsonEncode(item.payload);
    await db.insert(
      _table,
      item.toRow(payloadJson),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Returns all queued items ordered by [queuedAt] ascending.
  Future<List<QueuedCheckin>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(_table, orderBy: 'queued_at ASC');
    return rows.map((row) {
      final decodedPayload =
          jsonDecode(row['payload'] as String) as Map<String, dynamic>;
      return QueuedCheckin.fromRow(row, decodedPayload);
    }).toList();
  }

  /// Number of items currently in the queue.
  Future<int> get count async {
    final db = await AppDatabase.instance.database;
    final result =
        await db.rawQuery('SELECT COUNT(*) AS c FROM $_table');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Removes all items from the queue (call after successful sync).
  Future<void> clear() async {
    final db = await AppDatabase.instance.database;
    await db.delete(_table);
  }

  /// Removes a single item by [id] (for partial sync retry if needed).
  Future<void> remove(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> get isEmpty async => (await count) == 0;
}
