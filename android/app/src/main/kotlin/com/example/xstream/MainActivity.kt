package com.example.xstream

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.xstream/native"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startNodeService", "stopNodeService", "performAction" -> result.success("Android not supported")
                "checkNodeStatus" -> result.success(false)
                else -> result.notImplemented()
            }
        }
    }
}
