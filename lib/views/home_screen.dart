import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/location_model.dart';
import '../routes/app_routes.dart';
import '../utils/weather_condition_helper.dart';
import '../viewmodels/weather_viewmodel.dart';
import '../widgets/daily_forecast_tile.dart';
import '../widgets/weather_detail_card.dart';

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

  Future<void> _navigateToSearch() async {
    final selectedLocation = await Navigator.pushNamed(
      context,
      AppRoutes.search,
    );

    if (!mounted) return;
    final weatherVM = context.read<WeatherViewModel>();

    if (selectedLocation is LocationModel) {
      await weatherVM.selectLocation(selectedLocation);
    } else {
      // Sinkronkan status favorit jika diubah dari halaman pencarian
      weatherVM.syncFavoriteStatus();
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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  // Custom App Bar
                  _buildAppBar(context, weatherVM, location),

                  // Content Body
                  Expanded(
                    child: _buildBody(context, weatherVM, condition),
                  ),
                ],
              ),
            ),
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
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
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
                  style: textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (location != null && location.subtitleInfo.isNotEmpty)
                  Text(
                    location.subtitleInfo,
                    style: textTheme.labelMedium?.copyWith(
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
                weatherVM.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: weatherVM.isFavorite ? Colors.redAccent : Colors.white,
                size: 26,
              ),
              tooltip: weatherVM.isFavorite
                  ? 'Hapus dari Favorit'
                  : 'Simpan ke Favorit',
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final isNowFav = await weatherVM.toggleFavorite();
                final msg = isNowFav
                    ? '${location.name} ditambahkan ke favorit'
                    : '${location.name} dihapus dari favorit';
                messenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(msg),
                      duration: const Duration(seconds: 2),
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

  Widget _buildBody(
    BuildContext context,
    WeatherViewModel weatherVM,
    WeatherConditionInfo condition,
  ) {
    final textTheme = Theme.of(context).textTheme;

    // 1. Kondisi Loading
    if (weatherVM.isLoading && weatherVM.weatherData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'Mengambil data cuaca...',
              style: textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
          ],
        ),
      );
    }

    // 2. Kondisi Error
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
              Text(
                'Gagal Memuat Cuaca',
                style: textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                weatherVM.errorMessage ?? 'Terjadi kesalahan pada jaringan.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => weatherVM.fetchWeather(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blueGrey.shade900,
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Kondisi Data Kosong
    if (weatherVM.state == WeatherViewState.empty || weatherVM.weatherData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_searching_rounded,
                size: 64,
                color: Colors.white70,
              ),
              const SizedBox(height: 16),
              Text(
                'Data Cuaca Kosong',
                style: textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Silakan cari dan pilih kota untuk menampilkan informasi cuaca.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _navigateToSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blueGrey.shade900,
                ),
                icon: const Icon(Icons.search_rounded),
                label: const Text('Cari Kota'),
              ),
            ],
          ),
        ),
      );
    }

    final weather = weatherVM.weatherData!.current;
    final dailyList = weatherVM.weatherData!.daily;
    final todayRainProb = dailyList.isNotEmpty
        ? dailyList.first.precipitationProbabilityMax
        : null;

    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Colors.white,
      onRefresh: () => weatherVM.refresh(),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // Banner peringatan jika refresh gagal namun masih ada data sebelumnya
          if (weatherVM.state == WeatherViewState.error &&
              weatherVM.errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      weatherVM.errorMessage!,
                      style: textTheme.bodyMedium?.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

          // Header Hero Cuaca Utama
          _buildWeatherHero(context, weather.temperature, condition),

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
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Grid Responsif Info Tambahan Cuaca
          Text(
            'Informasi Cuaca',
            style: textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 560 ? 4 : 2;
              return GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 86,
                ),
                children: [
                  WeatherDetailCard(
                    icon: Icons.thermostat_rounded,
                    title: 'Terasa Seperti',
                    value: '${weather.apparentTemperature.toStringAsFixed(1)}°C',
                    subtitle: 'Suhu dirasakan',
                  ),
                  WeatherDetailCard(
                    icon: Icons.water_drop_rounded,
                    title: 'Kelembapan',
                    value: '${weather.relativeHumidity}%',
                    subtitle: 'Kelembapan udara',
                  ),
                  WeatherDetailCard(
                    icon: Icons.air_rounded,
                    title: 'Kecepatan Angin',
                    value: '${weather.windSpeed.toStringAsFixed(1)} km/h',
                    subtitle: 'Angin 10m',
                  ),
                  WeatherDetailCard(
                    icon: Icons.umbrella_rounded,
                    title: 'Curah & Peluang Hujan',
                    value: '${weather.precipitation.toStringAsFixed(1)} mm',
                    subtitle: todayRainProb != null
                        ? 'Peluang hujan: $todayRainProb%'
                        : 'Presipitasi saat ini',
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Ramalan Cuaca Harian
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Perkiraan ${dailyList.length} Hari ke Depan',
                style: textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              Text(
                'Min / Max',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (dailyList.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Data perkiraan cuaca harian tidak tersedia.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
            )
          else
            ...dailyList.asMap().entries.map((entry) {
              return DailyForecastTile(
                forecast: entry.value,
                isToday: entry.key == 0,
              );
            }),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildWeatherHero(
    BuildContext context,
    double temperature,
    WeatherConditionInfo condition,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      child: Column(
        children: [
          Icon(
            condition.icon,
            size: 84,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          Text(
            '${temperature.toStringAsFixed(0)}°C',
            style: textTheme.displayLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            condition.description,
            style: textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
