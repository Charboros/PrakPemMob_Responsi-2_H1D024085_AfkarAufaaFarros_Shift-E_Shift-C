import 'package:flutter/foundation.dart';
import '../models/location_model.dart';
import '../models/weather_response_model.dart';
import '../services/storage_service.dart';
import '../services/weather_api_service.dart';

enum WeatherViewState { initial, loading, loaded, error }

class WeatherViewModel extends ChangeNotifier {
  final WeatherApiService _apiService;
  final StorageService _storageService;

  WeatherViewState _state = WeatherViewState.initial;
  WeatherResponseModel? _weatherData;
  LocationModel? _currentLocation;
  String? _errorMessage;
  bool _isFavorite = false;

  WeatherViewModel({
    required WeatherApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService;

  // Getters
  WeatherViewState get state => _state;
  WeatherResponseModel? get weatherData => _weatherData;
  LocationModel? get currentLocation => _currentLocation;
  String? get errorMessage => _errorMessage;
  bool get isFavorite => _isFavorite;
  bool get isLoading => _state == WeatherViewState.loading;
  bool get hasData => _state == WeatherViewState.loaded && _weatherData != null;

  /// Default fallback lokasi (Jakarta) jika belum ada lokasi tersimpan
  static LocationModel get defaultLocation => LocationModel(
        id: 1642911,
        name: 'Jakarta',
        latitude: -6.21462,
        longitude: 106.84513,
        country: 'Indonesia',
        admin1: 'DKI Jakarta',
        timezone: 'Asia/Jakarta',
      );

  /// Inisialisasi awal: muat lokasi terakhir tersimpan di Hive, atau gunakan default
  Future<void> init() async {
    final savedLocation = _storageService.getLastSelectedLocation();
    final locationToLoad = savedLocation ?? defaultLocation;
    await selectLocation(locationToLoad, isInitial: true);
  }

  /// Memilih lokasi baru dan langsung mengambil data cuacanya
  Future<void> selectLocation(LocationModel location, {bool isInitial = false}) async {
    _currentLocation = location;
    _isFavorite = _storageService.isFavorite(location.id);

    // Simpan ke riwayat dan simpan sebagai lokasi aktif terakhir di Hive
    await _storageService.addToSearchHistory(location);
    await _storageService.saveLastSelectedLocation(location);

    notifyListeners();
    await fetchWeather();
  }

  /// Mengambil data cuaca terkini dan forecast dari Open-Meteo REST API
  Future<void> fetchWeather() async {
    if (_currentLocation == null) return;

    _state = WeatherViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiService.getForecast(
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
      );

      _weatherData = data;
      _state = WeatherViewState.loaded;
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = WeatherViewState.error;
    } catch (e) {
      _errorMessage = 'Gagal memuat cuaca: $e';
      _state = WeatherViewState.error;
    } finally {
      // Perbarui kembali status favorit terbaru
      if (_currentLocation != null) {
        _isFavorite = _storageService.isFavorite(_currentLocation!.id);
      }
      notifyListeners();
    }
  }

  /// Toggle status favorit untuk lokasi yang saat ini aktif
  Future<void> toggleFavorite() async {
    if (_currentLocation == null) return;

    final newStatus = await _storageService.toggleFavorite(_currentLocation!);
    _isFavorite = newStatus;
    _currentLocation = _currentLocation!.copyWith(isFavorite: newStatus);
    notifyListeners();
  }

  /// Refresh data cuaca saat user melakukan pull-to-refresh
  Future<void> refresh() async {
    await fetchWeather();
  }
}
