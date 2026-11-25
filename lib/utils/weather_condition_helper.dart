import 'package:flutter/material.dart';

class WeatherConditionInfo {
  final String description;
  final IconData icon;
  final List<Color> gradientColors;
  final String advice;

  const WeatherConditionInfo({
    required this.description,
    required this.icon,
    required this.gradientColors,
    required this.advice,
  });
}

class WeatherConditionHelper {
  /// Mendapatkan info visual dan deskripsi cuaca berdasarkan WMO Weather Code
  static WeatherConditionInfo getCondition(int code) {
    switch (code) {
      case 0:
        return const WeatherConditionInfo(
          description: 'Cerah',
          icon: Icons.wb_sunny_rounded,
          gradientColors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
          advice: 'Cuaca sangat cerah! Gunakan kacamata hitam atau tabir surya.',
        );
      case 1:
        return const WeatherConditionInfo(
          description: 'Sebagian Besar Cerah',
          icon: Icons.wb_sunny_outlined,
          gradientColors: [Color(0xFF2980B9), Color(0xFF6DD5FA)],
          advice: 'Kondisi hangat bersahabat, cocok untuk aktivitas luar.',
        );
      case 2:
        return const WeatherConditionInfo(
          description: 'Sebagian Berawan',
          icon: Icons.cloud_outlined,
          gradientColors: [Color(0xFF3F4C6B), Color(0xFF606C88)],
          advice: 'Sedikit berawan, suhu nyaman untuk beraktivitas santai.',
        );
      case 3:
        return const WeatherConditionInfo(
          description: 'Mendung Berawan',
          icon: Icons.cloud_rounded,
          gradientColors: [Color(0xFF485563), Color(0xFF29323C)],
          advice: 'Langit cukup mendung, bersiap jika sewaktu-waktu turun hujan.',
        );
      case 45:
      case 48:
        return const WeatherConditionInfo(
          description: 'Berkabut',
          icon: Icons.foggy,
          gradientColors: [Color(0xFF536976), Color(0xFF292E49)],
          advice: 'Jarak pandang berkurang karena kabut, hati-hati berkendara.',
        );
      case 51:
      case 53:
      case 55:
        return const WeatherConditionInfo(
          description: 'Gerimis Ringan',
          icon: Icons.grain_rounded,
          gradientColors: [Color(0xFF3a7bd5), Color(0xFF3a6073)],
          advice: 'Hujan rintik gerimis, sebaiknya bawa payung kecil.',
        );
      case 56:
      case 57:
        return const WeatherConditionInfo(
          description: 'Gerimis Dingin',
          icon: Icons.ac_unit_rounded,
          gradientColors: [Color(0xFF4B79A1), Color(0xFF283E51)],
          advice: 'Gerimis sangat dingin, kenakan jaket tebal.',
        );
      case 61:
        return const WeatherConditionInfo(
          description: 'Hujan Ringan',
          icon: Icons.water_drop_outlined,
          gradientColors: [Color(0xFF1F4068), Color(0xFF162447)],
          advice: 'Turun hujan ringan, siapkan payung atau jas hujan.',
        );
      case 63:
        return const WeatherConditionInfo(
          description: 'Hujan Sedang',
          icon: Icons.water_drop_rounded,
          gradientColors: [Color(0xFF1D2671), Color(0xFFC33764)],
          advice: 'Hujan sedang turun, pastikan barang bawaan aman dari air.',
        );
      case 65:
        return const WeatherConditionInfo(
          description: 'Hujan Lebat',
          icon: Icons.thunderstorm_outlined,
          gradientColors: [Color(0xFF0F2027), Color(0xFF203A43)],
          advice: 'Hujan sangat lebat, prioritaskan berteduh di tempat aman.',
        );
      case 66:
      case 67:
        return const WeatherConditionInfo(
          description: 'Hujan Es Dingin',
          icon: Icons.ac_unit,
          gradientColors: [Color(0xFF243B55), Color(0xFF141E30)],
          advice: 'Hujan es bersuhu dingin, hindari berada di tempat terbuka.',
        );
      case 71:
      case 73:
      case 75:
      case 77:
        return const WeatherConditionInfo(
          description: 'Hujan Salju',
          icon: Icons.ac_unit_rounded,
          gradientColors: [Color(0xFF83a4d4), Color(0xFFb6fbff)],
          advice: 'Salju turun, kenakan mantel hangat dan sarung tangan.',
        );
      case 80:
      case 81:
      case 82:
        return const WeatherConditionInfo(
          description: 'Hujan Deras Lokal',
          icon: Icons.shower_rounded,
          gradientColors: [Color(0xFF283048), Color(0xFF859398)],
          advice: 'Hujan deras mendadak berpotensi terjadi, waspada genangan air.',
        );
      case 85:
      case 86:
        return const WeatherConditionInfo(
          description: 'Badai Salju',
          icon: Icons.snowing,
          gradientColors: [Color(0xFF616161), Color(0xFF9bc5c3)],
          advice: 'Badai salju, disarankan tetap berada di dalam ruangan.',
        );
      case 95:
        return const WeatherConditionInfo(
          description: 'Badai Petir',
          icon: Icons.thunderstorm_rounded,
          gradientColors: [Color(0xFF0f0c29), Color(0xFF302b63)],
          advice: 'Badai disertai kilat petir, hindari pohon tinggi & ruang terbuka!',
        );
      case 96:
      case 99:
        return const WeatherConditionInfo(
          description: 'Badai Petir & Es',
          icon: Icons.flash_on_rounded,
          gradientColors: [Color(0xFF141E30), Color(0xFF243B55)],
          advice: 'Kondisi cuaca ekstrem! Tetap waspada di lokasi terlindung.',
        );
      default:
        return const WeatherConditionInfo(
          description: 'Berawan',
          icon: Icons.wb_cloudy_rounded,
          gradientColors: [Color(0xFF3E5151), Color(0xFFDECBA4)],
          advice: 'Kondisi cuaca bervariasi sepanjang hari.',
        );
    }
  }
}
