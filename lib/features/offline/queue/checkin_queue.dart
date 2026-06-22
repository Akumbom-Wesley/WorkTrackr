import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../models/queued_checkin.dart';

/// Thin wrapper around the Hive box for the offline check-in queue.
/// Box must be opened before use — call [CheckinQueue.init()] in main().
class CheckinQueue {
  CheckinQueue._();
  static final CheckinQueue instance = CheckinQueue._();

  static const _boxName = AppConstants.checkinQueueBox;

  Box get _box => Hive.box(_boxName);

  static Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  /// Appends a [QueuedCheckin] to the local queue.
  Future<void> enqueue(QueuedCheckin item) async {
    await _box.put(item.id, item.toHive());
  }

  /// Returns all queued items ordered by [queuedAt] ascending.
  List<QueuedCheckin> getAll() {
    return _box.values
        .map((v) => QueuedCheckin.fromHive(v as Map))
        .toList()
      ..sort((a, b) => a.queuedAt.compareTo(b.queuedAt));
  }

  /// Number of items currently in the queue.
  int get count => _box.length;

  /// Removes all items from the queue (call after successful sync).
  Future<void> clear() async {
    await _box.clear();
  }

  /// Removes a single item by [id] (for partial sync retry if needed).
  Future<void> remove(String id) async {
    await _box.delete(id);
  }

  bool get isEmpty => _box.isEmpty;
}
