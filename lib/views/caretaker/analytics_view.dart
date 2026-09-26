import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controllers/caretaker_controller.dart';

class AnalyticsView extends StatelessWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final CaretakerController controller = Get.find<CaretakerController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: SafeArea(
        child: Obx(() {
          if (controller.patients.isEmpty) {
            return const Center(child: Text('No patients available for analytics.'));
          }

          int totalPatients = controller.patients.length;
          int avgAdherence = controller.averageAdherence;
          int totalTodayTaken = controller.patients.fold(0, (sum, p) => sum + p.todayTaken);
          int totalTodayMissed = controller.patients.fold(0, (sum, p) => sum + p.missedToday);
          int totalTodayTotal = controller.patients.fold(0, (sum, p) => sum + p.todayTotal);
          int totalTodayPending = totalTodayTotal - totalTodayTaken - totalTodayMissed;
          if (totalTodayPending < 0) totalTodayPending = 0;

          List<double> avgWeeklyAdherence = List.filled(7, 0.0);
          for (int i = 0; i < 7; i++) {
            double sum = 0;
            for (var p in controller.patients) {
              sum += p.weeklyAdherenceData[i];
            }
            avgWeeklyAdherence[i] = totalPatients > 0 ? sum / totalPatients : 0.0;
          }

          final List<String> insights = [];
          insights.add('Overall adherence is $avgAdherence% across $totalPatients patients');
          final needsAttention = controller.patients.where((p) => p.adherence < 70).toList();
          if (needsAttention.isNotEmpty) {
            insights.add('${needsAttention.first.name} needs attention - adherence is ${needsAttention.first.adherence}%');
          } else {
            insights.add('All patients are maintaining good adherence');
          }
          final perfect = controller.patients.where((p) => p.adherence >= 95).toList();
          if (perfect.isNotEmpty) {
             insights.add('${perfect.first.name} maintains excellent ${perfect.first.adherence}% adherence rate');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Analytics'.tr,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  'Overview of patient adherence trends'.tr,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),

                // Stats Grid
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.8,
                  children: [
                    _buildStatCard(
                      label: 'Total Patients'.tr,
                      value: '$totalPatients',
                      icon: Icons.people_alt_rounded,
                      color: Colors.blue,
                    ),
                    _buildStatCard(
                      label: 'Avg Adherence'.tr,
                      value: '$avgAdherence%',
                      icon: Icons.trending_up_rounded,
                      color: Colors.green,
                    ),
                    _buildStatCard(
                      label: 'Today\'s Taken'.tr,
                      value: '$totalTodayTaken',
                      icon: Icons.check_circle_outline_rounded,
                      color: const Color(0xFF10B981),
                    ),
                    _buildStatCard(
                      label: 'Today\'s Missed'.tr,
                      value: '$totalTodayMissed',
                      icon: Icons.cancel_outlined,
                      color: Colors.red,
                    ),
                  ],
                ),
              const SizedBox(height: 16),

              // Weekly Adherence Trend Graph
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Adherence Trend'.tr,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 180,
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            maxY: 100,
                            lineTouchData: LineTouchData(enabled: true),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: const Color(0xFFF1F5F9),
                                strokeWidth: 1,
                              ),
                            ),
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
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(7, (index) => FlSpot(index.toDouble(), avgWeeklyAdherence[index])),
                                isCurved: true,
                                color: const Color(0xFF2ECC71),
                                barWidth: 3,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: const Color(0xFF2ECC71).withOpacity(0.1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Patient Adherence Comparison Bar Chart
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patient Adherence Comparison'.tr,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 180,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: 100,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: const Color(0xFFF1F5F9),
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    final list = controller.patients.take(6).toList();
                                    if (value >= 0 && value < list.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          list[value.toInt()].name.split(' ').first,
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
                            borderData: FlBorderData(show: false),
                            barGroups: controller.patients.take(6).toList().asMap().entries.map((entry) {
                              return _buildBarGroup(entry.key, entry.value.adherence.toDouble());
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Medicine Status Distribution Pie Chart
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Medicine Status Distribution'.tr,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 140,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 4,
                                  centerSpaceRadius: 36,
                                  sections: [
                                    if (totalTodayTaken > 0)
                                      PieChartSectionData(
                                        color: const Color(0xFF10B981),
                                        value: totalTodayTaken.toDouble(),
                                        title: 'Taken',
                                        radius: 40,
                                        titleStyle: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                      ),
                                    if (totalTodayMissed > 0)
                                      PieChartSectionData(
                                        color: Colors.redAccent,
                                        value: totalTodayMissed.toDouble(),
                                        title: 'Missed',
                                        radius: 40,
                                        titleStyle: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                      ),
                                    if (totalTodayPending > 0 || (totalTodayTaken == 0 && totalTodayMissed == 0))
                                      PieChartSectionData(
                                        color: Colors.amber,
                                        value: (totalTodayPending > 0) ? totalTodayPending.toDouble() : 1, // At least show something if all 0
                                        title: (totalTodayTaken == 0 && totalTodayMissed == 0 && totalTodayPending == 0) ? 'No Meds' : 'Pending',
                                        radius: 40,
                                        titleStyle: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPieLegend(const Color(0xFF10B981), 'Taken'.tr, '$totalTodayTaken ' + 'doses'.tr),
                              const SizedBox(height: 8),
                              _buildPieLegend(Colors.redAccent, 'Missed'.tr, '$totalTodayMissed ' + 'doses'.tr),
                              const SizedBox(height: 8),
                              _buildPieLegend(Colors.amber, 'Pending'.tr, '$totalTodayPending ' + 'doses'.tr),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Key Insights Card
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lightbulb_outline_rounded,
                              color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Key Insights'.tr,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: insights
                            .map((insight) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '• ',
                                        style: TextStyle(
                                            color: Color(0xFF2ECC71),
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Expanded(
                                        child: Text(
                                          insight,
                                          style: const TextStyle(
                                              fontSize: 12, color: Color(0xFF475569)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
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

  Widget _buildPieLegend(Color color, String label, String valueText) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            Text(
              valueText,
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            ),
          ],
        )
      ],
    );
  }
}
