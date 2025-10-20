import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/data/models/weather_model.dart';
import '../../../app/widgets/custom_card.dart';
import '../controllers/weather_controller.dart';

class WeatherDetailView extends GetView<WeatherController> {
  // ✅ FIX: Constructor ko 'const' banaya hai.
  const WeatherDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final WeatherModel weather = Get.arguments as WeatherModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weather Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    weather.location,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${weather.dateTime.day}/${weather.dateTime.month}/${weather.dateTime.year}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Weather Details
            _buildWeatherDetailCard('Temperature', controller.getTemperatureDisplay(weather.temperature)),
            const SizedBox(height: 12),
            _buildWeatherDetailCard('Humidity', '${weather.humidity.toStringAsFixed(0)}%'),
            const SizedBox(height: 12),
            _buildWeatherDetailCard('Wind Speed', '${weather.windSpeed.toStringAsFixed(1)} m/s'),
            const SizedBox(height: 12),
            _buildWeatherDetailCard('Description', weather.description),

            const SizedBox(height: 24),

            // Recommendations
            _buildDetailedRecommendations(context, weather),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetailCard(String label, String value) {
    return CustomCard(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDetailedRecommendations(BuildContext context, WeatherModel weather) {
    return CustomCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Farming Recommendations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Recommendations list
          ...weather.recommendations.map((recommendation) {
            return _buildDetailedRecommendationItem(recommendation);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDetailedRecommendationItem(WeatherRecommendation recommendation) {
    final isRecommended = recommendation.isRecommended;
    final color = isRecommended ? Colors.green.shade800 : Colors.red.shade800;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isRecommended ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column( // ✅ FIX: Column ke andar structure aab theek hai.
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getCategoryIcon(recommendation.category),
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  recommendation.category.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            controller.getRecommendationText(recommendation),
            style: TextStyle(color: color),
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
        return Icons.spa; // ✅ FIX: Behtar icon
      case 'harvesting':
        return Icons.agriculture;
      default:
        return Icons.info;
    }
  }
}