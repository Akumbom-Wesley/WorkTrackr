package com.worktrackr.worktrackr

import android.content.Context
import android.net.wifi.WifiManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val wifiChannel = "com.worktrackr.worktrackr/wifi_band"
    private val mediaStoreChannel = "com.worktrackr.worktrackr/media_store"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, wifiChannel)
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

        // Unlike wifiChannel above, failures here are surfaced via
        // result.error(...), not swallowed to a null/success response —
        // a failed save must be visible to the Dart side as a real error
        // so it surfaces through the existing _showErrorAlert flow.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, mediaStoreChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSdkInt" -> result.success(android.os.Build.VERSION.SDK_INT)
                    "saveToDownloads" -> {
                        try {
                            val bytes = call.argument<ByteArray>("bytes")
                                ?: throw IllegalArgumentException("Missing 'bytes' argument")
                            val displayName = call.argument<String>("displayName")
                                ?: throw IllegalArgumentException("Missing 'displayName' argument")
                            val mimeType = call.argument<String>("mimeType")
                                ?: throw IllegalArgumentException("Missing 'mimeType' argument")

                            val savedPath = MediaStoreSaver(applicationContext)
                                .save(bytes, displayName, mimeType)
                            result.success(savedPath)
                        } catch (e: Exception) {
                            result.error("SAVE_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
