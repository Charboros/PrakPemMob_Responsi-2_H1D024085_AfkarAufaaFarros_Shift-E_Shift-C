import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/location_model.dart';
import '../viewmodels/search_viewmodel.dart';
import '../widgets/location_list_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchViewModel>().loadFavoritesAndHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onLocationSelected(LocationModel location) {
    Navigator.pop(context, location);
  }

  @override
  Widget build(BuildContext context) {
    final searchVM = context.watch<SearchViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Lokasi'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Input Kolom Pencarian
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'Ketik nama kota (contoh: Bandung, Purwokerto)',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          searchVM.clearSearch();
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                searchVM.onQueryChanged(value);
              },
              onSubmitted: (value) {
                searchVM.executeSearch(value);
              },
            ),
          ),

          // Body Content: Jika sedang cari, tampilkan hasil. Jika tidak, tampilkan Tabs Favorit & Riwayat.
          Expanded(
            child: _buildMainContent(searchVM),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(SearchViewModel searchVM) {
    // Jika ada teks pencarian
    if (searchVM.currentQuery.isNotEmpty) {
      return _buildSearchResults(searchVM);
    }

    // Jika tidak sedang mencari: Tampilkan TabBar untuk Favorit & Riwayat Pencarian
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

  Widget _buildSearchResults(SearchViewModel searchVM) {
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

    if (searchVM.state == SearchViewState.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 54, color: Colors.redAccent),
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

    if (searchVM.state == SearchViewState.empty || searchVM.searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off_rounded, size: 54, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'Tidak ada lokasi ditemukan untuk "${searchVM.currentQuery}"',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
              TextButton.icon(
                icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                label: const Text('Hapus Semua'),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Hapus Riwayat?'),
                      content: const Text('Semua riwayat pencarian lokasi akan dihapus.'),
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
