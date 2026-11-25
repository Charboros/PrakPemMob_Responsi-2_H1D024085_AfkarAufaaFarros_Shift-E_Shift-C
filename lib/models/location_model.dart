class LocationModel {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final String country;
  final String? admin1; // Provinsi / Daerah
  final String? timezone;
  final bool isFavorite;
  final DateTime? lastViewedAt;

  LocationModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.country,
    this.admin1,
    this.timezone,
    this.isFavorite = false,
    this.lastViewedAt,
  });

  LocationModel copyWith({
    int? id,
    String? name,
    double? latitude,
    double? longitude,
    String? country,
    String? admin1,
    String? timezone,
    bool? isFavorite,
    DateTime? lastViewedAt,
  }) {
    return LocationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      country: country ?? this.country,
      admin1: admin1 ?? this.admin1,
      timezone: timezone ?? this.timezone,
      isFavorite: isFavorite ?? this.isFavorite,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
    );
  }

  // Mapping dari Open-Meteo Geocoding JSON
  factory LocationModel.fromGeocodingJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      name: json['name'] as String? ?? 'Lokasi Tidak Diketahui',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      country: json['country'] as String? ?? '',
      admin1: json['admin1'] as String?,
      timezone: json['timezone'] as String?,
    );
  }

  // Konversi ke Map untuk penyimpanan di Hive
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'country': country,
      'admin1': admin1,
      'timezone': timezone,
      'isFavorite': isFavorite,
      'lastViewedAt': lastViewedAt?.toIso8601String(),
    };
  }

  // Baca dari Map Hive
  factory LocationModel.fromMap(Map<dynamic, dynamic> map) {
    return LocationModel(
      id: map['id'] as int? ?? 0,
      name: map['name'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      country: map['country'] as String? ?? '',
      admin1: map['admin1'] as String?,
      timezone: map['timezone'] as String?,
      isFavorite: map['isFavorite'] as bool? ?? false,
      lastViewedAt: map['lastViewedAt'] != null
          ? DateTime.tryParse(map['lastViewedAt'] as String)
          : null,
    );
  }

  String get displayName {
    if (admin1 != null && admin1!.isNotEmpty && admin1 != name) {
      return '$name, $admin1';
    }
    if (country.isNotEmpty) {
      return '$name, $country';
    }
    return name;
  }

  String get subtitleInfo {
    final parts = <String>[];
    if (admin1 != null && admin1!.isNotEmpty) parts.add(admin1!);
    if (country.isNotEmpty) parts.add(country);
    return parts.join(', ');
  }
}
