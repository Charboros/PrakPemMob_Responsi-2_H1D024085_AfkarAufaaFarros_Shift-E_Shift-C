import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/location_model.dart';
import '../routes/app_routes.dart';
import '../utils/weather_condition_helper.dart';
import '../viewmodels/weather_viewmodel.dart';
import '../widgets/daily_forecast_tile.dart';
import '../widgets/weather_detail_card.dart';

/// ============================================================================
/// LAYER VIEW (MVVM) - HomeScreen (Layar Utama Cuaca)
/// ----------------------------------------------------------------------------
/// Menggunakan `StatefulWidget` karena membutuhkan method lifecycle `initState()`
/// untuk memicu pemuatan lokasi & data cuaca awal satu kali saat layar dibuka.
/// Menampilkan:
/// 1. Nama kota yang sedang dipilih + tombol Favorit & tombol Cari Kota
/// 2. Suhu saat ini & kondisi cuaca terkini (ikon + gradien dinamis)
/// 3. Informasi tambahan: suhu dirasakan, kelembapan, kecepatan angin, curah & peluang hujan
/// 4. Perkiraan cuaca harian 7 hari ke depan
/// ============================================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Memanggil inisialisasi ViewModel setelah frame pertama selesai digambar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherViewModel>().init();
    });
  }

  /// Berpindah ke SearchScreen dan menangkap kota yang dipilih oleh pengguna
  Future<void> _navigateToSearch() async {
    final selectedLocation = await Navigator.pushNamed(
      context,
      AppRoutes.search,
    );

    if (!mounted) return;
    final weatherVM = context.read<WeatherViewModel>();

    // Jika pengguna memilih sebuah kota, muat cuaca kota tersebut di HomeScreen
    if (selectedLocation is LocationModel) {
      await weatherVM.selectLocation(selectedLocation);
    } else {
      // Jika pengguna hanya menekan tombol kembali, sinkronkan status favorit terbaru
      weatherVM.syncFavoriteStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mendengarkan perubahan state pada WeatherViewModel secara reaktif
    final weatherVM = context.watch<WeatherViewModel>();
    final location = weatherVM.currentLocation;
    final weather = weatherVM.weatherData?.current;

    // Menentukan deskripsi, ikon, dan gradien latar berdasarkan kode cuaca WMO terkini
    final condition = weather != null
        ? WeatherConditionHelper.getCondition(weather.weatherCode)
        : WeatherConditionHelper.getCondition(-1);

    return Scaffold(
      body: Container(
        // Latar belakang gradien yang berubah dinamis mengikuti kondisi cuaca
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: condition.gradientColors,
          ),
        ),
        child: SafeArea(
          child: Center(
            // ConstrainedBox menjaga tampilan tetap rapi & responsif di layar lebar/tablet
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  // Bagian atas: Nama kota, tombol favorit, dan tombol pencarian
                  _buildAppBar(context, weatherVM, location),

                  // Bagian isi utama (menyesuaikan state loading / error / empty / loaded)
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

  /// Membangun bar bagian atas berisi informasi lokasi aktif & aksi navigasi
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
          // Nama kota dan keterangan provinsi/negara
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

          // Tombol simpan / hapus kota aktif dari daftar favorit Hive
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

          // Tombol menuju halaman pencarian kota (SearchScreen)
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

  /// Membangun konten utama berdasarkan status state pada WeatherViewModel
  Widget _buildBody(
    BuildContext context,
    WeatherViewModel weatherVM,
    WeatherConditionInfo condition,
  ) {
    final textTheme = Theme.of(context).textTheme;

    // 1. Penanganan Kondisi LOADING (saat menunggu respons dari API)
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

    // 2. Penanganan Kondisi ERROR (saat internet mati / timeout / gagal request)
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

    // 3. Penanganan Kondisi DATA KOSONG (empty state)
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

    // 4. Kondisi LOADED: Data cuaca berhasil diterima dari API
    final weather = weatherVM.weatherData!.current;
    final dailyList = weatherVM.weatherData!.daily;
    final todayRainProb = dailyList.isNotEmpty
        ? dailyList.first.precipitationProbabilityMax
        : null;

    // RefreshIndicator memungkinkan pengguna menarik layar ke bawah untuk refresh data API
    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Colors.white,
      onRefresh: () => weatherVM.refresh(),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // Peringatan kecil jika gagal refresh saat data sebelumnya masih tertampil
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

          // Tampilan utama: Ikon cuaca, suhu saat ini (°C), & deskripsi kondisi cuaca
          _buildWeatherHero(context, weather.temperature, condition),

          const SizedBox(height: 16),

          // Kotak saran aktivitas sesuai kondisi cuaca saat ini
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

          // Grid Responsif untuk menampilkan 4 informasi cuaca tambahan
          Text(
            'Informasi Cuaca',
            style: textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              // Responsif: 2 kolom pada layar ponsel, 4 kolom pada layar lebar/lanskap
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

          // Bagian daftar perkiraan cuaca beberapa hari ke depan (Daily Forecast)
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
            // Merender setiap hari ramalan cuaca menggunakan widget DailyForecastTile
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

  /// Menampilkan ikon cuaca besar, suhu saat ini, dan teks kondisi cuaca terkini
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
