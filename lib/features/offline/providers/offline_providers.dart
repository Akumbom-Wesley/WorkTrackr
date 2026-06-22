import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../queue/checkin_queue.dart';
import '../sync/sync_service.dart';

/// Exposes the current offline queue count to the UI.
/// Invalidate after enqueue or sync to refresh badge.
final queueCountProvider = Provider<int>((ref) {
  return CheckinQueue.instance.count;
});

/// Exposes syncNow() to the UI (e.g. manual retry button).
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService.instance;
});
