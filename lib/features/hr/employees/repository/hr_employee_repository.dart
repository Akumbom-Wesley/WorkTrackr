import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../model/hr_employee_models.dart';
import 'hr_employee_cache.dart';

class HrEmployeeRepository {
  HrEmployeeRepository()
      : _dio = DioClient.instance.dio,
        _cache = HrEmployeeCache.instance;

  final Dio _dio;
  final HrEmployeeCache _cache;

  // ── Employee list ──────────────────────────────────────────────────────
  //
  // Cache-then-network stream, identical pattern to DashboardRepository /
  // HrDashboardRepository / HistoryRepository:
  // 1. Yield cached data immediately if present.
  // 2. Attempt the network call.
  // 3. On success: write through to cache, yield fresh data.
  // 4. On failure: if cache was already yielded, swallow the error
  //    (cached data stays on screen). If nothing was cached, rethrow
  //    so the UI can show a real error state.
  //
  // This is the single source of truth for the employee list — the
  // Onboarding feature derives its not-onboarded subset from this same
  // cached/fresh list rather than maintaining its own copy.
  Stream<List<HrEmployee>> watchAll() async* {
    final cached = await _cache.readList(HrEmployeeCache.scopeList);
    var hadCache = false;

    if (cached != null) {
      hadCache = true;
      yield cached
          .map((e) => HrEmployee.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    try {
      final response = await _dio.get('/employees/');
      final items = response.data as List<dynamic>;
      await _cache.writeList(HrEmployeeCache.scopeList, items);
      yield items
          .map((e) => HrEmployee.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (!hadCache) rethrow;
    }
  }

  /// One-shot fetch for callers that just need the current list without
  /// subscribing to the stream (e.g. OnboardingRepository deriving stats).
  /// Prefers cache, falls back to network, matching watchAll()'s semantics
  /// but collapsed to a single value.
  Future<List<HrEmployee>> fetchAll() async {
    List<HrEmployee>? latest;
    await for (final value in watchAll()) {
      latest = value;
    }
    if (latest == null) {
      throw StateError('Employee list stream completed with no data');
    }
    return latest;
  }

  // ── Employee detail ────────────────────────────────────────────────────

  Stream<HrEmployee> watchOne(int id) async* {
    final scope = HrEmployeeCache.scopeDetail(id);
    final cached = await _cache.read(scope);
    var hadCache = false;

    if (cached != null) {
      hadCache = true;
      yield HrEmployee.fromJson(cached);
    }

    try {
      final response = await _dio.get('/employees/$id/');
      final json = response.data as Map<String, dynamic>;
      await _cache.write(scope, json);
      yield HrEmployee.fromJson(json);
    } catch (e) {
      if (!hadCache) rethrow;
    }
  }

  Future<HrEmployee> fetchOne(int id) async {
    HrEmployee? latest;
    await for (final value in watchOne(id)) {
      latest = value;
    }
    if (latest == null) {
      throw StateError('Employee detail stream completed with no data');
    }
    return latest;
  }

  // ── Employee history (date-range scoped) ──────────────────────────────

  Stream<HrEmployeeHistory> watchHistory(
    int id, {
    required String dateFrom,
    required String dateTo,
  }) async* {
    final scope = HrEmployeeCache.scopeHistory(id, dateFrom, dateTo);
    final cached = await _cache.read(scope);
    var hadCache = false;

    if (cached != null) {
      hadCache = true;
      yield HrEmployeeHistory.fromJson(cached);
    }

    try {
      final response = await _dio.get(
        '/employees/$id/history/',
        queryParameters: {'date_from': dateFrom, 'date_to': dateTo},
      );
      final json = response.data as Map<String, dynamic>;
      await _cache.write(scope, json);
      yield HrEmployeeHistory.fromJson(json);
    } catch (e) {
      if (!hadCache) rethrow;
    }
  }

  Future<HrEmployeeHistory> fetchHistory(
    int id, {
    required String dateFrom,
    required String dateTo,
  }) async {
    HrEmployeeHistory? latest;
    await for (final value
        in watchHistory(id, dateFrom: dateFrom, dateTo: dateTo)) {
      latest = value;
    }
    if (latest == null) {
      throw StateError('Employee history stream completed with no data');
    }
    return latest;
  }

  // ── Last check-in audit ────────────────────────────────────────────────
  //
  // A 404 (no prior audit) is an expected state, not exceptional, and is
  // deliberately NOT cached — caching "null" would make a since-completed
  // first check-in invisible offline until the next successful network
  // fetch. Only real audit records are cached.

  Stream<HrCheckinAudit?> watchLastAudit(int id) async* {
    final scope = HrEmployeeCache.scopeAudit(id);
    final cached = await _cache.read(scope);
    var hadCache = false;

    if (cached != null) {
      hadCache = true;
      yield HrCheckinAudit.fromJson(cached);
    }

    try {
      final response = await _dio.get('/employees/$id/last-checkin-audit/');
      final json = response.data as Map<String, dynamic>;
      await _cache.write(scope, json);
      yield HrCheckinAudit.fromJson(json);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Confirmed no audit exists yet — evict any stale cached audit
        // from before this employee had one, then yield null.
        await _cache.delete(scope);
        yield null;
        return;
      }
      if (!hadCache) rethrow;
    } catch (e) {
      if (!hadCache) rethrow;
    }
  }

  Future<HrCheckinAudit?> fetchLastAudit(int id) async {
    HrCheckinAudit? latest;
    var got = false;
    await for (final value in watchLastAudit(id)) {
      latest = value;
      got = true;
    }
    if (!got) {
      throw StateError('Audit stream completed with no emission');
    }
    return latest;
  }
}
