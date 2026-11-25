import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'routes/app_routes.dart';
import 'services/storage_service.dart';
import 'services/weather_api_service.dart';
import 'utils/app_theme.dart';
import 'viewmodels/search_viewmodel.dart';
import 'viewmodels/weather_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi format tanggal Bahasa Indonesia (intl)
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi Local Storage Hive
  final storageService = StorageService();
  await storageService.init();

  // Inisialisasi REST API Service (Open-Meteo)
  final apiService = WeatherApiService();

  runApp(
    AplikasiCuacaApp(
      storageService: storageService,
      apiService: apiService,
    ),
  );
}

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
    return MultiProvider(
      providers: [
        // Dependency Injection Services
        Provider<StorageService>.value(value: storageService),
        Provider<WeatherApiService>.value(value: apiService),

        // ViewModels untuk arsitektur MVVM
        ChangeNotifierProvider<WeatherViewModel>(
          create: (_) => WeatherViewModel(
            apiService: apiService,
            storageService: storageService,
          ),
        ),
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
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.home,
        routes: AppRoutes.routes,
      ),
    );
  }
}
