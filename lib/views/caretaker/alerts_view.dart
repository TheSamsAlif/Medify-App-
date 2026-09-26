import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/caretaker_controller.dart';

class AlertsView extends StatefulWidget {
  const AlertsView({super.key});

  @override
  State<AlertsView> createState() => _AlertsViewState();
}

class _AlertsViewState extends State<AlertsView> {
  final CaretakerController _controller = Get.find<CaretakerController>();
  final varAlertTabFilter = 'all'.obs; // 'all' | 'unread' | 'high' | 'read'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Alerts'.tr,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                'Actionable alerts for patient adherence issues'.tr,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),

              // Alert Count Badges Grid
              Row(
                children: [
                  Expanded(
                    child: _buildCountBadge(
                      count: '3',
                      label: 'High Priority'.tr,
                      color: const Color(0xFFFFEBEE),
                      textColor: const Color(0xFFC62828),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCountBadge(
                      count: '5',
                      label: 'Missed Doses'.tr,
                      color: const Color(0xFFFFF3E0),
                      textColor: const Color(0xFFEF6C00),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCountBadge(
                      count: '2',
                      label: 'Late Doses'.tr,
                      color: const Color(0xFFFFFDE7),
                      textColor: const Color(0xFFF57F17),
                    ),
                  ),
                ],
              ),
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
                        _buildTabButton('all', 'All'.tr),
                        _buildTabButton('unread', 'Unread'.tr),
                        _buildTabButton('high', 'High'.tr),
                        _buildTabButton('read', 'Read'.tr),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),

              // List of Alerts
              Expanded(
                child: Obx(() {
                  final rawAlerts = _controller.alerts;
                  var filtered = <AlertItem>[];

                  if (varAlertTabFilter.value == 'all') {
                    filtered = rawAlerts;
                  } else if (varAlertTabFilter.value == 'unread') {
                    filtered = rawAlerts.where((a) => !a.isRead).toList();
                  } else if (varAlertTabFilter.value == 'high') {
                    filtered = rawAlerts.where((a) => a.priority == 'high').toList();
                  } else if (varAlertTabFilter.value == 'read') {
                    filtered = rawAlerts.where((a) => a.isRead).toList();
                  }

                  if (filtered.isEmpty) {
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
                            Icons.check_circle_outline_rounded,
                            size: 40,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No alerts found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You are all caught up!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final alert = filtered[index];

                      Color borderLeftColor = Colors.grey;
                      if (alert.priority == 'high') {
                        borderLeftColor = Colors.red;
                      } else if (alert.priority == 'medium') {
                        borderLeftColor = Colors.orange;
                      } else if (alert.priority == 'low') {
                        borderLeftColor = Colors.blue;
                      }

                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: !alert.isRead ? const Color(0xFFEFF6FF) : Colors.white,
                            border: Border(
                              left: BorderSide(color: borderLeftColor, width: 4),
                            ),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar representation
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(0xFFF1F5F9),
                                backgroundImage: alert.patientAvatar.isNotEmpty ? NetworkImage(alert.patientAvatar) : null,
                                child: alert.patientAvatar.isEmpty
                                    ? Text(
                                        alert.patientName.isNotEmpty ? alert.patientName.trim().split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join('').toUpperCase() : 'P',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF475569),
                                            fontSize: 13),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),

                              // Alert Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          alert.patientName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                        _buildPriorityBadge(alert.priority),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      alert.medicine,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      alert.message,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.access_time_rounded,
                                                size: 13, color: Color(0xFF94A3B8)),
                                            const SizedBox(width: 4),
                                            Text(
                                              alert.time,
                                              style: const TextStyle(
                                                  fontSize: 11, color: Color(0xFF64748B)),
                                            ),
                                          ],
                                        ),
                                        if (!alert.isRead)
                                          TextButton.icon(
                                            onPressed: () {
                                              _controller.markAlertAsRead(alert.id);
                                              Get.snackbar(
                                                'Marked Read',
                                                'Alert from ${alert.patientName} marked as read.',
                                                snackPosition: SnackPosition.BOTTOM,
                                              );
                                            },
                                            icon: const Icon(Icons.check_circle_outline_rounded,
                                                size: 14),
                                            label: const Text('Mark Read',
                                                style: TextStyle(fontSize: 11)),
                                            style: TextButton.styleFrom(
                                              foregroundColor: const Color(0xFF2ECC71),
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 10, vertical: 4),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                          )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountBadge({
    required String count,
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String value, String text) {
    return Expanded(
      child: GestureDetector(
        onTap: () => varAlertTabFilter.value = value,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: varAlertTabFilter.value == value ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: varAlertTabFilter.value == value
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
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: varAlertTabFilter.value == value
                  ? const Color(0xFF1E293B)
                  : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = const Color(0xFF475569);
    String text = 'Low';

    if (priority == 'high') {
      bg = const Color(0xFFFFEBEE);
      fg = const Color(0xFFC62828);
      text = 'High';
    } else if (priority == 'medium') {
      bg = const Color(0xFFFFF3E0);
      fg = const Color(0xFFE65100);
      text = 'Medium';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
