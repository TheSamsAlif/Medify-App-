import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/patient_controller.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final compareDate = DateTime(date.year, date.month, date.day);

    if (compareDate == today) {
      return 'Today';
    } else if (compareDate == yesterday) {
      return 'Yesterday';
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final PatientController controller = Get.find<PatientController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Text(
                'History',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Text(
                'Track your medicine intake history',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),

              // Stats Row
              Obx(() {
                final taken = controller.historyList.where((h) => h.status == 'taken').length;
                final missed = controller.historyList.where((h) => h.status == 'missed').length;
                return GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.2,
                  children: [
                    _buildStatCard(
                      label: 'Adherence',
                      value: '${controller.adherenceRate}%',
                      colors: [const Color(0xFF10B981), const Color(0xFF059669)],
                      icon: Icons.trending_up_rounded,
                    ),
                    _buildStatCard(
                      label: 'Taken',
                      value: '$taken',
                      colors: [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
                      icon: Icons.check_circle_outline_rounded,
                    ),
                    _buildStatCard(
                      label: 'Missed',
                      value: '$missed',
                      colors: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                      icon: Icons.cancel_outlined,
                    ),
                    _buildStatCard(
                      label: 'Streak',
                      value: '${controller.currentStreak} days',
                      colors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                      icon: Icons.local_fire_department_rounded,
                    ),
                  ],
                );
              }),
              const SizedBox(height: 16),

              // Filter Tabs
              Obx(() => Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _buildTabButton(controller, 'all', 'All'),
                        _buildTabButton(controller, 'taken', 'Taken'),
                        _buildTabButton(controller, 'missed', 'Missed'),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),

              // Grouped History List
              Expanded(
                child: Obx(() {
                  final grouped = controller.groupedHistory;
                  if (grouped.isEmpty) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            size: 36,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No history found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          controller.historyFilter.value == 'all'
                              ? 'Start taking your medicines to see log here'
                              : 'No ${controller.historyFilter.value} medicines records found',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    );
                  }

                  final keys = grouped.keys.toList();
                  // Sort dates descending
                  keys.sort((a, b) => b.compareTo(a));

                  return ListView.builder(
                    itemCount: keys.length,
                    itemBuilder: (context, idx) {
                      final date = keys[idx];
                      final entries = grouped[date]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Header
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 14, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 8),
                              Text(
                                _formatDateHeader(date),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Timeline children
                          Padding(
                            padding: const EdgeInsets.only(left: 6.0),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: entries.length,
                              itemBuilder: (context, entryIdx) {
                                final entry = entries[entryIdx];
                                final isTaken = entry.status == 'taken';
                                final isLast = entryIdx == entries.length - 1;

                                return IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Timeline column
                                      Column(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: entry.status == 'taken' 
                                                  ? Colors.green 
                                                  : entry.status == 'upcoming' 
                                                      ? Colors.amber 
                                                      : Colors.red,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 2),
                                            ),
                                          ),
                                          if (!isLast)
                                            Expanded(
                                              child: Container(
                                                width: 2,
                                                color: const Color(0xFFCBD5E1),
                                              ),
                                            )
                                          else
                                            const SizedBox(height: 12),
                                        ],
                                      ),
                                      const SizedBox(width: 16),

                                      // Entry card content
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(bottom: 12.0),
                                          child: Card(
                                            color: Colors.white,
                                            margin: EdgeInsets.zero,
                                            child: Padding(
                                              padding: const EdgeInsets.all(12.0),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 36,
                                                    height: 36,
                                                    decoration: BoxDecoration(
                                                      color: entry.color.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Icon(Icons.medical_services_rounded,
                                                        color: entry.color, size: 20),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          entry.medicineName,
                                                          style: const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.bold,
                                                            color: Color(0xFF1E293B),
                                                          ),
                                                        ),
                                                        Text(
                                                          entry.dosage,
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            color: Color(0xFF64748B),
                                                          ),
                                                        ),
                                                        const SizedBox(height: 6),
                                                        Wrap(
                                                          crossAxisAlignment: WrapCrossAlignment.center,
                                                          spacing: 4,
                                                          runSpacing: 4,
                                                          children: [
                                                            const Icon(Icons.access_time_rounded,
                                                                size: 12, color: Color(0xFF64748B)),
                                                            Text(
                                                              'Scheduled: ${entry.scheduledTime}',
                                                              style: const TextStyle(
                                                                  fontSize: 11,
                                                                  color: Color(0xFF64748B)),
                                                            ),
                                                            if (entry.takenTime != null) ...[
                                                              const SizedBox(width: 4),
                                                              const Icon(
                                                                  Icons.check_circle_outline_rounded,
                                                                  size: 12,
                                                                  color: Colors.green),
                                                              Text(
                                                                'Taken: ${entry.takenTime}',
                                                                style: const TextStyle(
                                                                    fontSize: 11,
                                                                    color: Colors.green,
                                                                    fontWeight: FontWeight.bold),
                                                              ),
                                                            ]
                                                          ],
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: entry.status == 'taken'
                                                          ? Colors.green[50]
                                                          : entry.status == 'upcoming'
                                                              ? Colors.amber[50]
                                                              : Colors.red[50],
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          entry.status == 'taken'
                                                              ? Icons.check_circle
                                                              : entry.status == 'upcoming'
                                                                  ? Icons.schedule_rounded
                                                                  : Icons.cancel,
                                                          color: entry.status == 'taken'
                                                              ? Colors.green
                                                              : entry.status == 'upcoming'
                                                                  ? Colors.amber[700]
                                                                  : Colors.red,
                                                          size: 14,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          entry.status == 'taken' 
                                                              ? 'Taken' 
                                                              : entry.status == 'upcoming' 
                                                                  ? 'Upcoming' 
                                                                  : 'Missed',
                                                          style: TextStyle(
                                                            color: entry.status == 'taken'
                                                                ? Colors.green
                                                                : entry.status == 'upcoming'
                                                                    ? Colors.amber[800]
                                                                    : Colors.red,
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    },
                  );
                }),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required List<Color> colors,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTabButton(PatientController controller, String value, String text) {
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.historyFilter.value = value,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: controller.historyFilter.value == value ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: controller.historyFilter.value == value
                ? const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: controller.historyFilter.value == value
                  ? const Color(0xFF1E293B)
                  : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}
