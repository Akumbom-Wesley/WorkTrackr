import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../reports/repository/media_store_saver.dart';
import '../model/hr_analytics_models.dart';
import '../repository/hr_analytics_repository.dart';

final hrAnalyticsRepositoryProvider = Provider<HrAnalyticsRepository>(
  (_) => HrAnalyticsRepository(),
);

String? _iso(DateTime? d) => d == null
    ? null
    : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// ── Shared period/date selector, used by ALL 3 tabs ─────────────────────
final hrAnalyticsPeriodProvider = StateProvider<String?>((ref) => 'week');
final hrAnalyticsDateFromProvider = StateProvider<DateTime?>((ref) => null);
final hrAnalyticsDateToProvider = StateProvider<DateTime?>((ref) => null);

// ── Performance tab (Hours Leaderboard) ─────────────────────────────────

class HrHoursLeaderboardNotifier extends AsyncNotifier<HoursLeaderboard> {
  @override
  Future<HoursLeaderboard> build() async {
    final period = ref.watch(hrAnalyticsPeriodProvider);
    final dateFrom = ref.watch(hrAnalyticsDateFromProvider);
    final dateTo = ref.watch(hrAnalyticsDateToProvider);
    final repo = ref.watch(hrAnalyticsRepositoryProvider);
    return _fetch(repo, period, dateFrom, dateTo);
  }

  Future<HoursLeaderboard> _fetch(
    HrAnalyticsRepository repo,
    String? period,
    DateTime? dateFrom,
    DateTime? dateTo,
  ) async {
    // Cache-then-network: explicitly set loading, yield cache immediately
    // if present, then overwrite with fresh network data.
    // Using await-for over the repository stream rather than .listen() +
    // .asFuture() — the old pattern set state as a side-effect inside
    // callbacks, which races with Riverpod's own build() lifecycle and
    // causes stale/empty data on period changes.
    final effectivePeriod = (dateFrom != null || dateTo != null) ? null : period;
    final isoFrom = _iso(dateFrom);
    final isoTo = _iso(dateTo);

    HoursLeaderboard? result;
    await for (final value in repo.watchHoursLeaderboard(
      period: effectivePeriod,
      dateFrom: isoFrom,
      dateTo: isoTo,
    )) {
      result = value;
      // Emit cache hit immediately so the UI shows stale data rather than
      // a loading spinner while the network call is in flight.
      state = AsyncData(value);
    }

    if (result == null) {
      throw StateError('Hours leaderboard stream completed with no data');
    }
    return result;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(
          ref.read(hrAnalyticsRepositoryProvider),
          ref.read(hrAnalyticsPeriodProvider),
          ref.read(hrAnalyticsDateFromProvider),
          ref.read(hrAnalyticsDateToProvider),
        ));
  }
}

final hrHoursLeaderboardProvider =
    AsyncNotifierProvider<HrHoursLeaderboardNotifier, HoursLeaderboard>(
  HrHoursLeaderboardNotifier.new,
);

// ── Attendance tab (Summary + Trend) ─────────────────────────────────────

class HrAttendanceAnalyticsData {
  final AttendanceSummary summary;
  final AttendanceTrend trend;
  final DepartmentBreakdown breakdown;
  const HrAttendanceAnalyticsData({
    required this.summary,
    required this.trend,
    required this.breakdown,
  });
}

class HrAttendanceAnalyticsNotifier
    extends AsyncNotifier<HrAttendanceAnalyticsData> {
  @override
  Future<HrAttendanceAnalyticsData> build() async {
    final period = ref.watch(hrAnalyticsPeriodProvider);
    final dateFrom = ref.watch(hrAnalyticsDateFromProvider);
    final dateTo = ref.watch(hrAnalyticsDateToProvider);
    final repo = ref.watch(hrAnalyticsRepositoryProvider);
    return _fetch(repo, period, dateFrom, dateTo);
  }

  Future<HrAttendanceAnalyticsData> _fetch(
    HrAnalyticsRepository repo,
    String? period,
    DateTime? dateFrom,
    DateTime? dateTo,
  ) async {
    final effectivePeriod = (dateFrom != null || dateTo != null) ? null : period;
    final isoFrom = _iso(dateFrom);
    final isoTo = _iso(dateTo);

    // Summary and trend are fetched via the direct fetch methods (not watch
    // streams) since they're always shown together and we combine them into
    // one state object. fetchX() internally does await-for over watchX()
    // which handles cache-then-network; it returns the freshest value
    // (network if available, else cache).
    final results = await Future.wait([
      repo.fetchAttendanceSummary(
        period: effectivePeriod,
        dateFrom: isoFrom,
        dateTo: isoTo,
      ),
      repo.fetchAttendanceTrend(
        period: effectivePeriod,
        dateFrom: isoFrom,
        dateTo: isoTo,
      ),
      repo.fetchDepartmentBreakdown(
        period: effectivePeriod,
        dateFrom: isoFrom,
        dateTo: isoTo,
      ),
    ]);

    return HrAttendanceAnalyticsData(
      summary: results[0] as AttendanceSummary,
      trend: results[1] as AttendanceTrend,
      breakdown: results[2] as DepartmentBreakdown,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(
          ref.read(hrAnalyticsRepositoryProvider),
          ref.read(hrAnalyticsPeriodProvider),
          ref.read(hrAnalyticsDateFromProvider),
          ref.read(hrAnalyticsDateToProvider),
        ));
  }
}

final hrAttendanceAnalyticsProvider =
    AsyncNotifierProvider<HrAttendanceAnalyticsNotifier, HrAttendanceAnalyticsData>(
  HrAttendanceAnalyticsNotifier.new,
);

// ── Efficiency tab (Late Arrivals & Shift Compliance) ─────────────────────

class HrEfficiencyAnalyticsData {
  final LateArrivalsReport lateArrivals;
  final ShiftCompliance shiftCompliance;
  const HrEfficiencyAnalyticsData({
    required this.lateArrivals,
    required this.shiftCompliance,
  });
}

class HrEfficiencyAnalyticsNotifier extends AsyncNotifier<HrEfficiencyAnalyticsData> {
  @override
  Future<HrEfficiencyAnalyticsData> build() async {
    final period = ref.watch(hrAnalyticsPeriodProvider);
    final dateFrom = ref.watch(hrAnalyticsDateFromProvider);
    final dateTo = ref.watch(hrAnalyticsDateToProvider);
    final repo = ref.watch(hrAnalyticsRepositoryProvider);
    return _fetch(repo, period, dateFrom, dateTo);
  }

  Future<HrEfficiencyAnalyticsData> _fetch(
    HrAnalyticsRepository repo,
    String? period,
    DateTime? dateFrom,
    DateTime? dateTo,
  ) async {
    final effectivePeriod = (dateFrom != null || dateTo != null) ? null : period;
    final isoFrom = _iso(dateFrom);
    final isoTo = _iso(dateTo);

    final results = await Future.wait([
      repo.fetchLateArrivals(
        period: effectivePeriod,
        dateFrom: isoFrom,
        dateTo: isoTo,
      ),
      repo.fetchShiftCompliance(
        period: effectivePeriod,
        dateFrom: isoFrom,
        dateTo: isoTo,
      ),
    ]);

    return HrEfficiencyAnalyticsData(
      lateArrivals: results[0] as LateArrivalsReport,
      shiftCompliance: results[1] as ShiftCompliance,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(
          ref.read(hrAnalyticsRepositoryProvider),
          ref.read(hrAnalyticsPeriodProvider),
          ref.read(hrAnalyticsDateFromProvider),
          ref.read(hrAnalyticsDateToProvider),
        ));
  }
}

final hrEfficiencyAnalyticsProvider =
    AsyncNotifierProvider<HrEfficiencyAnalyticsNotifier, HrEfficiencyAnalyticsData>(
  HrEfficiencyAnalyticsNotifier.new,
);

// ── Department Breakdown ──────────────────────────────────────────────────

class HrDepartmentBreakdownNotifier extends AsyncNotifier<DepartmentBreakdown> {
  @override
  Future<DepartmentBreakdown> build() async {
    final period = ref.watch(hrAnalyticsPeriodProvider);
    final dateFrom = ref.watch(hrAnalyticsDateFromProvider);
    final dateTo = ref.watch(hrAnalyticsDateToProvider);
    final repo = ref.watch(hrAnalyticsRepositoryProvider);
    return _fetch(repo, period, dateFrom, dateTo);
  }

  Future<DepartmentBreakdown> _fetch(
    HrAnalyticsRepository repo,
    String? period,
    DateTime? dateFrom,
    DateTime? dateTo,
  ) async {
    final effectivePeriod = (dateFrom != null || dateTo != null) ? null : period;
    final isoFrom = _iso(dateFrom);
    final isoTo = _iso(dateTo);

    DepartmentBreakdown? result;
    await for (final value in repo.watchDepartmentBreakdown(
      period: effectivePeriod,
      dateFrom: isoFrom,
      dateTo: isoTo,
    )) {
      result = value;
      state = AsyncData(value);
    }

    if (result == null) {
      throw StateError('Department breakdown stream completed with no data');
    }
    return result;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(
          ref.read(hrAnalyticsRepositoryProvider),
          ref.read(hrAnalyticsPeriodProvider),
          ref.read(hrAnalyticsDateFromProvider),
          ref.read(hrAnalyticsDateToProvider),
        ));
  }
}

final hrDepartmentBreakdownProvider =
    AsyncNotifierProvider<HrDepartmentBreakdownNotifier, DepartmentBreakdown>(
  HrDepartmentBreakdownNotifier.new,
);

// ── Shift Compliance ──────────────────────────────────────────────────────

class HrShiftComplianceNotifier extends AsyncNotifier<ShiftCompliance> {
  @override
  Future<ShiftCompliance> build() async {
    final period = ref.watch(hrAnalyticsPeriodProvider);
    final dateFrom = ref.watch(hrAnalyticsDateFromProvider);
    final dateTo = ref.watch(hrAnalyticsDateToProvider);
    final repo = ref.watch(hrAnalyticsRepositoryProvider);
    return _fetch(repo, period, dateFrom, dateTo);
  }

  Future<ShiftCompliance> _fetch(
    HrAnalyticsRepository repo,
    String? period,
    DateTime? dateFrom,
    DateTime? dateTo,
  ) async {
    final effectivePeriod = (dateFrom != null || dateTo != null) ? null : period;
    final isoFrom = _iso(dateFrom);
    final isoTo = _iso(dateTo);

    ShiftCompliance? result;
    await for (final value in repo.watchShiftCompliance(
      period: effectivePeriod,
      dateFrom: isoFrom,
      dateTo: isoTo,
    )) {
      result = value;
      state = AsyncData(value);
    }

    if (result == null) {
      throw StateError('Shift compliance stream completed with no data');
    }
    return result;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(
          ref.read(hrAnalyticsRepositoryProvider),
          ref.read(hrAnalyticsPeriodProvider),
          ref.read(hrAnalyticsDateFromProvider),
          ref.read(hrAnalyticsDateToProvider),
        ));
  }
}

final hrShiftComplianceProvider =
    AsyncNotifierProvider<HrShiftComplianceNotifier, ShiftCompliance>(
  HrShiftComplianceNotifier.new,
);

// ── Export (CSV/XLSX) ────────────────────────────────────────────────────

enum HrAnalyticsTab { performance, attendance, efficiency }

class HrAnalyticsExportNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async => null;

  Future<void> export(HrAnalyticsTab tab, AnalyticsOutputFormat format) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(hrAnalyticsRepositoryProvider);
      final period = ref.read(hrAnalyticsPeriodProvider);
      final dateFrom = ref.read(hrAnalyticsDateFromProvider);
      final dateTo = ref.read(hrAnalyticsDateToProvider);
      final effectivePeriod = (dateFrom != null || dateTo != null) ? null : period;
      final isoFrom = _iso(dateFrom);
      final isoTo = _iso(dateTo);

      final AnalyticsFileResult file;
      switch (tab) {
        case HrAnalyticsTab.performance:
          file = await repo.fetchHoursLeaderboardFile(
            period: effectivePeriod,
            dateFrom: isoFrom,
            dateTo: isoTo,
            format: format,
          );
        case HrAnalyticsTab.attendance:
          file = await repo.fetchAttendanceSummaryFile(
            period: effectivePeriod,
            dateFrom: isoFrom,
            dateTo: isoTo,
            format: format,
          );
        case HrAnalyticsTab.efficiency:
          file = await repo.fetchLateArrivalsFile(
            period: effectivePeriod,
            dateFrom: isoFrom,
            dateTo: isoTo,
            format: format,
          );
      }

      return _saveToDownloads(file, format: format);
    });
  }

  Future<String> _saveToDownloads(
    AnalyticsFileResult file, {
    required AnalyticsOutputFormat format,
  }) async {
    if (Platform.isAndroid) {
      final sdkInt = await MediaStoreSaver.getSdkInt();
      if (sdkInt >= 29) {
        return MediaStoreSaver.saveToDownloads(
          bytes: file.bytes,
          displayName: file.suggestedFileName,
          mimeType: format.mimeType,
        );
      } else {
        final granted = await _ensureAndroidStoragePermission();
        if (!granted) {
          throw StateError(
            'Storage permission was not granted — cannot save to Downloads.',
          );
        }
        final dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        final filePath = '${dir.path}/${file.suggestedFileName}';
        await File(filePath).writeAsBytes(file.bytes);
        return filePath;
      }
    } else {
      Directory? dir = await getDownloadsDirectory();
      dir ??= await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/${file.suggestedFileName}';
      await File(filePath).writeAsBytes(file.bytes);
      return filePath;
    }
  }

  Future<bool> _ensureAndroidStoragePermission() async {
    final storageStatus = await Permission.storage.request();
    return storageStatus.isGranted;
  }
}

final hrAnalyticsExportProvider =
    AsyncNotifierProvider<HrAnalyticsExportNotifier, String?>(
  HrAnalyticsExportNotifier.new,
);
