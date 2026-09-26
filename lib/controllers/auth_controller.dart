import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController extends GetxController {
  // Loading state
  var isLoading = false.obs;

  // Onboarding Slide Index
  var currentSlide = 0.obs;

  // Selected Role (patient / caretaker)
  var selectedRole = 'patient'.obs;

  // Password Visibility Toggles
  var showPassword = false.obs;
  var showConfirmPassword = false.obs;

  // Sign In inputs
  var email = ''.obs;
  var password = ''.obs;

  // Register inputs
  var registerName = ''.obs;
  var registerEmail = ''.obs;
  var registerPassword = ''.obs;
  var registerConfirmPassword = ''.obs;

  // Forgot Password input
  var forgotEmail = ''.obs;
  var resetEmailSent = false.obs;

  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyUserRole = 'user_role';
  static const String keyUserUid = 'user_uid';
  static const String keyUserEmail = 'user_email';
  static const String keyUserName = 'user_name';

  void nextSlide(int totalSlides) {
    if (currentSlide.value < totalSlides - 1) {
      currentSlide.value++;
    } else {
      goToLogin();
    }
  }

  void skipOnboarding() {
    goToLogin();
  }

  Future<void> checkAuthAndNavigate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
      final cachedIsLoggedIn = prefs.getBool(keyIsLoggedIn) ?? false;
      final cachedRole = prefs.getString(keyUserRole);

      // 1. Check if Firebase Auth has a current user or wait briefly for auth restoration
      User? currentUser;
      try {
        currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null && cachedIsLoggedIn) {
          currentUser = await FirebaseAuth.instance
              .authStateChanges()
              .first
              .timeout(const Duration(milliseconds: 1500));
        }
      } catch (e) {
        // Firebase not initialized or not available on web
      }

      // 2. If logged in (either by FirebaseAuth or cached session flag)
      if (currentUser != null || cachedIsLoggedIn) {
        String role = cachedRole ?? 'patient';

        // If we don't have a cached role, try to get from Firestore with a short timeout
        if (cachedRole == null && currentUser != null) {
          try {
            final doc = await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .get()
                .timeout(const Duration(seconds: 2));
            if (doc.exists) {
              role = doc.get('role') ?? 'patient';
              await prefs.setString(keyUserRole, role);
            }
          } catch (_) {}
        }

        await prefs.setBool(keyIsLoggedIn, true);
        await prefs.setBool('hasSeenOnboarding', true);

        if (role == 'caretaker') {
          Get.offAllNamed('/caretaker');
        } else {
          Get.offAllNamed('/patient');
        }
        return;
      }

      // 3. User is not logged in: check onboarding status
      if (!hasSeenOnboarding) {
        Get.offNamed('/onboarding');
      } else {
        Get.offNamed('/login');
      }
    } catch (e) {
      Get.offNamed('/onboarding');
    }
  }

  void goToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    await checkAuthAndNavigate();
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyIsLoggedIn);
    await prefs.remove(keyUserRole);
    await prefs.remove(keyUserUid);
    await prefs.remove(keyUserEmail);
    await prefs.remove(keyUserName);
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }

  void selectRole(String role) {
    selectedRole.value = role;
    Get.toNamed('/login');
  }

  void togglePasswordVisibility() {
    showPassword.toggle();
  }

  void toggleConfirmPasswordVisibility() {
    showConfirmPassword.toggle();
  }

  Future<void> login() async {
    if (email.value.isNotEmpty && password.value.isNotEmpty) {
      isLoading.value = true;
      try {
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.value.trim(),
          password: password.value,
        );
        
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();
        
        if (userDoc.exists) {
          String role = userDoc.get('role') ?? 'patient';
          String name = userDoc.get('name') ?? '';

          // Persist login state and role locally so user never gets logged out
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(keyIsLoggedIn, true);
          await prefs.setString(keyUserRole, role);
          await prefs.setString(keyUserUid, userCredential.user!.uid);
          await prefs.setString(keyUserEmail, email.value.trim());
          await prefs.setString(keyUserName, name);
          
          if (role == 'patient') {
            Get.offAllNamed('/patient');
          } else {
            Get.offAllNamed('/caretaker');
          }
          Get.snackbar(
            'Success',
            'Signed in as ${role == 'patient' ? 'Patient' : 'Caretaker'}',
            snackPosition: SnackPosition.BOTTOM,
          );
        } else {
          Get.snackbar('Error', 'User data not found.', snackPosition: SnackPosition.BOTTOM);
        }
      } on FirebaseAuthException catch (e) {
        Get.snackbar(
          'Login Failed',
          e.message ?? 'An unknown error occurred',
          snackPosition: SnackPosition.BOTTOM,
        );
      } catch (e) {
        // Fallback for web demo when Firebase isn't configured
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(keyIsLoggedIn, true);
        await prefs.setString(keyUserRole, selectedRole.value);
        await prefs.setString(keyUserEmail, email.value.trim());
        await prefs.setString(keyUserName, email.value.trim().split('@').first);
        if (selectedRole.value == 'caretaker') {
          Get.offAllNamed('/caretaker');
        } else {
          Get.offAllNamed('/patient');
        }
        Get.snackbar(
          'Demo Mode',
          'Signed in as ${selectedRole.value == 'caretaker' ? 'Caretaker' : 'Patient'}',
          snackPosition: SnackPosition.BOTTOM,
        );
      } finally {
        isLoading.value = false;
      }
    } else {
      Get.snackbar(
        'Error',
        'Please enter email and password',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> register() async {
    final emailVal = registerEmail.value.trim();
    final nameVal = registerName.value.trim();
    final passVal = registerPassword.value;
    final confirmPassVal = registerConfirmPassword.value;

    if (passVal != confirmPassVal) {
      Get.snackbar(
        'Error',
        'Passwords do not match',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (emailVal.isNotEmpty && nameVal.isNotEmpty && passVal.isNotEmpty) {
      isLoading.value = true;
      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailVal,
          password: passVal,
        );

        try {
          await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
            'uid': userCredential.user!.uid,
            'name': nameVal,
            'email': emailVal,
            'role': selectedRole.value,
            'photo': '', 
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (firestoreError) {
          // If Firestore fails, delete the created auth user so they aren't bricked
          await userCredential.user?.delete();
          throw Exception('Database Error: ${firestoreError.toString()}');
        }

        // Persist session details upon registration
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(keyIsLoggedIn, true);
        await prefs.setString(keyUserRole, selectedRole.value);
        await prefs.setString(keyUserUid, userCredential.user!.uid);
        await prefs.setString(keyUserEmail, emailVal);
        await prefs.setString(keyUserName, nameVal);

        if (selectedRole.value == 'patient') {
          Get.offAllNamed('/patient');
        } else {
          Get.offAllNamed('/caretaker');
        }
        Get.snackbar(
          'Success',
          'Account created successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
      } on FirebaseAuthException catch (e) {
        Get.snackbar(
          'Registration Failed',
          e.message ?? 'An unknown error occurred',
          snackPosition: SnackPosition.BOTTOM,
        );
      } catch (e) {
        // Fallback for web demo when Firebase isn't configured
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(keyIsLoggedIn, true);
        await prefs.setString(keyUserRole, selectedRole.value);
        await prefs.setString(keyUserUid, 'demo_${DateTime.now().millisecondsSinceEpoch}');
        await prefs.setString(keyUserEmail, emailVal);
        await prefs.setString(keyUserName, nameVal);

        if (selectedRole.value == 'patient') {
          Get.offAllNamed('/patient');
        } else {
          Get.offAllNamed('/caretaker');
        }
        Get.snackbar(
          'Demo Mode',
          'Account created and signed in as ${selectedRole.value == 'caretaker' ? 'Caretaker' : 'Patient'}',
          snackPosition: SnackPosition.BOTTOM,
        );
      } finally {
        isLoading.value = false;
      }
    } else {
      Get.snackbar(
        'Error',
        'Please fill in all details',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> sendResetLink() async {
    if (forgotEmail.value.isNotEmpty) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: forgotEmail.value);
        resetEmailSent.value = true;
      } on FirebaseAuthException catch (e) {
        Get.snackbar(
          'Reset Failed',
          e.message ?? 'An unknown error occurred',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } else {
      Get.snackbar(
        'Error',
        'Please enter your email',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void tryAnotherEmail() {
    resetEmailSent.value = false;
    forgotEmail.value = '';
  }
}
