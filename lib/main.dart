import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'services/weather_api_service.dart';
import 'viewmodels/search_viewmodel.dart';
import 'viewmodels/weather_viewmodel.dart';
import 'views/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Storage Hive
  final storageService = StorageService();
  await storageService.init();

  // Inisialisasi API Service
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
        // Provider Service
        Provider<StorageService>.value(value: storageService),
        Provider<WeatherApiService>.value(value: apiService),

        // ChangeNotifierProvider ViewModels (MVVM)
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
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E88E5),
            brightness: Brightness.light,
          ),
          cardTheme: const CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
