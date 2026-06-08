import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';
import 'package:safe_device/safe_device.dart';

class StepResult {
  final bool passed;
  final String? errorCode;
  final String? errorMessage;
  const StepResult.pass()
      : passed = true,
        errorCode = null,
        errorMessage = null;
  const StepResult.fail(this.errorCode, this.errorMessage) : passed = false;
}

class CheckinPayload {
  final String deviceUniqueId;
  final String logType;
  final bool biometricPassed;
  final double latSmoothed;
  final double lngSmoothed;
  final int accuracyMetres;
  final DateTime timestampGps;
  final DateTime timestampDevice;
  final String wifiBand;
  final String wifiSsid;
  final String wifiBssid;
  final int? rssiAvg;
  final bool mockLocation;
  final bool isRooted;

  const CheckinPayload({
    required this.deviceUniqueId,
    required this.logType,
    required this.biometricPassed,
    required this.latSmoothed,
    required this.lngSmoothed,
    required this.accuracyMetres,
    required this.timestampGps,
    required this.timestampDevice,
    required this.wifiBand,
    required this.wifiSsid,
    required this.wifiBssid,
    this.rssiAvg,
    required this.mockLocation,
    required this.isRooted,
  });

  Map<String, dynamic> toJson() => {
        'device_unique_id': deviceUniqueId,
        'log_type': logType,
        'timestamp_gps': timestampGps.toUtc().toIso8601String(),
        'timestamp_device': timestampDevice.toUtc().toIso8601String(),
        'gps_lat_smoothed': latSmoothed.toStringAsFixed(6),
        'gps_lng_smoothed': lngSmoothed.toStringAsFixed(6),
        'gps_accuracy_metres': accuracyMetres,
        'biometric_passed': biometricPassed,
        'wifi_band': wifiBand,
        'wifi_ssid': wifiSsid,
        'wifi_bssid': wifiBssid,
        'rssi_avg': rssiAvg,
        'antispoofing_flags': {
          'mock_location': mockLocation,
          'is_rooted': isRooted,
        },
      };
}

typedef WifiResult = ({
  StepResult result,
  String band,
  String ssid,
  String bssid,
  int? rssi
});

typedef GpsResult = ({StepResult result, Position? position});

typedef SpoofResult = ({bool mockLocation, bool isRooted});

class CheckinService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  // ── Step 1: Biometric ─────────────────────────────────────────────────

  Future<StepResult> runBiometric() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();



      if (!canCheck || !isSupported) {
        return const StepResult.fail(
          'BIOMETRIC_UNAVAILABLE',
          'Biometric authentication is not available on this device.',
        );
      }
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Verify your identity to clock in',
      );

      if (!authenticated) {
        return const StepResult.fail(
          'BIOMETRIC_FAILED',
          'Biometric verification failed. Please try again.',
        );
      }

      return const StepResult.pass();
    } on PlatformException catch (e) {
      return StepResult.fail(
        'BIOMETRIC_ERROR',
        e.message ?? 'Biometric error occurred.',
      );
    }
  }

  // ── Step 2: Wi-Fi ─────────────────────────────────────────────────────

  Future<WifiResult> runWifi() async {
    try {
      final results = await Connectivity().checkConnectivity();
      final isWifi = results.contains(ConnectivityResult.wifi);

      if (!isWifi) {
        return (
          result: const StepResult.pass(),
          band: 'UNAVAILABLE',
          ssid: '',
          bssid: '',
          rssi: null,
        );
      }

      // Band detection requires native channel — defaulting to UNAVAILABLE.
      // TODO: feature/wifi-band — implement WifiInfo.getFrequency() native channel
      return (
        result: const StepResult.pass(),
        band: 'UNAVAILABLE',
        ssid: '',
        bssid: '',
        rssi: null,
      );
    } catch (_) {
      return (
        result: const StepResult.pass(),
        band: 'UNAVAILABLE',
        ssid: '',
        bssid: '',
        rssi: null,
      );
    }
  }

  // ── Step 3: GPS ───────────────────────────────────────────────────────

  Future<GpsResult> runGps() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return (
          result: const StepResult.fail(
            'GPS_DISABLED',
            'Location services are disabled. Please enable GPS.',
          ),
          position: null,
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return (
            result: const StepResult.fail(
              'GPS_PERMISSION_DENIED',
              'Location permission denied.',
            ),
            position: null,
          );
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return (
          result: const StepResult.fail(
            'GPS_PERMISSION_PERMANENT',
            'Location permission permanently denied. Enable it in Settings.',
          ),
          position: null,
        );
      }

      Position? best;
      int attempts = 0;
      await for (final pos in Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
        ),
      )) {
        attempts++;
        if (best == null || pos.accuracy < best.accuracy) best = pos;
        if (best.accuracy <= 10.0 || attempts >= 10) break;
      }

      return (result: const StepResult.pass(), position: best);
    } catch (e) {
      return (
        result: StepResult.fail('GPS_ERROR', 'Could not get location: \$e'), // ignore: prefer_const_constructors
        position: null,
      );
    }
  }

  // ── Anti-spoofing ─────────────────────────────────────────────────────

  Future<SpoofResult> getAntispoofingFlags(Position position) async {
    final rooted = await SafeDevice.isJailBroken;
    return (
      mockLocation: position.isMocked,
      isRooted: rooted,
    );
  }
}
