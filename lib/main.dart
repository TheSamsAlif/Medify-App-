import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'routes/app_pages.dart';
import 'controllers/auth_controller.dart';
import 'utils/app_translations.dart';
import 'services/notification_service.dart';

void updateAppTheme(String languageCode) {
  final isBangla = languageCode == 'Bangla';
  final textTheme = isBangla 
      ? GoogleFonts.hindSiliguriTextTheme() 
      : GoogleFonts.outfitTextTheme();
      
  Get.changeTheme(ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4A90E2),
      primary: const Color(0xFF4A90E2),
      secondary: const Color(0xFF2ECC71),
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F9FF),
    textTheme: textTheme,
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  ));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize Notification Service with high importance channel & alarm sound
  await NotificationService.instance.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Medify',
      debugShowCheckedModeBanner: false,
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90E2),
          primary: const Color(0xFF4A90E2),
          secondary: const Color(0xFF2ECC71),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F9FF),
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      initialBinding: BindingsBuilder(() {
        Get.put(AuthController(), permanent: true);
      }),
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
    );
  }
}
