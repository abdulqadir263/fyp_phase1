import 'package:flutter/material.dart';
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

      print('Fetching weather data...');

      // Get current weather
      final weather = await _weatherService.getCurrentWeather();
      currentWeather.value = weather;

      print('Current weather loaded: ${weather?.location}');

      // Get 5-day forecast
      final forecastData = await _weatherService.getWeatherForecast();
      forecast.value = forecastData;

      print('Forecast loaded: ${forecastData.length} days');

    } catch (e) {
      print('Error in fetchWeatherData: $e');
      Get.snackbar(
        'Weather Info',
        'Using demo weather data. Some features may be limited.',
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
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
      // Convert to Fahrenheit
      final fahrenheit = (temperature * 9/5) + 32;
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

  // Navigate to detailed weather view
  void navigateToDetail(WeatherModel weather) {
    Get.toNamed(AppRoutes.WEATHER_DETAIL, arguments: weather);
  }
}