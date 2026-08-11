// Models for the HR Analytics feature. Field names map directly to the
// snake_case JSON documented for /api/v1/analytics/* — see handover notes.
// All models are cache-round-trippable (fromJson/toJson) since Analytics
// is offline-first like the rest of the app.

// ── Attendance Summary ──────────────────────────────────────────────────

class AttendanceSummary {
  final String? period;
  final String dateFrom;
  final String dateTo;
  final int presentCount;
  final int absentCount;
  final int totalActiveEmployees;
  final int businessDays;
  final int expectedPersonDays;
  final int actualPersonDays;
  final int absentPersonDays;
  final double attendanceRatePct;
  final double onTimeRatePct;
  final double shiftCompletionRatePct;
  final double adherenceScore;

  const AttendanceSummary({
    this.period,
    required this.dateFrom,
    required this.dateTo,
    required this.presentCount,
    required this.absentCount,
    required this.totalActiveEmployees,
    required this.businessDays,
    required this.expectedPersonDays,
    required this.actualPersonDays,
    required this.absentPersonDays,
    required this.attendanceRatePct,
    required this.onTimeRatePct,
    required this.shiftCompletionRatePct,
    required this.adherenceScore,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      period: json['period'] as String?,
      dateFrom: json['date_from'] as String,
      dateTo: json['date_to'] as String,
      presentCount: json['present_count'] as int? ?? 0,
      absentCount: json['absent_count'] as int? ?? 0,
      totalActiveEmployees: json['total_active_employees'] as int? ?? 0,
      businessDays: json['business_days'] as int? ?? 0,
      expectedPersonDays: json['expected_person_days'] as int? ?? 0,
      actualPersonDays: json['actual_person_days'] as int? ?? 0,
      absentPersonDays: json['absent_person_days'] as int? ?? 0,
      attendanceRatePct: (json['attendance_rate_pct'] as num?)?.toDouble() ?? 0.0,
      onTimeRatePct: (json['on_time_rate_pct'] as num?)?.toDouble() ?? 0.0,
      shiftCompletionRatePct: (json['shift_completion_rate_pct'] as num?)?.toDouble() ?? 0.0,
      adherenceScore: (json['adherence_score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'period': period,
        'date_from': dateFrom,
        'date_to': dateTo,
        'present_count': presentCount,
        'absent_count': absentCount,
        'total_active_employees': totalActiveEmployees,
        'business_days': businessDays,
        'expected_person_days': expectedPersonDays,
        'actual_person_days': actualPersonDays,
        'absent_person_days': absentPersonDays,
        'attendance_rate_pct': attendanceRatePct,
        'on_time_rate_pct': onTimeRatePct,
        'shift_completion_rate_pct': shiftCompletionRatePct,
        'adherence_score': adherenceScore,
      };
}

// ── Attendance Trend ─────────────────────────────────────────────────────

class AttendanceTrendPoint {
  final String date;
  final int present;
  final int absent;
  final double ratePct;

  const AttendanceTrendPoint({
    required this.date,
    required this.present,
    required this.absent,
    required this.ratePct,
  });

  factory AttendanceTrendPoint.fromJson(Map<String, dynamic> json) {
    return AttendanceTrendPoint(
      date: json['date'] as String,
      present: json['present'] as int,
      absent: json['absent'] as int,
      ratePct: (json['rate_pct'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'present': present,
        'absent': absent,
        'rate_pct': ratePct,
      };
}

class AttendanceTrend {
  final String? period;
  final String dateFrom;
  final String dateTo;
  final List<AttendanceTrendPoint> trend;

  const AttendanceTrend({
    this.period,
    required this.dateFrom,
    required this.dateTo,
    required this.trend,
  });

  factory AttendanceTrend.fromJson(Map<String, dynamic> json) {
    return AttendanceTrend(
      period: json['period'] as String?,
      dateFrom: json['date_from'] as String,
      dateTo: json['date_to'] as String,
      trend: (json['trend'] as List<dynamic>)
          .map((e) => AttendanceTrendPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'period': period,
        'date_from': dateFrom,
        'date_to': dateTo,
        'trend': trend.map((e) => e.toJson()).toList(),
      };
}

// ── Late Arrivals ────────────────────────────────────────────────────────

class LateArrivalEntry {
  final int employeeId;
  final String erpnextEmployeeId;
  final String fullName;
  final int occurrences;
  final double avgMinutesLate;
  final String latestClockIn;

  const LateArrivalEntry({
    required this.employeeId,
    required this.erpnextEmployeeId,
    required this.fullName,
    required this.occurrences,
    required this.avgMinutesLate,
    required this.latestClockIn,
  });

  factory LateArrivalEntry.fromJson(Map<String, dynamic> json) {
    return LateArrivalEntry(
      employeeId: json['employee_id'] as int,
      erpnextEmployeeId: json['erpnext_employee_id'] as String,
      fullName: json['full_name'] as String,
      occurrences: json['occurrences'] as int,
      avgMinutesLate: (json['avg_minutes_late'] as num).toDouble(),
      latestClockIn: json['latest_clock_in'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'employee_id': employeeId,
        'erpnext_employee_id': erpnextEmployeeId,
        'full_name': fullName,
        'occurrences': occurrences,
        'avg_minutes_late': avgMinutesLate,
        'latest_clock_in': latestClockIn,
      };
}

class LateArrivalsReport {
  final String? period;
  final String dateFrom;
  final String dateTo;
  final String lateThreshold;
  final List<LateArrivalEntry> lateArrivals;

  const LateArrivalsReport({
    this.period,
    required this.dateFrom,
    required this.dateTo,
    required this.lateThreshold,
    required this.lateArrivals,
  });

  factory LateArrivalsReport.fromJson(Map<String, dynamic> json) {
    return LateArrivalsReport(
      period: json['period'] as String?,
      dateFrom: json['date_from'] as String,
      dateTo: json['date_to'] as String,
      lateThreshold: json['late_threshold'] as String,
      lateArrivals: (json['late_arrivals'] as List<dynamic>)
          .map((e) => LateArrivalEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'period': period,
        'date_from': dateFrom,
        'date_to': dateTo,
        'late_threshold': lateThreshold,
        'late_arrivals': lateArrivals.map((e) => e.toJson()).toList(),
      };
}

// ── Hours Leaderboard ────────────────────────────────────────────────────

class HoursLeaderboardEntry {
  final int rank;
  final int employeeId;
  final String erpnextEmployeeId;
  final String fullName;
  final double totalHoursWorked;
  final int totalDaysPresent;

  const HoursLeaderboardEntry({
    required this.rank,
    required this.employeeId,
    required this.erpnextEmployeeId,
    required this.fullName,
    required this.totalHoursWorked,
    required this.totalDaysPresent,
  });

  factory HoursLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return HoursLeaderboardEntry(
      rank: json['rank'] as int,
      employeeId: json['employee_id'] as int,
      erpnextEmployeeId: json['erpnext_employee_id'] as String,
      fullName: json['full_name'] as String,
      totalHoursWorked: (json['total_hours_worked'] as num).toDouble(),
      totalDaysPresent: json['total_days_present'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'rank': rank,
        'employee_id': employeeId,
        'erpnext_employee_id': erpnextEmployeeId,
        'full_name': fullName,
        'total_hours_worked': totalHoursWorked,
        'total_days_present': totalDaysPresent,
      };
}

class HoursLeaderboard {
  final String? period;
  final String dateFrom;
  final String dateTo;
  final List<HoursLeaderboardEntry> leaderboard;

  const HoursLeaderboard({
    this.period,
    required this.dateFrom,
    required this.dateTo,
    required this.leaderboard,
  });

  factory HoursLeaderboard.fromJson(Map<String, dynamic> json) {
    return HoursLeaderboard(
      period: json['period'] as String?,
      dateFrom: json['date_from'] as String,
      dateTo: json['date_to'] as String,
      leaderboard: (json['leaderboard'] as List<dynamic>)
          .map((e) => HoursLeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'period': period,
        'date_from': dateFrom,
        'date_to': dateTo,
        'leaderboard': leaderboard.map((e) => e.toJson()).toList(),
      };
}

// ── Department Breakdown ──────────────────────────────────────────────────

class DepartmentStat {
  final String department;
  final int totalEmployees;
  final int presentCount;
  final int absentCount;
  final double attendanceRatePct;
  final int lateArrivalsCount;
  final double avgLateMinutes;

  const DepartmentStat({
    required this.department,
    required this.totalEmployees,
    required this.presentCount,
    required this.absentCount,
    required this.attendanceRatePct,
    required this.lateArrivalsCount,
    required this.avgLateMinutes,
  });

  factory DepartmentStat.fromJson(Map<String, dynamic> json) {
    return DepartmentStat(
      department: json['department'] as String,
      totalEmployees: json['total_employees'] as int,
      presentCount: json['present_count'] as int,
      absentCount: json['absent_count'] as int,
      attendanceRatePct: (json['attendance_rate_pct'] as num).toDouble(),
      lateArrivalsCount: json['late_arrivals_count'] as int,
      avgLateMinutes: (json['avg_late_minutes'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'department': department,
        'total_employees': totalEmployees,
        'present_count': presentCount,
        'absent_count': absentCount,
        'attendance_rate_pct': attendanceRatePct,
        'late_arrivals_count': lateArrivalsCount,
        'avg_late_minutes': avgLateMinutes,
      };
}

class DepartmentBreakdown {
  final String? period;
  final String dateFrom;
  final String dateTo;
  final List<DepartmentStat> departments;

  const DepartmentBreakdown({
    this.period,
    required this.dateFrom,
    required this.dateTo,
    required this.departments,
  });

  factory DepartmentBreakdown.fromJson(Map<String, dynamic> json) {
    return DepartmentBreakdown(
      period: json['period'] as String?,
      dateFrom: json['date_from'] as String,
      dateTo: json['date_to'] as String,
      departments: (json['departments'] as List<dynamic>)
          .map((e) => DepartmentStat.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'period': period,
        'date_from': dateFrom,
        'date_to': dateTo,
        'departments': departments.map((e) => e.toJson()).toList(),
      };
}

// ── Shift Compliance ──────────────────────────────────────────────────────

class FrequentEarlyExit {
  final int employeeId;
  final String erpnextEmployeeId;
  final String fullName;
  final int occurrences;
  final double avgMinutesEarly;

  const FrequentEarlyExit({
    required this.employeeId,
    required this.erpnextEmployeeId,
    required this.fullName,
    required this.occurrences,
    required this.avgMinutesEarly,
  });

  factory FrequentEarlyExit.fromJson(Map<String, dynamic> json) {
    return FrequentEarlyExit(
      employeeId: json['employee_id'] as int,
      erpnextEmployeeId: json['erpnext_employee_id'] as String,
      fullName: json['full_name'] as String,
      occurrences: json['occurrences'] as int,
      avgMinutesEarly: (json['avg_minutes_early'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'employee_id': employeeId,
        'erpnext_employee_id': erpnextEmployeeId,
        'full_name': fullName,
        'occurrences': occurrences,
        'avg_minutes_early': avgMinutesEarly,
      };
}

class ShiftCompliance {
  final String? period;
  final String dateFrom;
  final String dateTo;
  final String lateThreshold;
  final String earlyExitThreshold;
  final int totalSessions;
  final int onTimeCount;
  final double onTimePct;
  final int lateArrivalCount;
  final double lateArrivalPct;
  final int earlyExitCount;
  final double earlyExitPct;
  final int incompleteShiftCount;
  final double incompleteShiftPct;
  final List<FrequentEarlyExit> frequentEarlyExits;

  const ShiftCompliance({
    this.period,
    required this.dateFrom,
    required this.dateTo,
    required this.lateThreshold,
    required this.earlyExitThreshold,
    required this.totalSessions,
    required this.onTimeCount,
    required this.onTimePct,
    required this.lateArrivalCount,
    required this.lateArrivalPct,
    required this.earlyExitCount,
    required this.earlyExitPct,
    required this.incompleteShiftCount,
    required this.incompleteShiftPct,
    required this.frequentEarlyExits,
  });

  factory ShiftCompliance.fromJson(Map<String, dynamic> json) {
    return ShiftCompliance(
      period: json['period'] as String?,
      dateFrom: json['date_from'] as String,
      dateTo: json['date_to'] as String,
      lateThreshold: json['late_threshold'] as String,
      earlyExitThreshold: json['early_exit_threshold'] as String,
      totalSessions: json['total_sessions'] as int,
      onTimeCount: json['on_time_count'] as int,
      onTimePct: (json['on_time_pct'] as num).toDouble(),
      lateArrivalCount: json['late_arrival_count'] as int,
      lateArrivalPct: (json['late_arrival_pct'] as num).toDouble(),
      earlyExitCount: json['early_exit_count'] as int,
      earlyExitPct: (json['early_exit_pct'] as num).toDouble(),
      incompleteShiftCount: json['incomplete_shift_count'] as int,
      incompleteShiftPct: (json['incomplete_shift_pct'] as num).toDouble(),
      frequentEarlyExits: (json['frequent_early_exits'] as List<dynamic>)
          .map((e) => FrequentEarlyExit.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'period': period,
        'date_from': dateFrom,
        'date_to': dateTo,
        'late_threshold': lateThreshold,
        'early_exit_threshold': earlyExitThreshold,
        'total_sessions': totalSessions,
        'on_time_count': onTimeCount,
        'on_time_pct': onTimePct,
        'late_arrival_count': lateArrivalCount,
        'late_arrival_pct': lateArrivalPct,
        'early_exit_count': earlyExitCount,
        'early_exit_pct': earlyExitPct,
        'incomplete_shift_count': incompleteShiftCount,
        'incomplete_shift_pct': incompleteShiftPct,
        'frequent_early_exits': frequentEarlyExits.map((e) => e.toJson()).toList(),
      };
}
