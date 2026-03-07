import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/data/models/weather_model.dart';
import '../../../app/widgets/custom_card.dart';
import '../../../core/utils/responsive_helper.dart';
import '../controllers/weather_controller.dart';

class WeatherDetailView extends GetView<WeatherController> {
  const WeatherDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final WeatherModel weather = Get.arguments as WeatherModel;

    return Scaffold(
      appBar: AppBar(
        title: Text('weather_details'.tr),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveHelper.tabletCenter(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weather Header
            _buildWeatherHeader(weather),
            const SizedBox(height: 24),

            // Current Conditions
            _buildCurrentConditions(weather),
            const SizedBox(height: 24),

            // Weather Details
            _buildWeatherDetailsSection(weather),
            const SizedBox(height: 24),

            // Agriculture Recommendations
            _buildAgricultureAdvisorySection(weather),
            const SizedBox(height: 16),
          ],
        ),
      ),
      ),
      ),
    );
  }

  Widget _buildWeatherHeader(WeatherModel weather) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(Get.context!).primaryColor,
            Theme.of(Get.context!).primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, color: Colors.white.withOpacity(0.9), size: 20),
              const SizedBox(width: 8),
              Text(
                weather.location,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('EEEE, MMMM d, yyyy').format(weather.dateTime),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Updated: ${DateFormat('hh:mm a').format(weather.dateTime)}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentConditions(WeatherModel weather) {
    return CustomCard(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Conditions',
                      style: Get.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      toTitleCase(weather.description),
                      style: Get.textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(35),
                ),
                alignment: Alignment.center,
                child: Text(
                  weather.icon,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Get.theme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                controller.getTemperatureDisplay(weather.temperature),
                style: Get.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Get.theme.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetailsSection(WeatherModel weather) {
    return CustomCard(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weather Details',
            style: Get.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildWeatherDetailRow('Temperature', controller.getTemperatureDisplay(weather.temperature), Icons.thermostat),
          const SizedBox(height: 12),
          _buildWeatherDetailRow('Humidity', '${weather.humidity.toStringAsFixed(0)}%', Icons.water_drop),
          const SizedBox(height: 12),
          _buildWeatherDetailRow('Wind Speed', controller.getWindSpeedDisplay(weather.windSpeed), Icons.air),
          const SizedBox(height: 12),
          _buildWeatherDetailRow('Conditions', toTitleCase(weather.description), Icons.cloud),
        ],
      ),
    );
  }

  Widget _buildWeatherDetailRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Get.theme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Get.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: Get.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgricultureAdvisorySection(WeatherModel weather) {
    final agricultureRecs = weather.agricultureRecommendations;

    if (agricultureRecs.isEmpty) {
      return _buildDefaultRecommendations(weather);
    }

    return CustomCard(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.agriculture, color: Get.theme.primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Smart Farming Advisory',
                style: Get.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Comprehensive agriculture recommendations based on current weather analysis',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),

          // Agriculture Rules Summary
          _buildAgricultureRulesSummary(agricultureRecs),
          const SizedBox(height: 20),

          // Detailed Recommendations
          Column(
            children: agricultureRecs.map((recommendation) {
              return _buildDetailedAgricultureItem(recommendation);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultRecommendations(WeatherModel weather) {
    if (weather.recommendations.isEmpty) {
      return CustomCard(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(Icons.agriculture, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No Specific Recommendations',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current weather conditions are generally favorable for farming activities.',
              textAlign: TextAlign.center,
              style: Get.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return CustomCard(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Get.theme.primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Farming Recommendations',
                style: Get.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Expert advice based on current weather conditions',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),

          // Recommendations list
          Column(
            children: weather.recommendations.map((recommendation) {
              return _buildDetailedRecommendationItem(recommendation);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAgricultureRulesSummary(List<AgricultureRecommendation> recs) {
    final activeRules = recs.length;
    final highPriority = recs.where((rec) => rec.priority == 'high').length;
    final recommended = recs.where((rec) => rec.isRecommended).length;
    final highRisk = recs.where((rec) => rec.riskLevel == 'high').length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highRisk > 0 ? Colors.orange.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highRisk > 0 ? Colors.orange.shade200 : Colors.blue.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Active Rules', activeRules.toString(), Icons.rule),
              _buildSummaryItem('High Priority', highPriority.toString(), Icons.priority_high),
              _buildSummaryItem('Recommended', recommended.toString(), Icons.check_circle),
            ],
          ),
          if (highRisk > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade800, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '$highRisk high-risk condition${highRisk > 1 ? 's' : ''} need attention',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: Colors.blue.shade700),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: Get.textTheme.bodySmall?.copyWith(
            color: Colors.blue.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedAgricultureItem(AgricultureRecommendation recommendation) {
    final isRecommended = recommendation.isRecommended;
    final color = isRecommended ? Colors.green.shade800 : Colors.orange.shade800;
    final bgColor = isRecommended ? Colors.green.shade50 : Colors.orange.shade50;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status and priority
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      controller.getAgricultureCategoryIcon(recommendation.category),
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        recommendation.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
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
                      controller.getAgriculturePriorityIcon(recommendation.priority),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      recommendation.priority.toUpperCase(),
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
            recommendation.description,
            style: Get.textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),

          const SizedBox(height: 12),

          // Risk Level
          Row(
            children: [
              Text(
                'Risk Level: ',
                style: Get.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                recommendation.riskLevel.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(controller.getRiskLevelColor(recommendation.riskLevel)),
            ],
          ),

          const SizedBox(height: 12),

          // Recommended Actions
          Text(
            'Recommended Actions:',
            style: Get.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            children: recommendation.actions.map((action) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.arrow_right,
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        action,
                        style: Get.textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isRecommended ? 'RECOMMENDED' : 'NOT RECOMMENDED',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedRecommendationItem(WeatherRecommendation recommendation) {
    final isRecommended = recommendation.isRecommended;
    final color = isRecommended ? Colors.green.shade800 : Colors.orange.shade800;
    final bgColor = isRecommended ? Colors.green.shade50 : Colors.orange.shade50;
    final icon = isRecommended ? Icons.check_circle : Icons.info;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getCategoryTitle(recommendation.category),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  controller.getRecommendationText(recommendation),
                  style: Get.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isRecommended ? 'RECOMMENDED' : 'NOT RECOMMENDED',
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
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

  String toTitleCase(String text) {
    if (text.isEmpty) return "";
    return text.split(' ').map((word) {
      if (word.isEmpty) return "";
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}