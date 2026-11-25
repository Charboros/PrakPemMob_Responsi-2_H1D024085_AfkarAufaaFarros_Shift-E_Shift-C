import 'weather_model.dart';
import 'daily_forecast_model.dart';

/// ============================================================================
/// LAYER MODEL (MVVM) - WeatherResponseModel
/// ----------------------------------------------------------------------------
/// Model pembungkus utama (root response) dari Open-Meteo Weather Forecast API
/// yang menyatukan informasi koordinat, zona waktu, cuaca saat ini (`current`),
/// serta daftar ramalan cuaca beberapa hari ke depan (`daily`).
/// ============================================================================
class WeatherResponseModel {
  final double latitude;
  final double longitude;
  final String timezone;
  final CurrentWeatherModel current;
  final List<DailyForecastModel> daily;

  WeatherResponseModel({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.current,
    required this.daily,
  });

  /// Parsing JSON lengkap dari endpoint `/v1/forecast` ke objek model Dart
  factory WeatherResponseModel.fromJson(Map<String, dynamic> json) {
    return WeatherResponseModel(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      timezone: json['timezone'] as String? ?? 'UTC',
      current: CurrentWeatherModel.fromJson(
        json['current'] as Map<String, dynamic>? ?? {},
      ),
      daily: DailyForecastModel.listFromJson(
        json['daily'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}
