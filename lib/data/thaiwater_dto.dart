import '../domain/flood_station.dart';

/// One row of `waterlevel_data.data` in the ThaiWater `waterlevel_load` response.
class ThaiWaterLevelDto {
  const ThaiWaterLevelDto({
    required this.name,
    required this.amphoe,
    required this.province,
    required this.latitude,
    required this.longitude,
    required this.situationLevel,
    required this.datetime,
    required this.waterLevelMsl,
    required this.storagePercent,
  });

  factory ThaiWaterLevelDto.fromJson(Map<String, dynamic> json) {
    final station = json['station'] as Map<String, dynamic>? ?? const {};
    final geocode = json['geocode'] as Map<String, dynamic>? ?? const {};
    return ThaiWaterLevelDto(
      name: _th(station['tele_station_name']),
      amphoe: _th(geocode['amphoe_name']),
      province: _th(geocode['province_name']),
      latitude: _toDouble(station['tele_station_lat']),
      longitude: _toDouble(station['tele_station_long']),
      situationLevel: (json['situation_level'] as num?)?.toInt(),
      datetime: json['waterlevel_datetime'] as String?,
      waterLevelMsl: _toDouble(json['waterlevel_msl']),
      storagePercent: _toDouble(json['storage_percent']),
    );
  }

  final String name;
  final String amphoe;
  final String province;
  final double? latitude;
  final double? longitude;
  final int? situationLevel;

  /// Thai local time, formatted "yyyy-MM-dd HH:mm".
  final String? datetime;
  final double? waterLevelMsl;
  final double? storagePercent;

  /// Returns null when the row can't be placed on the map or has no status.
  FloodStation? toEntity() {
    final lat = latitude, lng = longitude, level = situationLevel;
    final observedAt = _parseThaiTime(datetime);
    if (lat == null || lng == null || level == null || observedAt == null) {
      return null;
    }
    return FloodStation(
      name: name,
      province: province,
      location: [amphoe, province].where((s) => s.isNotEmpty).join(', '),
      latitude: lat,
      longitude: lng,
      risk: riskFromSituationLevel(level),
      observedAt: observedAt,
      waterLevelMsl: waterLevelMsl,
      capacityPercent: storagePercent,
    );
  }

  // ThaiWater scale: 5 = overflowing bank (>100%), 4 = high (>70%),
  // 1–3 = normal down to critically low.
  static FloodRisk riskFromSituationLevel(int level) => switch (level) {
    >= 5 => FloodRisk.high,
    4 => FloodRisk.watch,
    _ => FloodRisk.normal,
  };

  static DateTime? _parseThaiTime(String? value) {
    if (value == null) return null;
    return DateTime.tryParse('${value.replaceFirst(' ', 'T')}:00+07:00');
  }

  static String _th(Object? names) =>
      (names as Map<String, dynamic>?)?['th'] as String? ?? '';

  // Numeric fields arrive as either numbers or strings.
  static double? _toDouble(Object? value) => switch (value) {
    num n => n.toDouble(),
    String s => double.tryParse(s),
    _ => null,
  };
}
