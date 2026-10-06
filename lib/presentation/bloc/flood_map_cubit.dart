import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/flood_repository.dart';
import '../../domain/flood_station.dart';
import '../../domain/location_service.dart';
import 'flood_map_state.dart';

class FloodMapCubit extends Cubit<FloodMapState> {
  FloodMapCubit(
    this._repository,
    this._locationService, {
    this.locationTimeout = const Duration(seconds: 10),
  }) : super(const FloodMapInitial());

  final FloodRepository _repository;
  final LocationService _locationService;
  final Duration locationTimeout;

  Future<void> load() async {
    final previous = state;
    emit(const FloodMapLoading());
    try {
      final stations = await _repository.getStations();
      // Default to the device's province on first load; keep the user's
      // choice across refreshes.
      final province = previous is FloodMapLoaded
          ? previous.province
          : await _nearestProvince(stations);
      emit(FloodMapLoaded(stations, province: province));
    } catch (e) {
      emit(FloodMapFailure(e.toString()));
    }
  }

  void selectProvince(String? province) {
    if (state case final FloodMapLoaded s) {
      emit(FloodMapLoaded(s.stations, province: province));
    }
  }

  /// Province of the station closest to the device. Null (whole country)
  /// when location is unavailable, so the map still works without it.
  Future<String?> _nearestProvince(List<FloodStation> stations) async {
    if (stations.isEmpty) return null;
    final ({double latitude, double longitude}) pos;
    try {
      pos = await _locationService.currentPosition().timeout(locationTimeout);
    } on LocationException {
      return null;
    } on TimeoutException {
      return null;
    }
    const distance = Distance();
    final here = LatLng(pos.latitude, pos.longitude);
    final nearest = stations.reduce(
      (a, b) =>
          distance(here, LatLng(a.latitude, a.longitude)) <=
              distance(here, LatLng(b.latitude, b.longitude))
          ? a
          : b,
    );
    return nearest.province.isEmpty ? null : nearest.province;
  }
}
