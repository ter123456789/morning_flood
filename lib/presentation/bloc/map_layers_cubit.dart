import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/geo_point.dart';
import '../../domain/location_service.dart';
import '../../domain/waterway_repository.dart';
import '../../domain/wind_repository.dart';
import 'map_layers_state.dart';

typedef GeoBounds = ({double south, double west, double north, double east});

class MapLayersCubit extends Cubit<MapLayersState> {
  MapLayersCubit(
    this._waterwayRepository,
    this._windRepository,
    this._locationService, {
    this.locationTimeout = const Duration(seconds: 10),
  }) : super(const MapLayersState());

  final WaterwayRepository _waterwayRepository;
  final WindRepository _windRepository;
  final LocationService _locationService;
  final Duration locationTimeout;

  /// Samples per side of the wind grid.
  static const windGridSize = 5;

  var _windRequest = 0;

  Future<void> loadWaterways() async {
    try {
      final waterways = await _waterwayRepository.getWaterways();
      emit(state.copyWith(waterways: waterways, errorMessage: () => null));
    } catch (e) {
      emit(state.copyWith(errorMessage: () => 'โหลดเส้นทางน้ำไม่สำเร็จ: $e'));
    }
  }

  void toggleWaterways() =>
      emit(state.copyWith(showWaterways: !state.showWaterways));

  void toggleWind() {
    _windRequest++; // Drop any in-flight response.
    emit(
      state.copyWith(
        showWind: !state.showWind,
        // Stale samples would flash at old positions when re-enabled.
        wind: const [],
      ),
    );
    if (state.showWind && state.myPosition == null) _locate();
  }

  /// Device position for the "wind here" bubble; the layer works without it.
  Future<void> _locate() async {
    try {
      final pos = await _locationService.currentPosition().timeout(
        locationTimeout,
      );
      emit(state.copyWith(myPosition: () => pos));
    } on LocationException {
      return;
    } on TimeoutException {
      return;
    }
  }

  Future<void> loadWind(GeoBounds bounds) async {
    if (!state.showWind) return;
    // The map fires many moves; only the latest request may update state.
    final request = ++_windRequest;
    try {
      final wind = await _windRepository.getCurrentWind(windGrid(bounds));
      if (request != _windRequest || !state.showWind) return;
      emit(state.copyWith(wind: wind, errorMessage: () => null));
    } catch (e) {
      if (request != _windRequest) return;
      emit(state.copyWith(errorMessage: () => 'โหลดข้อมูลลมไม่สำเร็จ: $e'));
    }
  }

  /// Evenly spaced points inset from the edges of [bounds].
  static List<GeoPoint> windGrid(GeoBounds bounds) {
    const n = windGridSize;
    final latStep = (bounds.north - bounds.south) / n;
    final lngStep = (bounds.east - bounds.west) / n;
    return [
      for (var row = 0; row < n; row++)
        for (var col = 0; col < n; col++)
          (
            latitude: bounds.south + latStep * (row + 0.5),
            longitude: bounds.west + lngStep * (col + 0.5),
          ),
    ];
  }
}
