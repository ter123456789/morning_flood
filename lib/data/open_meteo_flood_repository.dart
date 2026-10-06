import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/flood_repository.dart';
import '../domain/flood_station.dart';
import 'flood_api_dto.dart';

class MonitoringPoint {
  const MonitoringPoint(this.name, this.latitude, this.longitude);

  final String name;
  final double latitude;
  final double longitude;
}

// Coordinates are snapped to the GloFAS grid cell on each river's main
// channel; a city-centre coordinate often lands on a tiny tributary cell.
const thaiMonitoringPoints = [
  MonitoringPoint('แม่น้ำปิง – เชียงใหม่', 18.68, 98.95),
  MonitoringPoint('แม่น้ำยม – สุโขทัย', 16.91, 99.87),
  MonitoringPoint('แม่น้ำน่าน – พิษณุโลก', 16.72, 100.21),
  MonitoringPoint('เจ้าพระยา – นครสวรรค์', 15.60, 100.02),
  MonitoringPoint('เจ้าพระยา – อยุธยา', 14.25, 100.52),
  MonitoringPoint('เจ้าพระยา – กรุงเทพฯ', 13.62, 100.46),
  MonitoringPoint('แม่น้ำป่าสัก – สระบุรี', 14.53, 100.81),
  MonitoringPoint('บางปะกง – ฉะเชิงเทรา', 13.59, 100.97),
  MonitoringPoint('แม่น้ำโขง – หนองคาย', 17.98, 102.84),
  MonitoringPoint('แม่น้ำชี – ขอนแก่น', 16.40, 102.85),
  MonitoringPoint('แม่น้ำมูล – อุบลราชธานี', 15.28, 104.91),
  MonitoringPoint('แม่น้ำตาปี – สุราษฎร์ธานี', 9.18, 99.32),
];

class OpenMeteoFloodRepository implements FloodRepository {
  OpenMeteoFloodRepository({
    http.Client? client,
    this.points = thaiMonitoringPoints,
    this.forecastDays = 7,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final List<MonitoringPoint> points;
  final int forecastDays;

  @override
  Future<List<FloodStation>> getStations() async {
    final uri = Uri.https('flood-api.open-meteo.com', '/v1/flood', {
      'latitude': points.map((p) => p.latitude).join(','),
      'longitude': points.map((p) => p.longitude).join(','),
      'daily': 'river_discharge,river_discharge_max',
      'forecast_days': '$forecastDays',
    });

    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw FloodApiException('HTTP ${res.statusCode}');
    }

    final body = jsonDecode(res.body);
    // A single coordinate returns an object; multiple return a list.
    final entries = body is List ? body : [body];
    return [
      for (var i = 0; i < entries.length && i < points.length; i++)
        FloodApiDto.fromJson(
          entries[i] as Map<String, dynamic>,
        ).toEntity(points[i].name),
    ];
  }
}

class FloodApiException implements Exception {
  const FloodApiException(this.message);

  final String message;

  @override
  String toString() => 'FloodApiException: $message';
}
