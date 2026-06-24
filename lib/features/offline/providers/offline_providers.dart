import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../queue/checkin_queue.dart';

/// Exposes the current offline queue count to the UI.
/// Invalidate (ref.invalidate(queueCountProvider)) after enqueue or sync
/// to refresh the badge.
final queueCountProvider = FutureProvider<int>((ref) {
  return CheckinQueue.instance.count;
});
