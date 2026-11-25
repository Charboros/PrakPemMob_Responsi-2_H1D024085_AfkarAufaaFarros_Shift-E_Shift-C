import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/daily_forecast_model.dart';
import '../utils/weather_condition_helper.dart';

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
          // Hari dan Tanggal
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                    color: isToday ? Theme.of(context).colorScheme.primary : null,
                  ),
                ),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Icon dan Kondisi Cuaca
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Icon(
                  condition.icon,
                  size: 26,
                  color: condition.gradientColors.first,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    condition.description,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Peluang Hujan (jika > 0)
          if (forecast.precipitationProbabilityMax > 0) ...[
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
            const SizedBox(width: 8),
          ],

          // Suhu Min - Max
          Text(
            '${forecast.temperatureMin.toStringAsFixed(0)}° / ${forecast.temperatureMax.toStringAsFixed(0)}°',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
