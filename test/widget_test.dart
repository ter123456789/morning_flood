import 'package:flutter_test/flutter_test.dart';
import 'package:worning_foold/main.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('shows flood map page with legend and report controls', (
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

    expect(find.text('เฝ้าระวังน้ำท่วม'), findsOneWidget);
    expect(find.text('ล้นตลิ่ง'), findsOneWidget);
    expect(find.text('รายงานทั้งหมด'), findsOneWidget);
    expect(find.text('แจ้งที่ตำแหน่งฉัน'), findsOneWidget);
  });
}
