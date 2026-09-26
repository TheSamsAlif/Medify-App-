import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/caretaker_controller.dart';

class PatientsView extends StatefulWidget {
  const PatientsView({super.key});

  @override
  State<PatientsView> createState() => _PatientsViewState();
}

class _PatientsViewState extends State<PatientsView> {
  final CaretakerController _controller = Get.find<CaretakerController>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
                'Patients'.tr,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                'Monitor and manage your connected patients'.tr,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),

              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: (val) => _controller.patientsSearchQuery.value = val,
                decoration: InputDecoration(
                  hintText: 'Search patients or conditions...'.tr,
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                  suffixIcon: Obx(() => _controller.patientsSearchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            _controller.patientsSearchQuery.value = '';
                          },
                        )
                      : const SizedBox.shrink()),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Horizontal Category Tabs
              Obx(() => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTab('all', 'All'.tr),
                        const SizedBox(width: 8),
                        _buildTab('excellent', 'Excellent (>90%)'.tr),
                        const SizedBox(width: 8),
                        _buildTab('good', 'Good (70-90%)'.tr),
                        const SizedBox(width: 8),
                        _buildTab('needs', 'Needs Attention'.tr + ' (<70%)'),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),

              // Patients List
              Expanded(
                child: Obx(() {
                  final list = _controller.filteredPatients;
                  if (list.isEmpty) {
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
                            Icons.people_outline_rounded,
                            size: 40,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No patients found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _controller.patientsSearchQuery.value.isNotEmpty
                              ? 'Try matching a different name or condition'
                              : 'No patients in this category',
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
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top info row
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: adColor.withOpacity(0.1),
                                    backgroundImage: patient.avatar.isNotEmpty ? NetworkImage(patient.avatar) : null,
                                    child: patient.avatar.isEmpty
                                        ? Text(
                                            patient.name.isNotEmpty ? patient.name.trim().split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join('').toUpperCase() : 'P',
                                            style: TextStyle(
                                                color: adColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          patient.name,
                                          style: const TextStyle(
                                            fontSize: 16,
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
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${patient.adherence}%',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: adColor),
                                      ),
                                      const Text(
                                        'Adherence',
                                        style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Today's Progress Bar
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Today's Intake Progress",
                                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                  Text(
                                    "${patient.todayTaken}/${patient.todayTotal} taken",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
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
                              const SizedBox(height: 12),

                              // Bottom actions row
                              const Divider(color: Color(0xFFF1F5F9)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded,
                                          size: 14, color: Color(0xFF94A3B8)),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Last taken: ${patient.lastTaken}',
                                        style: const TextStyle(
                                            fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      _controller.selectPatient(patient);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF0FDF4),
                                      foregroundColor: const Color(0xFF2ECC71),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                    ),
                                    child: const Row(
                                      children: [
                                        Text('Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        SizedBox(width: 4),
                                        Icon(Icons.arrow_forward_rounded, size: 14),
                                      ],
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
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

  Widget _buildTab(String filterVal, String label) {
    final isSelected = _controller.patientTabFilter.value == filterVal;
    return GestureDetector(
      onTap: () {
        _controller.patientTabFilter.value = filterVal;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2ECC71) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2ECC71).withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
