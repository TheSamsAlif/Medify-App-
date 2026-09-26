package com.medify.app

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

object AlarmStore {
    private const val PREFS_NAME = "medify_alarms_prefs"

    fun saveAlarm(
        context: Context,
        alarmId: Int,
        triggerAtMillis: Long,
        medicineName: String,
        dosage: String,
        scheduledTime: String,
        hour: Int? = null,
        minute: Int? = null
    ) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val json = JSONObject().apply {
            put("alarmId", alarmId)
            put("triggerAtMillis", triggerAtMillis)
            put("medicineName", medicineName)
            put("dosage", dosage)
            put("scheduledTime", scheduledTime)
            if (hour != null) put("hour", hour)
            if (minute != null) put("minute", minute)
        }
        prefs.edit().putString("alarm_$alarmId", json.toString()).apply()
    }

    fun removeAlarm(context: Context, alarmId: Int) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().remove("alarm_$alarmId").apply()
    }

    fun getAllAlarms(context: Context): List<SavedAlarm> {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val list = mutableListOf<SavedAlarm>()
        for ((key, value) in prefs.all) {
            if (key.startsWith("alarm_") && value is String) {
                try {
                    val json = JSONObject(value)
                    list.add(
                        SavedAlarm(
                            alarmId = json.getInt("alarmId"),
                            triggerAtMillis = json.getLong("triggerAtMillis"),
                            medicineName = json.getString("medicineName"),
                            dosage = json.getString("dosage"),
                            scheduledTime = json.getString("scheduledTime"),
                            hour = if (json.has("hour")) json.getInt("hour") else null,
                            minute = if (json.has("minute")) json.getInt("minute") else null
                        )
                    )
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
        return list
    }
}

data class SavedAlarm(
    val alarmId: Int,
    var triggerAtMillis: Long,
    val medicineName: String,
    val dosage: String,
    val scheduledTime: String,
    val hour: Int? = null,
    val minute: Int? = null
)

class AlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action

        Log.d("AlarmReceiver", "onReceive triggered with action: $action, is_notification_action: ${intent.getBooleanExtra("is_notification_action", false)}")

        // 1. Device reboot or package update -> Restore all alarms
        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == "android.intent.action.QUICKBOOT_POWERON" ||
            action == "com.htc.intent.action.QUICKBOOT_POWERON" ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            restoreAllAlarmsAfterBoot(context)
            return
        }

        // 2. Notification action clicked ("Mark as Taken" or "Dismiss")
        if (intent.getBooleanExtra("is_notification_action", false)) {
            val actionType = intent.getStringExtra("action_type")
            val actionAlarmId = intent.getIntExtra("alarmId", 0)

            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.cancel(actionAlarmId)

            if (actionType == "taken") {
                recordPendingNotificationAction(context, intent)
            }
            return
        }

        val medicineName = intent.getStringExtra("medicineName") ?: "Medicine"
        val dosage = intent.getStringExtra("dosage") ?: ""
        val scheduledTime = intent.getStringExtra("scheduledTime") ?: ""
        val alarmId = intent.getIntExtra("alarmId", 99999)
        val hour = if (intent.hasExtra("hour")) intent.getIntExtra("hour", -1) else null
        val minute = if (intent.hasExtra("minute")) intent.getIntExtra("minute", -1) else null

        // 3. Wake up CPU and turn screen ON
        try {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            @Suppress("DEPRECATION")
            val wakeLock = powerManager.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
                        PowerManager.ACQUIRE_CAUSES_WAKEUP or
                        PowerManager.ON_AFTER_RELEASE,
                "medify:AlarmReceiverWakeLock"
            )
            wakeLock.acquire(30 * 1000L) // 30 seconds wake lock
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // 4. Build Full-Screen Intent pointing to AlarmActivity (displayed on lockscreen!)
        val fullScreenIntent = Intent(context, AlarmActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            )
            putExtra("from_alarm", true)
            putExtra("medicineName", medicineName)
            putExtra("dosage", dosage)
            putExtra("scheduledTime", scheduledTime)
            putExtra("alarmId", alarmId)
        }

        val fullScreenPendingIntent = PendingIntent.getActivity(
            context,
            alarmId,
            fullScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // 5. Post High-Priority Full-Screen Alarm Notification
        showAlarmNotification(context, medicineName, dosage, scheduledTime, alarmId, fullScreenPendingIntent)

        // 6. Directly launch AlarmActivity (will open full screen over lockscreen or when unlocked)
        try {
            context.startActivity(fullScreenIntent)
        } catch (e: Exception) {
            Log.e("AlarmReceiver", "startActivity for AlarmActivity failed: ${e.message}")
        }

        // 7. Auto-reschedule repeating alarm for tomorrow at the same time
        if (alarmId != 999999) { // Avoid auto-rescheduling one-time test alarm
            val nextHour = if (hour != null && hour >= 0) hour else null
            val nextMinute = if (minute != null && minute >= 0) minute else null

            scheduleNativeAlarm(
                context = context,
                alarmId = alarmId,
                triggerAtMillis = System.currentTimeMillis() + (24 * 60 * 60 * 1000L),
                medicineName = medicineName,
                dosage = dosage,
                scheduledTime = scheduledTime,
                hour = nextHour,
                minute = nextMinute
            )
        }
    }

    private fun showAlarmNotification(
        context: Context,
        medicineName: String,
        dosage: String,
        scheduledTime: String,
        alarmId: Int,
        fullScreenPendingIntent: PendingIntent
    ) {
        try {
            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channelId = "medify_alarm_clock_channel_v6"

            val soundUri = Uri.parse("android.resource://${context.packageName}/raw/alarm_sound")

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val audioAttributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()

                val channel = NotificationChannel(
                    channelId,
                    "Urgent Medicine Reminders",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Exact alarms for scheduled medicines"
                    try {
                        setSound(soundUri, audioAttributes)
                    } catch (e: Exception) {
                        val defaultSound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                        setSound(defaultSound, audioAttributes)
                    }
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 1000, 500, 1000, 500, 1000)
                    enableLights(true)
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                }
                notificationManager.createNotificationChannel(channel)
            }

            // Action: Taken
            val takenIntent = Intent(context, AlarmReceiver::class.java).apply {
                putExtra("is_notification_action", true)
                putExtra("action_type", "taken")
                putExtra("medicineName", medicineName)
                putExtra("dosage", dosage)
                putExtra("scheduledTime", scheduledTime)
                putExtra("alarmId", alarmId)
            }
            val takenPendingIntent = PendingIntent.getBroadcast(
                context,
                alarmId * 10 + 1,
                takenIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // Action: Dismiss
            val dismissIntent = Intent(context, AlarmReceiver::class.java).apply {
                putExtra("is_notification_action", true)
                putExtra("action_type", "dismiss")
                putExtra("alarmId", alarmId)
            }
            val dismissPendingIntent = PendingIntent.getBroadcast(
                context,
                alarmId * 10 + 2,
                dismissIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val notificationBuilder = NotificationCompat.Builder(context, channelId)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle("🚨 Time for Medicine: $medicineName")
                .setContentText("Take $dosage ($scheduledTime)")
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setAutoCancel(true)
                .setOngoing(false)
                .setSound(soundUri)
                .setVibrate(longArrayOf(0, 1000, 500, 1000, 500, 1000))
                .setFullScreenIntent(fullScreenPendingIntent, true)
                .setContentIntent(fullScreenPendingIntent)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .addAction(android.R.drawable.checkbox_on_background, "Mark as Taken", takenPendingIntent)
                .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Dismiss", dismissPendingIntent)

            val notification = notificationBuilder.build()
            notification.flags = notification.flags or Notification.FLAG_INSISTENT

            notificationManager.notify(alarmId, notification)
            Log.d("AlarmReceiver", "showAlarmNotification posted for $medicineName (id=$alarmId)")
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun recordPendingNotificationAction(context: Context, intent: Intent) {
        try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val pendingKey = "flutter.pending_alarm_actions"
            val existingJson = prefs.getString(pendingKey, "[]") ?: "[]"
            val jsonArray = try {
                JSONArray(existingJson)
            } catch (e: Exception) {
                JSONArray()
            }

            val payloadObj = JSONObject().apply {
                put("medicineName", intent.getStringExtra("medicineName") ?: "")
                put("dosage", intent.getStringExtra("dosage") ?: "")
                put("scheduledTime", intent.getStringExtra("scheduledTime") ?: "")
                put("alarmId", intent.getIntExtra("alarmId", 0))
            }

            val actionObj = JSONObject().apply {
                put("actionId", "action_taken")
                put("payload", payloadObj.toString())
                put("timestamp", System.currentTimeMillis())
            }

            jsonArray.put(actionObj.toString())
            prefs.edit().putString(pendingKey, jsonArray.toString()).apply()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun restoreAllAlarmsAfterBoot(context: Context) {
        val alarms = AlarmStore.getAllAlarms(context)
        Log.d("AlarmReceiver", "Restoring ${alarms.size} alarms after boot")
        for (alarm in alarms) {
            scheduleNativeAlarm(
                context = context,
                alarmId = alarm.alarmId,
                triggerAtMillis = alarm.triggerAtMillis,
                medicineName = alarm.medicineName,
                dosage = alarm.dosage,
                scheduledTime = alarm.scheduledTime,
                hour = alarm.hour,
                minute = alarm.minute
            )
        }
    }

    companion object {
        fun scheduleNativeAlarm(
            context: Context,
            alarmId: Int,
            triggerAtMillis: Long,
            medicineName: String,
            dosage: String,
            scheduledTime: String,
            hour: Int? = null,
            minute: Int? = null
        ) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return

            // Calculate precise trigger timestamp natively using device's system calendar
            val actualTriggerMillis: Long = if (hour != null && minute != null && hour >= 0 && minute >= 0) {
                val calendar = Calendar.getInstance().apply {
                    timeInMillis = System.currentTimeMillis()
                    set(Calendar.HOUR_OF_DAY, hour)
                    set(Calendar.MINUTE, minute)
                    set(Calendar.SECOND, 0)
                    set(Calendar.MILLISECOND, 0)
                    if (timeInMillis <= System.currentTimeMillis()) {
                        add(Calendar.DAY_OF_YEAR, 1)
                    }
                }
                calendar.timeInMillis
            } else {
                if (triggerAtMillis <= System.currentTimeMillis()) {
                    triggerAtMillis + (24 * 60 * 60 * 1000L)
                } else {
                    triggerAtMillis
                }
            }

            val intent = Intent(context, AlarmReceiver::class.java).apply {
                putExtra("from_alarm", true)
                putExtra("alarmId", alarmId)
                putExtra("medicineName", medicineName)
                putExtra("dosage", dosage)
                putExtra("scheduledTime", scheduledTime)
                if (hour != null) putExtra("hour", hour)
                if (minute != null) putExtra("minute", minute)
            }

            val pendingIntent = PendingIntent.getBroadcast(
                context,
                alarmId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // Save to persistent storage for reboot survival
            AlarmStore.saveAlarm(
                context = context,
                alarmId = alarmId,
                triggerAtMillis = actualTriggerMillis,
                medicineName = medicineName,
                dosage = dosage,
                scheduledTime = scheduledTime,
                hour = hour,
                minute = minute
            )

            // Intent to launch AlarmActivity directly when clicking the alarm clock widget/setting
            val showIntent = Intent(context, AlarmActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                putExtra("medicineName", medicineName)
                putExtra("dosage", dosage)
                putExtra("scheduledTime", scheduledTime)
                putExtra("alarmId", alarmId)
            }
            val showPendingIntent = PendingIntent.getActivity(
                context,
                alarmId,
                showIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            try {
                // AlarmClockInfo guarantees high priority, Doze bypass, and exact second trigger on all Android ROMs
                val alarmClockInfo = AlarmManager.AlarmClockInfo(actualTriggerMillis, showPendingIntent)
                alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
                Log.d("AlarmReceiver", "Successfully scheduled setAlarmClock for $medicineName (id=$alarmId, millis=$actualTriggerMillis, in ${(actualTriggerMillis - System.currentTimeMillis()) / 1000}s)")
            } catch (e: Exception) {
                Log.w("AlarmReceiver", "setAlarmClock failed, trying fallback: ${e.message}")
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        alarmManager.setExactAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP,
                            actualTriggerMillis,
                            pendingIntent
                        )
                    } else {
                        alarmManager.setExact(
                            AlarmManager.RTC_WAKEUP,
                            actualTriggerMillis,
                            pendingIntent
                        )
                    }
                } catch (ex: Exception) {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            alarmManager.setAndAllowWhileIdle(
                                AlarmManager.RTC_WAKEUP,
                                actualTriggerMillis,
                                pendingIntent
                            )
                        }
                    } catch (finalEx: Exception) {
                        finalEx.printStackTrace()
                    }
                }
            }
        }

        fun cancelNativeAlarm(context: Context, alarmId: Int) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
            val intent = Intent(context, AlarmReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                alarmId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(pendingIntent)
            AlarmStore.removeAlarm(context, alarmId)

            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.cancel(alarmId)
            Log.d("AlarmReceiver", "Cancelled alarm $alarmId")
        }
    }
}
