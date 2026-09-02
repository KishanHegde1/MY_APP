package com.kisha.multiservice

import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.kisha.multiservice/app_configuration",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isGoogleMapsConfigured" -> result.success(isGoogleMapsConfigured())
                else -> result.notImplemented()
            }
        }
    }

    private fun isGoogleMapsConfigured(): Boolean {
        val applicationInfo = packageManager.getApplicationInfo(
            packageName,
            PackageManager.GET_META_DATA,
        )
        val apiKey = applicationInfo.metaData
            ?.getString("com.google.android.geo.API_KEY")
            ?.trim()
        return !apiKey.isNullOrEmpty() && apiKey != "MAPS_API_KEY_NOT_CONFIGURED"
    }
}
