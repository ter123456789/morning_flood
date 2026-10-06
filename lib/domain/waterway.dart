import 'geo_point.dart';

class Waterway {
  const Waterway({required this.name, required this.lines});

  final String name;

  /// A river is mapped as several disconnected segments.
  final List<List<GeoPoint>> lines;
}
