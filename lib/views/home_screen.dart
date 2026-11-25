import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/location_model.dart';
import '../utils/weather_condition_helper.dart';
import '../viewmodels/weather_viewmodel.dart';
import '../widgets/daily_forecast_tile.dart';
import '../widgets/weather_detail_card.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Muat data saat screen pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherViewModel>().init();
    });
  }

  void _navigateToSearch() async {
    final selectedLocation = await Navigator.push<LocationModel>(
      context,
      MaterialPageRoute(builder: (context) => const SearchScreen()),
    );

    if (selectedLocation != null && mounted) {
      context.read<WeatherViewModel>().selectLocation(selectedLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    final weatherVM = context.watch<WeatherViewModel>();
    final location = weatherVM.currentLocation;
    final weather = weatherVM.weatherData?.current;
    final condition = weather != null
        ? WeatherConditionHelper.getCondition(weather.weatherCode)
        : WeatherConditionHelper.getCondition(-1);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: condition.gradientColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              _buildAppBar(context, weatherVM, location),

              // Content Body
              Expanded(
                child: _buildBody(weatherVM, condition),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    WeatherViewModel weatherVM,
    LocationModel? location,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Icon Lokasi & Nama Kota
          const Icon(
            Icons.location_on_rounded,
            color: Colors.white,
            size: 26,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  location?.name ?? 'Memuat Lokasi...',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (location != null && location.subtitleInfo.isNotEmpty)
                  Text(
                    location.subtitleInfo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Tombol Favorit
          if (location != null)
            IconButton(
              icon: Icon(
                weatherVM.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: weatherVM.isFavorite ? Colors.redAccent : Colors.white,
                size: 26,
              ),
              tooltip: weatherVM.isFavorite ? 'Hapus dari Favorit' : 'Simpan ke Favorit',
              onPressed: () {
                weatherVM.toggleFavorite();
                final msg = weatherVM.isFavorite
                    ? '${location.name} ditambahkan ke favorit'
                    : '${location.name} dihapus dari favorit';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(msg),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),

          // Tombol Pencarian
          IconButton(
            icon: const Icon(
              Icons.search_rounded,
              color: Colors.white,
              size: 26,
            ),
            tooltip: 'Cari Kota',
            onPressed: _navigateToSearch,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(WeatherViewModel weatherVM, WeatherConditionInfo condition) {
    if (weatherVM.isLoading && weatherVM.weatherData == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Mengambil data cuaca...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (weatherVM.state == WeatherViewState.error && weatherVM.weatherData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 72,
                color: Colors.white70,
              ),
              const SizedBox(height: 16),
              const Text(
                'Gagal Memuat Cuaca',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                weatherVM.errorMessage ?? 'Terjadi kesalahan pada jaringan.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => weatherVM.fetchWeather(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blueGrey.shade900,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final weather = weatherVM.weatherData!.current;
    final dailyList = weatherVM.weatherData!.daily;

    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Colors.white,
      onRefresh: () => weatherVM.refresh(),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // Header Hero Cuaca Utama
          _buildWeatherHero(weather, condition),

          const SizedBox(height: 16),

          // Advice / Tips Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    condition.advice,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Grid Info Tambahan Cuaca
          const Text(
            'Informasi Cuaca',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.8,
            children: [
              WeatherDetailCard(
                icon: Icons.thermostat_rounded,
                title: 'Terasa Seperti',
                value: '${weather.apparentTemperature.toStringAsFixed(1)}°C',
                subtitle: 'Suhu dirasakan',
              ),
              WeatherDetailCard(
                icon: Icons.water_drop_rounded,
                title: 'Kelembapan Udara',
                value: '${weather.relativeHumidity}%',
                subtitle: 'Kelembapan relatif',
              ),
              WeatherDetailCard(
                icon: Icons.air_rounded,
                title: 'Kecepatan Angin',
                value: '${weather.windSpeed.toStringAsFixed(1)} km/h',
                subtitle: 'Angin 10m',
              ),
              WeatherDetailCard(
                icon: Icons.grain_rounded,
                title: 'Curah Hujan',
                value: '${weather.precipitation.toStringAsFixed(1)} mm',
                subtitle: 'Presipitasi saat ini',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Ramalan Cuaca Harian
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Perkiraan 7 Hari ke Depan',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Min / Max',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // List Ramalan Cuaca
          ...dailyList.asMap().entries.map((entry) {
            final index = entry.key;
            final forecast = entry.value;
            return DailyForecastTile(
              forecast: forecast,
              isToday: index == 0,
            );
          }),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildWeatherHero(dynamic weather, WeatherConditionInfo condition) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: Column(
        children: [
          // Icon Cuaca Utama
          Icon(
            condition.icon,
            size: 88,
            color: Colors.white,
          ),
          const SizedBox(height: 8),

          // Suhu Besar
          Text(
            '${weather.temperature.toStringAsFixed(0)}°',
            style: const TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.w200,
              color: Colors.white,
              height: 1.1,
            ),
          ),

          // Deskripsi Cuaca
          Text(
            condition.description,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
