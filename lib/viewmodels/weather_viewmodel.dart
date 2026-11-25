import 'package:flutter/foundation.dart';
import '../models/location_model.dart';
import '../models/weather_response_model.dart';
import '../services/storage_service.dart';
import '../services/weather_api_service.dart';

/// Representasi status tampilan layar utama untuk mengatur UI secara reaktif
enum WeatherViewState { initial, loading, loaded, empty, error }

/// ============================================================================
/// LAYER VIEWMODEL (MVVM) - WeatherViewModel
/// ----------------------------------------------------------------------------
/// Bertindak sebagai penghubung antara `HomeScreen` (View) dengan `WeatherApiService`
/// dan `StorageService` (Model/Data).
/// Menggunakan `ChangeNotifier` (Provider): setiap kali `notifyListeners()` dipanggil,
/// `HomeScreen` akan otomatis melakukan rebuild (recomposition) sesuai data terbaru.
/// ============================================================================
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

  // Enkapsulasi state melalui getter agar hanya bisa diubah lewat fungsi ViewModel
  WeatherViewState get state => _state;
  WeatherResponseModel? get weatherData => _weatherData;
  LocationModel? get currentLocation => _currentLocation;
  String? get errorMessage => _errorMessage;
  bool get isFavorite => _isFavorite;
  bool get isLoading => _state == WeatherViewState.loading;
  bool get hasData => _state == WeatherViewState.loaded && _weatherData != null;

  /// Lokasi awal default (Jakarta) apabila pengguna baru pertama kali menginstal aplikasi
  static LocationModel get defaultLocation => LocationModel(
        id: 1642911,
        name: 'Jakarta',
        latitude: -6.21462,
        longitude: 106.84513,
        country: 'Indonesia',
        admin1: 'DKI Jakarta',
        timezone: 'Asia/Jakarta',
      );

  /// Dipanggil saat aplikasi pertama kali dibuka:
  /// Mengecek apakah ada lokasi terakhir di Hive; jika belum ada, gunakan Jakarta
  Future<void> init() async {
    final savedLocation = storageService.getLastSelectedLocation();
    final locationToLoad = savedLocation ?? defaultLocation;
    await selectLocation(locationToLoad, isInitial: true);
  }

  /// Mengganti kota aktif (misal setelah dipilih dari halaman pencarian),
  /// mencatatnya ke Hive, lalu memanggil REST API cuaca untuk kota tersebut
  Future<void> selectLocation(LocationModel location, {bool isInitial = false}) async {
    final isDifferentCity = _currentLocation?.id != location.id;
    _currentLocation = location;
    _isFavorite = storageService.isFavorite(location.id);

    // Reset data cuaca lama jika berpindah ke kota berbeda agar indikator loading tampil bersih
    if (isDifferentCity) {
      _weatherData = null;
    }

    // Simpan ke riwayat pencarian dan simpan sebagai lokasi terakhir di Hive
    await storageService.addToSearchHistory(location);
    await storageService.saveLastSelectedLocation(location);

    notifyListeners();
    await fetchWeather();
  }

  /// Mengambil data cuaca terkini & ramalan 7 hari dari Open-Meteo API
  /// sekaligus menangani transisi state: loading -> loaded / empty / error
  Future<void> fetchWeather({bool clearOldData = false}) async {
    if (_currentLocation == null) {
      _state = WeatherViewState.empty;
      notifyListeners();
      return;
    }

    if (clearOldData) {
      _weatherData = null;
    }

    // Set state menjadi loading dan beritahu View untuk menampilkan indikator pemuatan
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
      // Menangkap pesan error yang sudah diformat dari WeatherApiService
      _errorMessage = e.message;
      _state = WeatherViewState.error;
    } catch (e) {
      _errorMessage = 'Gagal memuat cuaca: $e';
      _state = WeatherViewState.error;
    } finally {
      // Pastikan status favorit tersinkron lalu perbarui tampilan View
      syncFavoriteStatus(notify: false);
      notifyListeners();
    }
  }

  /// Menyelaraskan status ikon favorit kota aktif jika diubah dari SearchScreen
  void syncFavoriteStatus({bool notify = true}) {
    if (_currentLocation == null) return;
    final latest = storageService.isFavorite(_currentLocation!.id);
    if (_isFavorite != latest) {
      _isFavorite = latest;
      _currentLocation = _currentLocation!.copyWith(isFavorite: latest);
      if (notify) notifyListeners();
    }
  }

  /// Menambah / menghapus kota yang sedang dibuka ke dalam daftar favorit Hive
  Future<bool> toggleFavorite() async {
    if (_currentLocation == null) return false;

    final newStatus = await storageService.toggleFavorite(_currentLocation!);
    _isFavorite = newStatus;
    _currentLocation = _currentLocation!.copyWith(isFavorite: newStatus);
    notifyListeners();
    return newStatus;
  }

  /// Memuat ulang data cuaca terbaru saat pengguna menarik layar ke bawah (pull-to-refresh)
  Future<void> refresh() async {
    await fetchWeather();
  }
}
