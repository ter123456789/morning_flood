import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worning_foold/domain/flood_repository.dart';
import 'package:worning_foold/domain/flood_station.dart';
import 'package:worning_foold/presentation/bloc/flood_map_cubit.dart';
import 'package:worning_foold/presentation/bloc/flood_map_state.dart';

class _FakeRepository implements FloodRepository {
  _FakeRepository(this._result);

  final Future<List<FloodStation>> Function() _result;

  @override
  Future<List<FloodStation>> getStations() => _result();
}

const _station = FloodStation(
  name: 'A',
  latitude: 13.6,
  longitude: 100.5,
  currentDischarge: 100,
  peakForecastDischarge: 100,
);

void main() {
  blocTest<FloodMapCubit, FloodMapState>(
    'emits Loading then Loaded on success',
    build: () => FloodMapCubit(_FakeRepository(() async => [_station])),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<FloodMapLoading>(),
      isA<FloodMapLoaded>().having((s) => s.stations, 'stations', [_station]),
    ],
  );

  blocTest<FloodMapCubit, FloodMapState>(
    'emits Loading then Failure when repository throws',
    build: () =>
        FloodMapCubit(_FakeRepository(() async => throw Exception('boom'))),
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
