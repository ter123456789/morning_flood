import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../domain/wind_sample.dart';
import 'wind_field.dart';

/// Speed (km/h) to color ramp, shared by the particles and the legend.
const windSpeedStops = <(double, Color)>[
  (0, Color(0xFF8FCBFF)),
  (40, Color(0xFFC4E4FF)),
  (80, Color(0xFFEAF5FF)),
  (120, Colors.white),
];

Color windSpeedColor(double kmh) {
  for (var i = 1; i < windSpeedStops.length; i++) {
    final (hi, hiColor) = windSpeedStops[i];
    if (kmh <= hi) {
      final (lo, loColor) = windSpeedStops[i - 1];
      return Color.lerp(
        loColor,
        hiColor,
        ((kmh - lo) / (hi - lo)).clamp(0, 1),
      )!;
    }
  }
  return windSpeedStops.last.$2;
}

/// Animated wind streaks drawn over the map, in the style of weather apps.
///
/// Particles live in screen space and are respawned whenever the camera
/// moves; a coarse per-cell velocity grid keeps each frame cheap.
class WindParticleLayer extends StatefulWidget {
  const WindParticleLayer({
    super.key,
    required this.samples,
    this.particleCount = 700,
  });

  final List<WindSample> samples;
  final int particleCount;

  @override
  State<WindParticleLayer> createState() => _WindParticleLayerState();
}

class _WindParticleLayerState extends State<WindParticleLayer>
    with SingleTickerProviderStateMixin {
  static const _cellSize = 40.0;

  final _random = math.Random();
  final _frame = ValueNotifier<int>(0);
  late final Ticker _ticker;
  _VelocityGrid? _grid;
  var _particles = <_Particle>[];
  var _lastTick = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reset(MapCamera.of(context));
  }

  @override
  void didUpdateWidget(WindParticleLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.samples, widget.samples) ||
        oldWidget.particleCount != widget.particleCount) {
      _reset(MapCamera.of(context));
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  void _reset(MapCamera camera) {
    final size = camera.nonRotatedSize;
    if (widget.samples.isEmpty || size.isEmpty || !size.isFinite) {
      _grid = null;
      _particles = [];
      return;
    }
    final grid = _VelocityGrid(camera, WindField(widget.samples), _cellSize);
    _grid = grid;
    _particles = [
      for (var i = 0; i < widget.particleCount; i++) _spawn(grid.size),
    ];
  }

  _Particle _spawn(Size size) => _Particle(
    Offset(
      _random.nextDouble() * size.width,
      _random.nextDouble() * size.height,
    ),
    maxAge: 1 + _random.nextDouble() * 2.5,
  );

  void _tick(Duration elapsed) {
    // Clamp so a paused app doesn't fling every particle off screen.
    final dt = ((elapsed - _lastTick).inMicroseconds / 1e6).clamp(0.0, 0.1);
    _lastTick = elapsed;
    final grid = _grid;
    if (grid == null) return;
    for (var i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      p.age += dt;
      final cell = grid.cellAt(p.head);
      if (p.age > p.maxAge || cell == null) {
        _particles[i] = _spawn(grid.size);
        continue;
      }
      p.advance(Offset(grid.vx[cell], grid.vy[cell]) * dt, grid.speedKmh[cell]);
    }
    _frame.value++;
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _WindPainter(_particles, repaint: _frame),
      ),
    );
  }
}

class _Particle {
  _Particle(Offset start, {required this.maxAge}) : trail = [start];

  static const trailLength = 8;

  /// Oldest first.
  final List<Offset> trail;
  final double maxAge;
  double age = 0;
  double speedKmh = 0;

  Offset get head => trail.last;

  void advance(Offset delta, double speed) {
    trail.add(head + delta);
    if (trail.length > trailLength) trail.removeAt(0);
    speedKmh = speed;
  }
}

/// Screen-space velocity per grid cell, in px/s.
class _VelocityGrid {
  _VelocityGrid(MapCamera camera, WindField field, this.cellSize)
    : size = camera.nonRotatedSize,
      cols = (camera.nonRotatedSize.width / cellSize).ceil(),
      rows = (camera.nonRotatedSize.height / cellSize).ceil() {
    vx = Float32List(cols * rows);
    vy = Float32List(cols * rows);
    speedKmh = Float32List(cols * rows);
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final i = r * cols + c;
        final center = Offset((c + 0.5) * cellSize, (r + 0.5) * cellSize);
        final here = camera.screenOffsetToLatLng(center);
        final wind = field.at(here.latitude, here.longitude);
        if (wind == null) continue;
        // Project unit steps east and north so map rotation is respected.
        final origin = camera.latLngToScreenOffset(here);
        final east = _unit(
          camera.latLngToScreenOffset(
                LatLng(here.latitude, here.longitude + 0.01),
              ) -
              origin,
        );
        final north = _unit(
          camera.latLngToScreenOffset(
                LatLng(math.min(here.latitude + 0.01, 89.9), here.longitude),
              ) -
              origin,
        );
        final speed = math.sqrt(wind.u * wind.u + wind.v * wind.v);
        speedKmh[i] = speed;
        if (speed == 0) continue;
        final dir = _unit(east * wind.u + north * wind.v);
        final pxPerSecond = _basePxPerSecond + speed * _pxPerSecondPerKmh;
        vx[i] = dir.dx * pxPerSecond;
        vy[i] = dir.dy * pxPerSecond;
      }
    }
  }

  // The base keeps calm air visibly drifting.
  static const _basePxPerSecond = 12.0;
  static const _pxPerSecondPerKmh = 4.0;

  final Size size;
  final double cellSize;
  final int cols;
  final int rows;
  late final Float32List vx;
  late final Float32List vy;
  late final Float32List speedKmh;

  int? cellAt(Offset p) {
    final c = (p.dx / cellSize).floor();
    final r = (p.dy / cellSize).floor();
    if (c < 0 || r < 0 || c >= cols || r >= rows) return null;
    return r * cols + c;
  }

  static Offset _unit(Offset o) =>
      o.distance == 0 ? Offset.zero : o / o.distance;
}

class _WindPainter extends CustomPainter {
  _WindPainter(this.particles, {required super.repaint});

  final List<_Particle> particles;

  // Speed buckets; one draw call per bucket and trail segment keeps the
  // frame to a few dozen calls regardless of particle count.
  static const _bucketLimits = [20.0, 40.0, 80.0];
  static final _bucketColors = [
    for (final kmh in [10.0, 30.0, 60.0, 100.0]) windSpeedColor(kmh),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const segments = _Particle.trailLength - 1;
    final lines = List.generate(
      _bucketColors.length * segments,
      (_) => <double>[],
    );
    for (final p in particles) {
      var bucket = _bucketLimits.indexWhere((l) => p.speedKmh < l);
      if (bucket == -1) bucket = _bucketLimits.length;
      final t = p.trail;
      // Align to the newest end so the head is always the brightest.
      final offset = segments - (t.length - 1);
      for (var i = 1; i < t.length; i++) {
        lines[bucket * segments + offset + i - 1].addAll([
          t[i - 1].dx,
          t[i - 1].dy,
          t[i].dx,
          t[i].dy,
        ]);
      }
    }
    final paint = Paint()
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (var b = 0; b < _bucketColors.length; b++) {
      for (var s = 0; s < segments; s++) {
        final points = lines[b * segments + s];
        if (points.isEmpty) continue;
        paint.color = _bucketColors[b].withValues(alpha: (s + 1) / segments);
        canvas.drawRawPoints(
          ui.PointMode.lines,
          Float32List.fromList(points),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_WindPainter oldDelegate) =>
      !identical(oldDelegate.particles, particles);
}
