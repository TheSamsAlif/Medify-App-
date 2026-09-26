import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/patient_controller.dart';
import '../../services/notification_service.dart';
import 'patient_edit_profile_view.dart';

class PatientSettingsView extends StatelessWidget {
  const PatientSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final PatientController controller = Get.find<PatientController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Text(
                'Manage your account and preferences',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),

              // Profile Section
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Obx(() => Row(
                    children: [
                      GestureDetector(
                        onTap: controller.pickAndUploadImage,
                        child: Obx(() => CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFF4A90E2),
                          backgroundImage: controller.patientPhoto.value.isNotEmpty 
                              ? NetworkImage(controller.patientPhoto.value) 
                              : null,
                          child: controller.isUploadingImage.value 
                              ? const SizedBox(
                                  width: 24, height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : controller.patientPhoto.value.isEmpty 
                                  ? Text(
                                      controller.patientInitials.value.isNotEmpty ? controller.patientInitials.value : 'P',
                                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                    )
                                  : null,
                        )),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.patientName.value.isNotEmpty ? controller.patientName.value : 'Patient',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.mail_outline_rounded, size: 14, color: Color(0xFF64748B)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    controller.patientEmail.value.isNotEmpty ? controller.patientEmail.value : 'Not set',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF64748B)),
                                const SizedBox(width: 6),
                                Text(
                                  controller.patientPhone.value.isNotEmpty ? controller.patientPhone.value : 'Not set',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.to(() => const PatientEditProfileView()),
                        icon: const Icon(Icons.edit_outlined, color: Color(0xFF4A90E2)),
                      ),
                    ],
                  )),
                ),
              ),
              const SizedBox(height: 16),

              // App Preferences Section
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A90E2).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.tune_rounded, color: Color(0xFF4A90E2), size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'App Preferences',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                'Customize your app experience',
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 16),



                      // Medicine Reminders & Alarms Toggle
                      Obx(() => SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Medicine Reminders',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            subtitle: const Text(
                              'Exact alarms on time even when app is closed',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                            value: controller.notificationsEnabled.value,
                            activeTrackColor: const Color(0xFF2ECC71),
                            onChanged: (val) => controller.toggleNotifications(),
                          )),
                      const Divider(height: 20, color: Color(0xFFF1F5F9)),

                      // Language Dropdown
                      const Text(
                        'Language',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Obx(() => DropdownButtonFormField<String>(
                            value: controller.selectedLanguage.value,
                            items: const [
                              DropdownMenuItem(value: 'English', child: Text('English')),
                              DropdownMenuItem(value: 'Bangla', child: Text('Bangla')),
                            ],
                            onChanged: (val) {
                              if (val != null) controller.changeLanguage(val);
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding:
                                   const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Background Reminders & Alarms Testing Section
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.alarm_on_rounded,
                                color: Colors.amber, size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Background Reminders',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                'Verify alarms trigger when app is closed',
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: Color(0xFF4A90E2)),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'How to test background alarm:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '1. Tap the button below to schedule a 10s test alarm.\n2. Immediately swipe away / kill the app from recent apps.\n3. Lock your phone and wait 10 seconds. The alarm will ring with music and show action buttons!',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4A90E2),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () async {
                                  await NotificationService.instance.scheduleTestAlarm(secondsFromNow: 10);
                                  Get.snackbar(
                                    'Test Alarm Scheduled!',
                                    'Alarm will ring in 10 seconds. Close/kill the app now to test!',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: const Color(0xFF2ECC71),
                                    colorText: Colors.white,
                                    duration: const Duration(seconds: 4),
                                  );
                                },
                                icon: const Icon(Icons.timer_outlined, color: Colors.white, size: 18),
                                label: const Text(
                                  'Test Alarm in 10 Seconds',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                                ),
                                onPressed: () async {
                                  await NotificationService.instance.requestOverlayPermission();
                                  Get.snackbar(
                                    'Appear On Top Permission',
                                    'Please allow Medify to display over other apps so alarms can auto-open.',
                                    snackPosition: SnackPosition.BOTTOM,
                                    duration: const Duration(seconds: 4),
                                  );
                                },
                                icon: const Icon(Icons.open_in_new_rounded, size: 16, color: Color(0xFF4A90E2)),
                                label: const Text(
                                  'Allow "Display Over Other Apps" (Auto-Open)',
                                  style: TextStyle(color: Color(0xFF4A90E2), fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                                ),
                                onPressed: () async {
                                  await NotificationService.instance.requestPermissions();
                                  Get.snackbar(
                                    'Permissions Checked',
                                    'Exact alarm and notification permissions requested.',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                },
                                icon: const Icon(Icons.security_rounded, size: 16, color: Color(0xFF475569)),
                                label: const Text(
                                  'Check / Grant Alarm Permissions',
                                  style: TextStyle(color: Color(0xFF475569), fontSize: 13),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  side: const BorderSide(color: Color(0xFF2ECC71)),
                                  backgroundColor: const Color(0xFF2ECC71).withValues(alpha: 0.05),
                                ),
                                onPressed: () async {
                                  await NotificationService.instance.requestIgnoreBatteryOptimization();
                                  Get.snackbar(
                                    'Battery Optimization',
                                    'Select "Unrestricted" or "Don\'t optimize" so reminders work reliably when the app is closed.',
                                    snackPosition: SnackPosition.BOTTOM,
                                    duration: const Duration(seconds: 5),
                                  );
                                },
                                icon: const Icon(Icons.battery_charging_full_rounded, size: 16, color: Color(0xFF27AE60)),
                                label: const Text(
                                  'Disable Battery Restrictions (Keep Alarms Alive)',
                                  style: TextStyle(color: Color(0xFF27AE60), fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Caretaker Connection Section
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2ECC71).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.people_alt_rounded,
                                color: Color(0xFF2ECC71), size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Caretaker Connection',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                'Share this code with your caretaker',
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Code sharing card
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF0FDF4), Color(0xFFEFF6FF)],
                          ),
                          border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Your Patient Code',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Obx(() => Text(
                              controller.patientCode.value,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                color: Color(0xFF1E293B),
                              ),
                            )),
                            const SizedBox(height: 12),
                            Obx(() => ElevatedButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(
                                        ClipboardData(text: controller.patientCode.value));
                                    controller.copyPatientCode();
                                    Get.snackbar(
                                      'Copied',
                                      'Patient code copied to clipboard',
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                  },
                                  icon: Icon(
                                      controller.isCodeCopied.value
                                          ? Icons.check
                                          : Icons.copy_rounded,
                                      size: 16),
                                  label: Text(
                                      controller.isCodeCopied.value ? 'Copied!' : 'Copy Code'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF4A90E2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                                    ),
                                    elevation: 0,
                                  ),
                                )),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () => _showConnectCaretakerDialog(context, controller),
                              icon: const Icon(Icons.link_rounded, size: 18),
                              label: const Text('Add Caretaker Manually'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 44),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                side: const BorderSide(color: Color(0xFF4A90E2)),
                                foregroundColor: const Color(0xFF4A90E2),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'Connected Caretakers',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      // Connected Caretakers List
                      Obx(() {
                        if (controller.connectedCaretakers.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('No caretakers connected yet.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                          );
                        }
                        return Column(
                          children: controller.connectedCaretakers.map((ct) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  ct['photo'] != null && ct['photo'].toString().isNotEmpty
                                      ? CircleAvatar(
                                          radius: 20,
                                          backgroundColor: const Color(0xFF2ECC71),
                                          backgroundImage: NetworkImage(ct['photo'].toString()),
                                        )
                                      : Container(
                                          width: 40,
                                          height: 40,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF2ECC71),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              ct['name'] != null && ct['name'].toString().isNotEmpty 
                                                  ? ct['name'].toString().substring(0, 1).toUpperCase() 
                                                  : 'C',
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                          ),
                                        ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ct['name'] ?? 'Caretaker',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                        ),
                                        const Text(
                                          'Primary Caretaker',
                                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                                    child: const Text('Active', style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                    onPressed: () => _showRemoveCaretakerConfirmDialog(controller, ct),
                                  )
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      })
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Account Actions Card
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.account_box_rounded,
                                color: Colors.grey, size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Account Actions',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => _showLogoutConfirmDialog(controller),
                        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                        label: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: const BorderSide(color: Color(0xFFFFCDD2)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Center(
                child: Text(
                  'Medify v1.0.0',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmDialog(PatientController controller) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout? You will need to login again to access your account.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Logout'),
          )
        ],
      ),
    );
  }


  void _showConnectCaretakerDialog(BuildContext context, PatientController controller) {
    final codeController = TextEditingController();
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Connect Caretaker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter Caretaker Email or ID', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            const SizedBox(height: 8),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                hintText: 'e.g. caretaker@email.com',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              if (codeController.text.trim().isNotEmpty) {
                Get.back();
                controller.connectCaretaker(codeController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ECC71),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _showRemoveCaretakerConfirmDialog(PatientController controller, Map<String, dynamic> ct) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Caretaker', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove ${ct['name']} from your caretakers?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.removeCaretaker(ct);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Remove'),
          )
        ],
      ),
    );
  }
}


