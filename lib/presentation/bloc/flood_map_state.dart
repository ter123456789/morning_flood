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
  const FloodMapLoaded(this.stations, {this.province});

  final List<FloodStation> stations;

  /// Selected province, or null for the whole country.
  final String? province;

  List<FloodStation> get visibleStations => province == null
      ? stations
      : [
          for (final s in stations)
            if (s.province == province) s,
        ];

  List<String> get provinces =>
      {for (final s in stations) s.province}.where((p) => p.isNotEmpty).toList()
        ..sort();
}

final class FloodMapFailure extends FloodMapState {
  const FloodMapFailure(this.message);

  final String message;
}
