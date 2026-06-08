import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/constants/app_constants.dart';

class CheckinRepository {
  final Dio _dio = DioClient.instance.dio;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final SecureStorage _storage = SecureStorage.instance;

  Future<String> getDeviceUniqueId() async {
    final android = await _deviceInfo.androidInfo;
    return android.id;
  }

  Future<String> getDeviceLabel() async {
    final android = await _deviceInfo.androidInfo;
    return '${android.manufacturer} ${android.model}';
  }

  Future<int> getEmployeeId() async {
    final id = await _storage.read(key: AppConstants.employeeIdKey);
    return int.parse(id!);
  }

  /// Returns 'IN' or 'OUT' based on current employee status.
  Future<String> resolveLogType() async {
    final employeeId = await getEmployeeId();
    try {
      final response = await _dio.get('/employees/$employeeId/status/');
      final status = response.data['status'] as String?;
      const validCheckoutStatuses = {'present', 'break', 'errand', 'assignment'};
      if (status != null && validCheckoutStatuses.contains(status.toLowerCase())) {
        return 'OUT';
      }
      return 'IN';
    } on DioException {
      return 'IN';
    }
  }

  /// Returns true if device is already registered and active.
  Future<bool> isDeviceRegistered() async {
    final deviceId = await getDeviceUniqueId();
    try {
      final response = await _dio.get('/devices/me/');
      if (response.statusCode == 200) {
        final data = response.data;
        return data['device_unique_id'] == deviceId &&
            data['is_active'] == true;
      }
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return false;
      rethrow;
    }
  }

  /// Registers this device. Throws on failure.
  Future<void> registerDevice() async {
    final deviceId = await getDeviceUniqueId();
    final label = await getDeviceLabel();
    await _dio.post('/devices/register/', data: {
      'device_unique_id': deviceId,
      'attendance_device_id': label,
    });
  }

  /// Submits a check-in payload. Returns the response body.
  Future<Map<String, dynamic>> submitCheckin(
      Map<String, dynamic> payload) async {
    final response = await _dio.post('/checkins/', data: payload);
    if (response.statusCode != 201) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    }
    return response.data as Map<String, dynamic>;
  }
}
