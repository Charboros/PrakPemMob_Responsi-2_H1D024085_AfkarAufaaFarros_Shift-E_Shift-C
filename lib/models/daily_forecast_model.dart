/// ============================================================================
/// LAYER MODEL (MVVM) - DailyForecastModel
/// ----------------------------------------------------------------------------
/// Merepresentasikan perkiraan cuaca satu hari dari objek `daily` Open-Meteo.
/// Karena Open-Meteo mengirimkan array terpisah per atribut (time[], max[], min[]),
/// fungsi `listFromJson` menggabungkan indeks ke-i menjadi daftar objek harian.
/// ============================================================================
class DailyForecastModel {
  final DateTime date; // Tanggal perkiraan (daily.time)
  final int weatherCode; // Kode cuaca harian (daily.weather_code)
  final double temperatureMax; // Suhu maksimum harian (daily.temperature_2m_max)
  final double temperatureMin; // Suhu minimum harian (daily.temperature_2m_min)
  final int precipitationProbabilityMax; // Peluang hujan maks (daily.precipitation_probability_max)

  DailyForecastModel({
    required this.date,
    required this.weatherCode,
    required this.temperatureMax,
    required this.temperatureMin,
    required this.precipitationProbabilityMax,
  });

  /// Mengonversi kumpulan array paralel pada objek `daily` JSON menjadi `List<DailyForecastModel>`
  static List<DailyForecastModel> listFromJson(Map<String, dynamic> dailyJson) {
    final List<dynamic>? times = dailyJson['time'] as List<dynamic>?;
    final List<dynamic>? weatherCodes = dailyJson['weather_code'] as List<dynamic>?;
    final List<dynamic>? maxTemps = dailyJson['temperature_2m_max'] as List<dynamic>?;
    final List<dynamic>? minTemps = dailyJson['temperature_2m_min'] as List<dynamic>?;
    final List<dynamic>? rainProbs = dailyJson['precipitation_probability_max'] as List<dynamic>?;

    // Validasi aman jika respons API kosong / tidak lengkap
    if (times == null || weatherCodes == null || maxTemps == null || minTemps == null) {
      return [];
    }

    final List<DailyForecastModel> result = [];
    final int count = times.length;

    // Menggabungkan data pada indeks hari yang sama (hari ke-0 s/d hari ke-6)
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
