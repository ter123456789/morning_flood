import 'package:flutter_test/flutter_test.dart';
import 'package:worning_foold/domain/wind_sample.dart';
import 'package:worning_foold/presentation/wind_field.dart';

WindSample _sample(double lat, double lng, double speed, double dir) =>
    WindSample(
      latitude: lat,
      longitude: lng,
      speedKmh: speed,
      directionDegrees: dir,
    );

void main() {
  test('wind from the north blows south', () {
    final v = WindField.toVector(_sample(0, 0, 10, 0));
    expect(v.u, closeTo(0, 1e-9));
    expect(v.v, closeTo(-10, 1e-9));

    final east = WindField.toVector(_sample(0, 0, 10, 270));
    expect(east.u, closeTo(10, 1e-9), reason: 'westerly blows east');
  });

  test('returns the sample itself at a sample point', () {
    final field = WindField([
      _sample(13, 100, 10, 90),
      _sample(14, 101, 30, 180),
    ]);
    final w = WindField.fromVector(field.at(14, 101)!);

    expect(w.speedKmh, closeTo(30, 1e-9));
    expect(w.directionDegrees, closeTo(180, 1e-9));
  });

  test('blends vectors between samples', () {
    final field = WindField([_sample(13, 100, 10, 0), _sample(13, 102, 10, 0)]);
    final w = WindField.fromVector(field.at(13, 101)!);

    expect(w.speedKmh, closeTo(10, 1e-9));
    expect(w.directionDegrees, closeTo(0, 1e-9));
  });

  test('is null without samples', () {
    expect(WindField(const []).at(13, 100), isNull);
  });

  test('compass labels', () {
    expect(compassLabel(0), 'N');
    expect(compassLabel(44), 'NE');
    expect(compassLabel(200), 'S');
    expect(compassLabel(350), 'N');
  });
}
