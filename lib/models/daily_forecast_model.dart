class DailyForecastModel {
  final DateTime date;
  final int weatherCode;
  final double temperatureMax; // daily.temperature_2m_max (°C)
  final double temperatureMin; // daily.temperature_2m_min (°C)
  final int precipitationProbabilityMax; // daily.precipitation_probability_max (%)

  DailyForecastModel({
    required this.date,
    required this.weatherCode,
    required this.temperatureMax,
    required this.temperatureMin,
    required this.precipitationProbabilityMax,
  });

  static List<DailyForecastModel> listFromJson(Map<String, dynamic> dailyJson) {
    final List<dynamic>? times = dailyJson['time'] as List<dynamic>?;
    final List<dynamic>? weatherCodes = dailyJson['weather_code'] as List<dynamic>?;
    final List<dynamic>? maxTemps = dailyJson['temperature_2m_max'] as List<dynamic>?;
    final List<dynamic>? minTemps = dailyJson['temperature_2m_min'] as List<dynamic>?;
    final List<dynamic>? rainProbs = dailyJson['precipitation_probability_max'] as List<dynamic>?;

    if (times == null || weatherCodes == null || maxTemps == null || minTemps == null) {
      return [];
    }

    final List<DailyForecastModel> result = [];
    final int count = times.length;
    for (int i = 0; i < count; i++) {
      result.add(
        DailyForecastModel(
          date: DateTime.tryParse(times[i].toString()) ??
              DateTime.now().add(Duration(days: i)),
          weatherCode: (weatherCodes[i] as num?)?.toInt() ?? 0,
          temperatureMax: (maxTemps[i] as num?)?.toDouble() ?? 0.0,
          temperatureMin: (minTemps[i] as num?)?.toDouble() ?? 0.0,
          precipitationProbabilityMax: rainProbs != null && i < rainProbs.length
              ? (rainProbs[i] as num?)?.toInt() ?? 0
              : 0,
        ),
      );
    }
    return result;
  }
}
