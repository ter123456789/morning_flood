import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worning_foold/domain/flood_report.dart';
import 'package:worning_foold/presentation/bloc/flood_report_cubit.dart';
import 'package:worning_foold/presentation/report_form_sheet.dart';

import '../support/fakes.dart';

void main() {
  testWidgets('submit is disabled until a water depth is chosen', (
    tester,
  ) async {
    final repo = FakeFloodReportRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider(
            create: (_) => FloodReportCubit(repo),
            child: const ReportFormSheet(latitude: 13.7, longitude: 100.5),
          ),
        ),
      ),
    );

    FilledButton submit() => tester.widget(find.byType(FilledButton));
    expect(submit().onPressed, isNull);

    await tester.tap(find.byType(DropdownButtonFormField<WaterDepth>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ระดับเข่า').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'รถเล็กผ่านไม่ได้');

    expect(submit().onPressed, isNotNull);
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(repo.submitted.single.depth, WaterDepth.knee);
    expect(repo.submitted.single.note, 'รถเล็กผ่านไม่ได้');
  });
}
