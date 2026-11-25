class CurrentWeatherModel {
  final DateTime time;
  final double temperature; // current.temperature_2m (°C)
  final int relativeHumidity; // current.relative_humidity_2m (%)
  final double apparentTemperature; // current.apparent_temperature (°C)
  final double precipitation; // current.precipitation (mm)
  final int weatherCode; // current.weather_code
  final double windSpeed; // current.wind_speed_10m (km/h)

  CurrentWeatherModel({
    required this.time,
    required this.temperature,
    required this.relativeHumidity,
    required this.apparentTemperature,
    required this.precipitation,
    required this.weatherCode,
    required this.windSpeed,
  });

  factory CurrentWeatherModel.fromJson(Map<String, dynamic> json) {
    return CurrentWeatherModel(
      time: DateTime.tryParse(json['time'] as String? ?? '') ?? DateTime.now(),
      temperature: (json['temperature_2m'] as num?)?.toDouble() ?? 0.0,
      relativeHumidity: (json['relative_humidity_2m'] as num?)?.toInt() ?? 0,
      apparentTemperature: (json['apparent_temperature'] as num?)?.toDouble() ?? 0.0,
      precipitation: (json['precipitation'] as num?)?.toDouble() ?? 0.0,
      weatherCode: (json['weather_code'] as num?)?.toInt() ?? 0,
      windSpeed: (json['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
