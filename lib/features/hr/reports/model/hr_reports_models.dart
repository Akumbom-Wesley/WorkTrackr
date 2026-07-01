import '../../employees/model/hr_employee_models.dart';

/// Reports feature models.
///
/// Deliberately does NOT define a separate `EmployeeReport` class — the
/// backend's `/reports/employee/{id}/` JSON response is byte-for-byte the
/// same shape as `/employees/{id}/history/`, which `HrEmployeeHistory`
/// already models and `HrEmployeeRepository.fetchHistory()` already fetches
/// (cache-aware). `HrReportsRepository.fetchEmployeeReport()` delegates to
/// that existing method for the JSON case rather than duplicating it.
///
/// `CompanyReport` has no existing equivalent anywhere in the codebase, so
/// it's genuinely new — its `employees` list reuses `HrEmployeeHistory` for
/// each entry, since the backend doc confirms each item in that array has
/// the identical per-employee shape.
class CompanyReport {
  final String company;
  final DateTime dateFrom;
  final DateTime dateTo;
  final String companyTotalHoursWorked;
  final List<HrEmployeeHistory> employees;

  const CompanyReport({
    required this.company,
    required this.dateFrom,
    required this.dateTo,
    required this.companyTotalHoursWorked,
    required this.employees,
  });

  factory CompanyReport.fromJson(Map<String, dynamic> json) {
    return CompanyReport(
      company: json['company'] as String,
      dateFrom: DateTime.parse(json['date_from'] as String),
      dateTo: DateTime.parse(json['date_to'] as String),
      companyTotalHoursWorked: json['company_total_hours_worked'] as String,
      employees: (json['employees'] as List<dynamic>)
          .map((e) => HrEmployeeHistory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'company': company,
        'date_from': dateFrom.toIso8601String(),
        'date_to': dateTo.toIso8601String(),
        'company_total_hours_worked': companyTotalHoursWorked,
        'employees': employees.map((e) => e.toJson()).toList(),
      };
}

/// Which perspective the Reports screen's form is currently set to —
/// drives which fields are shown (employee picker vs nothing extra) and
/// which repository method/endpoint gets called on Generate.
enum ReportPerspective { employee, company }

/// Output format — `json` renders in-app via ReportResultView, `csv`/`pdf`
/// trigger a real file download + save-to-device via MediaStoreSaver on
/// Android (API 29+) or raw-path write (pre-29), path_provider on other
/// platforms.
enum ReportOutputFormat { json, csv, pdf }

extension ReportOutputFormatX on ReportOutputFormat {
  String get apiValue => switch (this) {
        ReportOutputFormat.json => 'json',
        ReportOutputFormat.csv => 'csv',
        ReportOutputFormat.pdf => 'pdf',
      };

  /// MIME type required by MediaStore at insert time (API 29+).
  String get mimeType => switch (this) {
        ReportOutputFormat.json => 'application/json',
        ReportOutputFormat.csv => 'text/csv',
        ReportOutputFormat.pdf => 'application/pdf',
      };
}
