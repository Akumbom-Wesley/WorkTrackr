import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../model/hr_analytics_models.dart';
import 'hr_analytics_cache.dart';

enum AnalyticsOutputFormat { json, csv, xlsx, pdf }

extension AnalyticsOutputFormatX on AnalyticsOutputFormat {
  String get apiValue => switch (this) {
        AnalyticsOutputFormat.json => 'json',
        AnalyticsOutputFormat.csv => 'csv',
        AnalyticsOutputFormat.xlsx => 'xlsx',
        AnalyticsOutputFormat.pdf => 'pdf',
      };

  String get mimeType => switch (this) {
        AnalyticsOutputFormat.json => 'application/json',
        AnalyticsOutputFormat.csv => 'text/csv',
        AnalyticsOutputFormat.xlsx =>
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        AnalyticsOutputFormat.pdf => 'application/pdf',
      };
}

/// Result of a csv/xlsx analytics export fetch — same shape as
/// ReportFileResult in the Reports feature (raw bytes + a filename derived
/// from Content-Disposition), kept as a separate local type since Analytics
/// and Reports are unrelated features and Reports' output-format enum
/// includes PDF, which Analytics never supports.
class AnalyticsFileResult {
  final List<int> bytes;
  final String suggestedFileName;
  const AnalyticsFileResult({required this.bytes, required this.suggestedFileName});
}

/// Analytics is offline-first (cache-then-network), UNLIKE Reports which is
/// explicitly request-driven/on-demand. Every JSON-fetching method here
/// follows the same cache-then-network stream shape used across the rest
/// of the app (HrEmployeeRepository, HrDashboardRepository, etc.). CSV/XLSX
/// exports are NOT cached — a downloaded file is a one-shot artifact, same
/// reasoning as Reports' file exports.
class HrAnalyticsRepository {
  HrAnalyticsRepository()
      : _dio = DioClient.instance.dio,
        _cache = HrAnalyticsCache.instance;

  final Dio _dio;
  final HrAnalyticsCache _cache;

  Map<String, dynamic> _rangeParams({String? period, String? dateFrom, String? dateTo}) {
    return {
      if (dateFrom == null && dateTo == null && period != null) 'period': period,
      if (dateFrom != null) 'date_from': dateFrom,
      if (dateTo != null) 'date_to': dateTo,
    };
  }

  // ── Attendance summary ───────────────────────────────────────────────────

  Stream<AttendanceSummary> watchAttendanceSummary({
    String? period,
    String? dateFrom,
    String? dateTo,
  }) async* {
    final params = _rangeParams(period: period, dateFrom: dateFrom, dateTo: dateTo);
    final scope = HrAnalyticsCache.scopeFor(
      'attendance_summary',
      period: period,
      dateFrom: dateFrom ?? '',
      dateTo: dateTo ?? '',
    );
    final cached = await _cache.read(scope);
    var hadCache = false;

    if (cached != null) {
      hadCache = true;
      yield AttendanceSummary.fromJson(cached);
    }

    try {
      final response = await _dio.get(
        '/analytics/attendance-summary/',
        queryParameters: params,
      );
      final json = response.data as Map<String, dynamic>;
      await _cache.write(scope, json);
      yield AttendanceSummary.fromJson(json);
    } catch (e) {
      if (!hadCache) rethrow;
    }
  }

  Future<AttendanceSummary> fetchAttendanceSummary({
    String? period,
    String? dateFrom,
    String? dateTo,
  }) async {
    AttendanceSummary? latest;
    await for (final value in watchAttendanceSummary(
      period: period,
      dateFrom: dateFrom,
      dateTo: dateTo,
    )) {
      latest = value;
    }
    if (latest == null) {
      throw StateError('Attendance summary stream completed with no data');
    }
    return latest;
  }

  Future<AnalyticsFileResult> fetchAttendanceSummaryFile({
    String? period,
    String? dateFrom,
    String? dateTo,
    required AnalyticsOutputFormat format,
  }) async {
    assert(format != AnalyticsOutputFormat.json);
    final params = _rangeParams(period: period, dateFrom: dateFrom, dateTo: dateTo)
      ..['output_format'] = format.apiValue;
    final response = await _dio.get<List<int>>(
      '/analytics/attendance-summary/',
      queryParameters: params,
      options: Options(responseType: ResponseType.bytes),
    );
    return AnalyticsFileResult(
      bytes: response.data ?? const [],
      suggestedFileName:
          _fileNameFrom(response, fallback: 'attendance_summary', format: format),
    );
  }

  // ── Attendance trend ──────────────────────────────────────────────────────

  Stream<AttendanceTrend> watchAttendanceTrend({
    String? period,
    String? dateFrom,
    String? dateTo,
  }) async* {
    final params = _rangeParams(period: period, dateFrom: dateFrom, dateTo: dateTo);
    final scope = HrAnalyticsCache.scopeFor(
      'attendance_trend',
      period: period,
      dateFrom: dateFrom ?? '',
      dateTo: dateTo ?? '',
    );
    final cached = await _cache.read(scope);
    var hadCache = false;

    if (cached != null) {
      hadCache = true;
      yield AttendanceTrend.fromJson(cached);
    }

    try {
      final response = await _dio.get(
        '/analytics/attendance-trend/',
        queryParameters: params,
      );
      final json = response.data as Map<String, dynamic>;
      await _cache.write(scope, json);
      yield AttendanceTrend.fromJson(json);
    } catch (e) {
      if (!hadCache) rethrow;
    }
  }

  Future<AttendanceTrend> fetchAttendanceTrend({
    String? period,
    String? dateFrom,
    String? dateTo,
  }) async {
    AttendanceTrend? latest;
    await for (final value in watchAttendanceTrend(
      period: period,
      dateFrom: dateFrom,
      dateTo: dateTo,
    )) {
      latest = value;
    }
    if (latest == null) {
      throw StateError('Attendance trend stream completed with no data');
    }
    return latest;
  }

  Future<AnalyticsFileResult> fetchAttendanceTrendFile({
    String? period,
    String? dateFrom,
    String? dateTo,
    required AnalyticsOutputFormat format,
  }) async {
    assert(format != AnalyticsOutputFormat.json);
    final params = _rangeParams(period: period, dateFrom: dateFrom, dateTo: dateTo)
      ..['output_format'] = format.apiValue;
    final response = await _dio.get<List<int>>(
      '/analytics/attendance-trend/',
      queryParameters: params,
      options: Options(responseType: ResponseType.bytes),
    );
    return AnalyticsFileResult(
      bytes: response.data ?? const [],
      suggestedFileName:
          _fileNameFrom(response, fallback: 'attendance_trend', format: format),
    );
  }

  // ── Late arrivals ─────────────────────────────────────────────────────────

  Stream<LateArrivalsReport> watchLateArrivals({
    String? period,
    String? dateFrom,
    String? dateTo,
  }) async* {
    final params = _rangeParams(period: period, dateFrom: dateFrom, dateTo: dateTo);
    final scope = HrAnalyticsCache.scopeFor(
      'late_arrivals',
      period: period,
      dateFrom: dateFrom ?? '',
      dateTo: dateTo ?? '',
    );
    final cached = await _cache.read(scope);
    var hadCache = false;

    if (cached != null) {
      hadCache = true;
      yield LateArrivalsReport.fromJson(cached);
    }

    try {
      final response = await _dio.get(
        '/analytics/late-arrivals/',
        queryParameters: params,
      );
      final json = response.data as Map<String, dynamic>;
      await _cache.write(scope, json);
      yield LateArrivalsReport.fromJson(json);
    } catch (e) {
      if (!hadCache) rethrow;
    }
  }

  Future<LateArrivalsReport> fetchLateArrivals({
    String? period,
    String? dateFrom,
    String? dateTo,
  }) async {
    LateArrivalsReport? latest;
    await for (final value in watchLateArrivals(
      period: period,
      dateFrom: dateFrom,
      dateTo: dateTo,
    )) {
      latest = value;
    }
    if (latest == null) {
      throw StateError('Late arrivals stream completed with no data');
    }
    return latest;
  }

  Future<AnalyticsFileResult> fetchLateArrivalsFile({
    String? period,
    String? dateFrom,
    String? dateTo,
    required AnalyticsOutputFormat format,
  }) async {
    assert(format != AnalyticsOutputFormat.json);
    final params = _rangeParams(period: period, dateFrom: dateFrom, dateTo: dateTo)
      ..['output_format'] = format.apiValue;
    final response = await _dio.get<List<int>>(
      '/analytics/late-arrivals/',
      queryParameters: params,
      options: Options(responseType: ResponseType.bytes),
    );
    return AnalyticsFileResult(
      bytes: response.data ?? const [],
      suggestedFileName:
          _fileNameFrom(response, fallback: 'late_arrivals', format: format),
    );
  }

  // ── Hours leaderboard ─────────────────────────────────────────────────────

  Stream<HoursLeaderboard> watchHoursLeaderboard({
    String? period,
    String? dateFrom,
    String? dateTo,
  }) async* {
    final params = _rangeParams(period: period, dateFrom: dateFrom, dateTo: dateTo);
    final scope = HrAnalyticsCache.scopeFor(
      'hours_leaderboard',
      period: period,
      dateFrom: dateFrom ?? '',
      dateTo: dateTo ?? '',
    );
    final cached = await _cache.read(scope);
    var hadCache = false;

    if (cached != null) {
      hadCache = true;
      yield HoursLeaderboard.fromJson(cached);
    }

    try {
      final response = await _dio.get(
        '/analytics/hours-leaderboard/',
        queryParameters: params,
      );
      final json = response.data as Map<String, dynamic>;
      await _cache.write(scope, json);
      yield HoursLeaderboard.fromJson(json);
    } catch (e) {
      if (!hadCache) rethrow;
    }
  }

  Future<HoursLeaderboard> fetchHoursLeaderboard({
    String? period,
    String? dateFrom,
    String? dateTo,
  }) async {
    HoursLeaderboard? latest;
    await for (final value in watchHoursLeaderboard(
      period: period,
      dateFrom: dateFrom,
      dateTo: dateTo,
    )) {
      latest = value;
    }
    if (latest == null) {
      throw StateError('Hours leaderboard stream completed with no data');
    }
    return latest;
  }

  Future<AnalyticsFileResult> fetchHoursLeaderboardFile({
    String? period,
    String? dateFrom,
    String? dateTo,
    required AnalyticsOutputFormat format,
  }) async {
    assert(format != AnalyticsOutputFormat.json);
    final params = _rangeParams(period: period, dateFrom: dateFrom, dateTo: dateTo)
      ..['output_format'] = format.apiValue;
    final response = await _dio.get<List<int>>(
      '/analytics/hours-leaderboard/',
      queryParameters: params,
      options: Options(responseType: ResponseType.bytes),
    );
    return AnalyticsFileResult(
      bytes: response.data ?? const [],
      suggestedFileName:
          _fileNameFrom(response, fallback: 'hours_leaderboard', format: format),
    );
  }

  // ── Department Breakdown ──────────────────────────────────────────────────

  Stream<DepartmentBreakdown> watchDepartmentBreakdown({
    String? period,
    String? dateFrom,
    String? dateTo,
  }) async* {
    final params = _rangeParams(period: period, dateFrom: dateFrom, dateTo: dateTo);
    final scope = HrAnalyticsCache.scopeFor(
      'department_breakdown',
      period: period,
      dateFrom: dateFrom ?? '',
      dateTo: dateTo ?? '',
    );
    final cached = await _cache.read(scope);
    var hadCache = false;

    if (cached != null) {
      hadCache = true;
      yield DepartmentBreakdown.fromJson(cached);
    }

    try {
      final response = await _dio.get(
        '/analytics/department-breakdown/',
        queryParameters: params,
      );
      final json = response.data as Map<String, dynamic>;
      await _cache.write(scope, json);
      yield DepartmentBreakdown.fromJson(json);
    } catch (e) {
      if (!hadCache) rethrow;
    }
  }

  Future<DepartmentBreakdown> fetchDepartmentBreakdown({
    String? period,
    String? dateFrom,
    String? dateTo,
  }) async {
    DepartmentBreakdown? latest;
    await for (final value in watchDepartmentBreakdown(
      period: period,
      dateFrom: dateFrom,
      dateTo: dateTo,
    )) {
      latest = value;
    }
    if (latest == null) {
      throw StateError('Department breakdown stream completed with no data');
    }
    return latest;
  }

  Future<AnalyticsFileResult> fetchDepartmentBreakdownFile({
    String? period,
    String? dateFrom,
    String? dateTo,
    required AnalyticsOutputFormat format,
  }) async {
    assert(format != AnalyticsOutputFormat.json);
    final params = _rangeParams(period: period, dateFrom: dateFrom, dateTo: dateTo)
      ..['output_format'] = format.apiValue;
    final response = await _dio.get<List<int>>(
      '/analytics/department-breakdown/',
      queryParameters: params,
      options: Options(responseType: ResponseType.bytes),
    );
    return AnalyticsFileResult(
      bytes: response.data ?? const [],
      suggestedFileName:
          _fileNameFrom(response, fallback: 'department_breakdown', format: format),
    );
  }

  // ── Shift Compliance ──────────────────────────────────────────────────────

  Stream<ShiftCompliance> watchShiftCompliance({
    String? period,
    String? dateFrom,
    String? dateTo,
  }) async* {
    final params = _rangeParams(period: period, dateFrom: dateFrom, dateTo: dateTo);
    final scope = HrAnalyticsCache.scopeFor(
      'shift_compliance',
      period: period,
      dateFrom: dateFrom ?? '',
      dateTo: dateTo ?? '',
    );
    final cached = await _cache.read(scope);
    var hadCache = false;

    if (cached != null) {
      hadCache = true;
      yield ShiftCompliance.fromJson(cached);
    }

    try {
      final response = await _dio.get(
        '/analytics/shift-compliance/',
        queryParameters: params,
      );
      final json = response.data as Map<String, dynamic>;
      await _cache.write(scope, json);
      yield ShiftCompliance.fromJson(json);
    } catch (e) {
      if (!hadCache) rethrow;
    }
  }

  Future<ShiftCompliance> fetchShiftCompliance({
    String? period,
    String? dateFrom,
    String? dateTo,
  }) async {
    ShiftCompliance? latest;
    await for (final value in watchShiftCompliance(
      period: period,
      dateFrom: dateFrom,
      dateTo: dateTo,
    )) {
      latest = value;
    }
    if (latest == null) {
      throw StateError('Shift compliance stream completed with no data');
    }
    return latest;
  }

  Future<AnalyticsFileResult> fetchShiftComplianceFile({
    String? period,
    String? dateFrom,
    String? dateTo,
    required AnalyticsOutputFormat format,
  }) async {
    assert(format != AnalyticsOutputFormat.json);
    final params = _rangeParams(period: period, dateFrom: dateFrom, dateTo: dateTo)
      ..['output_format'] = format.apiValue;
    final response = await _dio.get<List<int>>(
      '/analytics/shift-compliance/',
      queryParameters: params,
      options: Options(responseType: ResponseType.bytes),
    );
    return AnalyticsFileResult(
      bytes: response.data ?? const [],
      suggestedFileName:
          _fileNameFrom(response, fallback: 'shift_compliance', format: format),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  // Duplicated from HrReportsRepository rather than shared, since the two
  // features are otherwise fully decoupled and this is ~10 lines.

  String _fileNameFrom(
    Response response, {
    required String fallback,
    required AnalyticsOutputFormat format,
  }) {
    final disposition = response.headers.value('content-disposition');
    if (disposition != null) {
      final match = RegExp(r'filename="?([^"]+)"?').firstMatch(disposition);
      if (match != null) return _sanitizeFileName(match.group(1)!);
    }
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '${fallback}_$ts.${format.apiValue}';
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r"\s+"), "_");
  }
}
