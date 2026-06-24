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


/// Computed from today's [AttendanceRecord] list.
class TodaySummary {
  final DateTime? clockIn;
  final DateTime? clockOut;
  final Duration hoursWorked;
  final Duration weekTotal;

  const TodaySummary({
    this.clockIn,
    this.clockOut,
    required this.hoursWorked,
    this.weekTotal = Duration.zero,
  });

  factory TodaySummary.fromAttendance(
    List<Map<String, dynamic>> attendance, {
    List<Map<String, dynamic>> weekAttendance = const [],
  }) {
    // attendance is a list of paired entries from the report service.
    // We want the earliest clock_in and latest clock_out for today.
    DateTime? clockIn;
    DateTime? clockOut;

    // Sum only COMPLETE entries for today's display hours.
    // For the live timer: find the open INCOMPLETE entry (clock_out == null).
    // Earliest clock_in is only used for "first clocked in at X" display.
    DateTime? firstClockIn;   // earliest clock_in of the day (display only)
    DateTime? lastClockOut;   // latest clock_out of the day
    DateTime? openClockIn;    // most recent unpaired clock_in (live timer base)
    Duration completedToday = Duration.zero;

    for (final entry in attendance) {
      final ci = entry['clock_in'];
      final co = entry['clock_out'];
      final status = entry['status'] as String? ?? '';

      if (ci != null) {
        final parsed = DateTime.parse(ci as String).toLocal();
        if (firstClockIn == null || parsed.isBefore(firstClockIn)) {
          firstClockIn = parsed;
        }
        if (status == 'INCOMPLETE' && co == null) {
          // Track most recent open session
          if (openClockIn == null || parsed.isAfter(openClockIn)) {
            openClockIn = parsed;
          }
        }
      }
      if (co != null) {
        final parsed = DateTime.parse(co as String).toLocal();
        if (lastClockOut == null || parsed.isAfter(lastClockOut)) {
          lastClockOut = parsed;
        }
      }
      // Accumulate completed session durations
      final hw = entry['hours_worked'];
      if (hw != null && status == 'COMPLETE') {
        final parts = (hw as String).split(':');
        if (parts.length >= 2) {
          final h = int.tryParse(parts[0]) ?? 0;
          final m = int.tryParse(parts[1]) ?? 0;
          completedToday += Duration(hours: h, minutes: m);
        }
      }
    }

    clockIn = firstClockIn;
    clockOut = lastClockOut;

    // hoursWorked: sum of completed sessions + live open session if any
    Duration worked = completedToday;
    if (openClockIn != null) {
      final liveElapsed = DateTime.now().difference(openClockIn);
      if (!liveElapsed.isNegative) worked += liveElapsed;
    }

    // Sum hours_worked from COMPLETE week entries
    Duration weekTotal = Duration.zero;
    for (final entry in weekAttendance) {
      final hw = entry['hours_worked'];
      if (hw != null && (entry['status'] as String? ?? '') == 'COMPLETE') {
        final parts = (hw as String).split(':');
        if (parts.length == 2) {
          final h = int.tryParse(parts[0]) ?? 0;
          final m = int.tryParse(parts[1]) ?? 0;
          weekTotal += Duration(hours: h, minutes: m);
        }
      }
    }

    return TodaySummary(
      clockIn: clockIn,
      clockOut: clockOut,
      hoursWorked: worked,
      weekTotal: weekTotal,
    );
  }
}

/// Top-level object the provider exposes to the screen.
class DashboardData {
  final MeResponse me;
  final EmployeeStatusResponse employeeStatus;
  final TodaySummary todaySummary;

  /// True when this data came from the local cache rather than a fresh
  /// network response (e.g. while offline).
  final bool isFromCache;

  const DashboardData({
    required this.me,
    required this.employeeStatus,
    required this.todaySummary,
    this.isFromCache = false,
  });
}