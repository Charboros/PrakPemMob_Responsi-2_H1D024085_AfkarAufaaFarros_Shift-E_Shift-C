import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/location_model.dart';
import '../services/storage_service.dart';
import '../services/weather_api_service.dart';

/// Status state pada halaman pencarian lokasi
enum SearchViewState { idle, searching, results, empty, error }

/// ============================================================================
/// LAYER VIEWMODEL (MVVM) - SearchViewModel
/// ----------------------------------------------------------------------------
/// Mengelola seluruh logika bisnis pada `SearchScreen`:
/// - Pencarian kota ke Geocoding API dengan teknik Debounce (jeda 500ms)
/// - Pembacaan & pembaruan daftar Lokasi Favorit dari Hive
/// - Pembacaan & penghapusan daftar Riwayat Pencarian dari Hive
/// ============================================================================
class SearchViewModel extends ChangeNotifier {
  final WeatherApiService apiService;
  final StorageService storageService;

  SearchViewState _state = SearchViewState.idle;
  List<LocationModel> _searchResults = [];
  List<LocationModel> _favorites = [];
  List<LocationModel> _searchHistory = [];
  String? _errorMessage;
  String _currentQuery = '';

  // Timer untuk mekanisme debounce agar tidak mengirim request di setiap ketukan huruf
  Timer? _debounceTimer;

  SearchViewModel({
    required this.apiService,
    required this.storageService,
  });

  // Getters untuk dibaca oleh SearchScreen
  SearchViewState get state => _state;
  List<LocationModel> get searchResults => _searchResults;
  List<LocationModel> get favorites => _favorites;
  List<LocationModel> get searchHistory => _searchHistory;
  String? get errorMessage => _errorMessage;
  String get currentQuery => _currentQuery;
  bool get isSearching => _state == SearchViewState.searching;

  /// Memuat ulang daftar favorit dan riwayat pencarian yang tersimpan di Hive
  void loadFavoritesAndHistory() {
    _favorites = storageService.getFavorites();
    _searchHistory = storageService.getSearchHistory();
    notifyListeners();
  }

  /// Dipanggil setiap kali teks di kolom pencarian berubah.
  /// Menggunakan debounce 500 milidetik: API baru dipanggil setelah pengguna berhenti mengetik.
  void onQueryChanged(String query) {
    _currentQuery = query;
    _debounceTimer?.cancel();

    final trimmed = query.trim();
    // Jika kolom input dikosongkan, kembali tampilkan tab Favorit & Riwayat
    if (trimmed.isEmpty) {
      _state = SearchViewState.idle;
      _searchResults = [];
      _errorMessage = null;
      loadFavoritesAndHistory();
      notifyListeners();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      executeSearch(trimmed);
    });
  }

  /// Menjalankan HTTP GET ke Open-Meteo Geocoding API sesuai kata kunci nama kota
  Future<void> executeSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    _currentQuery = trimmed;
    _state = SearchViewState.searching;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await apiService.searchLocations(trimmed);

      // Tandai kota mana saja di hasil pencarian yang sudah masuk daftar favorit Hive
      final syncedResults = results.map((loc) {
        return loc.copyWith(isFavorite: storageService.isFavorite(loc.id));
      }).toList();

      _searchResults = syncedResults;
      // Bedakan state ketika hasil ditemukan vs hasil kosong (kota tidak ada)
      if (syncedResults.isEmpty) {
        _state = SearchViewState.empty;
      } else {
        _state = SearchViewState.results;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = SearchViewState.error;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan saat mencari: $e';
      _state = SearchViewState.error;
    } finally {
      notifyListeners();
    }
  }

  /// Menyimpan atau menghapus lokasi dari daftar favorit Hive langsung dari daftar
  Future<void> toggleFavorite(LocationModel location) async {
    await storageService.toggleFavorite(location);

    // Perbarui isi tab Favorit & Riwayat
    loadFavoritesAndHistory();

    // Perbarui juga ikon hati pada daftar hasil pencarian yang sedang tampil
    if (_searchResults.isNotEmpty) {
      _searchResults = _searchResults.map((item) {
        if (item.id == location.id) {
          return item.copyWith(isFavorite: storageService.isFavorite(item.id));
        }
        return item;
      }).toList();
      notifyListeners();
    }
  }

  /// Menghapus satu item lokasi dari riwayat pencarian
  Future<void> removeFromHistory(int locationId) async {
    await storageService.removeFromHistory(locationId);
    loadFavoritesAndHistory();
  }

  /// Menghapus seluruh riwayat pencarian sekaligus
  Future<void> clearHistory() async {
    await storageService.clearSearchHistory();
    loadFavoritesAndHistory();
  }

  /// Mereset teks & hasil pencarian ke kondisi awal (idle)
  void clearSearch() {
    _debounceTimer?.cancel();
    _currentQuery = '';
    _searchResults = [];
    _state = SearchViewState.idle;
    _errorMessage = null;
    loadFavoritesAndHistory();
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
