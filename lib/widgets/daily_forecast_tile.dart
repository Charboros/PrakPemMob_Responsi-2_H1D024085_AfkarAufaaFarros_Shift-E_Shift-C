import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/daily_forecast_model.dart';
import '../utils/weather_condition_helper.dart';

/// ============================================================================
/// WIDGET REUSABLE - DailyForecastTile
/// ----------------------------------------------------------------------------
/// Menggunakan `StatelessWidget` untuk menampilkan satu baris perkiraan cuaca
/// harian: nama hari & tanggal (Bahasa Indonesia), ikon & kondisi cuaca,
/// persentase peluang hujan maksimum, serta suhu minimum & maksimum harian.
/// ============================================================================
class DailyForecastTile extends StatelessWidget {
  final DailyForecastModel forecast;
  final bool isToday;

  const DailyForecastTile({
    super.key,
    required this.forecast,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    final condition = WeatherConditionHelper.getCondition(forecast.weatherCode);
    final textTheme = Theme.of(context).textTheme;

    // Memformat tanggal ke Bahasa Indonesia menggunakan paket `intl`
    final dayFormat = DateFormat('EEEE', 'id_ID');
    final dateFormat = DateFormat('d MMM', 'id_ID');

    String dayName;
    try {
      dayName = isToday ? 'Hari Ini' : dayFormat.format(forecast.date);
    } catch (_) {
      dayName = isToday ? 'Hari Ini' : DateFormat('EEEE').format(forecast.date);
    }

    String dateStr;
    try {
      dateStr = dateFormat.format(forecast.date);
    } catch (_) {
      dateStr = '${forecast.date.day}/${forecast.date.month}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Kolom 1: Nama Hari dan Tanggal
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyLarge?.copyWith(
                    fontSize: 14,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                    color:
                        isToday ? Theme.of(context).colorScheme.primary : null,
                  ),
                ),
                Text(
                  dateStr,
                  style: textTheme.labelMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Kolom 2: Ikon dan Deskripsi Kondisi Cuaca Harian
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Icon(
                  condition.icon,
                  size: 24,
                  color: condition.gradientColors.first,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    condition.description,
                    style: textTheme.labelMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Kolom 3: Peluang Hujan Maksimum (`daily.precipitation_probability_max`)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.water_drop,
                size: 14,
                color: Colors.lightBlue,
              ),
              const SizedBox(width: 2),
              Text(
                '${forecast.precipitationProbabilityMax}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.lightBlue,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),

          // Kolom 4: Suhu Minimum / Maksimum Harian (`temperature_2m_min` / `max`)
          Text(
            '${forecast.temperatureMin.toStringAsFixed(0)}° / ${forecast.temperatureMax.toStringAsFixed(0)}°',
            style: textTheme.bodyLarge?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
