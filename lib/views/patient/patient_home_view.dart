import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/patient_controller.dart';

class PatientHomeView extends StatelessWidget {
  const PatientHomeView({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 18) return 'Good Afternoon';
    return 'Good Evening';
  }

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Obx(() {
                        if (controller.patientPhoto.value.isNotEmpty) {
                          return Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: NetworkImage(controller.patientPhoto.value),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        } else {
                          return Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF4A90E2), Color(0xFF2ECC71)],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                controller.patientInitials.value.isEmpty ? '?' : controller.patientInitials.value,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        }
                      }),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Obx(() => Text(
                            controller.patientName.value.isEmpty ? 'Loading...' : controller.patientName.value,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          )),
                        ],
                      ),
                    ],
                  ),
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          Get.snackbar(
                            'Notifications',
                            'You are all caught up!',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                        icon: const Icon(Icons.notifications_outlined, color: Color(0xFF475569)),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.all(10),
                          elevation: 1,
                        ),
                      ),
                      Positioned(
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
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Health Status Card
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A90E2), Color(0xFF2ECC71)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Health Status',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Good',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Obx(() => Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Adherence Rate',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${controller.adherenceRate}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 48),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Medicines Today',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${controller.takenTodayCount}/${controller.totalTodayCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Scan Prescription Card
              GestureDetector(
                onTap: () {
                  controller.changeTab(2); // Go to Scanner view
                },
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF4A90E2),
                      style: BorderStyle.solid,
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A90E2).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Color(0xFF4A90E2),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Scan Prescription',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              'AI-powered scanner',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
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

              // Active SOS Banner (if triggered)
              Obx(() {
                if (!controller.isSosActive.value) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB71C1C),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🚨 SOS Alert Active!',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              'Caretaker has been alerted.',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => controller.cancelSosAlert(),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFB71C1C),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('Cancel SOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                );
              }),

              // Red SOS Emergency Button
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE53935), Color(0xFFC62828)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE53935).withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => controller.showSosConfirmationDialog(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.emergency_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SOS Emergency',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Instant alert to caretaker',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'SOS',
                              style: TextStyle(
                                color: Color(0xFFD32F2F),
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Grid Actions
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.4,
                children: [
                  _buildGridCard(
                    title: 'Add Medicine',
                    icon: Icons.add_rounded,
                    iconColor: const Color(0xFF2ECC71),
                    bgColor: const Color(0xFF2ECC71).withOpacity(0.1),
                    onTap: () {
                      controller.changeTab(1); // Go to medicines view
                    },
                  ),
                  _buildGridCard(
                    title: "Today's Schedule",
                    icon: Icons.calendar_today_rounded,
                    iconColor: const Color(0xFF4A90E2),
                    bgColor: const Color(0xFF4A90E2).withOpacity(0.1),
                    onTap: () {
                      _showUpcomingSchedule(context, controller);
                    },
                  ),
                  _buildGridCard(
                    title: 'SOS Alert',
                    icon: Icons.emergency_rounded,
                    iconColor: const Color(0xFFE53935),
                    bgColor: const Color(0xFFE53935).withOpacity(0.1),
                    onTap: () => controller.showSosConfirmationDialog(context),
                  ),
                  _buildGridCard(
                    title: 'History',
                    icon: Icons.hourglass_empty_rounded,
                    iconColor: Colors.purple,
                    bgColor: Colors.purple.withOpacity(0.1),
                    onTap: () {
                      controller.changeTab(3); // Go to history view
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Today's Medicines Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Today's Medicines",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${DateTime.now().day} ${_getMonthName(DateTime.now().month)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // List of medicines
              Obx(() {
                if (controller.medicines.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          'No medicines scheduled for today.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.medicines.length,
                  itemBuilder: (context, index) {
                    final medicine = controller.medicines[index];
                    // Map status based on dynamic history data
                    String status = controller.getTodayStatusForMedicine(medicine.name);

                    Color statusColor = Colors.orange;
                    Color borderLColor = Colors.orange;
                    Color itemBgColor = Colors.white;

                    if (status == 'taken') {
                      statusColor = Colors.green;
                      borderLColor = Colors.green;
                      itemBgColor = const Color(0xFFE8F5E9).withOpacity(0.4);
                    } else if (status == 'missed') {
                      statusColor = Colors.red;
                      borderLColor = Colors.red;
                      itemBgColor = const Color(0xFFFFEBEE).withOpacity(0.4);
                    }

                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: itemBgColor,
                          border: Border(
                            left: BorderSide(color: borderLColor, width: 4),
                          ),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: medicine.color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  '💊',
                                  style: TextStyle(fontSize: 20, color: medicine.color),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        medicine.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      if (status == 'taken') ...[
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 16,
                                        ),
                                      ]
                                    ],
                                  ),
                                  Text(
                                    '${medicine.dosage} • ${medicine.frequency}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  medicine.times.isNotEmpty ? medicine.times.first : '--:--',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: statusColor, width: 1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            )
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  void _showUpcomingSchedule(BuildContext context, PatientController controller) {
    final upcomingMeds = controller.medicines.where((m) => controller.getTodayStatusForMedicine(m.name) == 'upcoming').toList();
    
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upcoming Medicines', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 16),
            if (upcomingMeds.isEmpty)
              const Text('No upcoming medicines for today.', style: TextStyle(color: Color(0xFF64748B)))
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: upcomingMeds.length,
                  itemBuilder: (context, index) {
                    final med = upcomingMeds[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFF4A90E2).withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.medication_rounded, color: Color(0xFF4A90E2), size: 24),
                      ),
                      title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${med.dosage} • ${med.frequency}'),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
