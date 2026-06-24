import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../queue/checkin_queue.dart';

/// Listens for connectivity changes and automatically syncs the offline
/// check-in queue when the device comes back online.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  static const _syncEndpoint = '/checkins/sync/';

  final Dio _dio = DioClient.instance.dio;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _syncing = false;

  /// Call once from main().
  void start() {
    _subscription =
        Connectivity().onConnectivityChanged.listen((results) async {
      final online = results.any((r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet);
      if (online) await syncNow();
    });
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Manually trigger a sync attempt. Safe to call when already syncing.
  Future<SyncResult> syncNow() async {
    if (_syncing) return SyncResult.skipped;
    final queue = CheckinQueue.instance;
    if (await queue.isEmpty) return SyncResult.empty;

    _syncing = true;
    try {
      final items = await queue.getAll();
      final batch = items.map((e) => e.toSyncJson()).toList();

      final response = await _dio.post<dynamic>(
        _syncEndpoint,
        data: {'records': batch},
        options: Options(validateStatus: (s) => (s ?? 0) < 500),
      );

      if (response.statusCode == 202) {
        await queue.clear();
        return SyncResult.success;
      }
      return SyncResult.failed;
    } on DioException {
      return SyncResult.failed;
    } finally {
      _syncing = false;
    }
  }
}

enum SyncResult { success, failed, skipped, empty }
