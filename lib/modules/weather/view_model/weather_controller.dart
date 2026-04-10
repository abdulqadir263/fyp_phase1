import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../app/data/models/weather_model.dart';
import '../../../app/data/services/weather_service.dart';
import '../../../app/routes/app_routes.dart';

class WeatherController extends GetxController {
  final WeatherService _weatherService = Get.find<WeatherService>();

  final Rx<WeatherModel?> currentWeather = Rx<WeatherModel?>(null);
  final RxList<WeatherModel> forecast = <WeatherModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedLanguage = 'en'.obs;
  final RxBool isCelsius = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchWeatherData();
  }

  Future<void> fetchWeatherData() async {
    try {
      isLoading.value = true;

      final weather = await _weatherService.getCurrentWeather();
      currentWeather.value = weather;

      final forecastData = await _weatherService.getWeatherForecast();
      forecast.value = forecastData;
    } catch (e) {
      debugPrint('Error in fetchWeatherData: $e');
      _createDemoData();
      Get.snackbar(
        'Weather Info',
        'Using demo weather data with smart farming recommendations.',
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _createDemoData() {
    currentWeather.value = WeatherModel.demo(
      location: 'Punjab, Pakistan',
      temperature: 31.5,
      description: 'clear sky',
      humidity: 40.0,
      windSpeed: 1.8,
      dateTime: DateTime.now(),
      icon: '☀️',
    );

    forecast.value = [
      WeatherModel.demo(
        location: 'Punjab, Pakistan',
        temperature: 25.0,
        description: 'partly cloudy',
        humidity: 45.0,
        windSpeed: 2.0,
        dateTime: DateTime.now().add(const Duration(days: 1)),
        icon: '⛅',
      ),
      WeatherModel.demo(
        location: 'Punjab, Pakistan',
        temperature: 24.5,
        description: 'clear sky',
        humidity: 42.0,
        windSpeed: 1.5,
        dateTime: DateTime.now().add(const Duration(days: 2)),
        icon: '☀️',
      ),
    ];
  }

  String getRiskLevelColor(String riskLevel) {
    switch (riskLevel) {
      case 'high':
        return '🔴';
      case 'medium':
        return '🟡';
      case 'low':
        return '🟢';
      default:
        return '⚪';
    }
  }

  String getAgriculturePriorityIcon(String priority) {
    switch (priority) {
      case 'high':
        return '🚨';
      case 'medium':
        return '⚠️';
      case 'low':
        return 'ℹ️';
      default:
        return '📋';
    }
  }

  String getAgricultureCategoryIcon(String category) {
    switch (category) {
      case 'harvesting':
        return '🌾';
      case 'spraying':
        return '💧';
      case 'irrigation':
        return '🚰';
      case 'disease':
        return '🦠';
      case 'general':
        return '👨‍🌾';
      case 'livestock':
        return '🐄';
      default:
        return '🌱';
    }
  }

  Future<void> refreshWeather() async {
    await fetchWeatherData();
  }

  void toggleLanguage() {
    selectedLanguage.value = selectedLanguage.value == 'en' ? 'ur' : 'en';
  }

  void toggleTemperatureUnit() {
    isCelsius.value = !isCelsius.value;
  }

  String getTemperatureDisplay(double temperature) {
    if (isCelsius.value) {
      return '${temperature.toStringAsFixed(1)}°C';
    } else {
      final fahrenheit = (temperature * 9 / 5) + 32;
      return '${fahrenheit.toStringAsFixed(1)}°F';
    }
  }

  String getWindSpeedDisplay(double windSpeed) {
    return '${windSpeed.toStringAsFixed(1)} m/s';
  }

  String getRecommendationText(WeatherRecommendation recommendation) {
    return selectedLanguage.value == 'en'
        ? recommendation.recommendationEn
        : recommendation.recommendationUr;
  }

  void navigateToDetail(WeatherModel weather) {
    Get.toNamed(AppRoutes.WEATHER_DETAIL, arguments: weather);
  }
}
