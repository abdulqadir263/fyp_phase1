import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../models/weather_model.dart';

class WeatherService extends GetxService {
  final String _baseUrl = 'https://api.open-meteo.com/v1';

  // Get current weather by coordinates
  Future<WeatherModel?> getCurrentWeather({double? lat, double? lon}) async {
    try {
      // Get user location if not provided
      if (lat == null || lon == null) {
        Position? position = await _getUserLocation();
        if (position == null) {
          // Use default coordinates (Lahore, Pakistan) if location not available
          lat = 31.5204;
          lon = 74.3587;
        } else {
          lat = position.latitude;
          lon = position.longitude;
        }
      }

      final url =
          '$_baseUrl/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code&hourly=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto';

      debugPrint('Fetching weather from: $url');

      final response = await http.get(Uri.parse(url));

      debugPrint('Weather API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Extract current weather data
        final current = data['current'];
        final hourly = data['hourly'];

        // Get current temperature or use first available
        double temperature =
            current?['temperature_2m']?.toDouble() ??
            hourly['temperature_2m'][0]?.toDouble() ??
            20.0;

        double humidity =
            current?['relative_humidity_2m']?.toDouble() ??
            hourly['relative_humidity_2m'][0]?.toDouble() ??
            50.0;

        double windSpeed =
            current?['wind_speed_10m']?.toDouble() ??
            hourly['wind_speed_10m'][0]?.toDouble() ??
            5.0;

        int weatherCode =
            current?['weather_code'] ?? hourly['weather_code'][0] ?? 0;

        // Generate location name based on coordinates (simplified)
        String locationName = await _getLocationName(lat, lon);

        // Generate AI recommendations
        final recommendations = await _generateRecommendations(
          temperature: temperature,
          humidity: humidity,
          windSpeed: windSpeed,
          weatherCode: weatherCode,
        );

        // Generate agriculture recommendations
        final agricultureRecommendations =
            await _generateAgricultureRecommendations(
              temperature: temperature,
              humidity: humidity,
              windSpeed: windSpeed,
              weatherCode: weatherCode,
            );

        return WeatherModel(
          id: DateTime.now().toString(),
          location: locationName,
          temperature: temperature,
          humidity: humidity,
          windSpeed: windSpeed,
          description: _getWeatherDescription(weatherCode),
          icon: _getWeatherIcon(weatherCode),
          dateTime: DateTime.now(),
          recommendations: recommendations,
          agricultureRecommendations: agricultureRecommendations,
        );
      } else {
        debugPrint(
          'Weather API Error: ${response.statusCode} - ${response.body}',
        );
        // Return mock data if API fails
        return _getMockWeatherData();
      }
    } catch (e) {
      debugPrint('Error fetching weather: $e');
      // Return mock data as fallback
      return _getMockWeatherData();
    }
  }

  // Get 5-day forecast
  Future<List<WeatherModel>> getWeatherForecast({
    double? lat,
    double? lon,
  }) async {
    try {
      // Get user location if not provided
      if (lat == null || lon == null) {
        Position? position = await _getUserLocation();
        if (position == null) {
          lat = 31.5204;
          lon = 74.3587;
        } else {
          lat = position.latitude;
          lon = position.longitude;
        }
      }

      final url =
          '$_baseUrl/forecast?latitude=$lat&longitude=$lon&daily=weather_code,temperature_2m_max,temperature_2m_min,wind_speed_10m_max&timezone=auto';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<WeatherModel> forecast = [];
        final daily = data['daily'];

        // Get forecast for next 5 days
        for (int i = 0; i < 5 && i < daily['time'].length; i++) {
          final weatherCode = daily['weather_code'][i] ?? 0;
          final maxTemp = daily['temperature_2m_max'][i]?.toDouble() ?? 25.0;
          final minTemp = daily['temperature_2m_min'][i]?.toDouble() ?? 15.0;
          final avgTemp = (maxTemp + minTemp) / 2;
          final windSpeed = daily['wind_speed_10m_max'][i]?.toDouble() ?? 5.0;

          final recommendations = await _generateRecommendations(
            temperature: avgTemp,
            humidity: 60.0, // Default humidity for forecast
            windSpeed: windSpeed,
            weatherCode: weatherCode,
          );

          final agricultureRecommendations =
              await _generateAgricultureRecommendations(
                temperature: avgTemp,
                humidity: 60.0,
                windSpeed: windSpeed,
                weatherCode: weatherCode,
              );

          forecast.add(
            WeatherModel(
              id: 'forecast_$i',
              location: 'Forecast',
              temperature: avgTemp,
              humidity: 60.0,
              windSpeed: windSpeed,
              description: _getWeatherDescription(weatherCode),
              icon: _getWeatherIcon(weatherCode),
              dateTime: DateTime.parse(daily['time'][i]),
              recommendations: recommendations,
              agricultureRecommendations: agricultureRecommendations,
            ),
          );
        }

        return forecast;
      } else {
        debugPrint('Forecast API Error: ${response.statusCode}');
        return _getMockForecastData();
      }
    } catch (e) {
      debugPrint('Error fetching forecast: $e');
      return _getMockForecastData();
    }
  }

  // Generate Agriculture Recommendations based on weather conditions
  Future<List<AgricultureRecommendation>> _generateAgricultureRecommendations({
    required double temperature,
    required double humidity,
    required double windSpeed,
    required int weatherCode,
  }) async {
    final List<AgricultureRecommendation> recommendations = [];

    // Rule 1: Harvesting Conditions
    if (_isGoodForHarvesting(temperature, humidity, windSpeed, weatherCode)) {
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
    if (_isGoodForSpraying(temperature, humidity, windSpeed, weatherCode)) {
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
    recommendations.add(_getIrrigationRecommendation(temperature, humidity));

    // Rule 4: Disease Risk Assessment
    recommendations.add(_getDiseaseRiskRecommendation(temperature, humidity));

    // Rule 5: General Farming Operations
    recommendations.add(
      _getGeneralFarmingRecommendation(temperature, weatherCode),
    );

    // Rule 6: Livestock Management
    recommendations.add(_getLivestockRecommendation(temperature));

    return recommendations;
  }

  bool _isGoodForHarvesting(
    double temperature,
    double humidity,
    double windSpeed,
    int weatherCode,
  ) {
    final isRaining = weatherCode >= 51 && weatherCode <= 82;
    return temperature > 20 &&
        temperature < 35 &&
        windSpeed < 15 &&
        !isRaining &&
        humidity < 70;
  }

  bool _isGoodForSpraying(
    double temperature,
    double humidity,
    double windSpeed,
    int weatherCode,
  ) {
    final isRaining = weatherCode >= 51 && weatherCode <= 82;
    return windSpeed < 10 &&
        temperature > 15 &&
        temperature < 30 &&
        !isRaining &&
        humidity > 40 &&
        humidity < 80;
  }

  AgricultureRecommendation _getIrrigationRecommendation(
    double temperature,
    double humidity,
  ) {
    if (temperature > 30 && humidity < 50) {
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
    } else if (humidity > 80) {
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
    double temperature,
    double humidity,
  ) {
    if (humidity > 85 && temperature > 20) {
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
    } else if (humidity < 50) {
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
    double temperature,
    int weatherCode,
  ) {
    final isClearSky = weatherCode == 0;
    if (isClearSky && temperature > 25) {
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

  AgricultureRecommendation _getLivestockRecommendation(double temperature) {
    if (temperature > 30) {
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

  // FIXED: Improved location handling with proper timeout
  Future<Position?> _getUserLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return null;
      }

      // Check location permissions
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return null;
      }

      // Get current position with proper timeout handling
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        ).timeout(const Duration(seconds: 10));
        return position;
      } catch (e) {
        debugPrint('Error getting position: $e');
        return null;
      }
    } catch (e) {
      debugPrint('Error in location service: $e');
      return null;
    }
  }

  // Get location name from coordinates (simplified version)
  Future<String> _getLocationName(double lat, double lon) async {
    // Simplified location naming based on coordinates
    if (lat >= 31.0 && lat <= 34.0 && lon >= 73.0 && lon <= 75.0) {
      return 'Punjab, Pakistan';
    } else if (lat >= 24.0 && lat <= 27.0 && lon >= 67.0 && lon <= 71.0) {
      return 'Sindh, Pakistan';
    } else {
      return 'Current Location';
    }
  }

  // Convert weather code to description
  String _getWeatherDescription(int weatherCode) {
    switch (weatherCode) {
      case 0:
        return 'Clear sky';
      case 1:
      case 2:
      case 3:
        return 'Partly cloudy';
      case 45:
      case 48:
        return 'Foggy';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 61:
      case 63:
      case 65:
        return 'Rain';
      case 71:
      case 73:
      case 75:
        return 'Snow fall';
      case 80:
      case 81:
      case 82:
        return 'Rain showers';
      case 95:
        return 'Thunderstorm';
      default:
        return 'Unknown';
    }
  }

  // Convert weather code to icon - Use emojis instead of URLs
  String _getWeatherIcon(int weatherCode) {
    switch (weatherCode) {
      case 0:
        return '☀️'; // Clear sky
      case 1:
      case 2:
      case 3:
        return '⛅'; // Partly cloudy
      case 45:
      case 48:
        return '🌫️'; // Fog
      case 51:
      case 53:
      case 55:
        return '🌦️'; // Drizzle
      case 61:
      case 63:
      case 65:
        return '🌧️'; // Rain
      case 71:
      case 73:
      case 75:
        return '🌨️'; // Snow
      case 80:
      case 81:
      case 82:
        return '⛈️'; // Rain showers
      case 95:
        return '⛈️'; // Thunderstorm
      default:
        return '🌈'; // Default
    }
  }

  // Generate AI-based recommendations
  Future<List<WeatherRecommendation>> _generateRecommendations({
    required double temperature,
    required double humidity,
    required double windSpeed,
    required int weatherCode,
  }) async {
    final List<WeatherRecommendation> recommendations = [];

    // Watering recommendations
    if (temperature > 35) {
      recommendations.add(
        WeatherRecommendation(
          category: 'watering',
          recommendationEn: '🌡️ High temperature! Water plants early morning.',
          recommendationUr:
              '🌡️ زیادہ درجہ حرارت! پودوں کو صبح سویرے پانی دیں۔',
          isRecommended: true,
        ),
      );
    } else if (temperature < 10) {
      recommendations.add(
        WeatherRecommendation(
          category: 'watering',
          recommendationEn: '❄️ Cold weather! Reduce watering frequency.',
          recommendationUr: '❄️ سرد موسم! پانی دینے کی تعداد کم کریں۔',
          isRecommended: false,
        ),
      );
    }

    // Spraying recommendations
    if (windSpeed > 15) {
      recommendations.add(
        WeatherRecommendation(
          category: 'spraying',
          recommendationEn: '💨 High wind! Avoid spraying pesticides.',
          recommendationUr: '💨 تیز ہوا! کیڑے مار دوا کا چھڑکاؤ نہ کریں۔',
          isRecommended: false,
        ),
      );
    } else if (weatherCode >= 61 && weatherCode <= 82) {
      recommendations.add(
        WeatherRecommendation(
          category: 'spraying',
          recommendationEn: '🌧️ Rain expected! Avoid spraying.',
          recommendationUr: '🌧️ بارش متوقع! چھڑکاؤ سے گریز کریں۔',
          isRecommended: false,
        ),
      );
    }

    return recommendations;
  }

  // Mock data for fallback
  WeatherModel _getMockWeatherData() {
    final mockAgricultureRecs =
        AgricultureRecommendation.createDemoRecommendations();

    return WeatherModel(
      id: 'mock_${DateTime.now().toString()}',
      location: 'Lahore, Pakistan',
      temperature: 28.5,
      humidity: 65.0,
      windSpeed: 8.2,
      description: 'Partly cloudy',
      icon: '⛅',
      dateTime: DateTime.now(),
      recommendations: [
        WeatherRecommendation(
          category: 'general',
          recommendationEn: 'Good farming conditions today.',
          recommendationUr: 'آج کاشتکاری کے لیے اچھے حالات ہیں۔',
          isRecommended: true,
        ),
      ],
      agricultureRecommendations: mockAgricultureRecs,
    );
  }

  List<WeatherModel> _getMockForecastData() {
    final mockAgricultureRecs =
        AgricultureRecommendation.createDemoRecommendations();

    return [
      WeatherModel(
        id: 'mock_1',
        location: 'Lahore',
        temperature: 29.0,
        humidity: 60.0,
        windSpeed: 7.0,
        description: 'Sunny',
        icon: '☀️',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        recommendations: [],
        agricultureRecommendations: mockAgricultureRecs,
      ),
      WeatherModel(
        id: 'mock_2',
        location: 'Lahore',
        temperature: 27.5,
        humidity: 65.0,
        windSpeed: 6.0,
        description: 'Partly cloudy',
        icon: '⛅',
        dateTime: DateTime.now().add(const Duration(days: 2)),
        recommendations: [],
        agricultureRecommendations: mockAgricultureRecs,
      ),
    ];
  }
}
