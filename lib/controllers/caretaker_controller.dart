import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/notification_service.dart';
import '../../main.dart';
import 'auth_controller.dart';

class PatientItem {
  String id;
  String name;
  String avatar;
  String condition;
  int adherence;
  int todayTaken;
  int todayTotal;
  int missedToday;
  String lastTaken;
  int age;
  String gender;
  String phone;
  String email;
  String emergencyName;
  String emergencyPhone;
  List<Map<String, dynamic>> todayHistory;
  List<double> weeklyAdherenceData;

  PatientItem({
    required this.id,
    required this.name,
    required this.avatar,
    required this.condition,
    required this.adherence,
    required this.todayTaken,
    required this.todayTotal,
    required this.missedToday,
    required this.lastTaken,
    required this.age,
    required this.gender,
    required this.phone,
    required this.email,
    required this.emergencyName,
    required this.emergencyPhone,
    required this.todayHistory,
    required this.weeklyAdherenceData,
  });
}

class AlertItem {
  String id;
  String patientName;
  String patientAvatar;
  String medicine;
  String message;
  String time;
  String priority; // 'high' | 'medium' | 'low'
  bool isRead;
  DateTime date;

  AlertItem({
    required this.id,
    required this.patientName,
    required this.patientAvatar,
    required this.medicine,
    required this.message,
    required this.time,
    required this.priority,
    required this.isRead,
    required this.date,
  });
}

class CaretakerController extends GetxController {
  // Navigation
  var selectedIndex = 0.obs;

  // User Data
  var caretakerName = ''.obs;
  var caretakerInitials = ''.obs;
  var caretakerEmail = ''.obs;
  var caretakerPhone = ''.obs;
  var caretakerPhoto = ''.obs;
  var isUploadingImage = false.obs;

  // Patients
  var patients = <PatientItem>[].obs;
  var patientsSearchQuery = ''.obs;
  var patientTabFilter = 'all'.obs; // 'all' | 'excellent' | 'good' | 'needs'

  // Selected Patient Details
  var selectedPatient = Rxn<PatientItem>();

  // Alerts
  var alerts = <AlertItem>[].obs;

  // Settings
  var notificationsEnabled = true.obs;
  var darkModeEnabled = false.obs;
  var selectedLanguage = 'English'.obs;
  var isCodeCopied = false.obs;
  var caretakerCode = ''.obs;
  var caretakerId = ''.obs;

  // Emergency SOS State
  final AudioPlayer _sosAudioPlayer = AudioPlayer();
  Timer? _sosVibrateTimer;
  StreamSubscription? _sosAlertSubscription;
  var activeSosAlert = Rxn<Map<String, dynamic>>();
  var activeSosDocId = ''.obs;
  var isShowingSosDialog = false.obs;

  final Map<String, StreamSubscription> _patientSubscriptions = {};
  StreamSubscription? _usersSubscription;

  @override
  void onInit() {
    super.onInit();
    try {
      _loadUserData();
    } catch (_) {}
    try {
      _listenToPatients();
    } catch (_) {}
    try {
      _listenToSosAlerts();
    } catch (_) {}
  }

  @override
  void onClose() {
    _usersSubscription?.cancel();
    _sosAlertSubscription?.cancel();
    _stopEmergencyAlarm();
    _sosAudioPlayer.dispose();
    for (var sub in _patientSubscriptions.values) {
      sub.cancel();
    }
    super.onClose();
  }

  void _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().listen((doc) {
        if (doc.exists) {
          final data = doc.data()!;
          final name = data['name'] ?? 'Caretaker';
          caretakerName.value = name;
          caretakerEmail.value = data['email'] ?? user.email ?? '';
          caretakerPhone.value = data['phone'] ?? '';
          caretakerPhoto.value = data['photo'] ?? '';
          caretakerId.value = user.uid;
          
          if (data['caretakerCode'] != null) {
            caretakerCode.value = data['caretakerCode'];
          } else {
            final code = 'CT-${user.uid.substring(0, 4).toUpperCase()}-${DateTime.now().microsecond % 1000}';
            caretakerCode.value = code;
            FirebaseFirestore.instance.collection('users').doc(user.uid).update({
              'caretakerCode': code,
            });
          }
          
          final nameParts = name.trim().split(' ');
          if (nameParts.length > 1 && nameParts[1].isNotEmpty) {
            caretakerInitials.value = '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
          } else if (nameParts.isNotEmpty && nameParts[0].isNotEmpty) {
            caretakerInitials.value = nameParts[0][0].toUpperCase();
          } else {
            caretakerInitials.value = 'C';
          }
        }
      });
    }
  }

  Future<void> updateProfile(String name, String phone) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': name,
        'phone': phone,
      });
      Get.snackbar('Success', 'Profile updated successfully', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);

    if (image != null) {
      isUploadingImage.value = true;
      try {
        final bytes = await image.readAsBytes();
        var request = http.MultipartRequest('POST', Uri.parse('https://api.cloudinary.com/v1_1/cfnsqzjs/image/upload'));
        request.fields['upload_preset'] = 'mediapp';
        request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: image.name));
        
        var response = await request.send();
        if (response.statusCode == 200) {
          final respStr = await response.stream.bytesToString();
          final jsonMap = json.decode(respStr);
          final url = jsonMap['secure_url'];
          
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'photo': url});
            Get.snackbar('Success', 'Profile picture updated', snackPosition: SnackPosition.BOTTOM);
          }
        } else {
          Get.snackbar('Error', 'Failed to upload image', snackPosition: SnackPosition.BOTTOM);
        }
      } catch (e) {
        Get.snackbar('Error', 'An error occurred while uploading', snackPosition: SnackPosition.BOTTOM);
      } finally {
        isUploadingImage.value = false;
      }
    }
  }

  void changeTab(int index) {
    selectedIndex.value = index;
  }

  void _listenToPatients() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _usersSubscription = FirebaseFirestore.instance.collection('users').snapshots().listen((snapshot) {
      final currentPatientIds = <String>{};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('caretakers') && data['caretakers'] is List) {
          final caretakersList = List<dynamic>.from(data['caretakers']);
          final isMyPatient = caretakersList.any((c) => c['id'] == user.uid);
          
          if (isMyPatient) {
            currentPatientIds.add(doc.id);
            if (!_patientSubscriptions.containsKey(doc.id)) {
              _subscribeToPatientDetails(doc.id, data);
            }
          }
        }
      }
      
      // Remove disconnected patients
      final removedIds = _patientSubscriptions.keys.where((id) => !currentPatientIds.contains(id)).toList();
      for (var id in removedIds) {
        _patientSubscriptions[id]?.cancel();
        _patientSubscriptions.remove(id);
        patients.removeWhere((p) => p.id == id);
      }
    });
  }

  void _subscribeToPatientDetails(String patientId, Map<String, dynamic> userData) {
    _patientSubscriptions[patientId] = FirebaseFirestore.instance
        .collection('users')
        .doc(patientId)
        .collection('history')
        .snapshots()
        .listen((historySnapshot) {
      
      int todayTaken = 0;
      int todayTotal = 0;
      int missedToday = 0;
      int takenTotal = 0;
      int validRecordsForAdherence = 0;
      String lastTaken = 'No records';
      
      final today = DateTime.now();
      int currentWeekday = today.weekday;
      DateTime monday = today.subtract(Duration(days: currentWeekday - 1));
      monday = DateTime(monday.year, monday.month, monday.day);
      
      List<int> weeklyTaken = List.filled(7, 0);
      List<int> weeklyTotal = List.filled(7, 0);
      
      // Build alerts for this patient
      final List<AlertItem> patientAlerts = [];
      final List<Map<String, dynamic>> todayHistory = [];

      for (var doc in historySnapshot.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'upcoming';
        final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
        
        // Only count today or past dates for overall adherence to avoid future upcoming diluting it
        final isTodayOrPast = date.isBefore(DateTime(today.year, today.month, today.day + 1));
        if (isTodayOrPast) {
          validRecordsForAdherence++;
          if (status == 'taken') takenTotal++;
        }
        
        // Weekly adherence
        final dateOnly = DateTime(date.year, date.month, date.day);
        if (!dateOnly.isBefore(monday) && dateOnly.isBefore(monday.add(const Duration(days: 7)))) {
          int dayIndex = dateOnly.weekday - 1; // 0 for Mon, 6 for Sun
          weeklyTotal[dayIndex]++;
          if (status == 'taken') {
            weeklyTaken[dayIndex]++;
          }
        }
        
        if (date.year == today.year && date.month == today.month && date.day == today.day) {
          todayHistory.add(data);
          todayTotal++;
          if (status == 'taken') todayTaken++;
          if (status == 'missed') {
            missedToday++;
            // Generate an alert
            final timeStr = data['scheduledTime'] ?? 'Unknown time';
            patientAlerts.add(AlertItem(
              id: doc.id,
              patientName: userData['name'] ?? 'Patient',
              patientAvatar: userData['photo'] ?? '',
              medicine: data['medicineName'] ?? 'Medicine',
              message: 'Missed scheduled dose',
              time: timeStr,
              priority: 'high',
              isRead: false,
              date: date,
            ));
          }
          
          if (status == 'taken' && data['takenTime'] != null) {
            lastTaken = data['takenTime'];
          }
        }
      }
      
      int adherence = validRecordsForAdherence == 0 ? 0 : ((takenTotal / validRecordsForAdherence) * 100).round();
      
      List<double> weeklyAdherenceData = List.generate(7, (index) {
        if (weeklyTotal[index] == 0) return 0.0;
        return (weeklyTaken[index] / weeklyTotal[index]) * 100.0;
      });
      
      // Sort today history by time
      todayHistory.sort((a, b) {
        final timeA = a['scheduledTime'] ?? '';
        final timeB = b['scheduledTime'] ?? '';
        return timeA.compareTo(timeB);
      });
      
      final newPatient = PatientItem(
        id: patientId,
        name: userData['name'] ?? 'Unknown Patient',
        avatar: userData['photo'] ?? '',
        condition: userData['condition'] ?? 'General Care',
        adherence: adherence,
        todayTaken: todayTaken,
        todayTotal: todayTotal,
        missedToday: missedToday,
        lastTaken: lastTaken,
        age: int.tryParse(userData['age']?.toString() ?? '0') ?? 0,
        gender: userData['gender'] ?? 'Not specified',
        phone: userData['phone'] ?? '',
        email: userData['email'] ?? '',
        emergencyName: userData['emergencyName'] ?? '',
        emergencyPhone: userData['emergencyPhone'] ?? '',
        todayHistory: todayHistory,
        weeklyAdherenceData: weeklyAdherenceData,
      );
      
      final index = patients.indexWhere((p) => p.id == patientId);
      if (index != -1) {
        patients[index] = newPatient;
      } else {
        patients.add(newPatient);
      }
      
      // Update alerts
      alerts.removeWhere((a) => a.patientName == (userData['name'] ?? 'Patient'));
      alerts.addAll(patientAlerts);
      alerts.sort((a, b) => b.date.compareTo(a.date));
    });
  }

  // Dashboard calculations
  int get totalPatientsCount => patients.length;
  
  int get averageAdherence {
    if (patients.isEmpty) return 0;
    double sum = patients.map((p) => p.adherence).reduce((a, b) => a + b).toDouble();
    return (sum / patients.length).round();
  }

  int get activeAlertsCount => alerts.where((a) => !a.isRead && a.priority == 'high').length;

  List<PatientItem> get filteredPatients {
    var list = <PatientItem>[];
    if (patientTabFilter.value == 'all') {
      list = patients;
    } else if (patientTabFilter.value == 'excellent') {
      list = patients.where((p) => p.adherence > 90).toList();
    } else if (patientTabFilter.value == 'good') {
      list = patients.where((p) => p.adherence >= 70 && p.adherence <= 90).toList();
    } else if (patientTabFilter.value == 'needs') {
      list = patients.where((p) => p.adherence < 70).toList();
    }

    if (patientsSearchQuery.isEmpty) return list;
    return list
        .where((p) =>
            p.name.toLowerCase().contains(patientsSearchQuery.value.toLowerCase()) ||
            p.condition.toLowerCase().contains(patientsSearchQuery.value.toLowerCase()))
        .toList();
  }

  void selectPatient(PatientItem patient) {
    selectedPatient.value = patient;
    Get.toNamed('/caretaker/patient-details');
  }

  void markAlertAsRead(String alertId) {
    final index = alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      alerts[index].isRead = true;
      alerts.refresh();
    }
  }

  Future<void> disconnectPatient(String patientId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final patientDoc = await FirebaseFirestore.instance.collection('users').doc(patientId).get();
      if (patientDoc.exists) {
        final data = patientDoc.data()!;
        if (data.containsKey('caretakers') && data['caretakers'] is List) {
          final caretakersList = List<dynamic>.from(data['caretakers']);
          caretakersList.removeWhere((c) => c['id'] == user.uid);
          await FirebaseFirestore.instance.collection('users').doc(patientId).update({
            'caretakers': caretakersList
          });
          
          Get.snackbar(
            'Patient Removed',
            'Patient disconnected successfully.',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to disconnect patient', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Future<void> connectPatient(String codeOrEmail) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      QuerySnapshot<Map<String, dynamic>> query;
      if (codeOrEmail.contains('@')) {
        query = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: codeOrEmail).where('role', isEqualTo: 'patient').get();
      } else {
        query = await FirebaseFirestore.instance.collection('users').where('patientCode', isEqualTo: codeOrEmail).where('role', isEqualTo: 'patient').get();
      }

      if (query.docs.isNotEmpty) {
        final patientId = query.docs.first.id;
        final patientDoc = query.docs.first.data();
        
        final newCaretaker = {
          'id': user.uid,
          'name': caretakerName.value.isNotEmpty ? caretakerName.value : 'Caretaker',
          'email': caretakerEmail.value,
          'photo': caretakerPhoto.value,
        };

        await FirebaseFirestore.instance.collection('users').doc(patientId).update({
          'caretakers': FieldValue.arrayUnion([newCaretaker])
        });
        
        Get.snackbar('Success', 'Patient connected successfully!', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar(
          'Not Found', 
          'No patient found with this ID or Email', 
          snackPosition: SnackPosition.BOTTOM, 
          backgroundColor: Colors.redAccent, 
          colorText: Colors.white
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to connect patient', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  void copyCaretakerCode() {
    isCodeCopied.value = true;
    Timer(const Duration(seconds: 2), () {
      isCodeCopied.value = false;
    });
  }

  void toggleNotifications() {
    notificationsEnabled.toggle();
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

  void logout() async {
    await AuthController.clearSession();
    Get.offAllNamed('/role-selection');
  }

  // SOS Emergency Alert Handling
  void _listenToSosAlerts() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _sosAlertSubscription = FirebaseFirestore.instance
        .collection('sos_alerts')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isEmpty) {
        if (isShowingSosDialog.value) {
          _stopEmergencyAlarm();
          if (Get.isDialogOpen == true) {
            Get.back();
          }
          isShowingSosDialog.value = false;
          activeSosAlert.value = null;
          activeSosDocId.value = '';
        }
        return;
      }

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final patientId = data['patientId'] as String? ?? '';
        final List caretakerIds = (data['caretakerIds'] as List?) ?? [];

        final isMyPatient = caretakerIds.contains(user.uid) ||
            patients.any((p) => p.id == patientId);

        if (isMyPatient) {
          activeSosAlert.value = data;
          activeSosDocId.value = doc.id;

          if (!isShowingSosDialog.value) {
            _showRedSosEmergencyDialog(doc.id, data);
          }
          return;
        }
      }

      if (isShowingSosDialog.value) {
        _stopEmergencyAlarm();
        if (Get.isDialogOpen == true) {
          Get.back();
        }
        isShowingSosDialog.value = false;
        activeSosAlert.value = null;
        activeSosDocId.value = '';
      }
    });
  }

  void _startEmergencyAlarm() {
    try {
      _sosAudioPlayer.setReleaseMode(ReleaseMode.loop);
      _sosAudioPlayer.audioCache = AudioCache(prefix: 'Assets/');
      _sosAudioPlayer.play(AssetSource('music.mp3'));
    } catch (e) {
      debugPrint('SOS audio error: $e');
    }

    _sosVibrateTimer?.cancel();
    _sosVibrateTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      HapticFeedback.heavyImpact();
    });
  }

  void _stopEmergencyAlarm() {
    try {
      _sosAudioPlayer.stop();
    } catch (_) {}
    _sosVibrateTimer?.cancel();
    _sosVibrateTimer = null;
  }

  Future<void> resolveSosAlert(String alertId) async {
    _stopEmergencyAlarm();
    isShowingSosDialog.value = false;
    if (Get.isDialogOpen == true) {
      Get.back();
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('sos_alerts').doc(alertId).update({
        'status': 'resolved',
        'resolvedBy': user?.uid ?? 'caretaker',
        'resolvedAt': FieldValue.serverTimestamp(),
      });
      activeSosAlert.value = null;
      activeSosDocId.value = '';

      Get.snackbar(
        'SOS Acknowledged',
        'Emergency alert marked as resolved.',
        backgroundColor: const Color(0xFF2ECC71),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('Error resolving SOS: $e');
    }
  }

  void showActiveSosDialog() {
    if (activeSosDocId.value.isNotEmpty && activeSosAlert.value != null) {
      _showRedSosEmergencyDialog(activeSosDocId.value, activeSosAlert.value!);
    }
  }

  void _showRedSosEmergencyDialog(String docId, Map<String, dynamic> data) {
    if (isShowingSosDialog.value) return;
    isShowingSosDialog.value = true;
    activeSosDocId.value = docId;
    activeSosAlert.value = data;

    _startEmergencyAlarm();

    // Trigger local high priority notification
    final patientName = data['patientName'] ?? 'Patient';
    NotificationService.instance.showEmergencyNotification(
      title: '🚨 EMERGENCY SOS ALERT!',
      body: '$patientName pressed the emergency SOS button and needs immediate attention!',
    );

    Get.dialog(
      WillPopScope(
        onWillPop: () async => false, // Prevent dismissing by hardware back button
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: const Color(0xFFB71C1C), // Rich Deep Emergency Red
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFFB71C1C),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated / Glowing Warning Icon
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFB71C1C),
                        size: 48,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header Title
                  const Text(
                    'EMERGENCY SOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Immediate attention requested by patient!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // White Details Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Patient Avatar and Name
                        Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFB71C1C), width: 2),
                                image: (data['patientPhoto'] != null && data['patientPhoto'].toString().isNotEmpty)
                                    ? DecorationImage(
                                        image: NetworkImage(data['patientPhoto']),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                color: const Color(0xFFFFEBEE),
                              ),
                              child: (data['patientPhoto'] == null || data['patientPhoto'].toString().isEmpty)
                                  ? const Center(
                                      child: Icon(Icons.person, color: Color(0xFFB71C1C), size: 32),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['patientName'] ?? 'Unknown Patient',
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Code: ${data['patientCode'] ?? 'N/A'}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                        ),

                        // Patient Details Rows
                        _buildPatientDetailRow(
                          icon: Icons.phone_rounded,
                          label: 'Phone Number',
                          value: data['patientPhone'] != null && data['patientPhone'].toString().isNotEmpty
                              ? data['patientPhone'].toString()
                              : 'Not provided',
                          isHighlight: true,
                        ),
                        const SizedBox(height: 10),
                        _buildPatientDetailRow(
                          icon: Icons.email_outlined,
                          label: 'Email Address',
                          value: data['patientEmail'] != null && data['patientEmail'].toString().isNotEmpty
                              ? data['patientEmail'].toString()
                              : 'Not provided',
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPatientDetailRow(
                                icon: Icons.cake_outlined,
                                label: 'Age',
                                value: data['patientAge'] != null && data['patientAge'].toString().isNotEmpty
                                    ? '${data['patientAge']} yrs'
                                    : 'N/A',
                              ),
                            ),
                            Expanded(
                              child: _buildPatientDetailRow(
                                icon: Icons.person_outline_rounded,
                                label: 'Gender',
                                value: data['patientGender'] != null && data['patientGender'].toString().isNotEmpty
                                    ? data['patientGender'].toString()
                                    : 'N/A',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Call Patient Button (Green)
                  ElevatedButton(
                    onPressed: () async {
                      final phone = data['patientPhone']?.toString() ?? '';
                      if (phone.isNotEmpty) {
                        final uri = Uri.parse('tel:$phone');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        } else {
                          Get.snackbar('Error', 'Could not open phone dialer.');
                        }
                      } else {
                        Get.snackbar('No Phone', 'This patient has no registered phone number.');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ECC71),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone_in_talk_rounded, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'CALL PATIENT NOW',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Acknowledge & Dismiss Button (White outlined)
                  OutlinedButton(
                    onPressed: () => resolveSosAlert(docId),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white, width: 2),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'ACKNOWLEDGE & DISMISS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildPatientDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: isHighlight ? const Color(0xFFB71C1C) : const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: isHighlight ? const Color(0xFFB71C1C) : const Color(0xFF1E293B),
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
