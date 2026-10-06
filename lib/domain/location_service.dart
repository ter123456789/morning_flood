abstract interface class LocationService {
  /// Current device position. Throws [LocationException] when unavailable.
  Future<({double latitude, double longitude})> currentPosition();
}

class LocationException implements Exception {
  const LocationException(this.message);

  final String message;

  @override
  String toString() => message;
}
