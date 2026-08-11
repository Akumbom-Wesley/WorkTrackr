import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';
import 'package:safe_device/safe_device.dart';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../../../core/utils/wifi_band_channel.dart';
import 'checkin_repository.dart';

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
        biometricOnly: true,
        persistAcrossBackgrounding: true,
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

  Future<WifiResult> runWifi({GeofenceSiteConfig? site}) async {
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

      final band = await WifiBandChannel.getBand();
      final rssi = await WifiBandChannel.getRssi();
      final bssid = await WifiBandChannel.getBssid() ?? '';

      String ssid = '';
      try {
        final info = NetworkInfo();
        final raw = await info.getWifiName() ?? '';
        ssid = (raw.startsWith('"') && raw.endsWith('"'))
            ? raw.substring(1, raw.length - 1)
            : raw;
      } catch (_) {}

      debugPrint('[WIFI] band=$band ssid=$ssid bssid=$bssid rssi=$rssi');

      // Client-side validation against GeofenceSite config
      if (site != null) {
        final rssiOk = rssi != null && rssi >= site.rssiThreshold;
        final bssidOk = site.wifiBssid.isEmpty || bssid.toLowerCase() == site.wifiBssid.toLowerCase();
        final bandOk = !site.enforce5ghz || band == '5GHz';

        debugPrint(
          '[WIFI] rssiOk=$rssiOk bssidOk=$bssidOk bandOk=$bandOk',
        );

        if (!rssiOk || !bssidOk || !bandOk) {
          return (
            result: const StepResult.fail(
              'WIFI_CREDENTIAL_MISMATCH',
              'Office Wi-Fi not detected or signal too weak.',
            ),
            band: band,
            ssid: ssid,
            bssid: bssid,
            rssi: rssi,
          );
        }
      }

      return (
        result: const StepResult.pass(),
        band: band,
        ssid: ssid,
        bssid: bssid,
        rssi: rssi,
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
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
          timeLimit: Duration(seconds: 20),
        ),
      ).timeout(
        const Duration(seconds: 25),
        onTimeout: (sink) => sink.close(),
      )) {
        attempts++;
        if (best == null || pos.accuracy < best.accuracy) best = pos;
        if (best.accuracy <= 30.0 || attempts >= 8) break;
      }

      if (best == null) {
        return (
          result: const StepResult.fail(
            'GPS_TIMEOUT',
            'Could not get a location fix. Move to an open area and try again.',
          ),
          position: null,
        );
      }

      return (result: const StepResult.pass(), position: best);
    } catch (e) {
      return (
        result: StepResult.fail('GPS_ERROR', 'Could not get location: $e'),
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
