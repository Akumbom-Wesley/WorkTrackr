class HrEmployee {
  final int id;
  final String erpnextEmployeeId;
  final String fullName;
  final String email;
  final String department;
  final bool isActive;
  final bool isOnboarded;
  final int company;

  const HrEmployee({
    required this.id,
    required this.erpnextEmployeeId,
    required this.fullName,
    required this.email,
    required this.department,
    required this.isActive,
    required this.isOnboarded,
    required this.company,
  });

  factory HrEmployee.fromJson(Map<String, dynamic> json) {
    return HrEmployee(
      id:                  json['id']                    as int,
      erpnextEmployeeId:   json['erpnext_employee_id']   as String,
      fullName:            json['full_name']             as String,
      email:               json['email'] as String? ?? '',
      department:          json['department'] as String? ?? '',
      isActive:            json['is_active']             as bool,
      isOnboarded:         json['is_onboarded']          as bool,
      company:             json['company']               as int,
    );
  }
}

class HrEmployeeHistory {
  final String erpnextEmployeeId;
  final String fullName;
  final DateTime dateFrom;
  final DateTime dateTo;
  final int totalDaysPresent;
  final String totalHoursWorked;
  final List<HrAttendanceEntry> attendance;

  const HrEmployeeHistory({
    required this.erpnextEmployeeId,
    required this.fullName,
    required this.dateFrom,
    required this.dateTo,
    required this.totalDaysPresent,
    required this.totalHoursWorked,
    required this.attendance,
  });

  factory HrEmployeeHistory.fromJson(Map<String, dynamic> json) {
    return HrEmployeeHistory(
      erpnextEmployeeId: json['erpnext_employee_id'] as String,
      fullName:          json['full_name']           as String,
      dateFrom:          DateTime.parse(json['date_from'] as String),
      dateTo:            DateTime.parse(json['date_to']   as String),
      totalDaysPresent:  json['total_days_present']  as int,
      totalHoursWorked:  json['total_hours_worked']  as String,
      attendance: (json['attendance'] as List<dynamic>)
          .map((e) => HrAttendanceEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'erpnext_employee_id': erpnextEmployeeId,
        'full_name': fullName,
        'date_from': dateFrom.toIso8601String(),
        'date_to': dateTo.toIso8601String(),
        'total_days_present': totalDaysPresent,
        'total_hours_worked': totalHoursWorked,
        'attendance': attendance.map((e) => e.toJson()).toList(),
      };
}

class HrAttendanceEntry {
  final DateTime date;
  final DateTime? clockIn;
  final DateTime? clockOut;
  final String? hoursWorked;
  final String status; // COMPLETE | INCOMPLETE | OUT_ONLY

  const HrAttendanceEntry({
    required this.date,
    this.clockIn,
    this.clockOut,
    this.hoursWorked,
    required this.status,
  });

  factory HrAttendanceEntry.fromJson(Map<String, dynamic> json) {
    return HrAttendanceEntry(
      date:        DateTime.parse(json['date'] as String),
      clockIn:     json['clock_in']  != null
          ? DateTime.parse(json['clock_in']  as String).toLocal()
          : null,
      clockOut:    json['clock_out'] != null
          ? DateTime.parse(json['clock_out'] as String).toLocal()
          : null,
      hoursWorked: json['hours_worked'] as String?,
      status:      json['status']       as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'clock_in': clockIn?.toIso8601String(),
        'clock_out': clockOut?.toIso8601String(),
        'hours_worked': hoursWorked,
        'status': status,
      };
}

class HrCheckinAudit {
  final int id;
  final bool biometricResult;
  final bool geofenceResult;
  final bool rssiResult;
  final bool antispoofingResult;
  final bool wifiAvailable;
  final bool twoFactorOnly;
  final String errorCode;
  final String finalDecision; // PASS | FAIL | TWO_FACTOR_ONLY
  final DateTime? gpsTimestampUsed;
  final DateTime createdAt;

  const HrCheckinAudit({
    required this.id,
    required this.biometricResult,
    required this.geofenceResult,
    required this.rssiResult,
    required this.antispoofingResult,
    required this.wifiAvailable,
    required this.twoFactorOnly,
    required this.errorCode,
    required this.finalDecision,
    this.gpsTimestampUsed,
    required this.createdAt,
  });

  factory HrCheckinAudit.fromJson(Map<String, dynamic> json) {
    return HrCheckinAudit(
      id:                  json['id']                   as int,
      biometricResult:     json['biometric_result']     as bool,
      geofenceResult:      json['geofence_result']      as bool,
      rssiResult:          json['rssi_result']          as bool,
      antispoofingResult:  json['antispoofing_result']  as bool,
      wifiAvailable:       json['wifi_available']       as bool,
      twoFactorOnly:       json['two_factor_only']      as bool,
      errorCode:           json['error_code']           as String,
      finalDecision:       json['final_decision']       as String,
      gpsTimestampUsed:    json['gps_timestamp_used'] != null
          ? DateTime.parse(json['gps_timestamp_used'] as String).toLocal()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}
