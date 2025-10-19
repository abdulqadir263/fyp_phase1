import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart'; // ✅ Add this import
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/themes/app_theme.dart';
import 'app/data/services/firebase_service.dart';
import 'app/data/services/cloudinary_service.dart';
import 'firebase_options.dart';

// Ye app ka entry point hai
void main() async {
  // Firebase ko initialize karna zaroori hai
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase ko options ke saath initialize karna
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FirebaseService ko globally initialize karna
  Get.put(FirebaseService());

  // CloudinaryService ko globally initialize karna
  Get.put(CloudinaryService());

  runApp(FarmAssistApp());
}

class FarmAssistApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ✅ FIXED: GetX MaterialApp with Google Fonts
    return GetMaterialApp(
      title: 'FarmAssist',
      debugShowCheckedModeBanner: false,

      // ✅ FIXED: Use Google Fonts
      theme: AppTheme.lightTheme.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      darkTheme: AppTheme.darkTheme.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),

      // ✅ FIXED: Force light theme instead of system theme
      themeMode: ThemeMode.light,

      initialRoute: AppRoutes.LOGIN,
      getPages: AppPages.routes,
      defaultTransition: Transition.fade,
      locale: Locale('en', 'US'),
      fallbackLocale: Locale('en', 'US'),
    );
  }
}