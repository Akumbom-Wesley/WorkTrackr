import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

  // Use ValueNotifier so the UI can listen to sync status changes
  final ValueNotifier<SyncStatus> status = ValueNotifier(SyncStatus.idle);

  /// Call once from main().
  void start() {
    _subscription =
        Connectivity().onConnectivityChanged.listen((results) async {
      final hasRadio = results.any((r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet);

      if (hasRadio) {
        // Double check actual internet access before auto-syncing
        if (await _hasActualInternet()) {
          await syncNow();
        }
      }
    });
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Verifies if there is actual internet access, not just a radio connection.
  Future<bool> _hasActualInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Manually trigger a sync attempt. Safe to call when already syncing.
  Future<SyncResult> syncNow() async {
    if (status.value == SyncStatus.syncing) return SyncResult.skipped;

    final queue = CheckinQueue.instance;
    if (await queue.isEmpty) {
      status.value = SyncStatus.idle;
      return SyncResult.empty;
    }

    status.value = SyncStatus.syncing;

    try {
      // Final check for internet before POST
      if (!await _hasActualInternet()) {
        status.value = SyncStatus.failed;
        return SyncResult.noInternet;
      }

      final items = await queue.getAll();
      final batch = items.map((e) => e.toSyncJson()).toList();

      final response = await _dio.post<dynamic>(
        _syncEndpoint,
        data: {'records': batch},
        options: Options(validateStatus: (s) => (s ?? 0) < 500),
      );

      if (response.statusCode == 202) {
        await queue.clear();
        status.value = SyncStatus.success;
        // Reset to idle after a delay so success UI can be seen
        Future.delayed(const Duration(seconds: 3), () {
          status.value = SyncStatus.idle;
        });
        return SyncResult.success;
      }

      status.value = SyncStatus.failed;
      return SyncResult.failed;
    } on DioException {
      status.value = SyncStatus.failed;
      return SyncResult.failed;
    } catch (_) {
      status.value = SyncStatus.failed;
      return SyncResult.failed;
    }
  }
}

enum SyncStatus { idle, syncing, success, failed }
enum SyncResult { success, failed, skipped, empty, noInternet }
