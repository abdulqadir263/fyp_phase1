import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/themes/app_theme.dart';
import 'app/data/services/firebase_service.dart';
import 'app/data/services/cloudinary_service.dart';
import 'app/data/services/weather_service.dart';
import 'app/data/providers/auth_provider.dart';
import 'app/services/gemini_service.dart';
import 'modules/community/services/community_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize all core services as permanent
  Get.put(FirebaseService(), permanent: true);
  Get.put(CloudinaryService(), permanent: true);
  Get.put(WeatherService(), permanent: true);
  Get.put(GeminiService(), permanent: true);
  Get.put(AuthProvider(), permanent: true);
  Get.put(CommunityService(), permanent: true);

  // Global error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  runApp(const FarmAssistApp());
}

class FarmAssistApp extends StatelessWidget {
  const FarmAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Aasaan Kisaan',
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,

      initialRoute: AppRoutes.LOGIN,
      getPages: AppPages.routes,
      defaultTransition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 200),
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
    );
  }
}