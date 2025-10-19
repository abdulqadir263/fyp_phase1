import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

// Auth ka business logic, controller aur service ke beech ka bridge
class AuthProvider extends GetxService {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isAuthenticated = false.obs;

  @override
  void onInit() {
    super.onInit();

    // Auth state changes ko listen karna
    _firebaseService.authStateChanges.listen((User? user) {
      if (user != null) {
        print('AuthProvider: User detected: ${user.uid}'); // Debug log
        _fetchUserData(user.uid);
      } else {
        print('AuthProvider: No user detected'); // Debug log
        currentUser.value = null;
        isAuthenticated.value = false;
      }
    });
  }

  // User ka data fetch karna (Private method)
  Future<void> _fetchUserData(String uid) async {
    try {
      isLoading.value = true;
      print('AuthProvider: Fetching user data for: $uid'); // Debug log

      final userData = await _firebaseService.getUserData(uid);
      currentUser.value = userData;
      isAuthenticated.value = userData != null;

      print('AuthProvider: User data fetched: ${userData?.name}'); // Debug log

      // ✅ UPDATED: Navigation logic - Profile pe redirect karna
      if (userData != null) {
        print('AuthProvider: Checking if profile is complete'); // Debug log

        // Check if profile is complete
        bool isProfileComplete = _isProfileComplete(userData);

        if (isProfileComplete) {
          print('AuthProvider: Profile is complete, navigating to home'); // Debug log
          Get.offAllNamed(AppRoutes.HOME);
        } else {
          print('AuthProvider: Profile is incomplete, navigating to profile'); // Debug log
          Get.offAllNamed(AppRoutes.PROFILE);
        }
      } else {
        print('AuthProvider: User data is null, staying on login'); // Debug log
      }
    } catch (e) {
      print('AuthProvider: Error fetching user data: $e'); // Debug log
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ UPDATED: Check if profile is complete
  bool _isProfileComplete(UserModel user) {
    // Check if required fields are filled
    if (user.name.isEmpty || user.email.isEmpty || user.phone.isEmpty) {
      return false;
    }

    // Check based on user type
    switch (user.userType) {
      case 'farmer':
        return user.location != null && user.location!.isNotEmpty;
      case 'expert':
        return user.specialization != null && user.specialization!.isNotEmpty;
      case 'company':
        return user.companyName != null && user.companyName!.isNotEmpty;
      default:
        return false;
    }
  }

  // ✅ NEW: Public method to refresh user data (ProfileController ke liye)
  Future<void> refreshUserData() async {
    final user = _firebaseService.auth.currentUser;
    if (user != null) {
      print('AuthProvider: Refreshing user data for: ${user.uid}'); // Debug log
      await _fetchUserData(user.uid);
    } else {
      print('AuthProvider: No current user to refresh'); // Debug log
    }
  }

  // ✅ UPDATED: Signup function - Login screen par redirect karna
  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String userType,
  }) async {
    try {
      isLoading.value = true;
      print('AuthProvider: Starting signup for: $email'); // Debug log

      // Firebase Auth main user banana
      final userCredential = await _firebaseService.signUpWithEmail(
        email: email,
        password: password,
      );

      print('AuthProvider: User created in Firebase Auth: ${userCredential.user?.uid}'); // Debug log

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
      print('AuthProvider: User data saved to Firestore'); // Debug log

      Get.snackbar('Success', 'Account created successfully! Please login to continue.');

      // ✅ UPDATED: Login screen par redirect karna
      Get.offAllNamed(AppRoutes.LOGIN);

    } catch (e) {
      print('AuthProvider: Signup error: $e'); // Debug log
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Login function
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      print('AuthProvider: Starting login for: $email'); // Debug log

      await _firebaseService.signInWithEmail(
        email: email,
        password: password,
      );

      print('AuthProvider: Login successful'); // Debug log
      Get.snackbar('Success', 'Login successful!');

      // Navigation automatically _fetchUserData se ho jayega

    } catch (e) {
      print('AuthProvider: Login error: $e'); // Debug log
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Logout function
  Future<void> signOut() async {
    try {
      print('AuthProvider: Starting logout'); // Debug log
      await _firebaseService.signOut();
      currentUser.value = null;
      isAuthenticated.value = false;

      // Navigation automatically auth state change se ho jayega
      // Agar manually karna hai to:
      Get.offAllNamed(AppRoutes.LOGIN);

      Get.snackbar('Success', 'Logged out successfully!');
    } catch (e) {
      print('AuthProvider: Logout error: $e'); // Debug log
      Get.snackbar('Error', e.toString());
    }
  }

  // Guest user ke liye function
  Future<void> signInAsGuest() async {
    try {
      print('AuthProvider: Signing in as guest'); // Debug log
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
      Get.snackbar('Success', 'Logged in as Guest!');
    } catch (e) {
      print('AuthProvider: Guest login error: $e'); // Debug log
      Get.snackbar('Error', e.toString());
    }
  }
}