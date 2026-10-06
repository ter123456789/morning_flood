import '../../domain/geo_point.dart';
import '../../domain/waterway.dart';
import '../../domain/wind_sample.dart';

class MapLayersState {
  const MapLayersState({
    this.showWaterways = true,
    this.showWind = false,
    this.waterways = const [],
    this.wind = const [],
    this.myPosition,
    this.errorMessage,
  });

  final bool showWaterways;
  final bool showWind;
  final List<Waterway> waterways;
  final List<WindSample> wind;
  final GeoPoint? myPosition;

  /// Last load failure; cleared by the next successful load.
  final String? errorMessage;

  MapLayersState copyWith({
    bool? showWaterways,
    bool? showWind,
    List<Waterway>? waterways,
    List<WindSample>? wind,
    GeoPoint? Function()? myPosition,
    String? Function()? errorMessage,
  }) => MapLayersState(
    showWaterways: showWaterways ?? this.showWaterways,
    showWind: showWind ?? this.showWind,
    waterways: waterways ?? this.waterways,
    wind: wind ?? this.wind,
    myPosition: myPosition != null ? myPosition() : this.myPosition,
    errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
  );
}
