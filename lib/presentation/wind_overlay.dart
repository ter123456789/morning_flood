import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../domain/geo_point.dart';
import '../domain/wind_sample.dart';
import 'wind_field.dart';
import 'wind_particle_layer.dart';

const _windPanelColor = Color(0xCC1B3A66);

/// Recolors OSM tiles to a dark blue so white wind streaks stand out.
/// Maps luminance onto a deep-blue → light-blue ramp.
const windTileTint = ColorFilter.matrix([
  0.2126 * 0.27, 0.7152 * 0.27, 0.0722 * 0.27, 0, 20, //
  0.2126 * 0.35, 0.7152 * 0.35, 0.0722 * 0.35, 0, 50, //
  0.2126 * 0.40, 0.7152 * 0.40, 0.0722 * 0.40, 0, 100, //
  0, 0, 0, 1, 0, //
]);

Widget windTintTileBuilder(BuildContext context, Widget tile, TileImage _) =>
    ColorFiltered(colorFilter: windTileTint, child: tile);

class WindLegend extends StatelessWidget {
  const WindLegend({super.key});

  static const _height = 160.0;

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(color: Colors.white70, fontSize: 12);
    final max = windSpeedStops.last.$1;
    return Card(
      color: _windPanelColor,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ลม (กม./ชม.)',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: _height,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [for (final (_, c) in windSpeedStops) c],
                        stops: [for (final (v, _) in windSpeedStops) v / max],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final (v, _) in windSpeedStops.reversed)
                        Text(v.toStringAsFixed(0), style: labelStyle),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bubble above the device position showing the wind there,
/// e.g. "NE / 4 / กม./ชม.". Hidden until both position and wind are known.
class WindHereMarkerLayer extends StatelessWidget {
  const WindHereMarkerLayer({
    super.key,
    required this.position,
    required this.samples,
  });

  final GeoPoint? position;
  final List<WindSample> samples;

  @override
  Widget build(BuildContext context) {
    final pos = position;
    final wind = pos == null
        ? null
        : WindField(samples).at(pos.latitude, pos.longitude);
    if (pos == null || wind == null) return const SizedBox.shrink();
    final sample = WindField.fromVector(wind);
    return MarkerLayer(
      markers: [
        Marker(
          point: LatLng(pos.latitude, pos.longitude),
          width: 84,
          height: 104,
          // Bottom of the child (the dot) sits on the position.
          alignment: Alignment.topCenter,
          child: IgnorePointer(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F6DB5),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        compassLabel(sample.directionDegrees),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        sample.speedKmh.toStringAsFixed(0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          height: 1.1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'กม./ชม.',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF2F6DB5),
                      width: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
