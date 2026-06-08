import 'package:flutter/services.dart';

class WifiBandChannel {
  static const _channel = MethodChannel('com.worktrackr.worktrackr/wifi_band');

  /// Returns '2.4GHz', '5GHz', or 'UNAVAILABLE'
  static Future<String> getBand() async {
    try {
      final int? frequencyMhz = await _channel.invokeMethod<int>('getWifiFrequency');
      if (frequencyMhz == null) return 'UNAVAILABLE';
      if (frequencyMhz < 3000) return '2.4GHz';
      if (frequencyMhz >= 5000) return '5GHz';
      return 'UNAVAILABLE';
    } on PlatformException {
      return 'UNAVAILABLE';
    }
  }
}
