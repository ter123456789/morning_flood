import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:worning_foold/data/asset_waterway_repository.dart';

void main() {
  test('parses LineString and MultiLineString as lat/lng', () {
    final waterways = AssetWaterwayRepository.parseGeoJson('''
{"type":"FeatureCollection","features":[
  {"type":"Feature","properties":{"name":"แม่น้ำปิง"},
   "geometry":{"type":"LineString","coordinates":[[98.9,18.7],[99.0,18.6]]}},
  {"type":"Feature","properties":{"name":"แม่น้ำยม"},
   "geometry":{"type":"MultiLineString","coordinates":[[[99.8,16.9],[99.9,16.8]],[[100.0,16.0],[100.1,15.9]]]}},
  {"type":"Feature","properties":{"name":"จุด"},
   "geometry":{"type":"Point","coordinates":[100.0,15.0]}}
]}''');

    expect(waterways.map((w) => w.name), ['แม่น้ำปิง', 'แม่น้ำยม']);
    expect(waterways.first.lines.single.first, (
      latitude: 18.7,
      longitude: 98.9,
    ));
    expect(waterways.last.lines, hasLength(2));
  });

  test('bundled rivers asset parses', () {
    final waterways = AssetWaterwayRepository.parseGeoJson(
      File('assets/rivers.geojson').readAsStringSync(),
    );

    expect(waterways.map((w) => w.name), contains('แม่น้ำเจ้าพระยา'));
  });
}
