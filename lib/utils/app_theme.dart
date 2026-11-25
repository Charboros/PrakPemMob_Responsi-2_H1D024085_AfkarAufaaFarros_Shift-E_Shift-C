import 'package:flutter/material.dart';

/// ============================================================================
/// KONFIGURASI THEME & TYPOGRAPHY (AppTheme)
/// ----------------------------------------------------------------------------
/// Mengatur tampilan Material Design 3 secara terpusat agar warna komponen
/// dan ukuran huruf (Typography) konsisten serta mudah dibaca di seluruh layar.
/// ============================================================================
class AppTheme {
  // Warna dasar (seed color) untuk menghasilkan palet warna Material 3
  static const Color primarySeed = Color(0xFF1E88E5);

  /// Tema utama aplikasi
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primarySeed,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF6F8FC),

      // Hierarki Typography: dari teks angka suhu berukuran besar hingga label kecil
      textTheme: const TextTheme(
        // Dipakai untuk angka suhu utama di HomeScreen (misal: 28°C)
        displayLarge: TextStyle(
          fontSize: 68,
          fontWeight: FontWeight.w300,
          letterSpacing: -1.5,
          height: 1.1,
        ),
        // Dipakai untuk deskripsi kondisi cuaca utama & judul pesan status
        headlineSmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        // Dipakai untuk judul seksi (contoh: "Informasi Cuaca", nama kota di AppBar)
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        // Dipakai untuk nilai metrik cuaca pada kartu detail
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        // Dipakai untuk teks isi utama & daftar hari ramalan cuaca
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          height: 1.4,
        ),
        // Dipakai untuk teks keterangan pendukung / saran aktivitas cuaca
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          height: 1.35,
        ),
        // Dipakai untuk label kecil seperti tanggal dan subjudul kartu
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Standar tampilan AppBar di seluruh halaman
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),

      // Standar sudut membulat (rounded corner) pada widget Card
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Standar tampilan tombol ElevatedButton (misal tombol "Coba Lagi")
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      // Standar tampilan notifikasi mengambang (SnackBar) saat simpan/hapus favorit
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
