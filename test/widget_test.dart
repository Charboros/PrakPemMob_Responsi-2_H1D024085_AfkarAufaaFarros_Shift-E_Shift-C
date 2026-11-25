import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi_cuaca/models/location_model.dart';
import 'package:aplikasi_cuaca/models/weather_model.dart';
import 'package:aplikasi_cuaca/models/daily_forecast_model.dart';
import 'package:aplikasi_cuaca/utils/weather_condition_helper.dart';

void main() {
  group('Weather App Unit Tests', () {
    test('LocationModel serialization & deserialization', () {
      final loc = LocationModel(
        id: 12345,
        name: 'Bandung',
        latitude: -6.9175,
        longitude: 107.6191,
        country: 'Indonesia',
        admin1: 'Jawa Barat',
        timezone: 'Asia/Jakarta',
        isFavorite: true,
      );

      final map = loc.toMap();
      final fromMap = LocationModel.fromMap(map);

      expect(fromMap.id, 12345);
      expect(fromMap.name, 'Bandung');
      expect(fromMap.latitude, -6.9175);
      expect(fromMap.isFavorite, true);
      expect(fromMap.displayName, 'Bandung, Jawa Barat');
    });

    test('CurrentWeatherModel JSON parsing', () {
      final json = {
        'time': '2026-11-25T18:00',
        'temperature_2m': 28.5,
        'relative_humidity_2m': 80,
        'apparent_temperature': 32.1,
        'precipitation': 1.2,
        'weather_code': 61,
        'wind_speed_10m': 12.4,
      };

      final weather = CurrentWeatherModel.fromJson(json);

      expect(weather.temperature, 28.5);
      expect(weather.relativeHumidity, 80);
      expect(weather.apparentTemperature, 32.1);
      expect(weather.precipitation, 1.2);
      expect(weather.weatherCode, 61);
      expect(weather.windSpeed, 12.4);
    });

    test('DailyForecastModel list parsing', () {
      final dailyJson = {
        'time': ['2026-11-25', '2026-11-26'],
        'weather_code': [0, 95],
        'temperature_2m_max': [32.0, 29.5],
        'temperature_2m_min': [24.0, 23.0],
        'precipitation_probability_max': [10, 85],
      };

      final forecasts = DailyForecastModel.listFromJson(dailyJson);

      expect(forecasts.length, 2);
      expect(forecasts[0].weatherCode, 0);
      expect(forecasts[0].temperatureMax, 32.0);
      expect(forecasts[1].weatherCode, 95);
      expect(forecasts[1].precipitationProbabilityMax, 85);
    });

    test('WeatherConditionHelper maps weather codes correctly', () {
      final clearCondition = WeatherConditionHelper.getCondition(0);
      expect(clearCondition.description, 'Cerah');

      final stormCondition = WeatherConditionHelper.getCondition(95);
      expect(stormCondition.description, 'Badai Petir');

      final rainCondition = WeatherConditionHelper.getCondition(61);
      expect(rainCondition.description, 'Hujan Ringan');
    });
  });
}
