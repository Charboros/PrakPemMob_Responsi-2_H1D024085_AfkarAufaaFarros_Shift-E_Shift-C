import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/location_model.dart';
import '../viewmodels/search_viewmodel.dart';
import '../widgets/location_list_tile.dart';

/// ============================================================================
/// LAYER VIEW (MVVM) - SearchScreen (Layar Pencarian & Favorit Lokasi)
/// ----------------------------------------------------------------------------
/// Menggunakan `StatefulWidget` karena mengelola `TextEditingController`
/// untuk kolom input pencarian serta `TabController` (Favorit & Riwayat)
/// yang wajib dibersihkan lewat method `dispose()` saat halaman ditutup.
/// ============================================================================
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller untuk 2 tab: Tab Lokasi Favorit & Tab Riwayat
    _tabController = TabController(length: 2, vsync: this);

    // Memuat data favorit dan riwayat pencarian dari Hive saat halaman dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchViewModel>().loadFavoritesAndHistory();
    });
  }

  @override
  void dispose() {
    // Membersihkan controller dari memori ketika halaman ditutup
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// Mengirim objek kota yang dipilih kembali ke HomeScreen untuk ditampilkan cuacanya
  void _onLocationSelected(LocationModel location) {
    Navigator.pop(context, location);
  }

  @override
  Widget build(BuildContext context) {
    // Mengamati perubahan state dari SearchViewModel
    final searchVM = context.watch<SearchViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Lokasi'),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              // Kolom input pencarian nama kota
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText: 'Ketik nama kota (contoh: Bandung, Purwokerto)',
                    prefixIcon: const Icon(Icons.search_rounded),
                    // Tombol silang (X) muncul otomatis saat ada teks di kolom pencarian
                    suffixIcon: searchVM.currentQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              searchVM.clearSearch();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.4),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  // Memicu pencarian otomatis dengan debounce 500ms saat mengetik
                  onChanged: (value) {
                    searchVM.onQueryChanged(value);
                  },
                  // Memicu pencarian langsung saat menekan tombol Enter/Search di keyboard
                  onSubmitted: (value) {
                    searchVM.executeSearch(value);
                  },
                ),
              ),

              // Area konten dinamis: menampilkan hasil pencarian API atau Tab Favorit & Riwayat
              Expanded(
                child: _buildMainContent(searchVM),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Menentukan apakah menampilkan daftar hasil pencarian atau Tab Favorit/Riwayat
  Widget _buildMainContent(SearchViewModel searchVM) {
    // Jika pengguna sedang mengetik kata kunci, tampilkan hasil pencarian dari API
    if (searchVM.currentQuery.isNotEmpty) {
      return _buildSearchResults(searchVM);
    }

    // Jika kolom pencarian kosong, tampilkan Tab Lokasi Favorit & Riwayat dari Hive
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          indicatorWeight: 3,
          tabs: [
            Tab(
              icon: const Icon(Icons.favorite_rounded, size: 20),
              text: 'Favorit (${searchVM.favorites.length})',
            ),
            Tab(
              icon: const Icon(Icons.history_rounded, size: 20),
              text: 'Riwayat (${searchVM.searchHistory.length})',
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildFavoritesTab(searchVM),
              _buildHistoryTab(searchVM),
            ],
          ),
        ),
      ],
    );
  }

  /// Menampilkan state hasil pencarian lokasi (Loading / Error / Data Kosong / Daftar Kota)
  Widget _buildSearchResults(SearchViewModel searchVM) {
    // 1. Kondisi Loading saat request ke Geocoding API
    if (searchVM.isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Mencari kota di Open-Meteo...'),
          ],
        ),
      );
    }

    // 2. Kondisi Error saat gagal terhubung ke API
    if (searchVM.state == SearchViewState.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 54, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                searchVM.errorMessage ?? 'Gagal mencari lokasi.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => searchVM.executeSearch(searchVM.currentQuery),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Kondisi Data Kosong jika nama kota tidak ditemukan
    if (searchVM.state == SearchViewState.empty ||
        searchVM.searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off_rounded,
                  size: 54, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'Tidak ada lokasi ditemukan untuk "${searchVM.currentQuery}"',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              const Text(
                'Coba periksa kembali ejaan nama kota Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // 4. Kondisi Berhasil: merender daftar kota hasil pencarian API
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: searchVM.searchResults.length,
      itemBuilder: (context, index) {
        final location = searchVM.searchResults[index];
        return LocationListTile(
          location: location,
          onTap: () => _onLocationSelected(location),
          onFavoriteTap: () => searchVM.toggleFavorite(location),
        );
      },
    );
  }

  /// Membangun isi Tab Lokasi Favorit yang tersimpan di Hive
  Widget _buildFavoritesTab(SearchViewModel searchVM) {
    if (searchVM.favorites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border_rounded,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              const Text(
                'Belum Ada Lokasi Favorit',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tekan ikon hati pada kota yang Anda sukai untuk menyimpannya di sini.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: searchVM.favorites.length,
      itemBuilder: (context, index) {
        final location = searchVM.favorites[index];
        return LocationListTile(
          location: location,
          onTap: () => _onLocationSelected(location),
          onFavoriteTap: () => searchVM.toggleFavorite(location),
        );
      },
    );
  }

  /// Membangun isi Tab Riwayat Pencarian yang tersimpan di Hive
  Widget _buildHistoryTab(SearchViewModel searchVM) {
    if (searchVM.searchHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history_rounded,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              const Text(
                'Belum Ada Riwayat',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Lokasi yang Anda buka sebelumnya akan muncul di riwayat ini.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Terakhir Dilihat',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              // Tombol untuk membersihkan seluruh riwayat dengan dialog konfirmasi
              TextButton.icon(
                icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                label: const Text('Hapus Semua'),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Hapus Riwayat?'),
                      content: const Text(
                          'Semua riwayat pencarian lokasi akan dihapus.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Batal'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            searchVM.clearHistory();
                            Navigator.pop(ctx);
                          },
                          child: const Text('Hapus'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 12),
            itemCount: searchVM.searchHistory.length,
            itemBuilder: (context, index) {
              final location = searchVM.searchHistory[index];
              return LocationListTile(
                location: location,
                showDelete: true,
                onTap: () => _onLocationSelected(location),
                onFavoriteTap: () => searchVM.toggleFavorite(location),
                onDeleteTap: () => searchVM.removeFromHistory(location.id),
              );
            },
          ),
        ),
      ],
    );
  }
}
