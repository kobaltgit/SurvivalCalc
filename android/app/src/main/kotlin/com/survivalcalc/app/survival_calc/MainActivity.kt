package com.survivalcalc.app.survival_calc

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.InputStreamReader

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.survivalcalc.app/gpx_intent"
    private var initialGpxContent: String? = null
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "getInitialGpx") {
                result.success(initialGpxContent)
                initialGpxContent = null
            } else {
                result.notImplemented()
            }
        }
        handleIntent(intent, isInitial = true)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent, isInitial = false)
    }

    private fun handleIntent(intent: Intent?, isInitial: Boolean) {
        val uri: Uri? = intent?.data ?: (intent?.getParcelableExtra(Intent.EXTRA_STREAM) as? Uri)
        if (uri != null) {
            try {
                contentResolver.openInputStream(uri)?.use { inputStream ->
                    val reader = BufferedReader(InputStreamReader(inputStream))
                    val content = reader.readText()
                    if (content.contains("<gpx", ignoreCase = true)) {
                        if (isInitial) {
                            initialGpxContent = content
                        } else {
                            methodChannel?.invokeMethod("onGpxReceived", content)
                        }
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
