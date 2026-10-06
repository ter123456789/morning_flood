import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/geo_point.dart';
import '../domain/wind_repository.dart';
import '../domain/wind_sample.dart';

class OpenMeteoWindRepository implements WindRepository {
  OpenMeteoWindRepository({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<List<WindSample>> getCurrentWind(List<GeoPoint> points) async {
    if (points.isEmpty) return const [];
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': points.map((p) => p.latitude.toStringAsFixed(3)).join(','),
      'longitude': points.map((p) => p.longitude.toStringAsFixed(3)).join(','),
      'current': 'wind_speed_10m,wind_direction_10m',
    });

    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw WindApiException('HTTP ${res.statusCode}');
    }

    final body = jsonDecode(res.body);
    // A single coordinate returns an object; multiple return a list.
    final entries = body is List ? body : [body];
    return [
      for (var i = 0; i < entries.length && i < points.length; i++)
        ?_sample(entries[i] as Map<String, dynamic>, points[i]),
    ];
  }

  // Uses the requested point rather than the snapped grid cell Open-Meteo
  // returns, so arrows stay evenly spaced on screen.
  static WindSample? _sample(Map<String, dynamic> json, GeoPoint point) {
    final current = json['current'] as Map<String, dynamic>?;
    final speed = current?['wind_speed_10m'] as num?;
    final direction = current?['wind_direction_10m'] as num?;
    if (speed == null || direction == null) return null;
    return WindSample(
      latitude: point.latitude,
      longitude: point.longitude,
      speedKmh: speed.toDouble(),
      directionDegrees: direction.toDouble(),
    );
  }
}

class WindApiException implements Exception {
  const WindApiException(this.message);

  final String message;

  @override
  String toString() => 'WindApiException: $message';
}
