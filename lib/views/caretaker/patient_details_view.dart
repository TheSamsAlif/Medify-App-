import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controllers/caretaker_controller.dart';

class PatientDetailsView extends StatelessWidget {
  const PatientDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final CaretakerController controller = Get.find<CaretakerController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2ECC71),
        foregroundColor: Colors.white,
        title: const Text('Patient Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
      ),
      body: Obx(() {
        final patient = controller.selectedPatient.value;
        if (patient == null) {
          return const Center(child: Text('No patient selected'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Card
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(0xFF2ECC71).withOpacity(0.1),
                            backgroundImage: patient.avatar.isNotEmpty ? NetworkImage(patient.avatar) : null,
                            child: patient.avatar.isEmpty
                                ? Text(
                                    patient.name.isNotEmpty ? patient.name.trim().split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join('').toUpperCase() : 'P',
                                    style: const TextStyle(
                                        color: Color(0xFF2ECC71),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patient.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  patient.condition,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${patient.adherence}% Adherence',
                                    style: const TextStyle(
                                      color: Color(0xFF2ECC71),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Divider(color: Color(0xFFF1F5F9)),
                      ),
                      _buildContactRow(Icons.phone_outlined, patient.phone),
                      const SizedBox(height: 8),
                      _buildContactRow(Icons.mail_outline_rounded, patient.email),
                      const SizedBox(height: 8),
                      _buildContactRow(
                          Icons.person_outline_rounded, 'Age: ${patient.age} | ${patient.gender}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildMiniStatCard(
                      label: 'Weekly Adherence',
                      value: '${patient.adherence}%',
                      valueColor: const Color(0xFF2ECC71),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMiniStatCard(
                      label: 'Doses Taken',
                      value: '${patient.todayTaken}',
                      valueColor: const Color(0xFF4A90E2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMiniStatCard(
                      label: 'Doses Missed',
                      value: '${patient.missedToday}',
                      valueColor: Colors.redAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Weekly Adherence Trend Graph Card
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weekly Adherence Trend',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 180,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: 100,
                            barTouchData: BarTouchData(enabled: true),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                    if (value >= 0 && value < days.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          days[value.toInt()],
                                          style: const TextStyle(
                                              color: Color(0xFF64748B), fontSize: 10),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 28,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    if (value % 20 == 0) {
                                      return Text(
                                        '${value.toInt()}%',
                                        style: const TextStyle(
                                            color: Color(0xFF94A3B8), fontSize: 8),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: const Color(0xFFF1F5F9),
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: [
                              _buildBarGroup(0, patient.weeklyAdherenceData[0]),
                              _buildBarGroup(1, patient.weeklyAdherenceData[1]),
                              _buildBarGroup(2, patient.weeklyAdherenceData[2]),
                              _buildBarGroup(3, patient.weeklyAdherenceData[3]),
                              _buildBarGroup(4, patient.weeklyAdherenceData[4]),
                              _buildBarGroup(5, patient.weeklyAdherenceData[5]),
                              _buildBarGroup(6, patient.weeklyAdherenceData[6]),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Today's Progress timeline details
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Progress",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // List of today medicines
                      if (patient.todayHistory.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            'No medicines scheduled for today.',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          ),
                        )
                      else
                        ...patient.todayHistory.map((historyItem) {
                          final status = historyItem['status'] ?? 'upcoming';
                          String detail = 'Pending scheduled dose';
                          if (status == 'taken') {
                            detail = 'Taken at ${historyItem['takenTime'] ?? 'Unknown'}';
                          } else if (status == 'missed') {
                            detail = 'Missed scheduled dose';
                          }
                          
                          return _buildTimelineItem(
                            name: historyItem['medicineName'] ?? 'Medicine',
                            time: historyItem['scheduledTime'] ?? 'Unknown time',
                            status: status,
                            detailText: detail,
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Emergency Contact Card
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contact Information',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        patient.emergencyName.isNotEmpty ? patient.emergencyName : patient.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      _buildContactRow(
                        Icons.phone_outlined, 
                        patient.emergencyPhone.isNotEmpty 
                            ? patient.emergencyPhone 
                            : (patient.phone.isNotEmpty ? patient.phone : 'No phone number added'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
        ),
      ],
    );
  }

  Widget _buildMiniStatCard({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: valueColor),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: const Color(0xFF2ECC71),
          width: 14,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        )
      ],
    );
  }

  Widget _buildTimelineItem({
    required String name,
    required String time,
    required String status,
    required String detailText,
  }) {
    IconData icon;
    Color color;
    Color bg;

    if (status == 'taken') {
      icon = Icons.check_circle_rounded;
      color = const Color(0xFF2ECC71);
      bg = const Color(0xFFE8F5E9);
    } else if (status == 'missed') {
      icon = Icons.cancel_rounded;
      color = Colors.redAccent;
      bg = const Color(0xFFFFEBEE);
    } else {
      icon = Icons.access_time_filled_rounded;
      color = const Color(0xFF94A3B8);
      bg = const Color(0xFFF1F5F9);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Scheduled: $time',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 2),
                Text(
                  detailText,
                  style: TextStyle(
                      fontSize: 11,
                      color: status == 'taken'
                          ? const Color(0xFF2ECC71)
                          : (status == 'missed' ? Colors.red : const Color(0xFF64748B)),
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
