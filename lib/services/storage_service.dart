import 'package:hive_flutter/hive_flutter.dart';
import '../models/location_model.dart';

/// ============================================================================
/// LAYER SERVICE (Local Storage) - StorageService
/// ----------------------------------------------------------------------------
/// Mengimplementasikan penyimpanan lokal persisten menggunakan library **Hive**.
/// Data disimpan ke dalam 3 Box (tabel key-value NoSQL lokal di perangkat):
/// 1. `favorites_box`      : menyimpan daftar kota favorit pengguna.
/// 2. `search_history_box` : menyimpan riwayat lokasi yang pernah dibuka.
/// 3. `settings_box`       : menyimpan lokasi terakhir agar otomatis tampil kembali
///                           ketika aplikasi ditutup lalu dibuka ulang.
/// ============================================================================
class StorageService {
  static const String favoritesBoxName = 'favorites_box';
  static const String historyBoxName = 'search_history_box';
  static const String settingsBoxName = 'settings_box';
  static const String lastLocationKey = 'last_selected_location';

  late Box<Map> _favoritesBox;
  late Box<Map> _historyBox;
  late Box<dynamic> _settingsBox;

  /// Inisialisasi direktori penyimpanan Hive di Flutter dan membuka ketiga Box
  Future<void> init() async {
    await Hive.initFlutter();
    _favoritesBox = await Hive.openBox<Map>(favoritesBoxName);
    _historyBox = await Hive.openBox<Map>(historyBoxName);
    _settingsBox = await Hive.openBox<dynamic>(settingsBoxName);
  }

  // ==================== 1. MANAJEMEN LOKASI FAVORIT ====================

  /// Mengambil seluruh daftar lokasi favorit yang tersimpan di Hive
  List<LocationModel> getFavorites() {
    final List<LocationModel> favorites = [];
    for (final key in _favoritesBox.keys) {
      final data = _favoritesBox.get(key);
      if (data != null) {
        favorites.add(LocationModel.fromMap(data).copyWith(isFavorite: true));
      }
    }
    // Mengurutkan daftar favorit sesuai abjad nama kota (A-Z)
    favorites.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return favorites;
  }

  /// Mengecek apakah suatu ID kota sudah tersimpan di daftar favorit
  bool isFavorite(int locationId) {
    return _favoritesBox.containsKey(locationId.toString());
  }

  /// Menambah kota ke favorit jika belum ada, atau menghapusnya jika sudah ada
  Future<bool> toggleFavorite(LocationModel location) async {
    final key = location.id.toString();
    if (_favoritesBox.containsKey(key)) {
      await _favoritesBox.delete(key);
      return false; // Status terbaru: bukan favorit
    } else {
      final favLocation = location.copyWith(isFavorite: true);
      await _favoritesBox.put(key, favLocation.toMap());
      return true; // Status terbaru: menjadi favorit
    }
  }

  /// Menghapus satu lokasi dari Box favorit berdasarkan ID
  Future<void> removeFavorite(int locationId) async {
    await _favoritesBox.delete(locationId.toString());
  }

  // ==================== 2. MANAJEMEN RIWAYAT PENCARIAN ====================

  /// Mengambil seluruh riwayat lokasi yang pernah dilihat (diurutkan dari terbaru)
  List<LocationModel> getSearchHistory() {
    final List<LocationModel> history = [];
    for (final key in _historyBox.keys) {
      final data = _historyBox.get(key);
      if (data != null) {
        final loc = LocationModel.fromMap(data);
        // Menyelaraskan tanda ikon hati dengan status favorit terkini
        final isFav = isFavorite(loc.id);
        history.add(loc.copyWith(isFavorite: isFav));
      }
    }
    // Urutkan berdasarkan waktu kunjungan terbaru di posisi paling atas
    history.sort((a, b) {
      final aTime = a.lastViewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.lastViewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return history;
  }

  /// Mencatat lokasi yang dipilih pengguna ke dalam riwayat pencarian Hive
  Future<void> addToSearchHistory(LocationModel location) async {
    final key = location.id.toString();
    final updated = location.copyWith(
      lastViewedAt: DateTime.now(),
      isFavorite: isFavorite(location.id),
    );
    await _historyBox.put(key, updated.toMap());

    // Membatasi maksimal 20 riwayat terakhir agar penyimpanan tetap ringan
    if (_historyBox.length > 20) {
      final all = getSearchHistory();
      if (all.length > 20) {
        for (int i = 20; i < all.length; i++) {
          await _historyBox.delete(all[i].id.toString());
        }
      }
    }
  }

  /// Menghapus satu item tertentu dari riwayat pencarian
  Future<void> removeFromHistory(int locationId) async {
    await _historyBox.delete(locationId.toString());
  }

  /// Menghapus seluruh isi riwayat pencarian sekaligus
  Future<void> clearSearchHistory() async {
    await _historyBox.clear();
  }

  // ==================== 3. LOKASI TERAKHIR DIAKSES ====================

  /// Menyimpan kota yang sedang aktif agar tidak hilang saat aplikasi ditutup
  Future<void> saveLastSelectedLocation(LocationModel location) async {
    await _settingsBox.put(lastLocationKey, location.toMap());
  }

  /// Membaca kembali kota terakhir saat aplikasi baru dibuka
  LocationModel? getLastSelectedLocation() {
    final data = _settingsBox.get(lastLocationKey);
    if (data != null && data is Map) {
      final loc = LocationModel.fromMap(data);
      return loc.copyWith(isFavorite: isFavorite(loc.id));
    }
    return null;
  }
}
