import 'package:hive_flutter/hive_flutter.dart';
import '../models/location_model.dart';

class StorageService {
  static const String favoritesBoxName = 'favorites_box';
  static const String historyBoxName = 'search_history_box';
  static const String settingsBoxName = 'settings_box';
  static const String lastLocationKey = 'last_selected_location';

  late Box<Map> _favoritesBox;
  late Box<Map> _historyBox;
  late Box<dynamic> _settingsBox;

  /// Inisialisasi Hive dan buka seluruh Box yang diperlukan
  Future<void> init() async {
    await Hive.initFlutter();
    _favoritesBox = await Hive.openBox<Map>(favoritesBoxName);
    _historyBox = await Hive.openBox<Map>(historyBoxName);
    _settingsBox = await Hive.openBox<dynamic>(settingsBoxName);
  }

  // ==================== LOKASI FAVORIT ====================

  /// Mendapatkan semua lokasi favorit yang tersimpan
  List<LocationModel> getFavorites() {
    final List<LocationModel> favorites = [];
    for (final key in _favoritesBox.keys) {
      final data = _favoritesBox.get(key);
      if (data != null) {
        favorites.add(LocationModel.fromMap(data).copyWith(isFavorite: true));
      }
    }
    // Urutkan favorit berdasarkan nama
    favorites.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return favorites;
  }

  /// Cek apakah suatu ID lokasi ada di daftar favorit
  bool isFavorite(int locationId) {
    return _favoritesBox.containsKey(locationId.toString());
  }

  /// Toggle status favorit (tambah jika belum ada, hapus jika sudah ada)
  Future<bool> toggleFavorite(LocationModel location) async {
    final key = location.id.toString();
    if (_favoritesBox.containsKey(key)) {
      await _favoritesBox.delete(key);
      return false; // Sekarang bukan favorit
    } else {
      final favLocation = location.copyWith(isFavorite: true);
      await _favoritesBox.put(key, favLocation.toMap());
      return true; // Sekarang favorit
    }
  }

  /// Menghapus lokasi dari favorit
  Future<void> removeFavorite(int locationId) async {
    await _favoritesBox.delete(locationId.toString());
  }

  // ==================== RIWAYAT PENCARIAN ====================

  /// Mengambil daftar riwayat pencarian (maksimal 15 terakhir)
  List<LocationModel> getSearchHistory() {
    final List<LocationModel> history = [];
    for (final key in _historyBox.keys) {
      final data = _historyBox.get(key);
      if (data != null) {
        final loc = LocationModel.fromMap(data);
        // Sinkronkan status favorit saat ini
        final isFav = isFavorite(loc.id);
        history.add(loc.copyWith(isFavorite: isFav));
      }
    }
    // Urutkan dari yang paling baru dilihat
    history.sort((a, b) {
      final aTime = a.lastViewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.lastViewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return history;
  }

  /// Menambahkan lokasi ke riwayat pencarian
  Future<void> addToSearchHistory(LocationModel location) async {
    final key = location.id.toString();
    final updated = location.copyWith(
      lastViewedAt: DateTime.now(),
      isFavorite: isFavorite(location.id),
    );
    await _historyBox.put(key, updated.toMap());

    // Batasi riwayat maksimal 20 item agar hemat memori
    if (_historyBox.length > 20) {
      final all = getSearchHistory();
      if (all.length > 20) {
        for (int i = 20; i < all.length; i++) {
          await _historyBox.delete(all[i].id.toString());
        }
      }
    }
  }

  /// Menghapus satu item dari riwayat
  Future<void> removeFromHistory(int locationId) async {
    await _historyBox.delete(locationId.toString());
  }

  /// Membersihkan seluruh riwayat pencarian
  Future<void> clearSearchHistory() async {
    await _historyBox.clear();
  }

  // ==================== LOKASI TERAKHIR DIAKSES ====================

  /// Menyimpan lokasi terakhir yang sedang dibuka pengguna
  Future<void> saveLastSelectedLocation(LocationModel location) async {
    await _settingsBox.put(lastLocationKey, location.toMap());
  }

  /// Memuat lokasi terakhir yang disimpan saat aplikasi dibuka kembali
  LocationModel? getLastSelectedLocation() {
    final data = _settingsBox.get(lastLocationKey);
    if (data != null && data is Map) {
      final loc = LocationModel.fromMap(data);
      return loc.copyWith(isFavorite: isFavorite(loc.id));
    }
    return null;
  }
}
