import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/data/models/weather_model.dart';
import '../controllers/weather_controller.dart';
import '../../../app/widgets/custom_card.dart';
import '../../../app/widgets/custom_button.dart';
import '../../../core/utils/responsive_helper.dart';

class WeatherView extends GetView<WeatherController> {
  const WeatherView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('weather_advisory'.tr),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('loading_weather'.tr),
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
              'failed_load_weather'.tr,
              style: Get.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'check_internet'.tr,
              textAlign: TextAlign.center,
              style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey),
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
    return SafeArea(
      top: false,
      child: ResponsiveHelper.tabletCenter(
        child: RefreshIndicator(
          onRefresh: () => controller.refreshWeather(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCurrentWeatherCard(weather),
                const SizedBox(height: 24),
                _buildAgricultureAdvisoryCard(weather),
                const SizedBox(height: 24),
                _buildForecastCard(),
                const SizedBox(height: 16),
                _buildLastUpdatedInfo(),
              ],
            ),
          ),
        ),
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
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  weather.location,
                  style: Get.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
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
                      style: Get.textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildWeatherDetails(weather),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(40),
                ),
                alignment: Alignment.center,
                child: Text(
                  weather.icon,
                  style: const TextStyle(fontSize: 40),
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
          label: 'Wind Speed',
          value: controller.getWindSpeedDisplay(weather.windSpeed),
        ),
      ],
    );
  }

  Widget _buildWeatherDetail({required IconData icon, required String label, required String value}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Get.theme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: Get.theme.primaryColor),
        ),
        const SizedBox(height: 8),
        Text(value, style: Get.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        )),
        const SizedBox(height: 2),
        Text(
          label,
          style: Get.textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAgricultureAdvisoryCard(WeatherModel weather) {
    final agricultureRecs = weather.agricultureRecommendations;
    if (agricultureRecs.isEmpty) {
      return _buildDefaultRecommendationsCard(weather);
    }

    return CustomCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.agriculture, color: Get.theme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Smart Farming Advisory',
                style: Get.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'AI-powered recommendations based on current weather',
            style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),

          // Agriculture Risk Overview
          _buildRiskOverview(agricultureRecs),
          const SizedBox(height: 16),

          // Detailed Recommendations
          Column(
            children: agricultureRecs.map((rec) => _buildAgricultureRecommendationItem(rec)).toList(),
          ),

          const SizedBox(height: 12),
          _buildAgricultureFooter(),
        ],
      ),
    );
  }

  Widget _buildDefaultRecommendationsCard(WeatherModel weather) {
    return CustomCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.agriculture, color: Get.theme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Farming Recommendations',
                style: Get.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Based on current weather conditions',
            style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Column(
            children: weather.recommendations.map((rec) => _buildRecommendationItem(rec)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskOverview(List<AgricultureRecommendation> recommendations) {
    final highRiskCount = recommendations.where((rec) => rec.riskLevel == 'high').length;
    final mediumRiskCount = recommendations.where((rec) => rec.riskLevel == 'medium').length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highRiskCount > 0 ? Colors.orange.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highRiskCount > 0 ? Colors.orange.shade200 : Colors.green.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            highRiskCount > 0 ? Icons.warning : Icons.check_circle,
            color: highRiskCount > 0 ? Colors.orange : Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  highRiskCount > 0 ? 'Attention Required' : 'Favorable Conditions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: highRiskCount > 0 ? Colors.orange.shade800 : Colors.green.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  highRiskCount > 0
                      ? '$highRiskCount high-risk condition${highRiskCount > 1 ? 's' : ''} detected'
                      : 'Good conditions for farming activities',
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: highRiskCount > 0 ? Colors.orange.shade700 : Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgricultureRecommendationItem(AgricultureRecommendation rec) {
    final color = rec.isRecommended ? Colors.green.shade800 : Colors.orange.shade800;
    final bgColor = rec.isRecommended ? Colors.green.shade50 : Colors.orange.shade50;
    final borderColor = rec.isRecommended ? Colors.green.shade200 : Colors.orange.shade200;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with priority and risk
          Row(
            children: [
              Text(
                controller.getAgricultureCategoryIcon(rec.category),
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rec.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Text(
                      controller.getAgriculturePriorityIcon(rec.priority),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rec.priority.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Description
          Text(
            rec.description,
            style: Get.textTheme.bodyMedium?.copyWith(
              height: 1.4,
            ),
          ),

          const SizedBox(height: 8),

          // Risk Level
          Row(
            children: [
              Text(
                'Risk Level: ',
                style: Get.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                rec.riskLevel.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Text(controller.getRiskLevelColor(rec.riskLevel)),
            ],
          ),

          const SizedBox(height: 8),

          // Actions list
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rec.actions.map((action) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      rec.isRecommended ? Icons.check_circle : Icons.info,
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        action,
                        style: Get.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAgricultureFooter() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Recommendations update automatically with weather changes',
              style: Get.textTheme.bodySmall?.copyWith(
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(WeatherRecommendation recommendation) {
    final isRecommended = recommendation.isRecommended;
    final color = isRecommended ? Colors.green.shade800 : Colors.orange.shade800;
    final bgColor = isRecommended ? Colors.green.shade50 : Colors.orange.shade50;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getCategoryIcon(recommendation.category),
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getCategoryTitle(recommendation.category),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  controller.getRecommendationText(recommendation),
                  style: Get.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryTitle(String category) {
    switch (category) {
      case 'watering':
        return 'Watering Advice';
      case 'spraying':
        return 'Spraying Recommendation';
      case 'harvesting':
        return 'Harvesting Guidance';
      case 'general':
        return 'General Farming Tip';
      default:
        return 'Farming Advice';
    }
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
        return Icons.lightbulb_outline;
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
            Row(
              children: [
                Icon(Icons.calendar_today, color: Get.theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  '5-Day Forecast',
                  style: Get.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Weather outlook for the coming days',
              style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: forecast.length,
              itemBuilder: (context, index) {
                final day = forecast[index];
                return _buildForecastItem(day, index);
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _buildForecastItem(WeatherModel weather, int index) {
    final isToday = index == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isToday ? Get.theme.primaryColor.withOpacity(0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isToday ? Border.all(color: Get.theme.primaryColor.withOpacity(0.2)) : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? 'Today' : DateFormat('EEE').format(weather.dateTime),
                  style: Get.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM d').format(weather.dateTime),
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  controller.getTemperatureDisplay(weather.temperature),
                  style: Get.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  toTitleCase(weather.description),
                  textAlign: TextAlign.right,
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdatedInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            'Last updated: ${DateFormat('hh:mm a').format(DateTime.now())}',
            style: Get.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
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