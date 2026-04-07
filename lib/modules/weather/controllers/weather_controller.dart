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

      debugPrint('Fetching weather data...');

      // WeatherService now automatically includes agriculture recommendations
      final weather = await _weatherService.getCurrentWeather();
      currentWeather.value = weather;

      debugPrint('Current weather loaded: ${weather?.location}');

      // WeatherService now automatically includes agriculture recommendations
      final forecastData = await _weatherService.getWeatherForecast();
      forecast.value = forecastData;

      debugPrint('Forecast loaded: ${forecastData.length} days');
    } catch (e) {
      debugPrint('Error in fetchWeatherData: $e');
      // Create demo data - WeatherModel.demo already includes demo agriculture recommendations
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
    // Use the enhanced demo constructor that includes agriculture recommendations
    final demoWeather = WeatherModel.demo(
      location: 'Punjab, Pakistan',
      temperature: 31.5,
      description: 'clear sky',
      humidity: 40.0,
      windSpeed: 1.8,
      dateTime: DateTime.now(),
      icon: '☀️',
    );

    currentWeather.value = demoWeather;

    // Create demo forecast using the demo constructor
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

  // Agriculture Rule Engine
  List<AgricultureRecommendation> getAgricultureRecommendations(
    WeatherModel weather,
  ) {
    final recommendations = <AgricultureRecommendation>[];

    // Rule 1: Harvesting Conditions
    if (_isGoodForHarvesting(weather)) {
      recommendations.add(
        AgricultureRecommendation(
          category: 'harvesting',
          title: 'Ideal Harvesting Conditions',
          description: 'Perfect weather for crop harvesting operations',
          isRecommended: true,
          priority: 'high',
          actions: [
            'Proceed with wheat/rice harvesting',
            'Spread grains for sun drying',
            'Good for hay making and fodder preparation',
            'Check moisture content before storage',
          ],
          riskLevel: 'low',
        ),
      );
    } else {
      recommendations.add(
        AgricultureRecommendation(
          category: 'harvesting',
          title: 'Poor Harvesting Conditions',
          description: 'Weather not suitable for harvesting',
          isRecommended: false,
          priority: 'medium',
          actions: [
            'Delay harvesting operations',
            'Monitor weather for improvement',
            'Prepare harvesting equipment',
          ],
          riskLevel: 'medium',
        ),
      );
    }

    // Rule 2: Spraying Conditions
    if (_isGoodForSpraying(weather)) {
      recommendations.add(
        AgricultureRecommendation(
          category: 'spraying',
          title: 'Optimal Spraying Conditions',
          description: 'Safe for pesticide and herbicide application',
          isRecommended: true,
          priority: 'high',
          actions: [
            'Safe for pesticide application',
            'Low drift risk - efficient spraying',
            'Good absorption conditions',
            'Ideal for fungicide application if needed',
          ],
          riskLevel: 'low',
        ),
      );
    } else {
      recommendations.add(
        AgricultureRecommendation(
          category: 'spraying',
          title: 'Avoid Spraying',
          description: 'Weather conditions not suitable for spraying',
          isRecommended: false,
          priority: 'medium',
          actions: [
            'Delay chemical applications',
            'High drift risk detected',
            'Wait for calmer weather conditions',
          ],
          riskLevel: 'high',
        ),
      );
    }

    // Rule 3: Irrigation Advice
    recommendations.add(_getIrrigationRecommendation(weather));

    // Rule 4: Disease Risk Assessment
    recommendations.add(_getDiseaseRiskRecommendation(weather));

    // Rule 5: General Farming Operations
    recommendations.add(_getGeneralFarmingRecommendation(weather));

    // Rule 6: Livestock Management
    recommendations.add(_getLivestockRecommendation(weather));

    return recommendations;
  }

  bool _isGoodForHarvesting(WeatherModel weather) {
    return weather.temperature > 20 &&
        weather.temperature < 35 &&
        weather.windSpeed < 15 &&
        !weather.description.toLowerCase().contains('rain') &&
        weather.humidity < 70;
  }

  bool _isGoodForSpraying(WeatherModel weather) {
    return weather.windSpeed < 10 &&
        weather.temperature > 15 &&
        weather.temperature < 30 &&
        !weather.description.toLowerCase().contains('rain') &&
        weather.humidity > 40 &&
        weather.humidity < 80;
  }

  AgricultureRecommendation _getIrrigationRecommendation(WeatherModel weather) {
    if (weather.temperature > 30 && weather.humidity < 50) {
      return AgricultureRecommendation(
        category: 'irrigation',
        title: 'Increased Irrigation Needed',
        description: 'High temperature and low humidity increase water demand',
        isRecommended: true,
        priority: 'high',
        actions: [
          'Increase irrigation frequency',
          'Water in early morning or late evening',
          'Monitor soil moisture daily',
          'Check for signs of water stress in crops',
        ],
        riskLevel: 'medium',
      );
    } else if (weather.humidity > 80) {
      return AgricultureRecommendation(
        category: 'irrigation',
        title: 'Reduce Irrigation',
        description: 'High humidity reduces water requirement',
        isRecommended: false,
        priority: 'medium',
        actions: [
          'Reduce irrigation frequency',
          'Avoid overwatering',
          'Monitor for fungal diseases',
          'Improve field drainage if needed',
        ],
        riskLevel: 'low',
      );
    } else {
      return AgricultureRecommendation(
        category: 'irrigation',
        title: 'Normal Irrigation Schedule',
        description: 'Maintain regular irrigation routine',
        isRecommended: true,
        priority: 'low',
        actions: [
          'Continue with standard irrigation',
          'Monitor soil moisture levels',
          'Adjust based on crop growth stage',
        ],
        riskLevel: 'low',
      );
    }
  }

  AgricultureRecommendation _getDiseaseRiskRecommendation(
    WeatherModel weather,
  ) {
    if (weather.humidity > 85 && weather.temperature > 20) {
      return AgricultureRecommendation(
        category: 'disease',
        title: 'High Disease Risk Alert',
        description: 'Conditions favorable for fungal diseases',
        isRecommended: false,
        priority: 'high',
        actions: [
          'Monitor for powdery mildew and rust',
          'Consider preventive fungicide',
          'Improve air circulation in fields',
          'Avoid overhead irrigation',
        ],
        riskLevel: 'high',
      );
    } else if (weather.humidity < 50) {
      return AgricultureRecommendation(
        category: 'disease',
        title: 'Low Disease Risk',
        description: 'Unfavorable conditions for disease development',
        isRecommended: true,
        priority: 'low',
        actions: [
          'Low fungal disease pressure',
          'Reduce fungicide applications',
          'Focus on other farm operations',
        ],
        riskLevel: 'low',
      );
    } else {
      return AgricultureRecommendation(
        category: 'disease',
        title: 'Moderate Disease Risk',
        description: 'Monitor crops for disease symptoms',
        isRecommended: true,
        priority: 'medium',
        actions: [
          'Regular field scouting',
          'Watch for early disease signs',
          'Prepare fungicides if needed',
        ],
        riskLevel: 'medium',
      );
    }
  }

  AgricultureRecommendation _getGeneralFarmingRecommendation(
    WeatherModel weather,
  ) {
    if (weather.description.toLowerCase().contains('clear') &&
        weather.temperature > 25) {
      return AgricultureRecommendation(
        category: 'general',
        title: 'Excellent Field Conditions',
        description: 'Ideal weather for most farming operations',
        isRecommended: true,
        priority: 'high',
        actions: [
          'Good for land preparation',
          'Ideal for planting operations',
          'Excellent for fieldwork',
          'Good drying conditions for crops',
        ],
        riskLevel: 'low',
      );
    } else {
      return AgricultureRecommendation(
        category: 'general',
        title: 'Moderate Field Conditions',
        description: 'Suitable for most farming activities with precautions',
        isRecommended: true,
        priority: 'medium',
        actions: [
          'Plan outdoor work accordingly',
          'Monitor weather changes',
          'Take appropriate precautions',
        ],
        riskLevel: 'medium',
      );
    }
  }

  AgricultureRecommendation _getLivestockRecommendation(WeatherModel weather) {
    if (weather.temperature > 30) {
      return AgricultureRecommendation(
        category: 'livestock',
        title: 'Livestock Heat Stress Alert',
        description: 'High temperatures may stress animals',
        isRecommended: false,
        priority: 'high',
        actions: [
          'Provide ample shade and water',
          'Avoid handling animals during peak heat',
          'Monitor for signs of heat stress',
          'Adjust feeding schedules to cooler hours',
        ],
        riskLevel: 'high',
      );
    } else {
      return AgricultureRecommendation(
        category: 'livestock',
        title: 'Good Livestock Conditions',
        description: 'Comfortable weather for animals',
        isRecommended: true,
        priority: 'low',
        actions: [
          'Maintain regular care routine',
          'Ensure clean water supply',
          'Good conditions for outdoor grazing',
        ],
        riskLevel: 'low',
      );
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
