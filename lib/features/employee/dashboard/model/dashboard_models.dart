/// Matches GET /api/v1/auth/me/
class MeResponse {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String erpnextEmployeeId;
  final int? company;
  final String? companyName;
  final bool isOnboarded;

  /// Employee.pk — required for /employees/{pk}/status/
  /// Added via UserProfileSerializer.get_employee_id()
  final int? employeeId;

  const MeResponse({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.erpnextEmployeeId,
    this.company,
    this.companyName,
    required this.isOnboarded,
    this.employeeId,
  });

  /// Display name: first name if set, else username.
  String get displayFirstName =>
      firstName.isNotEmpty ? firstName : username;

  String get fullName =>
      [firstName, lastName].where((s) => s.isNotEmpty).join(' ');

  factory MeResponse.fromJson(Map<String, dynamic> json) {
    return MeResponse(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      role: json['role'] as String,
      erpnextEmployeeId: json['erpnext_employee_id'] as String,
      company: json['company'] as int?,
      companyName: json['company_name'] as String?,
      isOnboarded: json['is_onboarded'] as bool? ?? false,
      employeeId: json['employee_id'] as int?,
    );
  }
}

/// Matches GET /api/v1/employees/{pk}/status/
/// All fields nullable — endpoint returns nulls when no status exists yet.
class EmployeeStatusResponse {
  final String? status;
  final DateTime? changedAt;
  final DateTime? autoReturnAt;

  const EmployeeStatusResponse({
    this.status,
    this.changedAt,
    this.autoReturnAt,
  });

  factory EmployeeStatusResponse.fromJson(Map<String, dynamic> json) {
    return EmployeeStatusResponse(
      status: json['status'] as String?,
      changedAt: json['changed_at'] != null
          ? DateTime.parse(json['changed_at'] as String)
          : null,
      autoReturnAt: json['auto_return_at'] != null
          ? DateTime.parse(json['auto_return_at'] as String)
          : null,
    );
  }
}

/// One record from GET /api/v1/employees/me/history/
class AttendanceRecord {
  final int id;
  final String logType; // 'IN' or 'OUT'
  final DateTime timestampGps;
  final DateTime? timestampDevice;
  final bool isFlagged;

  const AttendanceRecord({
    required this.id,
    required this.logType,
    required this.timestampGps,
    this.timestampDevice,
    required this.isFlagged,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as int,
      logType: json['log_type'] as String,
      timestampGps: DateTime.parse(json['timestamp_gps'] as String),
      timestampDevice: json['timestamp_device'] != null
          ? DateTime.parse(json['timestamp_device'] as String)
          : null,
      isFlagged: json['is_flagged'] as bool? ?? false,
    );
  }
}

/// Computed from today's [AttendanceRecord] list.
class TodaySummary {
  final DateTime? clockIn;
  final DateTime? clockOut;
  final Duration hoursWorked;

  const TodaySummary({
    this.clockIn,
    this.clockOut,
    required this.hoursWorked,
  });

  factory TodaySummary.fromRecords(List<AttendanceRecord> records) {
    final now = DateTime.now();

    final todayRecords = records.where((r) {
      final local = r.timestampGps.toLocal();
      return local.year == now.year &&
          local.month == now.month &&
          local.day == now.day;
    }).toList()
      ..sort((a, b) => a.timestampGps.compareTo(b.timestampGps));

    DateTime? clockIn;
    DateTime? clockOut;

    for (final r in todayRecords) {
      if (r.logType == 'IN' && clockIn == null) {
        clockIn = r.timestampGps.toLocal();
      }
      if (r.logType == 'OUT') {
        clockOut = r.timestampGps.toLocal();
      }
    }

    Duration worked = Duration.zero;
    if (clockIn != null) {
      final end = clockOut ?? DateTime.now();
      worked = end.difference(clockIn);
      if (worked.isNegative) worked = Duration.zero;
    }

    return TodaySummary(
      clockIn: clockIn,
      clockOut: clockOut,
      hoursWorked: worked,
    );
  }
}

/// Top-level object the provider exposes to the screen.
class DashboardData {
  final MeResponse me;
  final EmployeeStatusResponse employeeStatus;
  final TodaySummary todaySummary;

  const DashboardData({
    required this.me,
    required this.employeeStatus,
    required this.todaySummary,
  });
}