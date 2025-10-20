import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/themes/app_theme.dart';
import 'app/data/services/firebase_service.dart';
import 'app/data/services/cloudinary_service.dart';
import 'app/data/services/weather_service.dart'; // ✅ NEW: Weather Service
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ FIXED: Firebase ko options ke saath initialize karna
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ FIXED: Initialize all services
  Get.put(FirebaseService());
  Get.put(CloudinaryService());
  Get.put(WeatherService()); // ✅ NEW: Weather Service

  runApp(FarmAssistApp());
}

class FarmAssistApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Aasaan Kisaan',
      debugShowCheckedModeBanner: false,

      // ✅ FIXED: Use fixed theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // ✅ FIXED: Force light theme

      initialRoute: AppRoutes.LOGIN,
      getPages: AppPages.routes,
      defaultTransition: Transition.fade,
      locale: Locale('en', 'US'),
      fallbackLocale: Locale('en', 'US'),
    );
  }
}