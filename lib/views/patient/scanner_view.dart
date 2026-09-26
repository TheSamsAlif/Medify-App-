import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/patient_controller.dart';

class ScannerView extends StatelessWidget {
  const ScannerView({super.key});

  @override
  Widget build(BuildContext context) {
    final PatientController controller = Get.find<PatientController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Obx(() {
            // Determine sub-view based on controller state
            final scanning = controller.isScanning.value;
            final detected = controller.scannedMedicines;
            final selected = controller.selectedScannedMedicine.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header (only show when not in editor mode)
                if (selected == null) ...[
                  const Text(
                    'AI Prescription Scanner',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Upload a prescription to detect medicines',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!scanning && detected.isEmpty && selected == null)
                          _buildUploadSection(controller, context)
                        else if (scanning)
                          _buildScanningSection(controller)
                        else if (detected.isNotEmpty && selected == null)
                          _buildResultsSection(controller, detected)
                        else if (selected != null)
                          _buildScheduleEditor(controller, selected, context)
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildUploadSection(PatientController controller, BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5, style: BorderStyle.solid),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF4A90E2).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Color(0xFF4A90E2),
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Upload Prescription',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Take a photo or upload an image of your prescription',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (BuildContext context) {
                    return SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          ListTile(
                            leading: const Icon(Icons.camera_alt),
                            title: const Text('Take Photo'),
                            onTap: () {
                              Navigator.pop(context);
                              controller.startPrescriptionScan(source: ImageSource.camera);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: const Text('Choose from Gallery'),
                            onTap: () {
                              Navigator.pop(context);
                              controller.startPrescriptionScan(source: ImageSource.gallery);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              icon: const Icon(Icons.upload_rounded),
              label: const Text('Choose File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildScanningSection(PatientController controller) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 360),
              duration: const Duration(seconds: 2),
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: value * 0.0174533, // degrees to radians
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90E2).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Color(0xFF4A90E2),
                      size: 40,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Scanning prescription...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  '${controller.scanProgress.value}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A90E2),
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: controller.scanProgress.value / 100,
              backgroundColor: const Color(0xFFE2E8F0),
              color: const Color(0xFF4A90E2),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 16),
            const Text(
              'Analyzing prescription with AI...',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection(PatientController controller, List<ScannedMedicine> medicines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.green, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detected Medicines',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      '${medicines.length} medicines found',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            OutlinedButton(
              onPressed: () {
                controller.clearScanResults();
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Scan Again', style: TextStyle(fontSize: 12)),
            )
          ],
        ),
        const SizedBox(height: 16),

        // List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: medicines.length,
          itemBuilder: (context, index) {
            final med = medicines[index];
            return Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => controller.selectScannedMedicine(med),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${med.dosage} • ${med.frequency}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              children: med.suggestedTimes
                                  .map((time) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.access_time_rounded,
                                                size: 12, color: Color(0xFF64748B)),
                                            const SizedBox(width: 4),
                                            Text(
                                              time,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF475569),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            )
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => controller.selectScannedMedicine(med),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A90E2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text('Schedule', style: TextStyle(fontSize: 12)),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            controller.saveAllScannedMedicines();
          },
          icon: const Icon(Icons.playlist_add_check_circle_rounded),
          label: const Text('Schedule All at Once'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2ECC71),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleEditor(
      PatientController controller, ScannedMedicine medicine, BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              medicine.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${medicine.dosage} • ${medicine.frequency}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Schedule Times',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),

            // Times edit list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.scannerScheduleTimes.length,
              itemBuilder: (context, idx) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null) {
                              controller.updateScannerScheduleTime(idx, time.format(context));
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  controller.scannerScheduleTimes[idx],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const Icon(Icons.access_time_rounded,
                                    color: Color(0xFF64748B), size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (controller.scannerScheduleTimes.length > 1) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                          onPressed: () => controller.removeScannerScheduleTime(idx),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red[50],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        )
                      ]
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => controller.addScannerScheduleTime(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Time'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      controller.selectedScannedMedicine.value = null;
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      controller.saveScannedMedicineSchedule();
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Save Schedule'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ECC71),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
