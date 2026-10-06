import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/geo_point.dart';
import '../domain/waterway.dart';
import '../domain/waterway_repository.dart';

/// Main rivers bundled as GeoJSON; regenerate with `tool/fetch_rivers.py`.
class AssetWaterwayRepository implements WaterwayRepository {
  AssetWaterwayRepository({
    AssetBundle? bundle,
    this.path = 'assets/rivers.geojson',
  }) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final String path;

  @override
  Future<List<Waterway>> getWaterways() async =>
      parseGeoJson(await _bundle.loadString(path));

  static List<Waterway> parseGeoJson(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return [
      for (final f in json['features'] as List)
        if (_lines(f['geometry'] as Map<String, dynamic>) case final lines?)
          Waterway(
            name:
                (f['properties'] as Map<String, dynamic>?)?['name']
                    as String? ??
                '',
            lines: lines,
          ),
    ];
  }

  static List<List<GeoPoint>>? _lines(Map<String, dynamic> geometry) {
    final coords = geometry['coordinates'] as List;
    return switch (geometry['type']) {
      'LineString' => [_line(coords)],
      'MultiLineString' => [for (final l in coords) _line(l as List)],
      _ => null,
    };
  }

  // GeoJSON positions are [longitude, latitude].
  static List<GeoPoint> _line(List coords) => [
    for (final c in coords)
      (
        latitude: ((c as List)[1] as num).toDouble(),
        longitude: (c[0] as num).toDouble(),
      ),
  ];
}
