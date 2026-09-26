import 'package:get/get.dart';
import '../views/auth/splash_view.dart';
import '../views/auth/onboarding_view.dart';
import '../views/auth/role_selection_view.dart';
import '../views/auth/login_view.dart';
import '../views/auth/register_view.dart';
import '../views/auth/forgot_password_view.dart';
import '../views/patient/patient_layout.dart';
import '../views/caretaker/caretaker_layout.dart';
import '../views/caretaker/patient_details_view.dart';
import '../controllers/auth_controller.dart';
import '../controllers/patient_controller.dart';
import '../controllers/caretaker_controller.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: _Paths.SPLASH,
      page: () => const SplashView(),
    ),
    GetPage(
      name: _Paths.ONBOARDING,
      page: () => const OnboardingView(),
    ),
    GetPage(
      name: _Paths.ROLE_SELECTION,
      page: () => const RoleSelectionView(),
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
    ),
    GetPage(
      name: _Paths.REGISTER,
      page: () => const RegisterView(),
    ),
    GetPage(
      name: _Paths.FORGOT_PASSWORD,
      page: () => const ForgotPasswordView(),
    ),
    GetPage(
      name: _Paths.PATIENT_LAYOUT,
      page: () => const PatientLayout(),
      binding: BindingsBuilder(() {
        Get.lazyPut<PatientController>(() => PatientController());
      }),
    ),
    GetPage(
      name: _Paths.CARETAKER_LAYOUT,
      page: () => const CaretakerLayout(),
      binding: BindingsBuilder(() {
        Get.lazyPut<CaretakerController>(() => CaretakerController());
      }),
    ),
    GetPage(
      name: _Paths.CARETAKER_PATIENT_DETAILS,
      page: () => const PatientDetailsView(),
      binding: BindingsBuilder(() {
        // Will share the caretaker controller or load parameters
        Get.lazyPut<CaretakerController>(() => CaretakerController());
      }),
    ),
  ];
}
