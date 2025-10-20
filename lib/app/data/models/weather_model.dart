import 'package:cloud_firestore/cloud_firestore.dart';

class WeatherModel {
  final String id;
  final String location;
  final double temperature;
  final double humidity;
  final double windSpeed;
  final String description;
  final String icon;
  final DateTime dateTime;
  final List<WeatherRecommendation> recommendations;

  WeatherModel({
    required this.id,
    required this.location,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.icon,
    required this.dateTime,
    this.recommendations = const [],
  });

  factory WeatherModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final recommendationsList = <WeatherRecommendation>[];
    if (data['recommendations'] != null) {
      final recList = data['recommendations'] as List<dynamic>;
      for (final rec in recList) {
        recommendationsList.add(WeatherRecommendation.fromMap(rec));
      }
    }

    return WeatherModel(
      id: doc.id,
      location: data['location'] ?? '',
      temperature: (data['temperature'] ?? 0.0).toDouble(),
      humidity: (data['humidity'] ?? 0.0).toDouble(),
      windSpeed: (data['windSpeed'] ?? 0.0).toDouble(),
      description: data['description'] ?? '',
      icon: data['icon'] ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      recommendations: recommendationsList,
    );
  }

  Map<String, dynamic> toDocument() {
    return {
      'location': location,
      'temperature': temperature,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'description': description,
      'icon': icon,
      'dateTime': Timestamp.fromDate(dateTime),
      'recommendations': recommendations.map((rec) => rec.toMap()).toList(),
    };
  }
}

class WeatherRecommendation {
  final String category; // watering, spraying, harvesting, etc.
  final String recommendationEn; // English recommendation
  final String recommendationUr; // Urdu recommendation
  final bool isRecommended; // Whether this action is recommended

  WeatherRecommendation({
    required this.category,
    required this.recommendationEn,
    required this.recommendationUr,
    this.isRecommended = true,
  });

  factory WeatherRecommendation.fromMap(Map<String, dynamic> map) {
    return WeatherRecommendation(
      category: map['category'] ?? '',
      recommendationEn: map['recommendationEn'] ?? '',
      recommendationUr: map['recommendationUr'] ?? '',
      isRecommended: map['isRecommended'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'recommendationEn': recommendationEn,
      'recommendationUr': recommendationUr,
      'isRecommended': isRecommended,
    };
  }
}