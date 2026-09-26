import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../services/notification_service.dart';
import 'auth_controller.dart';

class Medicine {
  String id;
  String name;
  String dosage;
  String frequency;
  List<String> times;
  Color color;

  Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.times,
    required this.color,
  });
}

class HistoryEntry {
  String id;
  String medicineName;
  String dosage;
  String scheduledTime;
  String? takenTime;
  String status; // 'taken' | 'missed'
  DateTime date;
  Color color;

  HistoryEntry({
    required this.id,
    required this.medicineName,
    required this.dosage,
    required this.scheduledTime,
    this.takenTime,
    required this.status,
    required this.date,
    required this.color,
  });
}

class ScannedMedicine {
  String id;
  String name;
  String dosage;
  String frequency;
  List<String> suggestedTimes;

  ScannedMedicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.suggestedTimes,
  });
}

class PatientController extends GetxController {
  // Navigation
  var selectedIndex = 0.obs;

  // User Data
  var patientName = ''.obs;
  var patientInitials = ''.obs;
  var patientEmail = ''.obs;
  var patientPhone = ''.obs;
  var patientPhoto = ''.obs;
  var patientAge = ''.obs;
  var patientGender = ''.obs;
  var isUploadingImage = false.obs;

  // Medicines List
  var medicines = <Medicine>[].obs;
  var searchQuery = ''.obs;

  // Scanner States
  var isScanning = false.obs;
  var scanProgress = 0.obs;
  var scannedMedicines = <ScannedMedicine>[].obs;
  var selectedScannedMedicine = Rxn<ScannedMedicine>();
  var scannerScheduleTimes = <String>[].obs;

  // History List
  var historyList = <HistoryEntry>[].obs;
  var historyFilter = 'all'.obs; // 'all' | 'taken' | 'missed'

  // Settings
  var notificationsEnabled = true.obs;
  var darkModeEnabled = false.obs;
  var selectedLanguage = 'English'.obs;
  var isCodeCopied = false.obs;

  // Dynamic Details
  var patientCode = ''.obs;
  var connectedCaretakers = <Map<String, dynamic>>[].obs;

  // SOS Emergency State
  var isSosActive = false.obs;
  var activeSosAlertId = ''.obs;
  StreamSubscription? _patientSosSubscription;

  Timer? _alarmTimer;
  Timer? _vibrationTimer;
  final Set<String> _notifiedHistoryIds = {};
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void onInit() {
    super.onInit();
    try {
      _loadLocalMedicines();
    } catch (_) {}
    try {
      _loadUserData();
    } catch (_) {}
    try {
      _listenToMedicines();
    } catch (_) {}
    try {
      _listenToHistory();
    } catch (_) {}
    try {
      _startAlarmChecker();
    } catch (_) {}
    try {
      _listenToPatientSos();
    } catch (_) {}

    try {
      NotificationService.instance.onActionReceived = _handleNotificationAction;
      NotificationService.instance.onNotificationTapped = _handleNotificationTap;
      _processPendingNotificationActions();
    } catch (_) {}
  }

  Future<void> _loadLocalMedicines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString('local_medicines');
      if (savedStr != null && savedStr.isNotEmpty) {
        final List<dynamic> decoded = json.decode(savedStr);
        final list = decoded.map((data) {
          return Medicine(
            id: data['id'] ?? '',
            name: data['name'] ?? '',
            dosage: data['dosage'] ?? '',
            frequency: data['frequency'] ?? '',
            times: List<String>.from(data['times'] ?? []),
            color: Color(data['color'] ?? Colors.blue.value),
          );
        }).toList();
        if (medicines.isEmpty && list.isNotEmpty) {
          medicines.assignAll(list);
          if (notificationsEnabled.value) {
            NotificationService.instance.syncAllMedicineAlarms(list);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading local medicines: $e');
    }
  }

  void _handleNotificationAction(String actionId, Map<String, dynamic> payload) async {
    final medicineName = payload['medicineName'] as String?;
    final dosage = payload['dosage'] as String? ?? '';
    final time = payload['scheduledTime'] as String? ?? '';
    final colorVal = payload['color'] as int?;

    if (medicineName == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final existingIndex = historyList.indexWhere((h) =>
        h.medicineName == medicineName &&
        h.date.year == today.year &&
        h.date.month == today.month &&
        h.date.day == today.day &&
        (time.isEmpty || h.scheduledTime == time));

    final status = (actionId == 'action_taken') ? 'taken' : 'missed';

    if (existingIndex != -1) {
      final entry = historyList[existingIndex];
      await updateHistoryStatus(entry.id, status);
    } else {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .add({
        'medicineName': medicineName,
        'dosage': dosage,
        'scheduledTime': time.isNotEmpty ? time : '${now.hour}:${now.minute}',
        'status': status,
        'date': Timestamp.fromDate(today),
        'takenTime': status == 'taken' ? '${now.hour}:${now.minute}' : null,
        'color': colorVal ?? Colors.blue.value,
      });
    }

    Get.snackbar(
      status == 'taken' ? 'Medicine Taken' : 'Medicine Missed',
      '$medicineName marked as $status',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: status == 'taken' ? const Color(0xFF2ECC71) : Colors.redAccent,
      colorText: Colors.white,
    );
  }

  void _handleNotificationTap(Map<String, dynamic> payload) {
    final medicineName = payload['medicineName'] as String?;
    if (medicineName == null || medicineName.isEmpty) return;

    final dosage = payload['dosage'] as String? ?? '';
    final time = payload['scheduledTime'] as String? ?? '';
    final colorVal = payload['color'] as int?;

    showReminderDialog(
      medicineName: medicineName,
      dosage: dosage,
      color: colorVal != null ? Color(colorVal) : const Color(0xFF4A90E2),
      scheduledTime: time,
    );
  }

  void checkPendingAlarmLaunch() {
    if (NotificationService.instance.pendingLaunchPayload != null) {
      final payload = NotificationService.instance.pendingLaunchPayload!;
      NotificationService.instance.pendingLaunchPayload = null;
      _handleNotificationTap(payload);
    }
  }

  Future<void> _processPendingNotificationActions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? pending = prefs.getStringList('pending_alarm_actions');
      if (pending != null && pending.isNotEmpty) {
        for (final item in pending) {
          final data = jsonDecode(item) as Map<String, dynamic>;
          final actionId = data['actionId'] as String;
          final payload = jsonDecode(data['payload'] as String) as Map<String, dynamic>;
          _handleNotificationAction(actionId, payload);
        }
        await prefs.remove('pending_alarm_actions');
      }
    } catch (e) {
      debugPrint('Error processing pending notification actions: $e');
    }
  }

  @override
  void onClose() {
    _alarmTimer?.cancel();
    _patientSosSubscription?.cancel();
    _audioPlayer.dispose();
    super.onClose();
  }

  void _startAlarmChecker() {
    _alarmTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!notificationsEnabled.value) return;

      final now = DateTime.now();

      // Check all active medicines directly so alarm triggers on time when app is open
      for (final med in medicines) {
        for (final timeStr in med.times) {
          final timeOfDay = NotificationService.instance.parseTimeString(timeStr);
          if (timeOfDay == null) continue;

          if (now.hour == timeOfDay.hour && now.minute == timeOfDay.minute) {
            final doseKey = '${med.id}_${now.year}_${now.month}_${now.day}_${timeOfDay.hour}_${timeOfDay.minute}';
            if (!_notifiedHistoryIds.contains(doseKey)) {
              _notifiedHistoryIds.add(doseKey);
              showReminderDialog(
                medicineName: med.name,
                dosage: med.dosage,
                color: med.color,
                scheduledTime: timeStr,
              );
            }
          }
        }
      }
    });
  }

  void showReminderDialog({
    required String medicineName,
    required String dosage,
    required Color color,
    required String scheduledTime,
    String? historyId,
  }) async {
    // Stop native foreground AlarmService audio/vibration since Flutter takes over UI
    NotificationService.instance.stopAlarm();
    if (Get.isDialogOpen == true) return;

    try {
      _audioPlayer.setReleaseMode(ReleaseMode.loop);
      _audioPlayer.audioCache = AudioCache(prefix: 'Assets/');
      _audioPlayer.play(AssetSource('music.mp3'));
    } catch (e) {
      debugPrint('Audio play error: $e');
    }

    _vibrationTimer?.cancel();
    _vibrationTimer =
        Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      HapticFeedback.heavyImpact();
    });

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.medication_liquid_rounded,
                    color: color, size: 56),
              ),
              const SizedBox(height: 20),
              const Text(
                "Time for your medicine!",
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                medicineName,
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                "Dosage: $dosage",
                style: const TextStyle(fontSize: 18, color: Colors.black54),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        NotificationService.instance.stopAlarm();
                        _audioPlayer.stop();
                        _vibrationTimer?.cancel();
                        _recordDoseAction(
                          medicineName: medicineName,
                          dosage: dosage,
                          scheduledTime: scheduledTime,
                          status: 'missed',
                          historyId: historyId,
                          color: color,
                        );
                        Get.back();
                      },
                      child: const Text('Missed',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ECC71),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        NotificationService.instance.stopAlarm();
                        _audioPlayer.stop();
                        _vibrationTimer?.cancel();
                        _recordDoseAction(
                          medicineName: medicineName,
                          dosage: dosage,
                          scheduledTime: scheduledTime,
                          status: 'taken',
                          historyId: historyId,
                          color: color,
                        );
                        Get.back();
                      },
                      child: const Text('Taken',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _recordDoseAction({
    required String medicineName,
    required String dosage,
    required String scheduledTime,
    required String status,
    String? historyId,
    required Color color,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (historyId != null && historyId.isNotEmpty) {
      await updateHistoryStatus(historyId, status);
    } else {
      final existingIndex = historyList.indexWhere((h) =>
          h.medicineName == medicineName &&
          h.date.year == today.year &&
          h.date.month == today.month &&
          h.date.day == today.day &&
          (scheduledTime.isEmpty || h.scheduledTime == scheduledTime));

      if (existingIndex != -1) {
        await updateHistoryStatus(historyList[existingIndex].id, status);
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('history')
            .add({
          'medicineName': medicineName,
          'dosage': dosage,
          'scheduledTime': scheduledTime.isNotEmpty ? scheduledTime : '${now.hour}:${now.minute}',
          'status': status,
          'date': Timestamp.fromDate(today),
          'takenTime': status == 'taken' ? '${now.hour}:${now.minute}' : null,
          'color': color.value,
        });
      }
    }
  }

  Future<void> updateHistoryStatus(String id, String status) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .doc(id)
          .update({
        'status': status,
        if (status == 'taken') 'takenTime': _formatCurrentTime(),
      });
    }
  }

  String _formatCurrentTime() {
    final now = DateTime.now();
    int h = now.hour;
    String ampm = h >= 12 ? 'PM' : 'AM';
    if (h > 12) h -= 12;
    if (h == 0) h = 12;
    String m = now.minute.toString().padLeft(2, '0');
    return '$h:$m $ampm';
  }

  void changeTab(int index) {
    selectedIndex.value = index;
  }

  void _loadUserData() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .listen((doc) {
          if (doc.exists) {
            final data = doc.data()!;
            final name = data['name'] ?? 'Patient';
            patientName.value = name;
            patientEmail.value = data['email'] ?? user.email ?? '';
            patientPhone.value = data['phone'] ?? '';
            patientPhoto.value = data['photo'] ?? '';
            patientAge.value = data['age']?.toString() ?? '';
            patientGender.value = data['gender'] ?? '';

            final nameParts = name.trim().split(' ');
            if (nameParts.length > 1 && nameParts[1].isNotEmpty) {
              patientInitials.value =
                  '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
            } else if (nameParts.isNotEmpty && nameParts[0].isNotEmpty) {
              patientInitials.value = nameParts[0][0].toUpperCase();
            } else {
              patientInitials.value = 'P';
            }

            // Generate patientCode if not exists
            if (!data.containsKey('patientCode') ||
                data['patientCode'] == null) {
              final newCode =
                  'P-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}-${user.uid.substring(0, 2).toUpperCase()}';
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .update({'patientCode': newCode});
              patientCode.value = newCode;
            } else {
              patientCode.value = data['patientCode'];
            }

            // Caretakers
            if (data.containsKey('caretakers') && data['caretakers'] is List) {
              connectedCaretakers.assignAll(
                  List<Map<String, dynamic>>.from(data['caretakers']));
            }
          }
        });
      }
    });
  }

  Future<void> updateProfile(String name, String phone,
      {String age = '', String gender = ''}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final updateData = <String, dynamic>{
        'name': name,
        'phone': phone,
      };
      if (age.isNotEmpty) updateData['age'] = age;
      if (gender.isNotEmpty) updateData['gender'] = gender;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updateData);

      patientName.value = name;
      patientPhone.value = phone;
      patientAge.value = age;
      patientGender.value = gender;
      final nameParts = name.trim().split(' ');
      if (nameParts.length > 1 && nameParts[1].isNotEmpty) {
        patientInitials.value =
            '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
      } else if (nameParts.isNotEmpty && nameParts[0].isNotEmpty) {
        patientInitials.value = nameParts[0][0].toUpperCase();
      } else {
        patientInitials.value = 'P';
      }
      Get.snackbar('Success', 'Profile updated successfully',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);

    if (image != null) {
      isUploadingImage.value = true;
      try {
        final bytes = await image.readAsBytes();
        var request = http.MultipartRequest('POST',
            Uri.parse('https://api.cloudinary.com/v1_1/cfnsqzjs/image/upload'));
        request.fields['upload_preset'] = 'mediapp';
        request.files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: image.name));

        var response = await request.send();
        if (response.statusCode == 200) {
          final respStr = await response.stream.bytesToString();
          final jsonMap = json.decode(respStr);
          final url = jsonMap['secure_url'];

          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({'photo': url});
            patientPhoto.value = url;
            Get.snackbar('Success', 'Profile picture updated',
                snackPosition: SnackPosition.BOTTOM);
          }
        } else {
          Get.snackbar('Error', 'Failed to upload image',
              snackPosition: SnackPosition.BOTTOM);
        }
      } catch (e) {
        Get.snackbar('Error', 'An error occurred while uploading',
            snackPosition: SnackPosition.BOTTOM);
      } finally {
        isUploadingImage.value = false;
      }
    }
  }

  void _listenToMedicines() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('medicines')
        .snapshots()
        .listen((snapshot) async {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        return Medicine(
          id: doc.id,
          name: data['name'] ?? '',
          dosage: data['dosage'] ?? '',
          frequency: data['frequency'] ?? '',
          times: List<String>.from(data['times'] ?? []),
          color: Color(data['color'] ?? Colors.blue.value),
        );
      }).toList();
      medicines.assignAll(list);

      // Automatically sync all medicine alarms with NotificationService for background on-time triggers
      if (notificationsEnabled.value) {
        NotificationService.instance.syncAllMedicineAlarms(list);
      }

      // Save locally to phone storage
      final prefs = await SharedPreferences.getInstance();
      final jsonList = list
          .map((m) => {
                'id': m.id,
                'name': m.name,
                'dosage': m.dosage,
                'frequency': m.frequency,
                'times': m.times,
                'color': m.color.value,
              })
          .toList();
      prefs.setString('local_medicines', json.encode(jsonList));
    });
  }

  void _listenToHistory() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('history')
        .snapshots()
        .listen((snapshot) {
      historyList.assignAll(snapshot.docs.map((doc) {
        final data = doc.data();
        return HistoryEntry(
          id: doc.id,
          medicineName: data['medicineName'] ?? '',
          dosage: data['dosage'] ?? '',
          scheduledTime: data['scheduledTime'] ?? '',
          takenTime: data['takenTime'],
          status: data['status'] ?? 'upcoming',
          date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
          color: Color(data['color'] ?? Colors.blue.value),
        );
      }).toList());
    });
  }

  // Add / Edit Medicines
  Future<void> saveMedicine({
    String? id,
    required String name,
    required String dosage,
    required String frequency,
    required List<String> times,
    required Color color,
    int durationInDays = 1,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final isNew = id == null;
    final docRef = isNew
        ? FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('medicines')
            .doc()
        : FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('medicines')
            .doc(id);

    await docRef.set({
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'times': times,
      'color': color.value,
    });

    final medicineId = docRef.id;

    // Optimistic update removed because the Firestore snapshot listener in _listenToMedicines 
    // instantly captures local writes (like docRef.set) and updates the medicines list automatically.

    // Schedule daily exact alarms via NotificationService so alarms trigger even when app is off
    if (notificationsEnabled.value) {
      for (final time in times) {
        await NotificationService.instance.scheduleDailyMedicineAlarm(
          medicineId: medicineId,
          medicineName: name,
          dosage: dosage,
          timeStr: time,
          color: color,
        );
      }
    }

    if (isNew) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      for (final time in times) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('history')
            .add({
          'medicineName': name,
          'dosage': dosage,
          'scheduledTime': time,
          'status': 'upcoming',
          'date': Timestamp.fromDate(today),
          'color': color.value,
        });
      }
    }
  }

  Future<void> deleteMedicine(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final med = medicines.firstWhereOrNull((m) => m.id == id);
    final medName = med?.name ?? 'Medicine';

    try {
      if (med != null) {
        await NotificationService.instance.cancelMedicineAlarms(
          medicineId: id,
          times: med.times,
        );
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('medicines')
          .doc(id)
          .delete();
          
      Get.snackbar(
        'Deleted',
        '$medName removed from list',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('Error deleting medicine: $e');
      Get.snackbar(
        'Error',
        'Failed to delete medicine. Please check your connection.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  List<Medicine> get filteredMedicines {
    if (searchQuery.isEmpty) return medicines.toList();
    return medicines
        .where((m) =>
            m.name.toLowerCase().contains(searchQuery.value.toLowerCase()))
        .toList();
  }

  String getTodayStatusForMedicine(String medicineName) {
    final today = DateTime.now();
    final entry = historyList.firstWhereOrNull((h) =>
        h.medicineName == medicineName &&
        h.date.year == today.year &&
        h.date.month == today.month &&
        h.date.day == today.day);
    return entry?.status ?? 'upcoming';
  }

  // Mistral API Key
  final String mistralApiKey = 'mstrl_YSWqDFwwQ8bvYagf9W4nrYgmb7pQzQWg_4uwsD3';

  Future<void> startPrescriptionScan({ImageSource source = ImageSource.gallery}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image == null) return;

      isScanning.value = true;
      scanProgress.value = 10;
      scannedMedicines.clear();

      // Compress image
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        image.path,
        minWidth: 800,
        minHeight: 800,
        quality: 70,
      );

      if (compressedBytes == null) {
        isScanning.value = false;
        Get.snackbar('Error', 'Failed to compress image');
        return;
      }

      scanProgress.value = 30;
      final base64Image = base64Encode(compressedBytes);

      scanProgress.value = 40;

      // 1. Call OCR.space API
      final ocrUrl = Uri.parse('https://api.ocr.space/parse/image');
      final ocrResponse = await http.post(
        ocrUrl,
        headers: {
          'apikey': 'K85757371688957',
        },
        body: {
          'base64Image': 'data:image/jpeg;base64,$base64Image',
          'language': 'eng',
          'OCREngine': '2',
        },
      );

      if (ocrResponse.statusCode != 200) {
        print('OCR.SPACE ERROR: ${ocrResponse.statusCode} - ${ocrResponse.body}');
        isScanning.value = false;
        Get.snackbar('API Error', 'Failed to extract text from image.');
        return;
      }

      scanProgress.value = 60;
      final ocrData = jsonDecode(ocrResponse.body);
      
      if (ocrData['IsErroredOnProcessing'] == true) {
        print('OCR.SPACE PROCESSING ERROR: ${ocrData['ErrorMessage']}');
        isScanning.value = false;
        Get.snackbar('Scan Failed', 'Error processing image in OCR.');
        return;
      }

      final parsedResults = ocrData['ParsedResults'] as List<dynamic>?;
      if (parsedResults == null || parsedResults.isEmpty) {
        isScanning.value = false;
        Get.snackbar('Scan Failed', 'No text found in the prescription.');
        return;
      }

      final markdownText = parsedResults[0]['ParsedText'] ?? '';
      
      scanProgress.value = 75;

      // 2. Parse text locally (Rule-based since Mistral is removed)
      scanProgress.value = 75;
      
      final lines = markdownText.split('\n');
      String doctorName = 'Unknown Doctor';
      if (lines.isNotEmpty) {
        doctorName = lines.first.trim();
        if (doctorName.length > 50) {
           doctorName = 'Unknown Doctor'; // fallback if first line is too long
        }
      }

      final List<dynamic> meds = [];
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        // Very basic detection of medicine lines
        if (line.toLowerCase().contains('tab') || 
            line.toLowerCase().contains('cap') || 
            line.toLowerCase().contains('syr') || 
            RegExp(r'\d+\s*(mg|ml)').hasMatch(line.toLowerCase())) {
            
            String freq = '1+0+1'; // default
            if (i + 1 < lines.length) {
              final nextLine = lines[i + 1].trim();
              if (nextLine.contains('+')) {
                // e.g., 1+1+1 (After meal)
                freq = nextLine.split(' ').first;
              }
            }
            
            meds.add({
              'medicineName': line,
              'dosage': '',
              'frequency': freq,
            });
        }
      }

      scanProgress.value = 90;

      final List<ScannedMedicine> results = [];
      final List<Map<String, dynamic>> medHistoryList = [];

      for (var i = 0; i < meds.length; i++) {
        final m = meds[i];
        final medName = m['medicineName'] ?? 'Unknown';
        final dosage = m['dosage'] ?? '';
        final freq = m['frequency'] ?? '';
        
        // Auto-generate suggested times based on frequency
        List<String> suggestedTimes = ['09:00 AM'];
        if (freq == '1+1+1') {
          suggestedTimes = ['09:00 AM', '02:00 PM', '09:00 PM'];
        } else if (freq == '1+0+1') {
          suggestedTimes = ['09:00 AM', '09:00 PM'];
        } else if (freq == '0+0+1') {
          suggestedTimes = ['09:00 PM'];
        } else if (freq == '1+0+0') {
          suggestedTimes = ['09:00 AM'];
        }

        results.add(
          ScannedMedicine(
            id: 'scan-${DateTime.now().millisecondsSinceEpoch}-$i',
            name: medName,
            dosage: dosage,
            frequency: freq,
            suggestedTimes: suggestedTimes,
          ),
        );

        medHistoryList.add({
          'medicineName': medName,
          'dosage': dosage,
        });
      }

      scannedMedicines.assignAll(results);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('history')
            .add({
          'scanDate': Timestamp.now(),
          'doctorName': doctorName,
          'imageBase64': base64Image,
          'medicineCount': results.length,
          'medicines': medHistoryList,
        });
      }

      scanProgress.value = 100;
      isScanning.value = false;
    } catch (e) {
      print('SCAN EXCEPTION: $e');
      isScanning.value = false;
      Get.snackbar('Error', 'An error occurred during scanning: $e');
    }
  }

  void selectScannedMedicine(ScannedMedicine medicine) {
    selectedScannedMedicine.value = medicine;
    scannerScheduleTimes.assignAll(medicine.suggestedTimes);
  }

  void addScannerScheduleTime() {
    scannerScheduleTimes.add('09:00 AM');
  }

  void removeScannerScheduleTime(int index) {
    if (scannerScheduleTimes.length > 1) {
      scannerScheduleTimes.removeAt(index);
    }
  }

  void updateScannerScheduleTime(int index, String time) {
    scannerScheduleTimes[index] = time;
  }

  void saveScannedMedicineSchedule() {
    if (selectedScannedMedicine.value != null) {
      final med = selectedScannedMedicine.value!;
      saveMedicine(
        name: med.name,
        dosage: med.dosage,
        frequency: med.frequency,
        times: List.from(scannerScheduleTimes),
        color: Colors.blue,
      );
      Get.snackbar(
        'Schedule Saved',
        'Medicine ${med.name} added to your schedule.',
        snackPosition: SnackPosition.BOTTOM,
      );
      selectedScannedMedicine.value = null;
      scannerScheduleTimes.clear();
      scannedMedicines.removeWhere((element) => element.id == med.id);
    }
  }

  void saveAllScannedMedicines() {
    for (var med in scannedMedicines) {
      saveMedicine(
        name: med.name,
        dosage: med.dosage,
        frequency: med.frequency,
        times: List.from(med.suggestedTimes),
        color: Colors.blue,
      );
    }
    Get.snackbar(
      'All Saved',
      '${scannedMedicines.length} medicines added to your schedule.',
      snackPosition: SnackPosition.BOTTOM,
    );
    selectedScannedMedicine.value = null;
    scannerScheduleTimes.clear();
    scannedMedicines.clear();
  }

  void clearScanResults() {
    scannedMedicines.clear();
    selectedScannedMedicine.value = null;
  }

  // History getters
  List<HistoryEntry> get filteredHistory {
    if (historyFilter.value == 'all') return historyList;
    return historyList.where((h) => h.status == historyFilter.value).toList();
  }

  Map<DateTime, List<HistoryEntry>> get groupedHistory {
    final map = <DateTime, List<HistoryEntry>>{};
    for (var entry in filteredHistory) {
      final dateOnly =
          DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (!map.containsKey(dateOnly)) {
        map[dateOnly] = [];
      }
      map[dateOnly]!.add(entry);
    }
    return map;
  }

  int get adherenceRate {
    if (historyList.isEmpty) return 0;
    final taken = historyList.where((h) => h.status == 'taken').length;
    return ((taken / historyList.length) * 100).round();
  }

  int get takenTodayCount {
    final today = DateTime.now();
    return historyList
        .where((h) =>
            h.status == 'taken' &&
            h.date.year == today.year &&
            h.date.month == today.month &&
            h.date.day == today.day)
        .length;
  }

  int get totalTodayCount {
    final today = DateTime.now();
    return historyList
        .where((h) =>
            h.date.year == today.year &&
            h.date.month == today.month &&
            h.date.day == today.day)
        .length;
  }

  int get currentStreak {
    final takenDates = historyList
        .where((h) => h.status == 'taken')
        .map((h) => DateTime(h.date.year, h.date.month, h.date.day))
        .toSet()
        .toList();
    takenDates.sort((a, b) => b.compareTo(a));

    if (takenDates.isEmpty) return 0;

    int streak = 0;
    final now = DateTime.now();
    DateTime checkDate = DateTime(now.year, now.month, now.day);

    if (!takenDates.contains(checkDate)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
      if (!takenDates.contains(checkDate)) return 0;
    }

    while (takenDates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  void toggleNotifications() async {
    notificationsEnabled.toggle();
    if (notificationsEnabled.value) {
      await NotificationService.instance.syncAllMedicineAlarms(medicines);
    } else {
      for (final m in medicines) {
        await NotificationService.instance.cancelMedicineAlarms(
          medicineId: m.id,
          times: m.times,
        );
      }
    }
  }

  void toggleDarkMode() {
    darkModeEnabled.toggle();
  }

  void changeLanguage(String lang) {
    selectedLanguage.value = lang;
    updateAppTheme(lang);
    if (lang == 'Bangla') {
      Get.updateLocale(const Locale('bn', 'BD'));
    } else {
      Get.updateLocale(const Locale('en', 'US'));
    }
  }

  void copyPatientCode() {
    isCodeCopied.value = true;
    Timer(const Duration(seconds: 2), () {
      isCodeCopied.value = false;
    });
  }

  Future<void> connectCaretaker(String codeOrEmail) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      QuerySnapshot<Map<String, dynamic>> query;
      if (codeOrEmail.contains('@')) {
        query = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: codeOrEmail)
            .get();
      } else {
        query = await FirebaseFirestore.instance
            .collection('users')
            .where('caretakerCode', isEqualTo: codeOrEmail)
            .get();
        if (query.docs.isEmpty) {
          query = await FirebaseFirestore.instance
              .collection('users')
              .where('patientCode', isEqualTo: codeOrEmail)
              .get();
        }
      }

      if (query.docs.isNotEmpty) {
        final caretakerData = query.docs.first.data();
        final caretakerId = query.docs.first.id;

        final newCaretaker = {
          'id': caretakerId,
          'name': caretakerData['name'] ?? 'Caretaker',
          'email': caretakerData['email'] ?? codeOrEmail,
          'photo': caretakerData['photo'] ?? '',
          'phone': caretakerData['phone'] ?? '',
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'caretakers': FieldValue.arrayUnion([newCaretaker])
        });
        Get.snackbar('Success', 'Caretaker connected successfully!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white);
      } else {
        Get.snackbar('Not Found', 'No caretaker found with this ID or Email',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.redAccent,
            colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to connect caretaker',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white);
    }
  }

  Future<void> removeCaretaker(Map<String, dynamic> caretaker) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'caretakers': FieldValue.arrayRemove([caretaker])
      });
      Get.snackbar('Removed', 'Caretaker has been removed.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to remove caretaker',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white);
    }
  }

  void logout() async {
    await AuthController.clearSession();
    Get.offAllNamed('/role-selection');
  }

  Future<void> callPrimaryCaretaker() async {
    if (connectedCaretakers.isEmpty) {
      Get.snackbar('No Caretaker', 'You have not connected any caretaker yet.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    
    final caretaker = connectedCaretakers.first;
    final caretakerId = caretaker['id'];
    
    if (caretakerId == null) return;
    
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(caretakerId).get();
      if (doc.exists) {
        final phone = doc.data()?['phone'] ?? '';
        if (phone.isEmpty) {
          Get.snackbar('No Phone Number', 'The caretaker does not have a phone number.', snackPosition: SnackPosition.BOTTOM);
          return;
        }
        
        final Uri url = Uri.parse('tel:$phone');
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        } else {
          Get.snackbar('Error', 'Could not launch dialer.', snackPosition: SnackPosition.BOTTOM);
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to get caretaker details.', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _listenToPatientSos() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _patientSosSubscription = FirebaseFirestore.instance
        .collection('sos_alerts')
        .where('patientId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        isSosActive.value = true;
        activeSosAlertId.value = snapshot.docs.first.id;
      } else {
        isSosActive.value = false;
        activeSosAlertId.value = '';
      }
    });
  }

  void showSosConfirmationDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFCDD2), width: 2),
                ),
                child: const Icon(
                  Icons.emergency_rounded,
                  color: Color(0xFFD32F2F),
                  size: 52,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Send SOS Alert?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB71C1C),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'This will instantly sound an emergency alarm on your caretaker\'s phone and display your full details for emergency response.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF475569),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        sendSosAlert();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 3,
                      ),
                      child: const Text(
                        'SEND SOS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  Future<void> sendSosAlert() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final caretakerIds = connectedCaretakers
          .map((c) => c['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      final alertDoc = await FirebaseFirestore.instance.collection('sos_alerts').add({
        'patientId': user.uid,
        'patientName': patientName.value.isNotEmpty ? patientName.value : 'Patient',
        'patientPhone': patientPhone.value,
        'patientEmail': patientEmail.value.isNotEmpty ? patientEmail.value : (user.email ?? ''),
        'patientAge': patientAge.value,
        'patientGender': patientGender.value,
        'patientPhoto': patientPhoto.value,
        'patientCode': patientCode.value,
        'caretakerIds': caretakerIds,
        'status': 'active',
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      activeSosAlertId.value = alertDoc.id;
      isSosActive.value = true;

      Get.snackbar(
        '🚨 SOS Alert Sent!',
        'Your caretaker has been notified with your details.',
        backgroundColor: const Color(0xFFD32F2F),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 5),
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
      );
    } catch (e) {
      debugPrint('Error sending SOS alert: $e');
      Get.snackbar(
        'Error',
        'Failed to send SOS alert. Please call your caretaker directly.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> cancelSosAlert() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      if (activeSosAlertId.value.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('sos_alerts')
            .doc(activeSosAlertId.value)
            .update({
          'status': 'resolved',
          'resolvedBy': 'patient',
          'resolvedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final snapshot = await FirebaseFirestore.instance
            .collection('sos_alerts')
            .where('patientId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'active')
            .get();
        for (var doc in snapshot.docs) {
          await doc.reference.update({
            'status': 'resolved',
            'resolvedBy': 'patient',
            'resolvedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      isSosActive.value = false;
      activeSosAlertId.value = '';

      Get.snackbar(
        'SOS Cancelled',
        'Emergency SOS alert has been cancelled.',
        backgroundColor: const Color(0xFF2ECC71),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('Error cancelling SOS alert: $e');
    }
  }
}
