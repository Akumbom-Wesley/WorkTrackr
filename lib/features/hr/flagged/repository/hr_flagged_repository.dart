import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../model/hr_flagged_models.dart';
import 'hr_flagged_cache.dart';

class HrFlaggedRepository {
  HrFlaggedRepository()
      : _dio = DioClient.instance.dio,
        _cache = HrFlaggedCache.instance;

  final Dio _dio;
  final HrFlaggedCache _cache;

  /// Cache-then-network stream — same pattern as HrDashboardRepository:
  /// 1. Yield cached list immediately if present.
  /// 2. Attempt the network call.
  /// 3. On success: write through to cache, yield fresh data.
  /// 4. On failure: if cache was already yielded, swallow the error
  ///    (stale list stays on screen). If nothing was cached, rethrow
  ///    so the UI shows a real error state.
  Stream<List<FlaggedRecord>> watchFlagged({required bool showResolved}) async* {
    final scope = _cache.scopeFor(showResolved: showResolved);
    final cached = await _readCache(scope);
    var hadCache = false;

    if (cached != null) {
      hadCache = true;
      yield cached;
    }

    try {
      final fresh = await _fetchFromNetwork(showResolved: showResolved);
      await _cache.write(scope, fresh.map((r) => r.toJson()).toList());
      yield fresh;
    } catch (e) {
      if (!hadCache) rethrow;
      // Cached data already on screen — nothing further to do.
    }
  }

  Future<List<FlaggedRecord>?> _readCache(String scope) async {
    final json = await _cache.read(scope);
    if (json == null) return null;
    return json.map((e) => FlaggedRecord.fromJson(e)).toList();
  }

  Future<List<FlaggedRecord>> _fetchFromNetwork({
    required bool showResolved,
  }) async {
    final response = await _dio.get(
      '/checkins/flagged/',
      queryParameters: showResolved ? null : {'status': 'pending'},
    );
    return (response.data as List<dynamic>)
        .map((e) => FlaggedRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Resolves a flagged record via PATCH, then updates the cache for both
  /// scope keys so the record's resolved state is consistent regardless of
  /// which filter the user switches to next.
  Future<FlaggedRecord> resolve(int id) async {
    final response = await _dio.patch(
      '/checkins/flagged/$id/approve/',
      data: {'review_note': 'Resolved via Dashboard'},
    );
    final updated = FlaggedRecord.fromJson(
        response.data as Map<String, dynamic>);

    // Update both cache scopes in-place — avoids a full network refetch
    // just to keep the cached lists consistent after a resolve action.
    for (final scope in [HrFlaggedCache.scopePending, HrFlaggedCache.scopeAll]) {
      final cached = await _cache.read(scope);
      if (cached != null) {
        final updatedList = cached.map((json) {
          if (json['id'] == id) return updated.toJson();
          return json;
        }).toList();
        await _cache.write(scope, updatedList);
      }
    }

    return updated;
  }
}
