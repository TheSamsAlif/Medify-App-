import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/caretaker_controller.dart';

class CaretakerDashboardView extends StatelessWidget {
  const CaretakerDashboardView({super.key});

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Obx(() => Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: controller.caretakerPhoto.value.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(controller.caretakerPhoto.value),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          gradient: controller.caretakerPhoto.value.isEmpty
                              ? const LinearGradient(
                                  colors: [Color(0xFF4A90E2), Color(0xFF2ECC71)],
                                )
                              : null,
                        ),
                        child: controller.caretakerPhoto.value.isEmpty
                            ? Center(
                                child: Text(
                                  controller.caretakerInitials.value,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                            : null,
                      )),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Obx(() => Text(
                            controller.caretakerName.value,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          )),
                          Text(
                            'Dashboard'.tr,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          controller.changeTab(2); // Go to Alerts view
                        },
                        icon: const Icon(Icons.notifications_outlined, color: Color(0xFF475569)),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.all(10),
                          elevation: 1,
                        ),
                      ),
                      Obx(() => controller.activeAlertsCount > 0
                          ? Positioned(
                              right: 12,
                              top: 12,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : const SizedBox.shrink())
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Active SOS Emergency Alert Banner
              Obx(() {
                if (controller.activeSosDocId.value.isEmpty || controller.activeSosAlert.value == null) {
                  return const SizedBox.shrink();
                }
                final alert = controller.activeSosAlert.value!;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => controller.showActiveSosDialog(),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFB71C1C),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '🚨 EMERGENCY SOS ACTIVE!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '${alert['patientName'] ?? 'Patient'} needs immediate help',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => controller.showActiveSosDialog(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFFB71C1C),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: const Text('VIEW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),

              // Stats Row
              Obx(() => Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          label: 'Total Patients'.tr,
                          value: '${controller.totalPatientsCount}',
                          icon: Icons.people_alt_rounded,
                          iconColor: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryCard(
                          label: 'Avg Adherence'.tr,
                          value: '${controller.averageAdherence}%',
                          icon: Icons.trending_up_rounded,
                          iconColor: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryCard(
                          label: 'Active Alerts'.tr,
                          value: '${controller.activeAlertsCount}',
                          icon: Icons.warning_amber_rounded,
                          iconColor: Colors.orange,
                        ),
                      ),
                    ],
                  )),
              const SizedBox(height: 24),

              // Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Patient Monitoring'.tr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  TextButton(
                    onPressed: () => controller.changeTab(1), // Go to Patients Tab
                    child: Text(
                      'See All'.tr,
                      style: const TextStyle(color: Color(0xFF2ECC71), fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 8),

              // Patients List
              Obx(() {
                if (controller.patients.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          'No patients connected. Share your Caretaker Code to add patients.'.tr,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  );
                }

                // Show all patients on Dashboard
                final list = controller.patients.toList();
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final patient = list[index];

                    Color adColor = Colors.green;
                    if (patient.adherence < 70) {
                      adColor = Colors.red;
                    } else if (patient.adherence < 90) {
                      adColor = Colors.orange;
                    }

                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => controller.selectPatient(patient),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  // Avatar
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: adColor.withOpacity(0.1),
                                    backgroundImage: patient.avatar.isNotEmpty ? NetworkImage(patient.avatar) : null,
                                    child: patient.avatar.isEmpty
                                        ? Text(
                                            patient.name.isNotEmpty ? patient.name.trim().split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join('').toUpperCase() : 'P',
                                            style: TextStyle(
                                              color: adColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),

                                  // Patient Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          patient.name,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                        Text(
                                          patient.condition,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Circular Progress for Adherence
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 36,
                                        height: 36,
                                        child: CircularProgressIndicator(
                                          value: patient.adherence / 100,
                                          backgroundColor: const Color(0xFFF1F5F9),
                                          color: adColor,
                                          strokeWidth: 3.5,
                                        ),
                                      ),
                                      Text(
                                        '${patient.adherence}%',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: adColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Progress bar
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              "Today's Progress",
                                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                            ),
                                            Text(
                                              "${patient.todayTaken}/${patient.todayTotal} taken",
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF475569),
                                              ),
                                            )
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        LinearProgressIndicator(
                                          value: patient.todayTotal > 0
                                              ? patient.todayTaken / patient.todayTotal
                                              : 0,
                                          backgroundColor: const Color(0xFFF1F5F9),
                                          color: adColor,
                                          minHeight: 6,
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  IconButton(
                                    onPressed: () => controller.selectPatient(patient),
                                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                                    style: IconButton.styleFrom(
                                      backgroundColor: const Color(0xFFF8FAFC),
                                      foregroundColor: const Color(0xFF475569),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
