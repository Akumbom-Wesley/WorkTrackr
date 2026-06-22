package com.worktrackr.worktrackr

import android.content.Context
import android.net.wifi.WifiManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val channel = "com.worktrackr.worktrackr/wifi_band"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                try {
                    val wifiManager = applicationContext
                        .getSystemService(Context.WIFI_SERVICE) as WifiManager
                    @Suppress("DEPRECATION")
                    val info = wifiManager.connectionInfo

                    when (call.method) {
                        "getWifiFrequency" -> {
                            if (info != null && info.frequency > 0) {
                                result.success(info.frequency)
                            } else {
                                result.success(null)
                            }
                        }
                        "getWifiRssi" -> {
                            if (info != null && info.rssi != 0 && info.rssi > -127) {
                                result.success(info.rssi)
                            } else {
                                result.success(null)
                            }
                        }
                        "getWifiBssid" -> {
                            val bssid = info?.bssid
                            if (!bssid.isNullOrEmpty() && bssid != "02:00:00:00:00:00") {
                                result.success(bssid)
                            } else {
                                result.success(null)
                            }
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.success(null)
                }
            }
    }
}
