import 'package:flutter/foundation.dart';
import '../models/location_model.dart';
import '../models/weather_response_model.dart';
import '../services/storage_service.dart';
import '../services/weather_api_service.dart';

enum WeatherViewState { initial, loading, loaded, empty, error }

class WeatherViewModel extends ChangeNotifier {
  final WeatherApiService apiService;
  final StorageService storageService;

  WeatherViewState _state = WeatherViewState.initial;
  WeatherResponseModel? _weatherData;
  LocationModel? _currentLocation;
  String? _errorMessage;
  bool _isFavorite = false;

  WeatherViewModel({
    required this.apiService,
    required this.storageService,
  });

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
    final savedLocation = storageService.getLastSelectedLocation();
    final locationToLoad = savedLocation ?? defaultLocation;
    await selectLocation(locationToLoad, isInitial: true);
  }

  /// Memilih lokasi baru dan langsung mengambil data cuacanya
  Future<void> selectLocation(LocationModel location, {bool isInitial = false}) async {
    final isDifferentCity = _currentLocation?.id != location.id;
    _currentLocation = location;
    _isFavorite = storageService.isFavorite(location.id);

    if (isDifferentCity) {
      _weatherData = null;
    }

    // Simpan ke riwayat dan simpan sebagai lokasi aktif terakhir di Hive
    await storageService.addToSearchHistory(location);
    await storageService.saveLastSelectedLocation(location);

    notifyListeners();
    await fetchWeather();
  }

  /// Mengambil data cuaca terkini dan forecast dari Open-Meteo REST API
  Future<void> fetchWeather({bool clearOldData = false}) async {
    if (_currentLocation == null) {
      _state = WeatherViewState.empty;
      notifyListeners();
      return;
    }

    if (clearOldData) {
      _weatherData = null;
    }

    _state = WeatherViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await apiService.getForecast(
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
      );

      _weatherData = data;
      _state = data.daily.isEmpty && data.timezone.isEmpty
          ? WeatherViewState.empty
          : WeatherViewState.loaded;
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = WeatherViewState.error;
    } catch (e) {
      _errorMessage = 'Gagal memuat cuaca: $e';
      _state = WeatherViewState.error;
    } finally {
      syncFavoriteStatus(notify: false);
      notifyListeners();
    }
  }

  /// Sinkronkan status favorit lokasi aktif dengan Hive
  void syncFavoriteStatus({bool notify = true}) {
    if (_currentLocation == null) return;
    final latest = storageService.isFavorite(_currentLocation!.id);
    if (_isFavorite != latest) {
      _isFavorite = latest;
      _currentLocation = _currentLocation!.copyWith(isFavorite: latest);
      if (notify) notifyListeners();
    }
  }

  /// Toggle status favorit untuk lokasi yang saat ini aktif
  Future<bool> toggleFavorite() async {
    if (_currentLocation == null) return false;

    final newStatus = await storageService.toggleFavorite(_currentLocation!);
    _isFavorite = newStatus;
    _currentLocation = _currentLocation!.copyWith(isFavorite: newStatus);
    notifyListeners();
    return newStatus;
  }

  /// Refresh data cuaca saat user melakukan pull-to-refresh
  Future<void> refresh() async {
    await fetchWeather();
  }
}
