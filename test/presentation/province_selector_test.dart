import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worning_foold/domain/flood_repository.dart';
import 'package:worning_foold/domain/flood_station.dart';
import 'package:worning_foold/main.dart';

import '../support/fakes.dart';

class _StationsRepository implements FloodRepository {
  @override
  Future<List<FloodStation>> getStations() async => [
    for (final (p, lat) in [
      ('กรุงเทพมหานคร', 13.7),
      ('เชียงใหม่', 18.8),
      ('เชียงราย', 19.9),
    ])
      FloodStation(
        name: p,
        province: p,
        location: p,
        latitude: lat,
        longitude: 100.5,
        risk: FloodRisk.normal,
        observedAt: DateTime.utc(2026, 10, 6),
      ),
  ];
}

void main() {
  testWidgets('typing in the province selector filters the list', (
    tester,
  ) async {
    await tester.pumpWidget(
      FloodApp(
        repository: _StationsRepository(),
        reportRepository: FakeFloodReportRepository(),
        locationService: FakeLocationService(),
      ),
    );
    await tester.pump();
    await tester.pump();

    final field = find.byType(TextField);
    // Defaults to the province nearest the fake location (Bangkok).
    expect(tester.widget<TextField>(field).controller!.text, 'กรุงเทพมหานคร');

    await tester.tap(field);
    await tester.enterText(field, 'เชียง');
    await tester.pump();

    // DropdownMenu also lays out an offstage copy of the menu for sizing.
    Finder item(String p) =>
        find.widgetWithText(MenuItemButton, p).hitTestable();
    expect(item('เชียงใหม่'), findsOneWidget);
    expect(item('เชียงราย'), findsOneWidget);
    expect(item('กรุงเทพมหานคร'), findsNothing);
  });
}
