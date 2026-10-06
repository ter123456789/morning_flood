import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:worning_foold/data/thaiwater_flood_repository.dart';
import 'package:worning_foold/domain/flood_station.dart';

Map<String, dynamic> _row({
  Object? level = 3,
  Object? lat = 13.661021,
  Object? msl = '1.66',
  Object? percent = '129.78',
}) => {
  'waterlevel_datetime': '2026-10-06 15:20',
  'waterlevel_msl': msl,
  'storage_percent': percent,
  'situation_level': level,
  'station': {
    'tele_station_name': {'th': 'ปตร. คลองลัดบางยอ 2', 'en': 'Gate'},
    'tele_station_lat': lat,
    'tele_station_long': 100.56727,
  },
  'geocode': {
    'amphoe_name': {'th': 'พระประแดง'},
    'province_name': {'th': 'สมุทรปราการ'},
  },
};

ThaiWaterFloodRepository _repo(Object body, {int status = 200}) =>
    ThaiWaterFloodRepository(
      client: MockClient(
        (_) async => http.Response.bytes(utf8.encode(jsonEncode(body)), status),
      ),
    );

Map<String, dynamic> _body(List<Object> rows) => {
  'waterlevel_data': {'result': 'OK', 'data': rows},
};

void main() {
  test('parses a station row', () async {
    final s = (await _repo(_body([_row()])).getStations()).single;

    expect(s.name, 'ปตร. คลองลัดบางยอ 2');
    expect(s.location, 'พระประแดง, สมุทรปราการ');
    expect(s.latitude, 13.661021);
    expect(s.waterLevelMsl, 1.66);
    expect(s.capacityPercent, 129.78);
    expect(s.observedAt, DateTime.utc(2026, 10, 6, 8, 20));
  });

  test('maps situation_level to risk', () async {
    final stations = await _repo(
      _body([_row(level: 5), _row(level: 4), _row(level: 3), _row(level: 1)]),
    ).getStations();

    expect(stations.map((s) => s.risk), [
      FloodRisk.high,
      FloodRisk.watch,
      FloodRisk.normal,
      FloodRisk.normal,
    ]);
  });

  test('skips rows without a level or coordinates', () async {
    final stations = await _repo(
      _body([_row(level: null), _row(lat: null), _row(percent: null)]),
    ).getStations();

    expect(stations.single.capacityPercent, isNull);
  });

  test('throws FloodApiException on non-200', () {
    expect(
      _repo({'error': true}, status: 500).getStations(),
      throwsA(isA<FloodApiException>()),
    );
  });

  test('throws FloodApiException when result is not OK', () {
    expect(
      _repo({
        'waterlevel_data': {'result': 'NO', 'data': []},
      }).getStations(),
      throwsA(isA<FloodApiException>()),
    );
  });
}
