import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

class OnboardingSlide {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  final AuthController _authController = Get.find<AuthController>();

  final List<OnboardingSlide> slides = [
    OnboardingSlide(
      icon: Icons.notifications_active_rounded,
      title: "Smart Medicine Reminder",
      description: "Never miss a dose with intelligent reminders tailored to your schedule",
      color: const Color(0xFF4A90E2),
    ),
    OnboardingSlide(
      icon: Icons.document_scanner_rounded,
      title: "Prescription Scanner AI",
      description: "Scan prescriptions instantly and let AI organize your medicine schedule",
      color: const Color(0xFF2ECC71),
    ),
    OnboardingSlide(
      icon: Icons.people_alt_rounded,
      title: "Caretaker Monitoring System",
      description: "Connect with caretakers who can monitor your health journey in real-time",
      color: const Color(0xFF4A90E2),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    _authController.currentSlide.value = index;
                  },
                  itemCount: slides.length,
                  itemBuilder: (context, index) {
                    final slide = slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated Container for Icon
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                slide.color.withOpacity(0.2),
                                slide.color.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Icon(
                            slide.icon,
                            size: 80,
                            color: slide.color,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            slide.description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF64748B),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              
              // Dots indicator and Buttons
              Column(
                children: [
                  // Indicator Dots
                  Obx(() => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          slides.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            height: 8,
                            width: _authController.currentSlide.value == index ? 32 : 8,
                            decoration: BoxDecoration(
                              color: _authController.currentSlide.value == index
                                  ? const Color(0xFF4A90E2)
                                  : const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      )),
                  const SizedBox(height: 32),

                  // Navigation Buttons
                  Obx(() {
                    final isLastPage =
                        _authController.currentSlide.value == slides.length - 1;
                    return Row(
                      children: [
                        if (!isLastPage) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                _authController.skipOnboarding();
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              child: const Text(
                                'Skip',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4A90E2), Color(0xFF2ECC71)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4A90E2).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                if (isLastPage) {
                                  _authController.goToLogin();
                                } else {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isLastPage ? 'Get Started' : 'Next',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
