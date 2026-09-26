import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/caretaker_controller.dart';

class CaretakerSettingsView extends StatelessWidget {
  const CaretakerSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final CaretakerController controller = Get.find<CaretakerController>();



    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Settings'.tr,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                'Manage your caretaker account and preferences'.tr,
                style: const TextStyle(
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
                          backgroundColor: const Color(0xFF2ECC71),
                          backgroundImage: controller.caretakerPhoto.value.isNotEmpty 
                              ? NetworkImage(controller.caretakerPhoto.value) 
                              : null,
                          child: controller.isUploadingImage.value 
                              ? const SizedBox(
                                  width: 24, height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : controller.caretakerPhoto.value.isEmpty 
                                  ? Text(
                                      controller.caretakerInitials.value.isNotEmpty ? controller.caretakerInitials.value : 'C',
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
                              controller.caretakerName.value.isNotEmpty ? controller.caretakerName.value : 'Caretaker',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              'Caretaker Account'.tr,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                            if (controller.caretakerEmail.value.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                controller.caretakerEmail.value,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                            if (controller.caretakerPhone.value.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                controller.caretakerPhone.value,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showEditProfileDialog(context, controller),
                        icon: const Icon(Icons.edit_outlined, color: Color(0xFF2ECC71)),
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
                              color: const Color(0xFF2ECC71).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.tune_rounded, color: Color(0xFF2ECC71), size: 18),
                          ),
                          const SizedBox(width: 12),
                           Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'App Preferences'.tr,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                'Customize your app experience'.tr,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 16),



                      // Language Dropdown
                      const SizedBox(height: 8),
                      Text(
                        'Language'.tr,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Obx(() => DropdownButtonFormField<String>(
                            value: controller.selectedLanguage.value,
                            items: [
                              DropdownMenuItem(value: 'English', child: Text('English'.tr)),
                              DropdownMenuItem(value: 'Bangla', child: Text('Bangla'.tr)),
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

              // Caretaker Code Section
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
                            child: const Icon(Icons.key_rounded,
                                color: Color(0xFF4A90E2), size: 18),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Caretaker Code'.tr,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                'Share this code with patients to link them'.tr,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Code sharing box
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC)],
                          ),
                          border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Obx(() => Text(
                              controller.caretakerCode.value,
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
                                        ClipboardData(text: controller.caretakerCode.value));
                                    controller.copyCaretakerCode();
                                    Get.snackbar(
                                      'Copied',
                                      'Caretaker code copied to clipboard',
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                  },
                                  icon: Icon(
                                      controller.isCodeCopied.value
                                          ? Icons.check
                                          : Icons.copy_rounded,
                                      size: 16),
                                  label: Text(
                                      controller.isCodeCopied.value ? 'Copied!'.tr : 'Copy Code'.tr),
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Connected Patients Section
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Connected Patients'.tr,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            onPressed: () => _showConnectPatientDialog(context, controller),
                            icon: const Icon(Icons.person_add_rounded, size: 16),
                            label: Text('Add Patient'.tr, style: const TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF2ECC71),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Patients List inside Settings
                      Obx(() {
                        if (controller.patients.isEmpty) {
                          return const Text('No patients connected yet.', style: TextStyle(color: Color(0xFF64748B)));
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.patients.length,
                          itemBuilder: (context, idx) {
                            final p = controller.patients[idx];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: const Color(0xFF2ECC71).withOpacity(0.1),
                                      backgroundImage: p.avatar.isNotEmpty ? NetworkImage(p.avatar) : null,
                                      child: p.avatar.isEmpty
                                          ? Text(
                                              p.name.isNotEmpty ? p.name.trim().split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join('').toUpperCase() : 'P',
                                              style: const TextStyle(
                                                  color: Color(0xFF2ECC71),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.name,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          Text(
                                            p.condition,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        Get.dialog(
                                          AlertDialog(
                                            title: const Text('Disconnect Patient'),
                                            content: Text('Are you sure you want to disconnect ${p.name}?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Get.back(),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Get.back();
                                                  controller.disconnectPatient(p.id);
                                                },
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                child: const Text('Disconnect'),
                                              )
                                            ],
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.person_remove_rounded,
                                          color: Colors.redAccent, size: 20),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      })
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Security & Privacy Card
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.shield_rounded, color: Colors.blueGrey, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Privacy & Security',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'Manage your account data and privacy options',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Logout Button
              ElevatedButton.icon(
                onPressed: () => _showLogoutConfirmDialog(controller),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout Account'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 24),

              const Center(
                child: Text(
                  'Medify Caretaker v1.0.0',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmDialog(CaretakerController controller) {
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

  void _showEditProfileDialog(BuildContext context, CaretakerController controller) {
    final nameController = TextEditingController(text: controller.caretakerName.value);
    final phoneController = TextEditingController(text: controller.caretakerPhone.value);

    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: controller.pickAndUploadImage,
                    child: Obx(() => Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(0xFF2ECC71),
                          backgroundImage: controller.caretakerPhoto.value.isNotEmpty 
                              ? NetworkImage(controller.caretakerPhoto.value) 
                              : null,
                          child: controller.isUploadingImage.value 
                              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                              : controller.caretakerPhoto.value.isEmpty 
                                  ? Text(
                                      controller.caretakerInitials.value.isNotEmpty ? controller.caretakerInitials.value : 'C',
                                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                                    )
                                  : null,
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A90E2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                        ),
                      ],
                    )),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Name',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your name',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Phone Number',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Enter your phone number',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Email (Cannot be changed here)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: TextEditingController(text: controller.caretakerEmail.value),
                  enabled: false,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                controller.updateProfile(nameController.text.trim(), phoneController.text.trim());
                Get.back();
              } else {
                Get.snackbar('Error', 'Name cannot be empty', snackPosition: SnackPosition.BOTTOM);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ECC71),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showConnectPatientDialog(BuildContext context, CaretakerController controller) {
    final inputController = TextEditingController();
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Connect a Patient', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter patient email or patient code to link them to your dashboard.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: inputController,
              decoration: InputDecoration(
                hintText: 'Patient Code or Email',
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
              if (inputController.text.trim().isNotEmpty) {
                controller.connectPatient(inputController.text.trim());
                Get.back();
              } else {
                Get.snackbar('Error', 'Please enter a valid code or email', snackPosition: SnackPosition.BOTTOM);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ECC71),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Connect'),
          )
        ],
      ),
    );
  }
}
