import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/patient_controller.dart';
import 'patient_home_view.dart';
import 'medicines_view.dart';
import 'scanner_view.dart';
import 'history_view.dart';
import 'patient_settings_view.dart';

class PatientLayout extends StatelessWidget {
  const PatientLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final PatientController controller = Get.find<PatientController>();

    final List<Widget> pages = [
      const PatientHomeView(),
      const MedicinesView(),
      const ScannerView(),
      const HistoryView(),
      const PatientSettingsView(),
    ];

    return Scaffold(
      body: Obx(() => IndexedStack(
            index: controller.selectedIndex.value,
            children: pages,
          )),
      bottomNavigationBar: Obx(() => Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: controller.selectedIndex.value,
              onTap: (index) => controller.changeTab(index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: const Color(0xFF4A90E2),
              unselectedItemColor: const Color(0xFF94A3B8),
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.medical_services_rounded),
                  label: 'Medicines',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.qr_code_scanner_rounded),
                  label: 'Scanner',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history_rounded),
                  label: 'History',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_rounded),
                  label: 'Settings',
                ),
              ],
            ),
          )),
    );
  }
}
