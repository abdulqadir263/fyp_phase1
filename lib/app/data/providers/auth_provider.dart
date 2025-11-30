import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../../utils/app_snackbar.dart';

// Auth ka business logic, controller aur service ke beech ka bridge
class AuthProvider extends GetxService {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isAuthenticated = false.obs;

  @override
  void onInit() {
    super.onInit();
    print('AuthProvider: Initialized successfully!');

    // Auth state changes ko listen karna
    _firebaseService.authStateChanges.listen((User? user) {
      print('AuthProvider: Auth state changed. User: ${user?.uid}');
      if (user != null) {
        print('AuthProvider: User is not null. Fetching data...');
        _fetchUserData(user.uid);
      } else {
        print('AuthProvider: User is null. Clearing current user.');
        currentUser.value = null;
        isAuthenticated.value = false;
      }
    });
  }

  // User ka data fetch karna (Private method)
  Future<void> _fetchUserData(String uid) async {
    try {
      isLoading.value = true;
      print('AuthProvider: [START] _fetchUserData for: $uid');

      final userData = await _firebaseService.getUserData(uid);
      print('AuthProvider: getUserData returned. Data is null: ${userData == null}');

      if (userData != null) {
        print('AuthProvider: User data found. Name: ${userData.name}, Type: ${userData.userType}');
        currentUser.value = userData;
        isAuthenticated.value = true;

        // Check if profile is complete
        bool isProfileComplete = _isProfileComplete(userData);
        print('AuthProvider: Profile complete check result: $isProfileComplete');

        if (isProfileComplete) {
          print('AuthProvider: [NAVIGATING] to HOME because profile is complete.');
          Get.offAllNamed(AppRoutes.HOME);
        } else {
          print('AuthProvider: [NAVIGATING] to PROFILE because profile is incomplete.');
          Get.offAllNamed(AppRoutes.PROFILE);
        }
      } else {
        print('AuthProvider: userData is null. Staying on login screen.');
        currentUser.value = null;
        isAuthenticated.value = false;
      }
    } catch (e, stackTrace) {
      print('AuthProvider: [ERROR] in _fetchUserData: $e');
      print('AuthProvider: [STACK TRACE] $stackTrace');
      AppSnackbar.error('Failed to fetch user data');
    } finally {
      isLoading.value = false;
      print('AuthProvider: [END] _fetchUserData');
    }
  }

  // Check if profile is complete
  bool _isProfileComplete(UserModel user) {
    print('AuthProvider: [CHECK] _isProfileComplete for user: ${user.name}');

    // Check if required fields are filled
    if (user.name.isEmpty || user.email.isEmpty || user.phone.isEmpty) {
      print('AuthProvider: [CHECK] Basic fields are empty. Returning false.');
      return false;
    }

    // Check based on user type
    switch (user.userType) {
      case 'farmer':
        bool locationValid = user.location != null && user.location!.isNotEmpty;
        print('AuthProvider: [CHECK] Farmer - Location valid: $locationValid');
        return locationValid;
      case 'expert':
        bool specializationValid = user.specialization != null && user.specialization!.isNotEmpty;
        print('AuthProvider: [CHECK] Expert - Specialization valid: $specializationValid');
        return specializationValid;
      case 'company':
        bool companyValid = user.companyName != null && user.companyName!.isNotEmpty;
        print('AuthProvider: [CHECK] Company - Company name valid: $companyValid');
        return companyValid;
      default:
        print('AuthProvider: [CHECK] Unknown or empty user type: "${user.userType}". Returning false.');
        return false;
    }
  }

  // Public method to refresh user data
  Future<void> refreshUserData() async {
    final user = _firebaseService.auth.currentUser;
    if (user != null) {
      print('AuthProvider: Refreshing user data for: ${user.uid}');
      await _fetchUserData(user.uid);
    } else {
      print('AuthProvider: No current user to refresh');
    }
  }

  // Signup function
  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String userType,
  }) async {
    try {
      isLoading.value = true;
      print('AuthProvider: [START] signUp for: $email');

      // ✅ FIXED: Added validation
      if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty || userType.isEmpty) {
        throw Exception('All fields are required for signup.');
      }

      // Firebase Auth main user banana
      final userCredential = await _firebaseService.signUpWithEmail(
        email: email,
        password: password,
      );

      print('AuthProvider: User created in Firebase Auth: ${userCredential.user?.uid}');

      // Firestore main user ka data save karna
      final newUser = UserModel(
        uid: userCredential.user!.uid,
        name: name,
        email: email,
        phone: phone,
        userType: userType,
        createdAt: DateTime.now(),
      );

      await _firebaseService.saveUserData(newUser);
      print('AuthProvider: User data saved to Firestore');

      AppSnackbar.success('Account created successfully! Please login to continue.');

      // Login screen par redirect karna
      print('AuthProvider: [NAVIGATING] to LOGIN after successful signup.');
      Get.offAllNamed(AppRoutes.LOGIN);

    } catch (e, stackTrace) {
      print('AuthProvider: [ERROR] in signUp: $e');
      print('AuthProvider: [STACK TRACE] $stackTrace');
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
      print('AuthProvider: [END] signUp');
    }
  }

  // Login function
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      print('AuthProvider: [START] signIn for: $email');

      await _firebaseService.signInWithEmail(
        email: email,
        password: password,
      );

      print('AuthProvider: signInWithEmail successful. Waiting for auth state change listener...');
      AppSnackbar.success('Login successful!');

    } catch (e, stackTrace) {
      print('AuthProvider: [ERROR] in signIn: $e');
      print('AuthProvider: [STACK TRACE] $stackTrace');
      AppSnackbar.error(e.toString());
    } finally {
      isLoading.value = false;
      print('AuthProvider: [END] signIn');
    }
  }

  // Logout function
  Future<void> signOut() async {
    try {
      print('AuthProvider: [START] signOut');
      await _firebaseService.signOut();
      currentUser.value = null;
      isAuthenticated.value = false;

      Get.offAllNamed(AppRoutes.LOGIN);
      AppSnackbar.success('Logged out successfully!');
    } catch (e) {
      print('AuthProvider: [ERROR] in signOut: $e');
      AppSnackbar.error(e.toString());
    }
  }

  // Guest user ke liye function
  Future<void> signInAsGuest() async {
    try {
      print('AuthProvider: [START] signInAsGuest');
      currentUser.value = UserModel(
        uid: 'guest_user',
        name: 'Guest User',
        email: 'guest@example.com',
        phone: '',
        userType: 'guest',
        createdAt: DateTime.now(),
      );
      isAuthenticated.value = true;

      Get.offAllNamed(AppRoutes.HOME);
      AppSnackbar.success('Logged in as Guest!');
    } catch (e) {
      print('AuthProvider: [ERROR] in signInAsGuest: $e');
      AppSnackbar.error(e.toString());
    }
  }

  // Add this method to the AuthProvider class

// Forgot password function
  Future<void> forgotPassword(String email) async {
    try {
      print('AuthProvider: [START] forgotPassword for: $email');

      await _firebaseService.sendPasswordResetEmail(email);

      print('AuthProvider: Password reset email sent successfully');

    } catch (e, stackTrace) {
      print('AuthProvider: [ERROR] in forgotPassword: $e');
      print('AuthProvider: [STACK TRACE] $stackTrace');
      throw e; // Re-throw to handle in controller
    }
  }


}