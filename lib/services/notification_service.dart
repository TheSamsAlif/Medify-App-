import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Top-level background notification callback (must be top-level or static)
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final prefs = await SharedPreferences.getInstance();
    final actionId = notificationResponse.actionId;
    final payloadStr = notificationResponse.payload;
    if (actionId != null && payloadStr != null) {
      final List<String> pending = prefs.getStringList('pending_alarm_actions') ?? [];
      pending.add(jsonEncode({
        'actionId': actionId,
        'payload': payloadStr,
        'timestamp': DateTime.now().toIso8601String(),
      }));
      await prefs.setStringList('pending_alarm_actions', pending);
    }
  } catch (e) {
    debugPrint('Error handling background notification response: $e');
  }
}

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const MethodChannel _nativeChannel = MethodChannel('com.medify.app/alarm');

  static const String channelId = 'medicine_alarm_channel_v2';
  static const String channelName = 'Medicine Alarms';
  static const String channelDesc = 'High priority exact time alarms for scheduled medicines';

  Function(String actionId, Map<String, dynamic> payload)? onActionReceived;
  Function(Map<String, dynamic> payload)? onNotificationTapped;

  Map<String, dynamic>? pendingLaunchPayload;

  Future<void> init() async {
    // 1. Initialize Timezones
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));
    } catch (_) {
      // Fallback to UTC if timezone lookup fails
    }

    // 2. Android & iOS Initialization Settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // 3. Initialize plugin with foreground and background callbacks
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleForegroundResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // 4. Create High-Priority Notification Channel with Alarm sound
    await _createNotificationChannel();

    // 5. Request necessary permissions
    await requestPermissions();

    // 6. Setup native Alarm Channel for auto-opening app
    _setupNativeAlarmChannel();

    // 7. Check if app was launched from native alarm cold start
    try {
      final initialAlarm =
          await _nativeChannel.invokeMethod<dynamic>('getInitialAlarm');
      if (initialAlarm != null && initialAlarm is Map) {
        pendingLaunchPayload = Map<String, dynamic>.from(initialAlarm);
        debugPrint('App launched from native alarm: $pendingLaunchPayload');
      }
    } catch (e) {
      debugPrint('Error checking native getInitialAlarm: $e');
    }

    // 8. Check if app was launched by tapping local notification
    try {
      final launchDetails =
          await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
        final payloadStr = launchDetails.notificationResponse?.payload;
        if (payloadStr != null && payloadStr.isNotEmpty) {
          pendingLaunchPayload =
              jsonDecode(payloadStr) as Map<String, dynamic>;
          debugPrint('App launched from local notification: $pendingLaunchPayload');
        }
      }
    } catch (e) {
      debugPrint('Error checking getNotificationAppLaunchDetails: $e');
    }
  }

  void _setupNativeAlarmChannel() {
    _nativeChannel.setMethodCallHandler((call) async {
      if (call.method == 'onAlarmTriggered') {
        final data = Map<String, dynamic>.from(call.arguments as Map);
        debugPrint('Native onAlarmTriggered received: $data');
        onNotificationTapped?.call(data);
      }
    });
  }

  Future<void> _createNotificationChannel() async {
    final androidImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl != null) {
      final Int64List vibrationPattern = Int64List.fromList([0, 1000, 500, 1000, 500, 1000]);

      final AndroidNotificationChannel channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDesc,
        importance: Importance.max,
        sound: const RawResourceAndroidNotificationSound('alarm_sound'),
        playSound: true,
        enableVibration: true,
        vibrationPattern: vibrationPattern,
        enableLights: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      );

      await androidImpl.createNotificationChannel(channel);
    }
  }

  Future<void> requestPermissions() async {
    final androidImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl != null) {
      try {
        await androidImpl.requestNotificationsPermission();
      } catch (e) {
        debugPrint('Error requesting notification permission: $e');
      }

      try {
        await androidImpl.requestExactAlarmsPermission();
      } catch (e) {
        debugPrint('Error requesting exact alarm permission: $e');
      }
    }
  }

  void _handleForegroundResponse(NotificationResponse response) {
    final payloadStr = response.payload;
    Map<String, dynamic> payload = {};
    if (payloadStr != null && payloadStr.isNotEmpty) {
      try {
        payload = jsonDecode(payloadStr) as Map<String, dynamic>;
      } catch (_) {}
    }

    if (response.actionId != null && response.actionId!.isNotEmpty) {
      onActionReceived?.call(response.actionId!, payload);
    } else {
      onNotificationTapped?.call(payload);
    }
  }

  /// Generates a positive 31-bit integer deterministic ID for notification
  int getNotificationId(String medicineId, String timeStr) {
    return (medicineId.hashCode ^ timeStr.hashCode).abs() % 2147483647;
  }

  /// Robust time parser supporting "08:00 AM", "8:00 AM", "08:00", etc.
  TimeOfDay? parseTimeString(String timeStr) {
    try {
      final trimmed = timeStr.trim().toUpperCase();
      final isPM = trimmed.contains('PM');
      final isAM = trimmed.contains('AM');

      final cleaned = trimmed.replaceAll('AM', '').replaceAll('PM', '').trim();
      final parts = cleaned.split(':');
      if (parts.length < 2) return null;

      int hour = int.parse(parts[0].trim());
      int minute = int.parse(parts[1].trim());

      if (isPM && hour < 12) hour += 12;
      if (isAM && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      debugPrint('Error parsing time string "$timeStr": $e');
      return null;
    }
  }

  /// Schedules an exact daily repeating alarm for a medicine dose
  Future<void> scheduleDailyMedicineAlarm({
    required String medicineId,
    required String medicineName,
    required String dosage,
    required String timeStr,
    Color? color,
  }) async {
    final timeOfDay = parseTimeString(timeStr);
    if (timeOfDay == null) return;

    final id = getNotificationId(medicineId, timeStr);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );

    // If the scheduled time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final payload = jsonEncode({
      'medicineId': medicineId,
      'medicineName': medicineName,
      'dosage': dosage,
      'scheduledTime': timeStr,
      'color': color?.value,
    });

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      sound: const RawResourceAndroidNotificationSound('alarm_sound'),
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      color: color ?? const Color(0xFF4A90E2),
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'action_taken',
          'Taken',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'action_missed',
          'Missed',
          showsUserInterface: true,
        ),
      ],
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        'Medicine Time: $medicineName',
        'Time to take $dosage of $medicineName. Tap or choose below.',
        scheduledDate,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
      debugPrint('Scheduled daily alarm for $medicineName at $timeStr (ID: $id, Next: $scheduledDate)');

      // Schedule native Android Alarm to auto-open app and ring AlarmService
      await _nativeChannel.invokeMethod('scheduleExactAlarm', {
        'alarmId': id,
        'hour': timeOfDay.hour,
        'minute': timeOfDay.minute,
        'triggerAtMillis': scheduledDate.millisecondsSinceEpoch,
        'medicineName': medicineName,
        'dosage': dosage,
        'scheduledTime': timeStr,
      });
    } catch (e) {
      debugPrint('Failed to schedule daily alarm for $medicineName: $e');
    }
  }

  /// Cancels all scheduled alarms for a specific medicine
  Future<void> cancelMedicineAlarms({
    required String medicineId,
    required List<String> times,
  }) async {
    for (final time in times) {
      final id = getNotificationId(medicineId, time);
      try {
        await _notificationsPlugin.cancel(id);
        await _nativeChannel.invokeMethod('cancelAlarm', {'alarmId': id});
        debugPrint('Cancelled alarm ID: $id for medicine: $medicineId');
      } catch (e) {
        debugPrint('Error cancelling alarm ID $id: $e');
      }
    }
  }

  /// Syncs all medicines with exact daily alarms
  Future<void> syncAllMedicineAlarms(List<dynamic> medicinesList) async {
    for (final m in medicinesList) {
      final id = m.id as String;
      final name = m.name as String;
      final dosage = m.dosage as String;
      final times = m.times as List<String>;
      final color = m.color as Color?;

      for (final time in times) {
        await scheduleDailyMedicineAlarm(
          medicineId: id,
          medicineName: name,
          dosage: dosage,
          timeStr: time,
          color: color,
        );
      }
    }
  }

  /// Stops any running foreground AlarmService audio and vibration
  Future<void> stopAlarm() async {
    try {
      await _nativeChannel.invokeMethod('stopAlarm');
    } catch (e) {
      debugPrint('Error stopping alarm: $e');
    }
  }

  /// Schedule a quick test alarm (e.g. 10 seconds from now) to verify background functionality
  Future<void> scheduleTestAlarm({int secondsFromNow = 10}) async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = now.add(Duration(seconds: secondsFromNow));
    final exactSystemEpochMillis = DateTime.now().millisecondsSinceEpoch + (secondsFromNow * 1000);

    const id = 999999;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      sound: const RawResourceAndroidNotificationSound('alarm_sound'),
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'action_taken',
          'Taken',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'action_missed',
          'Missed',
          showsUserInterface: true,
        ),
      ],
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidDetails);

    final payload = jsonEncode({
      'medicineId': 'test_demo',
      'medicineName': 'Test Medicine (Demo)',
      'dosage': '1 Tablet',
      'scheduledTime': '${scheduledDate.hour}:${scheduledDate.minute}',
    });

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        'Test Medicine Alarm!',
        'Background alarm test successful! Tap or choose below.',
        scheduledDate,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      // Auto-open app via native alarm clock exactly secondsFromNow from system time
      await _nativeChannel.invokeMethod('scheduleExactAlarm', {
        'alarmId': id,
        'triggerAtMillis': exactSystemEpochMillis,
        'medicineName': 'Test Medicine (Demo)',
        'dosage': '1 Tablet',
        'scheduledTime': '${scheduledDate.hour}:${scheduledDate.minute}',
      });
    } catch (e) {
      debugPrint('Error scheduling test alarm: $e');
    }

    debugPrint('Test alarm scheduled for $scheduledDate (exact millis: $exactSystemEpochMillis)');
  }

  Future<bool> checkOverlayPermission() async {
    try {
      final res = await _nativeChannel.invokeMethod<bool>('checkOverlayPermission');
      return res ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> requestOverlayPermission() async {
    try {
      await _nativeChannel.invokeMethod('requestOverlayPermission');
    } catch (e) {
      debugPrint('Error requesting overlay permission: $e');
    }
  }

  Future<bool> checkBatteryOptimization() async {
    try {
      final res = await _nativeChannel.invokeMethod<bool>('checkBatteryOptimization');
      return res ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> requestIgnoreBatteryOptimization() async {
    try {
      await _nativeChannel.invokeMethod('requestIgnoreBatteryOptimization');
    } catch (e) {
      debugPrint('Error requesting battery optimization exemption: $e');
    }
  }

  Future<bool> checkExactAlarmPermission() async {
    try {
      final res = await _nativeChannel.invokeMethod<bool>('checkExactAlarmPermission');
      return res ?? true;
    } catch (e) {
      return true;
    }
  }

  Future<void> requestExactAlarmPermission() async {
    try {
      await _nativeChannel.invokeMethod('requestExactAlarmPermission');
    } catch (e) {
      debugPrint('Error requesting exact alarm permission: $e');
    }
  }

  /// Displays an immediate high-priority emergency SOS heads-up notification
  Future<void> showEmergencyNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'emergency_sos_channel',
      'Emergency SOS Alerts',
      channelDescription: 'High priority urgent emergency alerts from patients',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(
        888888,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing emergency notification: $e');
    }
  }
}
