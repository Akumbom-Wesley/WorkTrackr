import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../employees/model/hr_employee_models.dart';
import '../model/hr_reports_models.dart';
import '../repository/hr_reports_repository.dart';
import '../repository/media_store_saver.dart';

final hrReportsRepositoryProvider = Provider<HrReportsRepository>(
  (_) => HrReportsRepository(),
);

// ── Form state ───────────────────────────────────────────────────────────
//
// Plain StateProviders for the form fields — Reports is request-driven
// (user fills the form, taps Generate), not auto-loaded on screen open,
// so there's no AsyncNotifier wrapping these the way the cache-then-network
// screens have. Confirmed with user: Reports is explicitly out of the
// offline-first caching scope.

final reportPerspectiveProvider =
    StateProvider<ReportPerspective>((ref) => ReportPerspective.employee);

final reportSelectedEmployeeProvider = StateProvider<HrEmployee?>((ref) => null);

final reportDateFromProvider = StateProvider<DateTime?>((ref) => null);
final reportDateToProvider = StateProvider<DateTime?>((ref) => null);

final reportOutputFormatProvider =
    StateProvider<ReportOutputFormat>((ref) => ReportOutputFormat.json);

// ── Generate result ─────────────────────────────────────────────────────

sealed class ReportResult {
  const ReportResult();
}

class EmployeeJsonResult extends ReportResult {
  final HrEmployeeHistory history;
  /// Non-null once the JSON has been saved to Downloads; null until then
  /// (should not remain null after generate() completes, since JSON format
  /// always saves-and-renders — set to null only as a defensive default).
  final String? savedPath;
  const EmployeeJsonResult(this.history, {this.savedPath});
}

class CompanyJsonResult extends ReportResult {
  final CompanyReport report;
  /// Non-null once the JSON has been saved to Downloads; null until then.
  final String? savedPath;
  const CompanyJsonResult(this.report, {this.savedPath});
}

class FileSavedResult extends ReportResult {
  final String savedPath;
  const FileSavedResult(this.savedPath);
}

class HrReportGenerateNotifier extends AsyncNotifier<ReportResult?> {
  @override
  Future<ReportResult?> build() async => null; // nothing generated yet

  Future<void> generate() async {
    final perspective = ref.read(reportPerspectiveProvider);
    final dateFrom = ref.read(reportDateFromProvider);
    final dateTo = ref.read(reportDateToProvider);
    final format = ref.read(reportOutputFormatProvider);

    if (dateFrom == null || dateTo == null) {
      state = AsyncError(
        StateError('Select both a start and end date before generating.'),
        StackTrace.current,
      );
      return;
    }

    final df = _fmt(dateFrom);
    final dt = _fmt(dateTo);
    final repo = ref.read(hrReportsRepositoryProvider);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (perspective == ReportPerspective.employee) {
        final employee = ref.read(reportSelectedEmployeeProvider);
        if (employee == null) {
          throw StateError('Select an employee before generating.');
        }
        if (format == ReportOutputFormat.json) {
          final history = await repo.fetchEmployeeReportJson(
            employee.id,
            dateFrom: df,
            dateTo: dt,
          );
          final ts = DateTime.now().millisecondsSinceEpoch;
          final fileName = 'employee_report_$ts.json';
          final savedPath = await _saveToDownloads(ReportFileResult(
            bytes: utf8.encode(jsonEncode(history.toJson())),
            suggestedFileName: fileName,
          ), format: format);
          return EmployeeJsonResult(history, savedPath: savedPath);
        }
        final file = await repo.fetchEmployeeReportFile(
          employee.id,
          dateFrom: df,
          dateTo: dt,
          format: format,
        );
        final savedPath = await _saveToDownloads(file, format: format);
        return FileSavedResult(savedPath);
      } else {
        if (format == ReportOutputFormat.json) {
          final report = await repo.fetchCompanyReportJson(
            dateFrom: df,
            dateTo: dt,
          );
          final ts = DateTime.now().millisecondsSinceEpoch;
          final fileName = 'company_report_$ts.json';
          final savedPath = await _saveToDownloads(ReportFileResult(
            bytes: utf8.encode(jsonEncode(report.toJson())),
            suggestedFileName: fileName,
          ), format: format);
          return CompanyJsonResult(report, savedPath: savedPath);
        }
        final file = await repo.fetchCompanyReportFile(
          dateFrom: df,
          dateTo: dt,
          format: format,
        );
        final savedPath = await _saveToDownloads(file, format: format);
        return FileSavedResult(savedPath);
      }
    });
  }

  /// Saves report bytes to the device's public Downloads folder.
  ///
  /// Android API 29+: delegates to MediaStoreSaver (native platform channel),
  /// which uses MediaStore.Downloads insertion — the scoped-storage-correct
  /// approach that actually registers the file with MediaStore (fixes the
  /// zero-MediaStore-record bug confirmed in the prior session).
  ///
  /// Android pre-29: falls back to a direct raw-path write. WRITE_EXTERNAL_
  /// STORAGE (maxSdkVersion=28, declared in the manifest) covers this branch.
  /// _ensureAndroidStoragePermission() is only called for this pre-29 path
  /// since MediaStore insertion needs no explicit storage permission.
  ///
  /// Non-Android: uses path_provider's getDownloadsDirectory(), unchanged
  /// from the prior implementation.
  ///
  /// NOT YET VERIFIED ON A REAL DEVICE for any branch — flagging forward
  /// per project convention.
  Future<String> _saveToDownloads(
    ReportFileResult file, {
    required ReportOutputFormat format,
  }) async {
    if (Platform.isAndroid) {
      final sdkInt = await MediaStoreSaver.getSdkInt();
      if (sdkInt >= 29) {
        // API 29+: MediaStore insertion via native channel
        return MediaStoreSaver.saveToDownloads(
          bytes: file.bytes,
          displayName: file.suggestedFileName,
          mimeType: format.mimeType,
        );
      } else {
        // Pre-29: raw-path write, needs WRITE_EXTERNAL_STORAGE
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

  /// Requests WRITE_EXTERNAL_STORAGE for pre-29 devices. On API 29+ this
  /// path is not reached (MediaStore insertion needs no storage permission),
  /// so Permission.manageExternalStorage is no longer requested — it was
  /// removed from the manifest and is no longer needed.
  Future<bool> _ensureAndroidStoragePermission() async {
    final storageStatus = await Permission.storage.request();
    return storageStatus.isGranted;
  }

  /// Best-effort API level check for the pre-29 branch decision.
  /// Uses Platform.operatingSystemVersion string parsing; not perfect
  /// but sufficient since the 29 boundary is a hard API-surface cut
  /// (MediaStore.Downloads.EXTERNAL_CONTENT_URI didn't exist before Q).
  /// If parsing fails, returns 0 (forces the safer pre-29 fallback path).
  int _androidSdkInt() {
    try {
      final version = Platform.operatingSystemVersion;
      final match = RegExp(r'SDK (\d+)').firstMatch(version);
      if (match != null) return int.parse(match.group(1)!);
    } catch (_) {}
    return 0;
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

final hrReportGenerateProvider =
    AsyncNotifierProvider<HrReportGenerateNotifier, ReportResult?>(
  HrReportGenerateNotifier.new,
);
