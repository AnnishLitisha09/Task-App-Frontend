package com.example.task_app

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.onesignal.flutter.OneSignalPlugin

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // FAIL-SAFE: Manually register OneSignal to prevent MissingPluginException
        try {
            flutterEngine.getPlugins().add(OneSignalPlugin())
        } catch (e: Exception) {
            // Plugin might already be registered by the automated system, which is fine
        }
    }
}
