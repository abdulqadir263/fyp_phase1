/// Model representing a crop document from Firestore 'crops' collection.
/// Each crop has min/max/mean values for 7 parameters used in scoring.
class CropModel {
  final String id;
  final String name;

  // Nitrogen
  final double minN;
  final double maxN;
  final double meanN;

  // Phosphorus
  final double minP;
  final double maxP;
  final double meanP;

  // Potassium
  final double minK;
  final double maxK;
  final double meanK;

  // Temperature
  final double minTemperature;
  final double maxTemperature;
  final double meanTemperature;

  // Humidity
  final double minHumidity;
  final double maxHumidity;
  final double meanHumidity;

  // pH
  final double minPH;
  final double maxPH;
  final double meanPH;

  // Rainfall
  final double minRainfall;
  final double maxRainfall;
  final double meanRainfall;

  CropModel({
    required this.id,
    required this.name,
    required this.minN,
    required this.maxN,
    required this.meanN,
    required this.minP,
    required this.maxP,
    required this.meanP,
    required this.minK,
    required this.maxK,
    required this.meanK,
    required this.minTemperature,
    required this.maxTemperature,
    required this.meanTemperature,
    required this.minHumidity,
    required this.maxHumidity,
    required this.meanHumidity,
    required this.minPH,
    required this.maxPH,
    required this.meanPH,
    required this.minRainfall,
    required this.maxRainfall,
    required this.meanRainfall,
  });

  /// Create CropModel from Firestore document snapshot.
  factory CropModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return CropModel(
      id: docId ?? json['id'] ?? '',
      name: json['name'] ?? json['label'] ?? '',
      minN: _toDouble(json['minN']),
      maxN: _toDouble(json['maxN']),
      meanN: _toDouble(json['meanN']),
      minP: _toDouble(json['minP']),
      maxP: _toDouble(json['maxP']),
      meanP: _toDouble(json['meanP']),
      minK: _toDouble(json['minK']),
      maxK: _toDouble(json['maxK']),
      meanK: _toDouble(json['meanK']),
      minTemperature: _toDouble(json['minTemperature']),
      maxTemperature: _toDouble(json['maxTemperature']),
      meanTemperature: _toDouble(json['meanTemperature']),
      minHumidity: _toDouble(json['minHumidity']),
      maxHumidity: _toDouble(json['maxHumidity']),
      meanHumidity: _toDouble(json['meanHumidity']),
      minPH: _toDouble(json['minPH']),
      maxPH: _toDouble(json['maxPH']),
      meanPH: _toDouble(json['meanPH']),
      minRainfall: _toDouble(json['minRainfall']),
      maxRainfall: _toDouble(json['maxRainfall']),
      meanRainfall: _toDouble(json['meanRainfall']),
    );
  }

  /// Safely parse a dynamic value to double.
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}


