package com.medify.app

import android.app.Activity
import android.app.KeyguardManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import org.json.JSONArray
import org.json.JSONObject

class AlarmActivity : Activity() {

    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private val handler = Handler(Looper.getMainLooper())
    private var autoSilenceRunnable: Runnable? = null

    private var medicineName: String = "Medicine"
    private var dosage: String = ""
    private var scheduledTime: String = ""
    private var alarmId: Int = 99999

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        wakeAndUnlock()

        medicineName = intent.getStringExtra("medicineName") ?: "Medicine"
        dosage = intent.getStringExtra("dosage") ?: ""
        scheduledTime = intent.getStringExtra("scheduledTime") ?: ""
        alarmId = intent.getIntExtra("alarmId", 99999)

        Log.d("AlarmActivity", "AlarmActivity started for $medicineName ($dosage, $scheduledTime, id=$alarmId)")

        // Dismiss the notification for this alarm since the screen is open
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.cancel(alarmId)

        buildLayout()
        startSoundAndVibration()

        // Auto-silence after 2 minutes if untouched
        val silenceTask = Runnable {
            stopSoundAndVibration()
            finish()
        }
        autoSilenceRunnable = silenceTask
        handler.postDelayed(silenceTask, 120 * 1000L)
    }

    private fun wakeAndUnlock() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val km = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
            km?.requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                        WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                        WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                        WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }

        try {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            @Suppress("DEPRECATION")
            wakeLock = pm.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
                        PowerManager.ACQUIRE_CAUSES_WAKEUP or
                        PowerManager.ON_AFTER_RELEASE,
                "medify:AlarmActivityWakeLock"
            ).apply {
                acquire(120 * 1000L)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun buildLayout() {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(48, 64, 48, 64)
            // Beautiful dark medical gradient background
            background = GradientDrawable(
                GradientDrawable.Orientation.TOP_BOTTOM,
                intArrayOf(Color.parseColor("#0F172A"), Color.parseColor("#1E3A8A"), Color.parseColor("#0F172A"))
            )
        }

        val scrollView = ScrollView(this).apply {
            isFillViewport = true
            addView(root)
        }

        // 1. Icon Container
        val iconContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(32, 32, 32, 32)
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#2563EB"))
            }
        }

        val icon = ImageView(this).apply {
            setImageResource(android.R.drawable.ic_popup_reminder)
            setColorFilter(Color.WHITE)
            layoutParams = LinearLayout.LayoutParams(120, 120)
        }
        iconContainer.addView(icon)
        root.addView(iconContainer)

        // Spacer
        root.addView(View(this).apply { layoutParams = LinearLayout.LayoutParams(1, 48) })

        // 2. Alarm Title
        val titleText = TextView(this).apply {
            text = "MEDICINE ALARM"
            setTextColor(Color.parseColor("#38BDF8"))
            textSize = 16f
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            letterSpacing = 0.15f
        }
        root.addView(titleText)

        // Spacer
        root.addView(View(this).apply { layoutParams = LinearLayout.LayoutParams(1, 16) })

        // 3. Medicine Name
        val nameText = TextView(this).apply {
            text = medicineName
            setTextColor(Color.WHITE)
            textSize = 34f
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
        }
        root.addView(nameText)

        // 4. Dosage & Time
        val infoText = TextView(this).apply {
            val displayDosage = if (dosage.isNotEmpty()) "Dosage: $dosage" else ""
            val displayTime = if (scheduledTime.isNotEmpty()) "Scheduled: $scheduledTime" else ""
            val fullInfo = listOf(displayDosage, displayTime).filter { it.isNotEmpty() }.joinToString(" • ")
            text = if (fullInfo.isNotEmpty()) fullInfo else "Time to take your scheduled dose"
            setTextColor(Color.parseColor("#CBD5E1"))
            textSize = 18f
            gravity = Gravity.CENTER
        }
        root.addView(infoText)

        // Spacer
        root.addView(View(this).apply { layoutParams = LinearLayout.LayoutParams(1, 64) })

        // 5. "Mark as Taken" Button
        val takeButton = Button(this).apply {
            text = "✓  MARK AS TAKEN"
            setTextColor(Color.WHITE)
            textSize = 18f
            typeface = Typeface.DEFAULT_BOLD
            setPadding(32, 36, 32, 36)
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = 32f
                setColor(Color.parseColor("#10B981")) // Emerald green
            }
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(0, 0, 0, 24)
            }
            setOnClickListener {
                onActionTaken()
            }
        }
        root.addView(takeButton)

        // 6. "Dismiss" Button
        val dismissButton = Button(this).apply {
            text = "DISMISS ALARM"
            setTextColor(Color.parseColor("#EF4444"))
            textSize = 16f
            typeface = Typeface.DEFAULT_BOLD
            setPadding(32, 28, 32, 28)
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = 32f
                setColor(Color.parseColor("#1E293B"))
                setStroke(3, Color.parseColor("#EF4444"))
            }
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            setOnClickListener {
                onActionDismiss()
            }
        }
        root.addView(dismissButton)

        setContentView(scrollView)
    }

    private fun startSoundAndVibration() {
        // 1. Audio Playback with MediaPlayer on USAGE_ALARM
        try {
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                val soundUri = Uri.parse("android.resource://${packageName}/raw/alarm_sound")
                try {
                    setDataSource(this@AlarmActivity, soundUri)
                } catch (e: Exception) {
                    val defaultAlarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                        ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                    setDataSource(this@AlarmActivity, defaultAlarmUri)
                }
                isLooping = true
                prepare()
                start()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // 2. Repeating Alarm Vibration
        try {
            vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vm = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                vm.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }

            val pattern = longArrayOf(0, 800, 400, 800, 400)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator?.vibrate(VibrationEffect.createWaveform(pattern, 0))
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(pattern, 0)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun stopSoundAndVibration() {
        try {
            autoSilenceRunnable?.let { handler.removeCallbacks(it) }
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
    }

    private fun onActionTaken() {
        stopSoundAndVibration()

        // Record taken into Flutter SharedPreferences
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
                put("medicineName", medicineName)
                put("dosage", dosage)
                put("scheduledTime", scheduledTime)
                put("alarmId", alarmId)
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

        // Open MainActivity to show congratulations / taken status
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra("from_alarm", true)
            putExtra("medicineName", medicineName)
            putExtra("dosage", dosage)
            putExtra("scheduledTime", scheduledTime)
            putExtra("alarmId", alarmId)
        }
        startActivity(launchIntent)
        finish()
    }

    private fun onActionDismiss() {
        stopSoundAndVibration()
        finish()
    }

    override fun onDestroy() {
        stopSoundAndVibration()
        super.onDestroy()
    }
}
