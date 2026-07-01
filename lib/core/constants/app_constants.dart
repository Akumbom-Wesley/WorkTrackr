class AppConstants {
  AppConstants._();

  // API
  static const String baseUrl        =  'http://192.168.0.244:8000/api/v1'; //'https://attendance-backend-ktpa.onrender.com/api/v1';
  static const int connectTimeout    = 10000; // ms
  static const int receiveTimeout    = 10000;

  // JWT storage keys
  static const String accessTokenKey  = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String roleKey    = 'user_role';
  static const String userIdKey           = 'user_id';
  static const String employeeIdKey        = 'employee_id';
  static const String erpnextEmployeeIdKey = 'erpnext_employee_id';
  static const String fullNameKey          = 'full_name';

  // Roles (as returned in JWT payload)
  static const String roleEmployee   = 'EMPLOYEE';
  static const String roleHrAdmin    = 'HR_ADMIN';
  static const String roleSuperAdmin = 'SUPER_ADMIN';

  // Splash
  static const int splashDuration   = 2; // seconds

  // Offline queue
  static const String checkinQueueBox = 'checkin_queue';
}