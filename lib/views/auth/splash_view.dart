import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/auth_controller.dart';
import '../../services/notification_service.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();

    // Navigate quickly if launched from alarm (150ms), otherwise after 2.2 seconds for splash branding
    bool isAlarmLaunch = false;
    try {
      isAlarmLaunch = NotificationService.instance.pendingLaunchPayload != null;
    } catch (_) {}
    final delay = isAlarmLaunch ? const Duration(milliseconds: 150) : const Duration(milliseconds: 2200);

    Timer(delay, () async {
      if (!mounted) return;
      try {
        await Get.find<AuthController>().checkAuthAndNavigate().timeout(
          const Duration(seconds: 4),
          onTimeout: () {
            debugPrint('checkAuthAndNavigate timed out, navigating to onboarding');
            if (mounted) Get.offNamed('/onboarding');
          },
        );
      } catch (e) {
        debugPrint('Splash navigation error: $e');
        if (mounted) Get.offNamed('/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animated pulsing circle 1
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 1.0, end: 1.3),
                          duration: const Duration(seconds: 2),
                          curve: Curves.easeInOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4A90E2).withOpacity(0.05),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          },
                        ),
                        // Animated pulsing circle 2
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 1.0, end: 1.15),
                          duration: const Duration(seconds: 2),
                          curve: Curves.easeInOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4A90E2).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          },
                        ),
                        // Premium App Logo Card
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4A90E2).withOpacity(0.15),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Image.asset(
                              'Assets/medify.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'Medify',
                      style: GoogleFonts.outfit(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your Health, Our Priority',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    // Premium Loading Indicator
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
                        strokeWidth: 3,
                        backgroundColor: const Color(0xFF4A90E2).withOpacity(0.1),
                      ),
                    ),
                    const SizedBox(height: 64),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
