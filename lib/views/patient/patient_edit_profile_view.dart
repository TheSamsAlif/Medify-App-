import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/patient_controller.dart';

class PatientEditProfileView extends StatefulWidget {
  const PatientEditProfileView({super.key});

  @override
  State<PatientEditProfileView> createState() => _PatientEditProfileViewState();
}

class _PatientEditProfileViewState extends State<PatientEditProfileView> {
  final PatientController controller = Get.find<PatientController>();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController phoneController;
  
  String? selectedAge;
  String? selectedGender;

  final List<String> ageOptions = List.generate(120, (index) => (index + 1).toString());
  final List<String> genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: controller.patientName.value);
    phoneController = TextEditingController(text: controller.patientPhone.value);
    
    // Set initial values if they exist in the options, otherwise null
    selectedAge = controller.patientAge.value.isNotEmpty && ageOptions.contains(controller.patientAge.value) 
        ? controller.patientAge.value 
        : null;
        
    selectedGender = controller.patientGender.value.isNotEmpty && genderOptions.contains(controller.patientGender.value) 
        ? controller.patientGender.value 
        : null;
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      controller.updateProfile(
        nameController.text.trim(),
        phoneController.text.trim(),
        age: selectedAge ?? '',
        gender: selectedGender ?? '',
      );
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: controller.pickAndUploadImage,
                    child: Obx(() => Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: const Color(0xFF4A90E2),
                              backgroundImage: controller.patientPhoto.value.isNotEmpty
                                  ? NetworkImage(controller.patientPhoto.value)
                                  : null,
                              child: controller.isUploadingImage.value
                                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                  : controller.patientPhoto.value.isEmpty
                                      ? Text(
                                          controller.patientInitials.value.isNotEmpty ? controller.patientInitials.value : 'P',
                                          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                                        )
                                      : null,
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2ECC71),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                            ),
                          ],
                        )),
                  ),
                ),
                const SizedBox(height: 30),
                
                // Name Field
                const Text('Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: nameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name cannot be empty';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter your name',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Phone Field
                const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return null; // Phone is optional
                    }
                    final regex = RegExp(r'^01[0-9]{9}$');
                    if (!regex.hasMatch(value.trim())) {
                      return 'Enter a valid 11-digit Bangladeshi number (e.g. 0171...)';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter phone number (optional)',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Age and Gender Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Age', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: selectedAge,
                            hint: const Text('Select Age'),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                            items: ageOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                selectedAge = newValue;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Gender', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: selectedGender,
                            hint: const Text('Select Gender'),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                            items: genderOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                selectedGender = newValue;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Email Field (Read Only)
                const Text('Email (Cannot be changed)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: TextEditingController(text: controller.patientEmail.value),
                  enabled: false,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFE2E8F0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 40),
                
                ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF4A90E2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
