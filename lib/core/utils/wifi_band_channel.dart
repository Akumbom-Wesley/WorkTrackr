import 'package:flutter/services.dart';

class WifiBandChannel {
  static const _channel = MethodChannel('com.worktrackr.worktrackr/wifi_band');

  /// Returns '2.4GHz', '5GHz', or 'UNAVAILABLE'
  static Future<String> getBand() async {
    try {
      final int? frequencyMhz =
          await _channel.invokeMethod<int>('getWifiFrequency');
      if (frequencyMhz == null) return 'UNAVAILABLE';
      if (frequencyMhz < 3000) return '2.4GHz';
      if (frequencyMhz >= 5000) return '5GHz';
      return 'UNAVAILABLE';
    } on PlatformException {
      return 'UNAVAILABLE';
    }
  }

  /// Returns RSSI in dBm (e.g. -65) or null if unavailable
  static Future<int?> getRssi() async {
    try {
      return await _channel.invokeMethod<int>('getWifiRssi');
    } on PlatformException {
      return null;
    }
  }

  /// Returns BSSID string (e.g. "aa:bb:cc:dd:ee:ff") or null if unavailable
  static Future<String?> getBssid() async {
    try {
      return await _channel.invokeMethod<String>('getWifiBssid');
    } on PlatformException {
      return null;
    }
  }
}
