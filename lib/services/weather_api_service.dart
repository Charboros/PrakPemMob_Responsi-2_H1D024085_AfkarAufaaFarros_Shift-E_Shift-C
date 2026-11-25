import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/location_model.dart';
import '../models/weather_response_model.dart';

/// Custom Exception untuk menampung pesan error jaringan yang ramah dibaca pengguna
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

/// ============================================================================
/// LAYER SERVICE (Networking) - WeatherApiService
/// ----------------------------------------------------------------------------
/// Bertugas melakukan komunikasi HTTP Request metode GET ke REST API Open-Meteo:
/// 1. Weather Forecast API : mengambil cuaca terkini & ramalan harian berdasarkan koordinat.
/// 2. Geocoding API        : mencari daftar lokasi/kota berdasarkan kata kunci nama kota.
/// ============================================================================
class WeatherApiService {
  static const String _forecastBaseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String _geocodingBaseUrl = 'https://geocoding-api.open-meteo.com/v1/search';
  static const Duration _timeout = Duration(seconds: 12);

  final http.Client _client;

  WeatherApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Mengambil data cuaca terkini (`current`) dan ramalan harian (`daily`)
  /// berdasarkan koordinat `latitude` dan `longitude` kota yang dipilih.
  Future<WeatherResponseModel> getForecast({
    required double latitude,
    required double longitude,
  }) async {
    // Menyusun parameter wajib sesuai spesifikasi soal responsi & dokumentasi Open-Meteo
    final queryParams = {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'current':
          'temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m',
      'daily':
          'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
      'timezone': 'auto', // Otomatis menyesuaikan zona waktu lokasi
    };

    final uri = Uri.parse(_forecastBaseUrl).replace(queryParameters: queryParams);

    try {
      // Mengirim HTTP Request metode GET dengan batas waktu tunggu (timeout) 12 detik
      final response = await _client.get(uri).timeout(_timeout);

      // Jika status 200 OK, decode teks JSON menjadi Map lalu ubah ke model Dart
      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        return WeatherResponseModel.fromJson(data);
      } else {
        throw ApiException('Gagal memuat data cuaca (Status: ${response.statusCode})');
      }
    } on SocketException {
      // Menangani kondisi perangkat sedang offline / tidak ada internet
      throw ApiException('Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
    } on TimeoutException {
      // Menangani kondisi jaringan lambat hingga melewati batas waktu
      throw ApiException('Koneksi terputus karena melebihi batas waktu (timeout). Coba lagi.');
    } on FormatException {
      throw ApiException('Format data respons server tidak valid.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kesalahan yang tidak terduga: $e');
    }
  }

  /// Mencari daftar kota berdasarkan nama menggunakan Open-Meteo Geocoding API
  Future<List<LocationModel>> searchLocations(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    // Parameter pencarian kota (maksimal 10 hasil, Bahasa Indonesia, format JSON)
    final queryParams = {
      'name': trimmed,
      'count': '10',
      'language': 'id',
      'format': 'json',
    };

    final uri = Uri.parse(_geocodingBaseUrl).replace(queryParameters: queryParams);

    try {
      // Mengirim HTTP GET request ke Geocoding API
      final response = await _client.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic>? results = data['results'] as List<dynamic>?;

        // Jika nama kota tidak ditemukan di API, kembalikan list kosong (empty state)
        if (results == null || results.isEmpty) {
          return [];
        }

        // Mengubah setiap item JSON hasil pencarian menjadi objek LocationModel
        return results
            .map((item) => LocationModel.fromGeocodingJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException('Gagal mencari lokasi (Status: ${response.statusCode})');
      }
    } on SocketException {
      throw ApiException('Koneksi internet tidak tersedia saat mencari lokasi.');
    } on TimeoutException {
      throw ApiException('Pencarian lokasi melebihi batas waktu (timeout). Coba lagi.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal melakukan pencarian lokasi: $e');
    }
  }
}
