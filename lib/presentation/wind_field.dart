import 'dart:math' as math;

import '../domain/wind_sample.dart';

typedef WindVector = ({double u, double v});

/// Continuous wind estimate from a sparse set of samples, by inverse-distance
/// weighting of their vectors (not of speed and direction separately, which
/// would average north-easterly and north-westerly into nonsense).
class WindField {
  WindField(this.samples);

  final List<WindSample> samples;

  /// Wind at a point in km/h: [u] toward east, [v] toward north.
  /// Null when there are no samples.
  WindVector? at(double latitude, double longitude) {
    if (samples.isEmpty) return null;
    var u = 0.0, v = 0.0, total = 0.0;
    for (final s in samples) {
      final dLat = s.latitude - latitude;
      final dLng = s.longitude - longitude;
      final d2 = dLat * dLat + dLng * dLng;
      final vec = toVector(s);
      if (d2 < 1e-12) return vec;
      final w = 1 / d2;
      u += vec.u * w;
      v += vec.v * w;
      total += w;
    }
    return (u: u / total, v: v / total);
  }

  /// [WindSample.directionDegrees] is where the wind comes *from*, so the
  /// vector points the opposite way.
  static WindVector toVector(WindSample s) {
    final rad = s.directionDegrees * math.pi / 180;
    return (u: -s.speedKmh * math.sin(rad), v: -s.speedKmh * math.cos(rad));
  }

  /// Speed and the direction the wind comes *from*, for display.
  static ({double speedKmh, double directionDegrees}) fromVector(
    WindVector w,
  ) => (
    speedKmh: math.sqrt(w.u * w.u + w.v * w.v),
    directionDegrees: (math.atan2(-w.u, -w.v) * 180 / math.pi) % 360,
  );
}

/// 8-point compass label for a direction in degrees, e.g. 45 → "NE".
String compassLabel(double degrees) => const [
  'N',
  'NE',
  'E',
  'SE',
  'S',
  'SW',
  'W',
  'NW',
][((degrees % 360) / 45).round() % 8];
