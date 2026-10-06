import '../../domain/flood_station.dart';

sealed class FloodMapState {
  const FloodMapState();
}

final class FloodMapInitial extends FloodMapState {
  const FloodMapInitial();
}

final class FloodMapLoading extends FloodMapState {
  const FloodMapLoading();
}

final class FloodMapLoaded extends FloodMapState {
  const FloodMapLoaded(this.stations);

  final List<FloodStation> stations;
}

final class FloodMapFailure extends FloodMapState {
  const FloodMapFailure(this.message);

  final String message;
}
