import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:worning_foold/data/open_meteo_flood_repository.dart';
import 'package:worning_foold/domain/flood_station.dart';

Map<String, dynamic> _entry(List<num?> discharge, List<num?> max) => {
  'latitude': 13.625,
  'longitude': 100.475,
  'daily': {
    'time': ['2026-10-06', '2026-10-07'],
    'river_discharge': discharge,
    'river_discharge_max': max,
  },
};

OpenMeteoFloodRepository _repo(Object body, {int status = 200}) =>
    OpenMeteoFloodRepository(
      client: MockClient((_) async => http.Response(jsonEncode(body), status)),
      points: const [
        MonitoringPoint('A', 13.62, 100.46),
        MonitoringPoint('B', 14.25, 100.52),
      ],
    );

void main() {
  test('parses multiple locations and maps names in order', () async {
    final stations = await _repo([
      _entry([100, 110], [120, 150]),
      _entry([100, 120], [250, 300]),
    ]).getStations();

    expect(stations.map((s) => s.name), ['A', 'B']);
    expect(stations[0].currentDischarge, 100);
    expect(stations[0].peakForecastDischarge, 150);
    expect(stations[0].risk, FloodRisk.watch);
    expect(stations[1].risk, FloodRisk.high);
  });

  test('accepts a single-object response and skips null values', () async {
    final stations = await _repo(_entry([null, 50], [null, 55])).getStations();

    expect(stations.single.currentDischarge, 50);
    expect(stations.single.risk, FloodRisk.normal);
  });

  test('throws FloodApiException on non-200', () {
    expect(
      _repo({'error': true}, status: 500).getStations(),
      throwsA(isA<FloodApiException>()),
    );
  });
}
