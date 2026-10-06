enum FloodRisk { normal, watch, high }

class FloodStation {
  const FloodStation({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.currentDischarge,
    required this.peakForecastDischarge,
  });

  final String name;
  final double latitude;
  final double longitude;

  /// Today's river discharge (m³/s).
  final double currentDischarge;

  /// Highest discharge across the forecast window and ensemble members (m³/s).
  final double peakForecastDischarge;

  /// Ratio of the forecast peak to today's discharge.
  double get riseRatio =>
      currentDischarge <= 0 ? 0 : peakForecastDischarge / currentDischarge;

  // The API has no historical baseline, so risk is based on how sharply the
  // discharge is forecast to rise from today.
  FloodRisk get risk {
    if (riseRatio >= 2.0) return FloodRisk.high;
    if (riseRatio >= 1.3) return FloodRisk.watch;
    return FloodRisk.normal;
  }
}
