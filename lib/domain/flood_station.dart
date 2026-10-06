enum FloodRisk { normal, watch, high }

class FloodStation {
  const FloodStation({
    required this.name,
    required this.province,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.risk,
    required this.observedAt,
    this.waterLevelMsl,
    this.capacityPercent,
  });

  final String name;
  final String province;

  /// District and province, e.g. "พระประแดง, สมุทรปราการ".
  final String location;
  final double latitude;
  final double longitude;
  final FloodRisk risk;
  final DateTime observedAt;

  /// Water level above mean sea level (m).
  final double? waterLevelMsl;

  /// Water level as a percentage of the channel's bank-full capacity.
  final double? capacityPercent;
}
