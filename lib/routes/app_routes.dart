import 'package:flutter/material.dart';
import '../views/home_screen.dart';
import '../views/search_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String search = '/search';

  static Map<String, WidgetBuilder> get routes => {
        home: (_) => const HomeScreen(),
        search: (_) => const SearchScreen(),
      };
}
