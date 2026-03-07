import 'dart:ui';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// LanguageController — manages app locale and persists selection.
/// Uses SharedPreferences to save the user's language preference.
/// Supports instant switching between English and Urdu (RTL).
class LanguageController extends GetxController {
  static const String _langKey = 'app_language';

  /// Current language code ('en' or 'ur')
  final RxString currentLanguage = 'en'.obs;

  /// Whether app is currently in Urdu (RTL)
  bool get isUrdu => currentLanguage.value == 'ur';

  @override
  void onInit() {
    super.onInit();
    _loadSavedLanguage();
  }

  /// Load saved language from SharedPreferences on app start
  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString(_langKey) ?? 'en';
    currentLanguage.value = savedLang;
    // Apply saved locale
    Get.updateLocale(Locale(savedLang));
  }

  /// Toggle language between English and Urdu
  void toggleLanguage() {
    final newLang = currentLanguage.value == 'en' ? 'ur' : 'en';
    changeLanguage(newLang);
  }

  /// Change to a specific language and persist the choice
  Future<void> changeLanguage(String langCode) async {
    currentLanguage.value = langCode;
    Get.updateLocale(Locale(langCode));

    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, langCode);
  }

  /// Get the saved locale (call before app starts for initial locale)
  static Future<Locale> getSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString(_langKey) ?? 'en';
    return Locale(savedLang);
  }
}

