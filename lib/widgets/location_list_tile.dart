import 'package:flutter/material.dart';
import '../models/location_model.dart';

/// ============================================================================
/// WIDGET REUSABLE - LocationListTile
/// ----------------------------------------------------------------------------
/// Menggunakan `StatelessWidget` untuk menampilkan satu item kota pada daftar
/// hasil pencarian, tab lokasi favorit, maupun tab riwayat pencarian.
/// Dilengkapi callback pemilihan lokasi, toggle favorit, & hapus riwayat.
/// ============================================================================
class LocationListTile extends StatelessWidget {
  final LocationModel location;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final VoidCallback? onDeleteTap;
  final bool showDelete;

  const LocationListTile({
    super.key,
    required this.location,
    required this.onTap,
    required this.onFavoriteTap,
    this.onDeleteTap,
    this.showDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.location_city_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          location.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          location.subtitleInfo.isNotEmpty
              ? location.subtitleInfo
              : 'Lat: ${location.latitude.toStringAsFixed(2)}, Lon: ${location.longitude.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tombol hati untuk menyimpan/menghapus lokasi dari daftar favorit Hive
            IconButton(
              icon: Icon(
                location.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: location.isFavorite
                    ? Colors.redAccent
                    : Colors.grey.shade500,
              ),
              tooltip: location.isFavorite
                  ? 'Hapus dari Favorit'
                  : 'Simpan ke Favorit',
              onPressed: onFavoriteTap,
            ),
            // Tombol silang (khusus di tab Riwayat) untuk menghapus satu item riwayat
            if (showDelete && onDeleteTap != null)
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: Colors.grey.shade500,
                ),
                tooltip: 'Hapus dari riwayat',
                onPressed: onDeleteTap,
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
