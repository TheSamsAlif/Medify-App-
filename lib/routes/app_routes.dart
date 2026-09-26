part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const SPLASH = _Paths.SPLASH;
  static const ONBOARDING = _Paths.ONBOARDING;
  static const ROLE_SELECTION = _Paths.ROLE_SELECTION;
  static const LOGIN = _Paths.LOGIN;
  static const REGISTER = _Paths.REGISTER;
  static const FORGOT_PASSWORD = _Paths.FORGOT_PASSWORD;
  
  static const PATIENT_LAYOUT = _Paths.PATIENT_LAYOUT;
  static const CARETAKER_LAYOUT = _Paths.CARETAKER_LAYOUT;
  static const CARETAKER_PATIENT_DETAILS = _Paths.CARETAKER_PATIENT_DETAILS;
}

abstract class _Paths {
  _Paths._();
  static const SPLASH = '/';
  static const ONBOARDING = '/onboarding';
  static const ROLE_SELECTION = '/role-selection';
  static const LOGIN = '/login';
  static const REGISTER = '/register';
  static const FORGOT_PASSWORD = '/forgot-password';
  
  static const PATIENT_LAYOUT = '/patient';
  static const CARETAKER_LAYOUT = '/caretaker';
  static const CARETAKER_PATIENT_DETAILS = '/caretaker/patient-details';
}
