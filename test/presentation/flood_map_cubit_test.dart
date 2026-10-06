import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worning_foold/domain/flood_repository.dart';
import 'package:worning_foold/domain/flood_station.dart';
import 'package:worning_foold/domain/location_service.dart';
import 'package:worning_foold/presentation/bloc/flood_map_cubit.dart';
import 'package:worning_foold/presentation/bloc/flood_map_state.dart';

import '../support/fakes.dart';

class _FakeRepository implements FloodRepository {
  _FakeRepository(this._result);

  final Future<List<FloodStation>> Function() _result;

  @override
  Future<List<FloodStation>> getStations() => _result();
}

class _DeniedLocationService implements LocationService {
  @override
  Future<({double latitude, double longitude})> currentPosition() async =>
      throw const LocationException('denied');
}

FloodStation _station(String province, double lat, double lng) => FloodStation(
  name: province,
  province: province,
  location: province,
  latitude: lat,
  longitude: lng,
  risk: FloodRisk.normal,
  observedAt: DateTime.utc(2026, 10, 6, 8, 20),
);

// FakeLocationService reports 13.75, 100.5 (Bangkok).
final _bangkok = _station('กรุงเทพมหานคร', 13.7, 100.5);
final _chiangMai = _station('เชียงใหม่', 18.8, 98.98);
final _stations = [_chiangMai, _bangkok];

FloodMapCubit _cubit({LocationService? location}) => FloodMapCubit(
  _FakeRepository(() async => _stations),
  location ?? FakeLocationService(),
);

void main() {
  blocTest<FloodMapCubit, FloodMapState>(
    'defaults to the province of the station nearest the device',
    build: _cubit,
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<FloodMapLoading>(),
      isA<FloodMapLoaded>()
          .having((s) => s.province, 'province', 'กรุงเทพมหานคร')
          .having((s) => s.visibleStations, 'visible', [_bangkok]),
    ],
  );

  blocTest<FloodMapCubit, FloodMapState>(
    'shows the whole country when location is unavailable',
    build: () => _cubit(location: _DeniedLocationService()),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<FloodMapLoading>(),
      isA<FloodMapLoaded>()
          .having((s) => s.province, 'province', isNull)
          .having((s) => s.visibleStations, 'visible', _stations),
    ],
  );

  blocTest<FloodMapCubit, FloodMapState>(
    'selectProvince changes the filter and refresh keeps it',
    build: _cubit,
    act: (cubit) async {
      await cubit.load();
      cubit.selectProvince('เชียงใหม่');
      await cubit.load();
    },
    skip: 2,
    expect: () => [
      isA<FloodMapLoaded>().having((s) => s.province, 'province', 'เชียงใหม่'),
      isA<FloodMapLoading>(),
      isA<FloodMapLoaded>().having((s) => s.province, 'province', 'เชียงใหม่'),
    ],
  );

  test('provinces are unique and sorted', () {
    final state = FloodMapLoaded([_chiangMai, _bangkok, _bangkok]);
    expect(state.provinces, ['กรุงเทพมหานคร', 'เชียงใหม่']);
  });

  blocTest<FloodMapCubit, FloodMapState>(
    'emits Loading then Failure when repository throws',
    build: () => FloodMapCubit(
      _FakeRepository(() async => throw Exception('boom')),
      FakeLocationService(),
    ),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<FloodMapLoading>(),
      isA<FloodMapFailure>().having(
        (s) => s.message,
        'message',
        contains('boom'),
      ),
    ],
  );
}
