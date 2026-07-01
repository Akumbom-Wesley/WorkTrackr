import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../model/hr_dashboard_models.dart';
import 'hr_dashboard_cache.dart';

class HrDashboardRepository {
  HrDashboardRepository()
      : _dio = DioClient.instance.dio,
        _cache = HrDashboardCache.instance;

  final Dio _dio;
  final HrDashboardCache _cache;

  static const String _statsPath = '/dashboard/hr/';

  /// Cache-then-network stream, identical pattern to DashboardRepository:
  /// 1. Yield cached stats immediately if present.
  /// 2. Attempt the network call.
  /// 3. On success: write through to cache, yield fresh data.
  /// 4. On failure: if cache was already yielded, swallow the error
  ///    (cached data stays on screen). If nothing was cached, rethrow
  ///    so the UI can show a real error state.
  Stream<HrDashboardStats> watchHrStats() async* {
    final cached = await _readCache();
    var hadCache = false;

    if (cached != null) {
      hadCache = true;
      yield cached;
    }

    try {
      final fresh = await _fetchFromNetwork();
      yield fresh;
    } catch (e) {
      if (!hadCache) rethrow;
      // Cached data already on screen — nothing further to do.
    }
  }

  Future<HrDashboardStats?> _readCache() async {
    final json = await _cache.read(HrDashboardCache.scopeStats);
    if (json == null) return null;
    return HrDashboardStats.fromJson(json, isFromCache: true);
  }

  Future<HrDashboardStats> _fetchFromNetwork() async {
    final response = await _dio.get<Map<String, dynamic>>(_statsPath);
    final json = response.data!;
    await _cache.write(HrDashboardCache.scopeStats, json);
    return HrDashboardStats.fromJson(json, isFromCache: false);
  }

  /// Kept for any call sites still using the old one-shot API.
  Future<HrDashboardStats> fetchStats() => _fetchFromNetwork();
}
