class AuthResponse {
  final String access;
  final String refresh;
  final String role;
  final int userId;
  final int employeeId;
  final String erpnextEmployeeId;
  final String fullName;

  const AuthResponse({
    required this.access,
    required this.refresh,
    required this.role,
    required this.userId,
    required this.employeeId,
    required this.erpnextEmployeeId,
    required this.fullName,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      access: json['access'] as String,
      refresh: json['refresh'] as String,
      role: json['role'] as String,
      userId: json['user_id'] as int,
      employeeId: (json['employee_id'] as int?) ?? 0,
      erpnextEmployeeId: (json['erpnext_employee_id'] as String?) ?? '',
      fullName: (json['full_name'] as String?) ?? '',
    );
  }
}

class LoggedInUser {
  final int userId;
  final int employeeId;
  final String erpnextEmployeeId;
  final String fullName;
  final String role;
  final String accessToken;
  final String refreshToken;

  const LoggedInUser({
    required this.userId,
    required this.employeeId,
    required this.erpnextEmployeeId,
    required this.fullName,
    required this.role,
    required this.accessToken,
    required this.refreshToken,
  });
}
