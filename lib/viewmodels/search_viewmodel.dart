import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/location_model.dart';
import '../services/storage_service.dart';
import '../services/weather_api_service.dart';

enum SearchViewState { idle, searching, results, empty, error }

class SearchViewModel extends ChangeNotifier {
  final WeatherApiService apiService;
  final StorageService storageService;

  SearchViewState _state = SearchViewState.idle;
  List<LocationModel> _searchResults = [];
  List<LocationModel> _favorites = [];
  List<LocationModel> _searchHistory = [];
  String? _errorMessage;
  String _currentQuery = '';

  Timer? _debounceTimer;

  SearchViewModel({
    required this.apiService,
    required this.storageService,
  });

  // Getters
  SearchViewState get state => _state;
  List<LocationModel> get searchResults => _searchResults;
  List<LocationModel> get favorites => _favorites;
  List<LocationModel> get searchHistory => _searchHistory;
  String? get errorMessage => _errorMessage;
  String get currentQuery => _currentQuery;
  bool get isSearching => _state == SearchViewState.searching;

  /// Memuat daftar favorit dan riwayat pencarian dari Hive
  void loadFavoritesAndHistory() {
    _favorites = storageService.getFavorites();
    _searchHistory = storageService.getSearchHistory();
    notifyListeners();
  }

  /// Pencarian dengan debounce otomatis saat pengguna mengetik
  void onQueryChanged(String query) {
    _currentQuery = query;
    _debounceTimer?.cancel();

    final trimmed = query.trim();
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

  /// Eksekusi pencarian ke Geocoding API
  Future<void> executeSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    _currentQuery = trimmed;
    _state = SearchViewState.searching;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await apiService.searchLocations(trimmed);

      // Sinkronkan status favorit dari Hive
      final syncedResults = results.map((loc) {
        return loc.copyWith(isFavorite: storageService.isFavorite(loc.id));
      }).toList();

      _searchResults = syncedResults;
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

  /// Toggle status favorit pada lokasi tertentu
  Future<void> toggleFavorite(LocationModel location) async {
    await storageService.toggleFavorite(location);

    // Refresh daftar favorit dan riwayat
    loadFavoritesAndHistory();

    // Perbarui juga flag di searchResults jika sedang ada hasil pencarian
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

  /// Hapus satu item dari riwayat pencarian
  Future<void> removeFromHistory(int locationId) async {
    await storageService.removeFromHistory(locationId);
    loadFavoritesAndHistory();
  }

  /// Bersihkan semua riwayat pencarian
  Future<void> clearHistory() async {
    await storageService.clearSearchHistory();
    loadFavoritesAndHistory();
  }

  /// Bersihkan input pencarian
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
