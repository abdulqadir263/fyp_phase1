import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/themes/app_theme.dart';
import 'app/data/services/firebase_service.dart';
import 'firebase_options.dart';

// Ye app ka entry point hai
void main() async {
  // Firebase ko initialize karna zaroori hai
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase ko options ke saath initialize karein
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FirebaseService ko globally initialize karna
  Get.put(FirebaseService());

  runApp(FarmAssistApp());
}

class FarmAssistApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // GetX MaterialApp hai jo routing aur state management handle karta hai
    return GetMaterialApp(
      title: 'FarmAssist',
      debugShowCheckedModeBanner: false, // Debug banner remove karna
      theme: AppTheme.lightTheme, // Light theme
      darkTheme: AppTheme.darkTheme, // Dark theme
      themeMode: ThemeMode.system, // System theme follow karega

      // Initial route jab app start hogi
      initialRoute: AppRoutes.LOGIN,

      // Sare routes jo humne define kiye hain
      getPages: AppPages.routes,

      // Navigation ka style
      defaultTransition: Transition.fade,

      // Translations ke liye (English/Urdu)
      locale: Locale('en', 'US'),
      fallbackLocale: Locale('en', 'US'),
    );
  }
}