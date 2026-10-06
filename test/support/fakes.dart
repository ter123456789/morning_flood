import 'dart:async';

import 'package:worning_foold/domain/flood_report.dart';
import 'package:worning_foold/domain/flood_report_repository.dart';
import 'package:worning_foold/domain/flood_repository.dart';
import 'package:worning_foold/domain/flood_station.dart';
import 'package:worning_foold/domain/geo_point.dart';
import 'package:worning_foold/domain/location_service.dart';
import 'package:worning_foold/domain/waterway.dart';
import 'package:worning_foold/domain/waterway_repository.dart';
import 'package:worning_foold/domain/wind_repository.dart';
import 'package:worning_foold/domain/wind_sample.dart';

class FakeFloodRepository implements FloodRepository {
  @override
  Future<List<FloodStation>> getStations() async => const [];
}

class FakeFloodReportRepository implements FloodReportRepository {
  FakeFloodReportRepository({this.currentUserId = 'me', this.submitError});

  final controller = StreamController<List<FloodReport>>.broadcast();
  final submitted = <NewFloodReport>[];
  final Object? submitError;

  @override
  final String? currentUserId;

  @override
  Stream<List<FloodReport>> watchRecent(Duration window) => controller.stream;

  @override
  Future<void> submit(NewFloodReport report) async {
    if (submitError case final e?) throw e;
    submitted.add(report);
  }
}

class FakeWaterwayRepository implements WaterwayRepository {
  @override
  Future<List<Waterway>> getWaterways() async => const [];
}

class FakeWindRepository implements WindRepository {
  final requests = <List<GeoPoint>>[];

  @override
  Future<List<WindSample>> getCurrentWind(List<GeoPoint> points) async {
    requests.add(points);
    return [
      for (final p in points)
        WindSample(
          latitude: p.latitude,
          longitude: p.longitude,
          speedKmh: 10,
          directionDegrees: 90,
        ),
    ];
  }
}

class FakeLocationService implements LocationService {
  @override
  Future<({double latitude, double longitude})> currentPosition() async =>
      (latitude: 13.75, longitude: 100.5);
}

FloodReport report({
  required String id,
  String userId = 'me',
  required DateTime createdAt,
}) => FloodReport(
  id: id,
  userId: userId,
  latitude: 13.7,
  longitude: 100.5,
  depth: WaterDepth.knee,
  createdAt: createdAt,
);
