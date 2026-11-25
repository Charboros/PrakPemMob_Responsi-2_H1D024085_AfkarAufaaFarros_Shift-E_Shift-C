/// ============================================================================
/// LAYER MODEL (MVVM) - CurrentWeatherModel
/// ----------------------------------------------------------------------------
/// Menyimpan data cuaca terkini hasil parsing objek `current` dari JSON
/// Open-Meteo Weather Forecast API sesuai field wajib pada soal responsi.
/// ============================================================================
class CurrentWeatherModel {
  final DateTime time;
  final double temperature; // Field API: current.temperature_2m (°C)
  final int relativeHumidity; // Field API: current.relative_humidity_2m (%)
  final double apparentTemperature; // Field API: current.apparent_temperature (°C)
  final double precipitation; // Field API: current.precipitation (mm)
  final int weatherCode; // Field API: current.weather_code (kode kondisi cuaca WMO)
  final double windSpeed; // Field API: current.wind_speed_10m (km/h)

  CurrentWeatherModel({
    required this.time,
    required this.temperature,
    required this.relativeHumidity,
    required this.apparentTemperature,
    required this.precipitation,
    required this.weatherCode,
    required this.windSpeed,
  });

  /// Mengubah map JSON `current` dari respons API menjadi objek Dart yang type-safe
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
