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
  final List<AgricultureRecommendation> agricultureRecommendations;

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
    this.agricultureRecommendations = const [],
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

    final agricultureRecsList = <AgricultureRecommendation>[];
    if (data['agricultureRecommendations'] != null) {
      final agRecList = data['agricultureRecommendations'] as List<dynamic>;
      for (final rec in agRecList) {
        agricultureRecsList.add(AgricultureRecommendation.fromMap(rec));
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
      agricultureRecommendations: agricultureRecsList,
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
      'agricultureRecommendations': agricultureRecommendations.map((rec) => rec.toMap()).toList(),
    };
  }

  // Convenience constructor for creating demo data
  factory WeatherModel.demo({
    String? location,
    double? temperature,
    double? humidity,
    double? windSpeed,
    String? description,
    String? icon,
    DateTime? dateTime,
  }) {
    return WeatherModel(
      id: 'demo',
      location: location ?? 'Punjab, Pakistan',
      temperature: temperature ?? 31.5,
      humidity: humidity ?? 40.0,
      windSpeed: windSpeed ?? 1.8,
      description: description ?? 'clear sky',
      icon: icon ?? '☀️',
      dateTime: dateTime ?? DateTime.now(),
      recommendations: [],
      agricultureRecommendations: [],
    );
  }

  // Copy with method for updating fields
  WeatherModel copyWith({
    String? id,
    String? location,
    double? temperature,
    double? humidity,
    double? windSpeed,
    String? description,
    String? icon,
    DateTime? dateTime,
    List<WeatherRecommendation>? recommendations,
    List<AgricultureRecommendation>? agricultureRecommendations,
  }) {
    return WeatherModel(
      id: id ?? this.id,
      location: location ?? this.location,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      windSpeed: windSpeed ?? this.windSpeed,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      dateTime: dateTime ?? this.dateTime,
      recommendations: recommendations ?? this.recommendations,
      agricultureRecommendations: agricultureRecommendations ?? this.agricultureRecommendations,
    );
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

class AgricultureRule {
  final String id;
  final String name;
  final String category;
  final bool isRecommended;
  final String description;
  final String detailedAdvice;
  final List<String> conditions;

  AgricultureRule({
    required this.id,
    required this.name,
    required this.category,
    required this.isRecommended,
    required this.description,
    required this.detailedAdvice,
    required this.conditions,
  });

  factory AgricultureRule.fromMap(Map<String, dynamic> map) {
    return AgricultureRule(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      isRecommended: map['isRecommended'] ?? true,
      description: map['description'] ?? '',
      detailedAdvice: map['detailedAdvice'] ?? '',
      conditions: List<String>.from(map['conditions'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'isRecommended': isRecommended,
      'description': description,
      'detailedAdvice': detailedAdvice,
      'conditions': conditions,
    };
  }
}

class AgricultureRecommendation {
  final String category;
  final String title;
  final String description;
  final bool isRecommended;
  final String priority; // 'high', 'medium', 'low'
  final List<String> actions;
  final String riskLevel;

  AgricultureRecommendation({
    required this.category,
    required this.title,
    required this.description,
    required this.isRecommended,
    required this.priority,
    required this.actions,
    required this.riskLevel,
  });

  factory AgricultureRecommendation.fromMap(Map<String, dynamic> map) {
    return AgricultureRecommendation(
      category: map['category'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      isRecommended: map['isRecommended'] ?? true,
      priority: map['priority'] ?? 'medium',
      actions: List<String>.from(map['actions'] ?? []),
      riskLevel: map['riskLevel'] ?? 'medium',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'title': title,
      'description': description,
      'isRecommended': isRecommended,
      'priority': priority,
      'actions': actions,
      'riskLevel': riskLevel,
    };
  }

  // Convenience method to create demo agriculture recommendations
  static List<AgricultureRecommendation> createDemoRecommendations() {
    return [
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
          'Check moisture content before storage'
        ],
        riskLevel: 'low',
      ),
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
          'Ideal for fungicide application if needed'
        ],
        riskLevel: 'low',
      ),
      AgricultureRecommendation(
        category: 'irrigation',
        title: 'Normal Irrigation Schedule',
        description: 'Maintain regular irrigation routine',
        isRecommended: true,
        priority: 'low',
        actions: [
          'Continue with standard irrigation',
          'Monitor soil moisture levels',
          'Adjust based on crop growth stage'
        ],
        riskLevel: 'low',
      ),
      AgricultureRecommendation(
        category: 'disease',
        title: 'Low Disease Risk',
        description: 'Unfavorable conditions for disease development',
        isRecommended: true,
        priority: 'low',
        actions: [
          'Low fungal disease pressure',
          'Reduce fungicide applications',
          'Focus on other farm operations'
        ],
        riskLevel: 'low',
      ),
      AgricultureRecommendation(
        category: 'general',
        title: 'Excellent Field Conditions',
        description: 'Ideal weather for most farming operations',
        isRecommended: true,
        priority: 'high',
        actions: [
          'Good for land preparation',
          'Ideal for planting operations',
          'Excellent for fieldwork',
          'Good drying conditions for crops'
        ],
        riskLevel: 'low',
      ),
      AgricultureRecommendation(
        category: 'livestock',
        title: 'Good Livestock Conditions',
        description: 'Comfortable weather for animals',
        isRecommended: true,
        priority: 'low',
        actions: [
          'Maintain regular care routine',
          'Ensure clean water supply',
          'Good conditions for outdoor grazing'
        ],
        riskLevel: 'low',
      ),
    ];
  }
}