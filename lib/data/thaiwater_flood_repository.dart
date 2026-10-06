import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/flood_repository.dart';
import '../domain/flood_station.dart';
import 'thaiwater_dto.dart';

/// Telemetered water levels from ThaiWater (HII). The endpoint is the public
/// one used by thaiwater.net; it is undocumented, so parse defensively.
class ThaiWaterFloodRepository implements FloodRepository {
  ThaiWaterFloodRepository({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<List<FloodStation>> getStations() async {
    final uri = Uri.https(
      'api-v3.thaiwater.net',
      '/api/v1/thaiwater30/public/waterlevel_load',
    );

    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw FloodApiException('HTTP ${res.statusCode}');
    }

    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final data = body['waterlevel_data'] as Map<String, dynamic>?;
    if (data?['result'] != 'OK') {
      throw const FloodApiException('Unexpected response');
    }
    return [
      for (final row in data!['data'] as List)
        ?ThaiWaterLevelDto.fromJson(row as Map<String, dynamic>).toEntity(),
    ];
  }
}

class FloodApiException implements Exception {
  const FloodApiException(this.message);

  final String message;

  @override
  String toString() => 'FloodApiException: $message';
}
