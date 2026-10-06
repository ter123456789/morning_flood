import '../domain/flood_station.dart';

/// One location entry of the Open-Meteo Flood API daily response.
class FloodApiDto {
  const FloodApiDto({
    required this.latitude,
    required this.longitude,
    required this.riverDischarge,
    required this.riverDischargeMax,
  });

  factory FloodApiDto.fromJson(Map<String, dynamic> json) {
    final daily = json['daily'] as Map<String, dynamic>;
    return FloodApiDto(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      riverDischarge: _toDoubles(daily['river_discharge']),
      riverDischargeMax: _toDoubles(daily['river_discharge_max']),
    );
  }

  final double latitude;
  final double longitude;
  final List<double?> riverDischarge;
  final List<double?> riverDischargeMax;

  FloodStation toEntity(String name) {
    final current = riverDischarge.firstWhere(
      (v) => v != null,
      orElse: () => 0,
    )!;
    final peaks = [...riverDischarge, ...riverDischargeMax].whereType<double>();
    return FloodStation(
      name: name,
      latitude: latitude,
      longitude: longitude,
      currentDischarge: current,
      peakForecastDischarge: peaks.isEmpty
          ? current
          : peaks.reduce((a, b) => a > b ? a : b),
    );
  }

  static List<double?> _toDoubles(Object? values) =>
      (values as List? ?? const [])
          .map((v) => (v as num?)?.toDouble())
          .toList();
}
