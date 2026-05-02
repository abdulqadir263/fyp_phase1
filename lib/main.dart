import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/themes/app_theme.dart';
import 'app/translations/app_translations.dart';
import 'core/localization/language_controller.dart';
import 'app/data/services/firebase_service.dart';
import 'app/data/services/cloudinary_service.dart';
import 'app/data/services/weather_service.dart';
import 'package:fyp_phase1/modules/auth/repository/auth_repository.dart';
import 'app/services/groq_service.dart';
import 'modules/community/repository/community_repository.dart';
import 'modules/appointments/repository/appointment_repository.dart';
import 'modules/marketplace/repository/marketplace_repository.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await dotenv.load(fileName: '.env');

  // Initialize Firebase
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) rethrow;
  }

  // Initialize App Check (debug mode for development)
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  }

  final savedLocale = await LanguageController.getSavedLocale();

  Get.put(FirebaseService(), permanent: true);
  Get.put(CloudinaryService(), permanent: true);
  Get.put(WeatherService(), permanent: true);
  Get.put(GroqService(), permanent: true);
  Get.put(AuthRepository(), permanent: true);
  Get.put(CommunityRepository(), permanent: true);
  Get.put(AppointmentRepository(), permanent: true);
  Get.put(MarketplaceRepository(), permanent: true);
  Get.put(LanguageController(), permanent: true);

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  runApp(FarmAssistApp(savedLocale: savedLocale));
}

class FarmAssistApp extends StatelessWidget {
  final Locale savedLocale;
  const FarmAssistApp({super.key, required this.savedLocale});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Aasaan Kisaan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      translations: AppTranslations(),
      locale: savedLocale,
      fallbackLocale: const Locale('en'),
      initialRoute: AppRoutes.SPLASH,
      getPages: AppPages.routes,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 150),
    );
  }
}