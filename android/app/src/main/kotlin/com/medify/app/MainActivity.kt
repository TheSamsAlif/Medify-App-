package com.medify.app

import android.app.AlarmManager
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.medify.app/alarm"
    private var methodChannel: MethodChannel? = null
    private var initialAlarmData: Map<String, Any?>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        wakeAndUnlock()
        extractAlarmData(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        wakeAndUnlock()
        extractAlarmData(intent)
        initialAlarmData?.let {
            methodChannel?.invokeMethod("onAlarmTriggered", it)
        }
    }

    private fun wakeAndUnlock() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
            keyguardManager?.requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }
    }

    private fun extractAlarmData(intent: Intent?) {
        if (intent != null && intent.getBooleanExtra("from_alarm", false)) {
            val data = HashMap<String, Any?>()
            data["medicineName"] = intent.getStringExtra("medicineName") ?: ""
            data["dosage"] = intent.getStringExtra("dosage") ?: ""
            data["scheduledTime"] = intent.getStringExtra("scheduledTime") ?: ""
            data["alarmId"] = intent.getIntExtra("alarmId", 0)
            initialAlarmData = data
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleExactAlarm" -> {
                    val alarmId = (call.argument<Any>("alarmId") as? Number)?.toInt() ?: 0
                    val triggerAtMillis = (call.argument<Any>("triggerAtMillis") as? Number)?.toLong() ?: 0L
                    val medicineName = call.argument<String>("medicineName") ?: ""
                    val dosage = call.argument<String>("dosage") ?: ""
                    val scheduledTime = call.argument<String>("scheduledTime") ?: ""
                    val hour = (call.argument<Any>("hour") as? Number)?.toInt()
                    val minute = (call.argument<Any>("minute") as? Number)?.toInt()

                    AlarmReceiver.scheduleNativeAlarm(
                        context = this,
                        alarmId = alarmId,
                        triggerAtMillis = triggerAtMillis,
                        medicineName = medicineName,
                        dosage = dosage,
                        scheduledTime = scheduledTime,
                        hour = hour,
                        minute = minute
                    )
                    result.success(true)
                }
                "stopAlarm" -> {
                    AlarmService.stop(this)
                    result.success(true)
                }
                "cancelAlarm" -> {
                    val alarmId = (call.argument<Any>("alarmId") as? Number)?.toInt() ?: 0
                    AlarmReceiver.cancelNativeAlarm(this, alarmId)
                    result.success(true)
                }
                "getInitialAlarm" -> {
                    val data = initialAlarmData
                    initialAlarmData = null // consume once
                    result.success(data)
                }
                "checkOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        result.success(Settings.canDrawOverlays(this))
                    } else {
                        result.success(true)
                    }
                }
                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                    }
                    result.success(true)
                }
                "checkBatteryOptimization" -> {
                    val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && powerManager != null) {
                        result.success(powerManager.isIgnoringBatteryOptimizations(packageName))
                    } else {
                        result.success(true)
                    }
                }
                "requestIgnoreBatteryOptimization" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        try {
                            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                data = Uri.parse("package:$packageName")
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            try {
                                val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                                startActivity(intent)
                                result.success(true)
                            } catch (ex: Exception) {
                                result.error("ERROR", ex.message, null)
                            }
                        }
                    } else {
                        result.success(true)
                    }
                }
                "checkExactAlarmPermission" -> {
                    val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && alarmManager != null) {
                        result.success(alarmManager.canScheduleExactAlarms())
                    } else {
                        result.success(true)
                    }
                }
                "requestExactAlarmPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        try {
                            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                                data = Uri.parse("package:$packageName")
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    } else {
                        result.success(true)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
