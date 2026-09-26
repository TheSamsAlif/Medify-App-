import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/caretaker_controller.dart';
import 'caretaker_dashboard_view.dart';
import 'patients_view.dart';
import 'alerts_view.dart';
import 'analytics_view.dart';
import 'caretaker_settings_view.dart';

class CaretakerLayout extends StatelessWidget {
  const CaretakerLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final CaretakerController controller = Get.find<CaretakerController>();

    final List<Widget> pages = [
      const CaretakerDashboardView(),
      const PatientsView(),
      const AlertsView(),
      const AnalyticsView(),
      const CaretakerSettingsView(),
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
              selectedItemColor: const Color(0xFF2ECC71), // Caretaker secondary green accent
              unselectedItemColor: const Color(0xFF94A3B8),
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
              elevation: 0,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.dashboard_rounded),
                  label: 'Dashboard'.tr,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.people_alt_rounded),
                  label: 'Patients'.tr,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.notifications_active_rounded),
                  label: 'Alerts'.tr,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.analytics_rounded),
                  label: 'Analytics'.tr,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.settings_rounded),
                  label: 'Settings'.tr,
                ),
              ],
            ),
          )),
    );
  }
}
