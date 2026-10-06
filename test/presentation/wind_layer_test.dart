import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worning_foold/main.dart';
import 'package:worning_foold/presentation/wind_particle_layer.dart';

import '../support/fakes.dart';

void main() {
  testWidgets('wind layer shows particles, legend and the wind-here bubble', (
    tester,
  ) async {
    await tester.pumpWidget(
      FloodApp(
        repository: FakeFloodRepository(),
        reportRepository: FakeFloodReportRepository(),
        locationService: FakeLocationService(),
        waterwayRepository: FakeWaterwayRepository(),
        windRepository: FakeWindRepository(),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.layers));
    await tester.pump(const Duration(milliseconds: 500));
    // The menu animates in from its origin; give it a start frame first.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final item = find.ancestor(
      of: find.text('ลม'),
      matching: find.byWidgetPredicate((w) => w is CheckedPopupMenuItem),
    );
    await tester.tap(item);
    // Let the menu close, wind load, and a few animation frames run.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(WindParticleLayer), findsOneWidget);
    expect(find.text('ลม (กม./ชม.)'), findsOneWidget);
    // FakeWindRepository: 10 km/h from the east everywhere.
    expect(find.text('E'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
