class WindSample {
  const WindSample({
    required this.latitude,
    required this.longitude,
    required this.speedKmh,
    required this.directionDegrees,
  });

  final double latitude;
  final double longitude;
  final double speedKmh;

  /// Meteorological convention: the direction the wind blows *from*,
  /// clockwise from north.
  final double directionDegrees;
}
