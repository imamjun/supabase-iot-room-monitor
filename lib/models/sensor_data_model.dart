class SensorData {
  final int? id;
  final DateTime createdAt;
  final double temperature;
  final double humidity;

  SensorData({
    this.id,
    required this.createdAt,
    required this.temperature,
    required this.humidity,
  });

  // Factory constructor untuk melakukan deserialisasi JSON ke Objek (OOP)
  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      id: json['id'] as int?,
      createdAt: DateTime.parse(json['created_at']),
      temperature: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
    );
  }
}