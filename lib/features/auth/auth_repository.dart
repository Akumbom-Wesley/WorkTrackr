import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/auth_model.dart';

class AuthRepository {
  final Dio _dio = DioClient.instance.dio;
  final SecureStorage _storage = SecureStorage.instance;

  Future<AuthResponse> login({
    required String erpNextEmployeeId,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/login/',
      data: {
        'erpnext_employee_id': erpNextEmployeeId,
        'password': password,
      },
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> saveTokens(AuthResponse auth) async {
    await _storage.write(key: AppConstants.accessTokenKey,       value: auth.access);
    await _storage.write(key: AppConstants.refreshTokenKey,      value: auth.refresh);
    await _storage.write(key: AppConstants.roleKey,              value: auth.role);
    await _storage.write(key: AppConstants.userIdKey,            value: auth.userId.toString());
    await _storage.write(key: AppConstants.employeeIdKey,        value: auth.employeeId.toString());
    await _storage.write(key: AppConstants.erpnextEmployeeIdKey, value: auth.erpnextEmployeeId);
    await _storage.write(key: AppConstants.fullNameKey,          value: auth.fullName);
  }

  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }

  Future<LoggedInUser?> getStoredUser() async {
    final access      = await _storage.read(key: AppConstants.accessTokenKey);
    final refresh     = await _storage.read(key: AppConstants.refreshTokenKey);
    final role        = await _storage.read(key: AppConstants.roleKey);
    final userId      = await _storage.read(key: AppConstants.userIdKey);
    final employeeId  = await _storage.read(key: AppConstants.employeeIdKey);
    final erpnextId   = await _storage.read(key: AppConstants.erpnextEmployeeIdKey);
    final fullName    = await _storage.read(key: AppConstants.fullNameKey);

    if (access == null || refresh == null || role == null ||
        userId == null || employeeId == null || erpnextId == null || fullName == null) {
      return null;
    }

    return LoggedInUser(
      userId: int.parse(userId),
      employeeId: int.parse(employeeId),
      erpnextEmployeeId: erpnextId,
      fullName: fullName,
      role: role,
      accessToken: access,
      refreshToken: refresh,
    );
  }
}
