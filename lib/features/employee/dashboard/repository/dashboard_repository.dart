import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../model/dashboard_models.dart';
import 'dashboard_cache.dart';

class DashboardRepository {
  DashboardRepository()
      : _dio = DioClient.instance.dio,
        _cache = DashboardCache.instance;

  final Dio _dio;
  final DashboardCache _cache;

  static const String _me = '/auth/me/';
  static const String _history = '/employees/me/history/';
  static String _status(int employeeId) => '/employees/$employeeId/status/';

  /// Cache-then-network stream, per the offline-first pattern:
  /// 1. Yield cached data immediately if any scope has it.
  /// 2. Attempt the network call.
  /// 3. On success: write through to cache, yield fresh data.
  /// 4. On failure: if cache was already yielded, swallow the error
  ///    (cached data remains on screen). If nothing was cached, rethrow
  ///    so the UI can show the error state — there's genuinely nothing
  ///    to show.
  Stream<DashboardData> watchDashboard() async* {
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

  Future<DashboardData?> _readCache() async {
    final meJson = await _cache.read(DashboardCache.scopeMe);
    if (meJson == null) return null;

    final statusJson = await _cache.read(DashboardCache.scopeStatus);
    final todayJson = await _cache.read(DashboardCache.scopeToday);
    final weekJson = await _cache.read(DashboardCache.scopeWeek);

    final me = MeResponse.fromJson(meJson);
    final status = statusJson != null
        ? EmployeeStatusResponse.fromJson(statusJson)
        : const EmployeeStatusResponse();

    final todayAttendance = (todayJson?['attendance'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final weekAttendance = (weekJson?['attendance'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    final todaySummary = TodaySummary.fromAttendance(
      todayAttendance,
      weekAttendance: weekAttendance,
    );

    return DashboardData(
      me: me,
      employeeStatus: status,
      todaySummary: todaySummary,
      isFromCache: true,
    );
  }

  Future<DashboardData> _fetchFromNetwork() async {
    final meResponse = await _dio.get<Map<String, dynamic>>(_me);
    final meJson = meResponse.data!;
    await _cache.write(DashboardCache.scopeMe, meJson);
    final me = MeResponse.fromJson(meJson);

    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final monday = now.subtract(Duration(days: now.weekday - 1));
    final mondayStr =
        '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';

    final futures = <Future<Response<Map<String, dynamic>>>>[
      _dio.get<Map<String, dynamic>>(
        _history,
        queryParameters: {'date_from': todayStr, 'date_to': todayStr},
      ),
      _dio.get<Map<String, dynamic>>(
        _history,
        queryParameters: {'date_from': mondayStr, 'date_to': todayStr},
      ),
    ];

    final results = await Future.wait(futures);

    final todayJson = results[0].data!;
    final weekJson = results[1].data!;
    await _cache.write(DashboardCache.scopeToday, todayJson);
    await _cache.write(DashboardCache.scopeWeek, weekJson);

    final todayAttendance = (todayJson['attendance'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final weekAttendance = (weekJson['attendance'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    final todaySummary = TodaySummary.fromAttendance(
      todayAttendance,
      weekAttendance: weekAttendance,
    );

    EmployeeStatusResponse status = const EmployeeStatusResponse();
    if (me.employeeId != null) {
      final statusResponse =
          await _dio.get<Map<String, dynamic>>(_status(me.employeeId!));
      final statusJson = statusResponse.data!;
      await _cache.write(DashboardCache.scopeStatus, statusJson);
      status = EmployeeStatusResponse.fromJson(statusJson);
    }

    return DashboardData(
      me: me,
      employeeStatus: status,
      todaySummary: todaySummary,
      isFromCache: false,
    );
  }
}
