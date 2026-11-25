import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'routes/app_routes.dart';
import 'services/storage_service.dart';
import 'services/weather_api_service.dart';
import 'utils/app_theme.dart';
import 'viewmodels/search_viewmodel.dart';
import 'viewmodels/weather_viewmodel.dart';

/// ============================================================================
/// ENTRY POINT APLIKASI (main.dart)
/// ----------------------------------------------------------------------------
/// Fungsi `main()` dijalankan pertama kali saat aplikasi dibuka.
/// Menggunakan `async` karena perlu menunggu proses inisialisasi asinkron
/// (format tanggal lokal Indonesia dan pembukaan database lokal Hive)
/// sebelum merender widget utama ke layar.
/// ============================================================================
void main() async {
  // Memastikan binding engine Flutter siap sebelum memanggil plugin native/async
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi format penanggalan Bahasa Indonesia (contoh: Senin, 25 Nov)
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi Local Storage menggunakan Hive (membuka box favorit, riwayat, & pengaturan)
  final storageService = StorageService();
  await storageService.init();

  // Inisialisasi Service untuk komunikasi HTTP GET ke REST API Open-Meteo
  final apiService = WeatherApiService();

  // Menjalankan root widget aplikasi dengan menyuntikkan instance service
  runApp(
    AplikasiCuacaApp(
      storageService: storageService,
      apiService: apiService,
    ),
  );
}

/// Root Widget aplikasi.
/// Menggunakan `StatelessWidget` karena konfigurasi root (Provider, Theme, Routes)
/// bersifat tetap dan tidak memiliki state lokal yang berubah-ubah sendiri.
class AplikasiCuacaApp extends StatelessWidget {
  final StorageService storageService;
  final WeatherApiService apiService;

  const AplikasiCuacaApp({
    super.key,
    required this.storageService,
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    // MultiProvider menyediakan akses Service & ViewModel ke seluruh halaman (pola MVVM)
    return MultiProvider(
      providers: [
        // Menyediakan instance tunggal (singleton) untuk StorageService dan WeatherApiService
        Provider<StorageService>.value(value: storageService),
        Provider<WeatherApiService>.value(value: apiService),

        // ViewModel untuk Home/Weather Screen (mengelola state data cuaca & kota aktif)
        ChangeNotifierProvider<WeatherViewModel>(
          create: (_) => WeatherViewModel(
            apiService: apiService,
            storageService: storageService,
          ),
        ),

        // ViewModel untuk Search Screen (mengelola pencarian kota, favorit, & riwayat)
        ChangeNotifierProvider<SearchViewModel>(
          create: (_) => SearchViewModel(
            apiService: apiService,
            storageService: storageService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Aplikasi Cuaca',
        debugShowCheckedModeBanner: false,
        // Mengaplikasikan standar Material Design 3 beserta Theme & Typography konsisten
        theme: AppTheme.lightTheme,
        // Konfigurasi navigasi antar-layar menggunakan Named Routes
        initialRoute: AppRoutes.home,
        routes: AppRoutes.routes,
      ),
    );
  }
}
