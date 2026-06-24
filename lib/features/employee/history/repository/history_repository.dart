import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../model/history_models.dart';
import 'history_cache.dart';

class HistoryRepository {
  HistoryRepository()
      : _dio = DioClient.instance.dio,
        _cache = HistoryCache.instance;

  final Dio _dio;
  final HistoryCache _cache;

  static const _historyEndpoint = '/employees/me/history/';

  /// Cache-then-network stream for the given date range.
  /// Cache scope encodes the date range so different ranges don't collide.
  Stream<HistoryReport> watchHistory({
    required DateTime dateFrom,
    required DateTime dateTo,
  }) async* {
    final scope = _scope(dateFrom, dateTo);
    final cached = await _readCache(scope);
    var hadCache = false;

    if (cached != null) {
      hadCache = true;
      yield HistoryReport.fromJson(cached, isFromCache: true);
    }

    try {
      final fresh = await _fetchFromNetwork(dateFrom: dateFrom, dateTo: dateTo);
      await _cache.write(scope, fresh);
      yield HistoryReport.fromJson(fresh, isFromCache: false);
    } catch (e) {
      if (!hadCache) rethrow;
    }
  }

  Future<Map<String, dynamic>?> _readCache(String scope) async {
    final json = await _cache.read(scope);
    return json;
  }

  Future<Map<String, dynamic>> _fetchFromNetwork({
    required DateTime dateFrom,
    required DateTime dateTo,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _historyEndpoint,
      queryParameters: {
        'date_from': _fmt(dateFrom),
        'date_to': _fmt(dateTo),
      },
    );
    return response.data!;
  }

  /// Scope string encodes date range — e.g. "history:2026-06-01:2026-06-30"
  static String _scope(DateTime from, DateTime to) =>
      'history:${_fmt(from)}:${_fmt(to)}';

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
