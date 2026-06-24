/// Matches one entry from build_employee_report()['attendance'].
/// status is one of: COMPLETE | INCOMPLETE | OUT_ONLY
class AttendanceEntry {
  final DateTime date;
  final DateTime? clockIn;
  final DateTime? clockOut;
  final Duration? hoursWorked;
  final String status;

  const AttendanceEntry({
    required this.date,
    this.clockIn,
    this.clockOut,
    this.hoursWorked,
    required this.status,
  });

  factory AttendanceEntry.fromJson(Map<String, dynamic> json) {
    Duration? hw;
    final hwRaw = json['hours_worked'] as String?;
    if (hwRaw != null) {
      final parts = hwRaw.split(':');
      if (parts.length >= 2) {
        hw = Duration(
          hours: int.tryParse(parts[0]) ?? 0,
          minutes: int.tryParse(parts[1]) ?? 0,
        );
      }
    }

    return AttendanceEntry(
      date: DateTime.parse(json['date'] as String),
      clockIn: json['clock_in'] != null
          ? DateTime.parse(json['clock_in'] as String).toLocal()
          : null,
      clockOut: json['clock_out'] != null
          ? DateTime.parse(json['clock_out'] as String).toLocal()
          : null,
      hoursWorked: hw,
      status: json['status'] as String? ?? 'INCOMPLETE',
    );
  }
}

/// Matches the top-level shape of build_employee_report() JSON response.
class HistoryReport {
  final String erpnextEmployeeId;
  final String fullName;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int totalDaysPresent;
  final Duration totalHoursWorked;
  final List<AttendanceEntry> attendance;

  /// True when this data came from the local cache.
  final bool isFromCache;

  const HistoryReport({
    required this.erpnextEmployeeId,
    required this.fullName,
    this.dateFrom,
    this.dateTo,
    required this.totalDaysPresent,
    required this.totalHoursWorked,
    required this.attendance,
    this.isFromCache = false,
  });

  factory HistoryReport.fromJson(
    Map<String, dynamic> json, {
    bool isFromCache = false,
  }) {
    Duration parseDuration(String? raw) {
      if (raw == null) return Duration.zero;
      final parts = raw.split(':');
      if (parts.length < 2) return Duration.zero;
      return Duration(
        hours: int.tryParse(parts[0]) ?? 0,
        minutes: int.tryParse(parts[1]) ?? 0,
      );
    }

    final attendance = (json['attendance'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(AttendanceEntry.fromJson)
        .toList();

    return HistoryReport(
      erpnextEmployeeId: json['erpnext_employee_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      dateFrom: json['date_from'] != null
          ? DateTime.tryParse(json['date_from'] as String)
          : null,
      dateTo: json['date_to'] != null
          ? DateTime.tryParse(json['date_to'] as String)
          : null,
      totalDaysPresent: json['total_days_present'] as int? ?? 0,
      totalHoursWorked: parseDuration(json['total_hours_worked'] as String?),
      attendance: attendance,
      isFromCache: isFromCache,
    );
  }
}
