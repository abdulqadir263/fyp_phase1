import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/data/models/weather_model.dart';
import '../controllers/weather_controller.dart';
import '../../../app/widgets/custom_card.dart';
import '../../../app/widgets/custom_button.dart';

class WeatherView extends GetView<WeatherController> {
  const WeatherView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Advisory'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: controller.refreshWeather,
          ),
          _buildSettingsMenu(),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.currentWeather.value == null) {
          return _buildLoadingState();
        }

        final currentWeather = controller.currentWeather.value;
        if (currentWeather == null) {
          return _buildErrorState();
        }

        return _buildWeatherContent(currentWeather);
      }),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading weather data...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Failed to load weather data',
              style: Get.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 120,
              child: CustomButton(
                text: 'Retry',
                onPressed: controller.refreshWeather,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherContent(WeatherModel weather) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentWeatherCard(weather),
          const SizedBox(height: 24),
          _buildRecommendationsCard(weather),
          const SizedBox(height: 24),
          _buildForecastCard(),
        ],
      ),
    );
  }

  Widget _buildSettingsMenu() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'language') {
          controller.toggleLanguage();
        } else if (value == 'unit') {
          controller.toggleTemperatureUnit();
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          value: 'language',
          child: Row(
            children: [
              const Icon(Icons.language),
              const SizedBox(width: 8),
              Obx(() => Text(
                  controller.selectedLanguage.value == 'en'
                      ? 'Switch to اردو'
                      : 'انگریزی میں تبدیل کریں'
              )),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'unit',
          child: Row(
            children: [
              const Icon(Icons.thermostat),
              const SizedBox(width: 8),
              Obx(() => Text(
                  controller.isCelsius.value
                      ? 'Use Fahrenheit (°F)'
                      : 'Use Celsius (°C)'
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentWeatherCard(WeatherModel weather) {
    return CustomCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            weather.location,
            style: Get.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.getTemperatureDisplay(weather.temperature),
                      style: Get.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      toTitleCase(weather.description),
                      style: Get.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    _buildWeatherDetails(weather),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Use emoji icons instead of network images
              Container(
                width: 80,
                height: 80,
                alignment: Alignment.center,
                child: Text(
                  weather.icon,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetails(WeatherModel weather) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildWeatherDetail(
          icon: Icons.water_drop,
          label: 'Humidity',
          value: '${weather.humidity.toStringAsFixed(0)}%',
        ),
        _buildWeatherDetail(
          icon: Icons.air,
          label: 'Wind',
          value: '${weather.windSpeed.toStringAsFixed(1)} m/s',
        ),
      ],
    );
  }

  Widget _buildWeatherDetail({required IconData icon, required String label, required String value}) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Get.theme.primaryColor),
        const SizedBox(height: 4),
        Text(value, style: Get.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: Get.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildRecommendationsCard(WeatherModel weather) {
    final recommendations = weather.recommendations;
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return CustomCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Farming Recommendations',
            style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Column(
            children: recommendations.map((rec) => _buildRecommendationItem(rec)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(WeatherRecommendation recommendation) {
    final isRecommended = recommendation.isRecommended;
    final color = isRecommended ? Colors.green.shade800 : Colors.red.shade800;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_getCategoryIcon(recommendation.category), color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              controller.getRecommendationText(recommendation),
              style: Get.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'watering':
        return Icons.water_drop;
      case 'spraying':
        return Icons.spa;
      case 'harvesting':
        return Icons.agriculture;
      default:
        return Icons.info_outline;
    }
  }

  Widget _buildForecastCard() {
    return Obx(() {
      final forecast = controller.forecast;
      if (forecast.isEmpty) {
        return const SizedBox.shrink();
      }

      return CustomCard(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '5-Day Forecast',
              style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: forecast.length,
              itemBuilder: (context, index) {
                final day = forecast[index];
                return _buildForecastItem(day);
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _buildForecastItem(WeatherModel weather) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('EEE').format(weather.dateTime),
              style: Get.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              alignment: Alignment.center,
              child: Text(
                weather.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              controller.getTemperatureDisplay(weather.temperature),
              textAlign: TextAlign.right,
              style: Get.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String toTitleCase(String text) {
    if (text.isEmpty) return "";
    return text.split(' ').map((word) {
      if (word.isEmpty) return "";
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}