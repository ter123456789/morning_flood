import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:worning_foold/data/open_meteo_wind_repository.dart';

Map<String, dynamic> _entry(num? speed, num? direction) => {
  'latitude': 13.743,
  'longitude': 100.496,
  'current': {'wind_speed_10m': speed, 'wind_direction_10m': direction},
};

OpenMeteoWindRepository _repo(
  Object body, {
  int status = 200,
  void Function(Uri)? onRequest,
}) => OpenMeteoWindRepository(
  client: MockClient((req) async {
    onRequest?.call(req.url);
    return http.Response(jsonEncode(body), status);
  }),
);

const _points = [
  (latitude: 13.75, longitude: 100.5),
  (latitude: 18.79, longitude: 98.98),
];

void main() {
  test(
    'requests all points at once and keeps the requested coordinates',
    () async {
      Uri? uri;
      final wind = await _repo([
        _entry(2.9, 11),
        _entry(7, 250),
      ], onRequest: (u) => uri = u).getCurrentWind(_points);

      expect(uri!.queryParameters['latitude'], '13.750,18.790');
      expect(wind.map((w) => w.speedKmh), [2.9, 7]);
      expect(wind.map((w) => w.directionDegrees), [11, 250]);
      expect(wind.first.latitude, 13.75);
    },
  );

  test('accepts a single-object response and skips missing values', () async {
    final single = await _repo(_entry(5, 90)).getCurrentWind([_points.first]);
    expect(single.single.speedKmh, 5);

    final missing = await _repo([
      _entry(null, 90),
      _entry(3, 180),
    ]).getCurrentWind(_points);
    expect(missing.single.directionDegrees, 180);
  });

  test('throws WindApiException on non-200', () {
    expect(
      _repo({'error': true}, status: 500).getCurrentWind(_points),
      throwsA(isA<WindApiException>()),
    );
  });
}
