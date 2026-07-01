import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../employees/model/hr_employee_models.dart';
import '../../employees/repository/hr_employee_repository.dart';
import '../model/hr_reports_models.dart';

/// Result of a csv/pdf report fetch — raw bytes plus a filename derived
/// from the response headers (falls back to a generated name if the
/// backend doesn't send Content-Disposition).
class ReportFileResult {
  final List<int> bytes;
  final String suggestedFileName;
  const ReportFileResult({required this.bytes, required this.suggestedFileName});
}

class HrReportsRepository {
  HrReportsRepository()
      : _dio = DioClient.instance.dio,
        _employeeRepo = HrEmployeeRepository();

  final Dio _dio;
  final HrEmployeeRepository _employeeRepo;

  // ── Employee report ─────────────────────────────────────────────────────
  //
  // JSON case delegates to HrEmployeeRepository.fetchHistory(), which is
  // the exact same backend call (/employees/{id}/history/, same response
  // shape) and is already cache-aware. No reason to re-implement it here.
  // csv/pdf hit /reports/employee/{id}/ directly since fetchHistory() has
  // no concept of output_format and those formats aren't cacheable in the
  // same sense (Reports is explicitly out of the offline-first scope).

  Future<HrEmployeeHistory> fetchEmployeeReportJson(
    int employeeId, {
    required String dateFrom,
    required String dateTo,
  }) {
    return _employeeRepo.fetchHistory(
      employeeId,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }

  Future<ReportFileResult> fetchEmployeeReportFile(
    int employeeId, {
    required String dateFrom,
    required String dateTo,
    required ReportOutputFormat format,
  }) async {
    assert(format != ReportOutputFormat.json);
    final response = await _dio.get<List<int>>(
      '/reports/employee/$employeeId/',
      queryParameters: {
        'date_from': dateFrom,
        'date_to': dateTo,
        'output_format': format.apiValue,
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return ReportFileResult(
      bytes: response.data ?? const [],
      suggestedFileName: _fileNameFrom(response, fallback: 'employee_report', format: format),
    );
  }

  // ── Company report ──────────────────────────────────────────────────────
  //
  // No existing repository method covers this — genuinely new. companyId
  // is only sent when explicitly provided (per backend doc: required only
  // for SUPER_ADMIN, HR_ADMIN is auto-scoped server-side).

  Future<CompanyReport> fetchCompanyReportJson({
    required String dateFrom,
    required String dateTo,
    int? companyId,
  }) async {
    final response = await _dio.get(
      '/reports/company/',
      queryParameters: {
        'date_from': dateFrom,
        'date_to': dateTo,
        if (companyId != null) 'company_id': companyId,
      },
    );
    return CompanyReport.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ReportFileResult> fetchCompanyReportFile({
    required String dateFrom,
    required String dateTo,
    required ReportOutputFormat format,
    int? companyId,
  }) async {
    assert(format != ReportOutputFormat.json);
    final response = await _dio.get<List<int>>(
      '/reports/company/',
      queryParameters: {
        'date_from': dateFrom,
        'date_to': dateTo,
        'output_format': format.apiValue,
        if (companyId != null) 'company_id': companyId,
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return ReportFileResult(
      bytes: response.data ?? const [],
      suggestedFileName: _fileNameFrom(response, fallback: 'company_report', format: format),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _fileNameFrom(
    Response response, {
    required String fallback,
    required ReportOutputFormat format,
  }) {
    final disposition = response.headers.value('content-disposition');
    if (disposition != null) {
      final match = RegExp(r'filename="?([^"]+)"?').firstMatch(disposition);
      if (match != null) return _sanitizeFileName(match.group(1)!);
    }
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '${fallback}_$ts.${format.apiValue}';
  }

  /// Replaces whitespace runs in a filename with underscores. Backend-supplied
  /// Content-Disposition filenames (e.g. derived from a company name) can
  /// contain spaces, which break shell/URI tooling (adb, MEDIA_SCANNER_SCAN_FILE
  /// broadcasts) and can affect Downloads-app indexing. Only whitespace is
  /// touched here -- other characters are left as-is.
  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r"\s+"), "_");
  }
}
