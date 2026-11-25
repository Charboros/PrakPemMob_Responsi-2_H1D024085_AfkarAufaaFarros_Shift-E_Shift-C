import 'package:flutter/material.dart';
import '../views/home_screen.dart';
import '../views/search_screen.dart';

/// ============================================================================
/// KONFIGURASI NAVIGASI (AppRoutes)
/// ----------------------------------------------------------------------------
/// Mengatur daftar Named Routes untuk perpindahan antar halaman utama aplikasi:
/// 1. `/`       -> HomeScreen (Layar utama cuaca terkini & perkiraan 7 hari)
/// 2. `/search` -> SearchScreen (Layar pencarian kota, favorit, & riwayat)
/// ============================================================================
class AppRoutes {
  static const String home = '/';
  static const String search = '/search';

  static Map<String, WidgetBuilder> get routes => {
        home: (_) => const HomeScreen(),
        search: (_) => const SearchScreen(),
      };
}
