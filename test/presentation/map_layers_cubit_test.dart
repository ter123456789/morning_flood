import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worning_foold/domain/geo_point.dart';
import 'package:worning_foold/domain/location_service.dart';
import 'package:worning_foold/domain/waterway.dart';
import 'package:worning_foold/domain/waterway_repository.dart';
import 'package:worning_foold/domain/wind_repository.dart';
import 'package:worning_foold/domain/wind_sample.dart';
import 'package:worning_foold/presentation/bloc/map_layers_cubit.dart';
import 'package:worning_foold/presentation/bloc/map_layers_state.dart';

import '../support/fakes.dart';

class _FailingWaterways implements WaterwayRepository {
  @override
  Future<List<Waterway>> getWaterways() async => throw Exception('missing');
}

class _DeniedLocation implements LocationService {
  @override
  Future<({double latitude, double longitude})> currentPosition() async =>
      throw const LocationException('denied');
}

class _FailingWind implements WindRepository {
  @override
  Future<List<WindSample>> getCurrentWind(List<GeoPoint> points) async =>
      throw Exception('offline');
}

const _bounds = (south: 13.0, west: 100.0, north: 14.0, east: 101.0);

void main() {
  test('wind grid is evenly spaced inside the bounds', () {
    final grid = MapLayersCubit.windGrid(_bounds);

    expect(grid, hasLength(25));
    expect(grid.first, (latitude: 13.1, longitude: 100.1));
    expect(grid.last.latitude, closeTo(13.9, 1e-9));
    expect(grid.last.longitude, closeTo(100.9, 1e-9));
  });

  blocTest<MapLayersCubit, MapLayersState>(
    'waterways are shown by default and wind is off',
    build: () => MapLayersCubit(
      FakeWaterwayRepository(),
      FakeWindRepository(),
      FakeLocationService(),
    ),
    verify: (c) {
      expect(c.state.showWaterways, isTrue);
      expect(c.state.showWind, isFalse);
    },
  );

  test('loadWind does nothing while the layer is off', () async {
    final wind = FakeWindRepository();
    await MapLayersCubit(
      FakeWaterwayRepository(),
      wind,
      FakeLocationService(),
    ).loadWind(_bounds);

    expect(wind.requests, isEmpty);
  });

  blocTest<MapLayersCubit, MapLayersState>(
    'loads wind for the grid once enabled',
    build: () => MapLayersCubit(
      FakeWaterwayRepository(),
      FakeWindRepository(),
      FakeLocationService(),
    ),
    act: (c) async {
      c.toggleWind();
      await c.loadWind(_bounds);
    },
    verify: (c) {
      expect(c.state.showWind, isTrue);
      expect(c.state.wind, hasLength(25));
      expect(c.state.myPosition, (latitude: 13.75, longitude: 100.5));
    },
  );

  test(
    'drops a wind response that arrives after the layer is turned off',
    () async {
      final gate = Completer<void>();
      final cubit = MapLayersCubit(
        FakeWaterwayRepository(),
        _GatedWind(gate.future),
        FakeLocationService(),
      )..toggleWind();

      final pending = cubit.loadWind(_bounds);
      cubit.toggleWind();
      gate.complete();
      await pending;

      expect(cubit.state.wind, isEmpty);
    },
  );

  blocTest<MapLayersCubit, MapLayersState>(
    'wind still works when location is unavailable',
    build: () => MapLayersCubit(
      FakeWaterwayRepository(),
      FakeWindRepository(),
      _DeniedLocation(),
    ),
    act: (c) async {
      c.toggleWind();
      await c.loadWind(_bounds);
    },
    verify: (c) {
      expect(c.state.myPosition, isNull);
      expect(c.state.wind, hasLength(25));
    },
  );

  blocTest<MapLayersCubit, MapLayersState>(
    'reports load errors',
    build: () => MapLayersCubit(
      _FailingWaterways(),
      _FailingWind(),
      FakeLocationService(),
    ),
    act: (c) async {
      await c.loadWaterways();
      c.toggleWind();
      await c.loadWind(_bounds);
    },
    verify: (c) => expect(c.state.errorMessage, contains('offline')),
    expect: () => [
      isA<MapLayersState>().having(
        (s) => s.errorMessage,
        'error',
        contains('missing'),
      ),
      isA<MapLayersState>(),
      isA<MapLayersState>(),
      isA<MapLayersState>(),
    ],
  );
}

class _GatedWind extends FakeWindRepository {
  _GatedWind(this._gate);

  final Future<void> _gate;

  @override
  Future<List<WindSample>> getCurrentWind(List<GeoPoint> points) async {
    await _gate;
    return super.getCurrentWind(points);
  }
}
