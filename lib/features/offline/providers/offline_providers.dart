import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../queue/checkin_queue.dart';

/// Exposes the current offline queue count to the UI.
/// Invalidate after enqueue or sync to refresh badge.
final queueCountProvider = Provider<int>((ref) {
  return CheckinQueue.instance.count;
});
