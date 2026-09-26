package com.medify.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import org.json.JSONObject

class AlarmService : Service() {

    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private val handler = Handler(Looper.getMainLooper())
    private var stopRunnable: Runnable? = null
    private var currentAlarmId: Int = 99999

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) {
            stopSelf()
            return START_NOT_STICKY
        }

        val action = intent.action

        // If user tapped "Taken" or "Dismiss" or app requested stop
        if (action == ACTION_STOP_ALARM) {
            val isTaken = intent.getBooleanExtra("is_taken", false)
            if (isTaken) {
                recordTakenAction(intent)
            }
            stopAlarm()
            stopSelf()
            return START_NOT_STICKY
        }

        val medicineName = intent.getStringExtra("medicineName") ?: "Medicine"
        val dosage = intent.getStringExtra("dosage") ?: ""
        val scheduledTime = intent.getStringExtra("scheduledTime") ?: ""
        currentAlarmId = intent.getIntExtra("alarmId", 99999)

        startAlarm(medicineName, dosage, scheduledTime, currentAlarmId)

        return START_STICKY
    }

    private fun startAlarm(medicineName: String, dosage: String, scheduledTime: String, alarmId: Int) {
        // 1. Acquire WakeLock to keep CPU running and turn on screen
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            @Suppress("DEPRECATION")
            wakeLock = powerManager.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
                        PowerManager.ACQUIRE_CAUSES_WAKEUP or
                        PowerManager.ON_AFTER_RELEASE,
                "medify:AlarmServiceWakeLock"
            ).apply {
                acquire(120 * 1000L) // 2 minutes maximum wake lock
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // 2. Build High-Priority Notification with FullScreenIntent
        val channelId = "medicine_alarm_service_channel_v3"
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Urgent Medicine Reminders",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Loud exact alarms for medicine reminders"
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 800, 400, 800, 400)
                setSound(null, null) // Audio is managed directly by MediaPlayer
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                enableLights(true)
            }
            notificationManager.createNotificationChannel(channel)
        }

        // Intent to launch MainActivity when notification body is clicked
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            )
            putExtra("from_alarm", true)
            putExtra("medicineName", medicineName)
            putExtra("dosage", dosage)
            putExtra("scheduledTime", scheduledTime)
            putExtra("alarmId", alarmId)
        }

        val fullScreenPendingIntent = PendingIntent.getActivity(
            this,
            alarmId,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Action: Taken
        val takenIntent = Intent(this, AlarmService::class.java).apply {
            action = ACTION_STOP_ALARM
            putExtra("is_taken", true)
            putExtra("medicineName", medicineName)
            putExtra("dosage", dosage)
            putExtra("scheduledTime", scheduledTime)
            putExtra("alarmId", alarmId)
        }
        val takenPendingIntent = PendingIntent.getService(
            this,
            alarmId * 10 + 1,
            takenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Action: Dismiss
        val dismissIntent = Intent(this, AlarmService::class.java).apply {
            action = ACTION_STOP_ALARM
            putExtra("is_taken", false)
            putExtra("alarmId", alarmId)
        }
        val dismissPendingIntent = PendingIntent.getService(
            this,
            alarmId * 10 + 2,
            dismissIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("🚨 Medicine Time: $medicineName")
            .setContentText("Time to take $dosage ($scheduledTime)")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setOngoing(true)
            .setAutoCancel(false)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .setContentIntent(fullScreenPendingIntent)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .addAction(android.R.drawable.checkbox_on_background, "Mark as Taken", takenPendingIntent)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Dismiss", dismissPendingIntent)
            .build()

        startForeground(alarmId, notification)

        // 3. Play Alarm Sound loudly on the ALARM stream
        try {
            mediaPlayer?.release()
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                val soundUri = Uri.parse("android.resource://${packageName}/raw/alarm_sound")
                try {
                    setDataSource(this@AlarmService, soundUri)
                } catch (e: Exception) {
                    val defaultAlarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                        ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                    setDataSource(this@AlarmService, defaultAlarmUri)
                }
                isLooping = true
                prepare()
                start()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // 4. Start Vibration in loop
        try {
            vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                vibratorManager.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }

            val pattern = longArrayOf(0, 800, 400, 800, 400)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator?.vibrate(VibrationEffect.createWaveform(pattern, 0)) // 0 means repeat
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(pattern, 0)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // 5. Try launching Activity directly if device allows overlay/unlock
        try {
            startActivity(launchIntent)
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // 6. Safety auto-timeout: Stop after 90 seconds if untouched
        stopRunnable = Runnable {
            stopAlarm()
            stopSelf()
        }
        handler.postDelayed(stopRunnable!!, 90 * 1000L)
    }

    private fun stopAlarm() {
        try {
            stopRunnable?.let { handler.removeCallbacks(it) }
            mediaPlayer?.apply {
                if (isPlaying) stop()
                release()
            }
            mediaPlayer = null
        } catch (e: Exception) {
            e.printStackTrace()
        }

        try {
            vibrator?.cancel()
            vibrator = null
        } catch (e: Exception) {
            e.printStackTrace()
        }

        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
            wakeLock = null
        } catch (e: Exception) {
            e.printStackTrace()
        }

        @Suppress("DEPRECATION")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            stopForeground(true)
        }

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(currentAlarmId)
    }

    private fun recordTakenAction(intent: Intent) {
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
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

    override fun onDestroy() {
        stopAlarm()
        super.onDestroy()
    }

    companion object {
        const val ACTION_STOP_ALARM = "com.medify.app.ACTION_STOP_ALARM"

        fun stop(context: Context) {
            val intent = Intent(context, AlarmService::class.java).apply {
                action = ACTION_STOP_ALARM
            }
            context.startService(intent)
        }
    }
}
