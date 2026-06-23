import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/constants/app_constants.dart';

class GeofenceSiteConfig {
  final String wifiSsid;
  final String wifiBssid;
  final int rssiThreshold;
  final bool enforce5ghz;
  final double latitude;
  final double longitude;
  final int radiusMetres;

  const GeofenceSiteConfig({
    required this.wifiSsid,
    required this.wifiBssid,
    required this.rssiThreshold,
    required this.enforce5ghz,
    required this.latitude,
    required this.longitude,
    required this.radiusMetres,
  });

  factory GeofenceSiteConfig.fromJson(Map<String, dynamic> json) {
    return GeofenceSiteConfig(
      wifiSsid: json['wifi_ssid'] as String? ?? '',
      wifiBssid: json['wifi_bssid'] as String? ?? '',
      rssiThreshold: json['rssi_threshold'] as int? ?? -70,
      enforce5ghz: json['enforce_5ghz'] as bool? ?? false,
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      radiusMetres: json['radius_metres'] as int? ?? 50,
    );
  }
}

class CheckinRepository {
  final Dio _dio = DioClient.instance.dio;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final SecureStorage _storage = SecureStorage.instance;

  static const String _cachedDeviceRegisteredKey = 'cached_device_registered';
  static const String _cachedNextLogTypeKey = 'cached_next_log_type';

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

  Future<void> setCachedDeviceRegistered(bool value) async {
    await _storage.write(
      key: _cachedDeviceRegisteredKey,
      value: value ? 'true' : 'false',
    );
  }

  Future<bool> getCachedDeviceRegistered() async {
    final value = await _storage.read(key: _cachedDeviceRegisteredKey);
    return value == 'true';
  }

  Future<void> cacheLastLogType(String nextValue) async {
    await _storage.write(
      key: _cachedNextLogTypeKey,
      value: nextValue,
    );
  }

  Future<String> resolveLogTypeOfflineSafe() async {
    final cached = await _storage.read(key: _cachedNextLogTypeKey) ?? 'IN';
    if (cached == 'IN' || cached == 'OUT') {
      return cached;
    }
    return 'IN';
  }

  Future<String> resolveLogType() async {
    final employeeId = await getEmployeeId();
    try {
      final response = await _dio.get('/employees/$employeeId/status/');
      final status = response.data['status'] as String?;
      const validCheckoutStatuses = {
        'present',
        'break',
        'errand',
        'assignment'
      };

      final resolved =
          status != null && validCheckoutStatuses.contains(status.toLowerCase())
              ? 'OUT'
              : 'IN';

      await cacheLastLogType(resolved);
      return resolved;
    } on DioException {
      return await resolveLogTypeOfflineSafe();
    }
  }

  Future<bool> isDeviceRegistered() async {
    final deviceId = await getDeviceUniqueId();
    try {
      final response = await _dio.get('/devices/me/');
      if (response.statusCode == 200) {
        final data = response.data;
        final registered =
            data['device_unique_id'] == deviceId && data['is_active'] == true;
        if (registered) {
          await setCachedDeviceRegistered(true);
        }
        return registered;
      }
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return false;
      rethrow;
    }
  }

  Future<void> registerDevice() async {
    final deviceId = await getDeviceUniqueId();
    final label = await getDeviceLabel();
    await _dio.post('/devices/register/', data: {
      'device_unique_id': deviceId,
      'attendance_device_id': label,
    });
    await setCachedDeviceRegistered(true);
  }

  Future<GeofenceSiteConfig?> fetchGeofenceSite() async {
    try {
      final response = await _dio.get('/companies/geofence-site/');
      if (response.statusCode == 200) {
        return GeofenceSiteConfig.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      return null;
    } on DioException {
      return null;
    }
  }

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
