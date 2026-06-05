class AuthResponse {
  final String access;
  final String refresh;
  final String role;
  final int userId;

  const AuthResponse({
    required this.access,
    required this.refresh,
    required this.role,
    required this.userId,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      access: json['access'] as String,
      refresh: json['refresh'] as String,
      role: json['role'] as String,
      userId: json['user_id'] as int,
    );
  }
}

class LoggedInUser {
  final int userId;
  final String role;
  final String accessToken;
  final String refreshToken;

  const LoggedInUser({
    required this.userId,
    required this.role,
    required this.accessToken,
    required this.refreshToken,
  });
}