import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/patient_controller.dart';

class MedicinesView extends StatefulWidget {
  const MedicinesView({super.key});

  @override
  State<MedicinesView> createState() => _MedicinesViewState();
}

class _MedicinesViewState extends State<MedicinesView> {
  final PatientController _controller = Get.find<PatientController>();
  final TextEditingController _searchController = TextEditingController();

  final List<Color> colorsList = [
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.amber,
    Colors.red,
    Colors.pink,
  ];

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Medicines',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Obx(() => Text(
                            '${_controller.medicines.length} medicine${_controller.medicines.length != 1 ? 's' : ''} in your list',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          )),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A90E2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: (val) => _controller.searchQuery.value = val,
                decoration: InputDecoration(
                  hintText: 'Search medicines...',
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                  suffixIcon: Obx(() => _controller.searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            _controller.searchQuery.value = '';
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

              // Medicines List
              Expanded(
                child: Obx(() {
                  final list = _controller.filteredMedicines;
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
                            Icons.medical_services_outlined,
                            size: 40,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No medicines found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _controller.searchQuery.value.isNotEmpty
                              ? 'Try a different search query'
                              : 'Add your first medicine using the Add button above',
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
                      final medicine = list[index];
                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Medicine Color Icon
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: medicine.color,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.medical_services_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      medicine.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${medicine.dosage} • ${medicine.frequency}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: medicine.times
                                          .map((time) => Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 4),
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

                              // Actions
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    onPressed: () => _showAddEditDialog(medicine: medicine),
                                    style: IconButton.styleFrom(
                                      foregroundColor: const Color(0xFF64748B),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                                    onPressed: () {
                                      _controller.deleteMedicine(medicine.id);
                                      Get.snackbar(
                                        'Deleted',
                                        '${medicine.name} removed from list',
                                        snackPosition: SnackPosition.BOTTOM,
                                      );
                                    },
                                    style: IconButton.styleFrom(
                                      foregroundColor: Colors.redAccent,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddEditDialog({Medicine? medicine}) {
    final nameController = TextEditingController(text: medicine?.name ?? '');
    final dosageController = TextEditingController(text: medicine?.dosage ?? '');
    final durationController = TextEditingController(text: '1');
    
    // Form temporary states using GetX observables for dialog reactivity
    final rxFrequency = (medicine?.frequency == 'Twice daily' 
        ? 'twice' 
        : medicine?.frequency == 'Three times a day' ? 'thrice' : 'once').obs;
    final rxColor = (medicine?.color ?? colorsList.first).obs;
    
    // We'll manage selected times in an RxList
    final rxTimes = RxList<String>(medicine?.times ?? ['09:00 AM']);

    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          medicine != null ? 'Edit Medicine' : 'Add Medicine',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Medicine Name',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Aspirin',
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
                  'Dosage',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: dosageController,
                  decoration: InputDecoration(
                    hintText: 'e.g. 100mg (Optional)',
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
                  'Frequency',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Obx(() => DropdownButtonFormField<String>(
                      value: rxFrequency.value,
                      items: const [
                        DropdownMenuItem(value: 'once', child: Text('Once daily')),
                        DropdownMenuItem(value: 'twice', child: Text('Twice daily')),
                        DropdownMenuItem(value: 'thrice', child: Text('Three times a day')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          rxFrequency.value = val;
                          if (val == 'once') {
                            rxTimes.assignAll(['09:00 AM']);
                          } else if (val == 'twice') {
                            rxTimes.assignAll(['08:00 AM', '08:00 PM']);
                          } else if (val == 'thrice') {
                            rxTimes.assignAll(['08:00 AM', '02:00 PM', '08:00 PM']);
                          }
                        }
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    )),
                const SizedBox(height: 16),

                const Text(
                  'Schedule Times',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Obx(() => Column(
                      children: List.generate(rxTimes.length, (idx) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (time != null) {
                                rxTimes[idx] = time.format(context);
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
                                    rxTimes[idx],
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const Icon(Icons.access_time_rounded,
                                      color: Color(0xFF64748B), size: 20),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    )),
                const SizedBox(height: 16),

                const Text(
                  'Duration (Days)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'e.g. 7 (Default: 1)',
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
                  'Color Theme',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: colorsList.map((color) {
                        final isSelected = rxColor.value == color;
                        return GestureDetector(
                          onTap: () => rxColor.value = color,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.black : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 16)
                                : null,
                          ),
                        );
                      }).toList(),
                    )),
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
              if (nameController.text.isNotEmpty) {
                int duration = int.tryParse(durationController.text) ?? 1;
                if (duration < 1) duration = 1;

                _controller.saveMedicine(
                  id: medicine?.id,
                  name: nameController.text,
                  dosage: dosageController.text.isEmpty ? 'N/A' : dosageController.text,
                  frequency: rxFrequency.value == 'once' 
                      ? 'Once daily' 
                      : rxFrequency.value == 'twice' 
                          ? 'Twice daily' 
                          : 'Three times a day',
                  times: List.from(rxTimes),
                  color: rxColor.value,
                  durationInDays: duration,
                );
                Get.back();
                Get.snackbar(
                  'Success',
                  medicine != null ? 'Medicine updated' : 'Medicine added',
                  snackPosition: SnackPosition.BOTTOM,
                );
              } else {
                Get.snackbar(
                  'Error',
                  'Please fill medicine name',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90E2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(medicine != null ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }
}
