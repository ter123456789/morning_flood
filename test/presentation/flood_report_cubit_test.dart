import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worning_foold/domain/flood_report.dart';
import 'package:worning_foold/presentation/bloc/flood_report_cubit.dart';
import 'package:worning_foold/presentation/bloc/flood_report_state.dart';

import '../support/fakes.dart';

void main() {
  final now = DateTime.utc(2026, 10, 6, 12);
  final fresh = report(
    id: 'fresh',
    createdAt: now.subtract(const Duration(hours: 1)),
  );
  final stale = report(
    id: 'stale',
    createdAt: now.subtract(const Duration(hours: 25)),
  );
  final other = report(id: 'other', userId: 'someone', createdAt: now);

  late FakeFloodReportRepository repo;
  setUp(() => repo = FakeFloodReportRepository());

  blocTest<FloodReportCubit, FloodReportState>(
    'drops reports older than the window',
    build: () => FloodReportCubit(repo, now: () => now),
    act: (cubit) async {
      cubit.start();
      repo.controller.add([fresh, stale]);
    },
    expect: () => [
      isA<FloodReportState>().having(
        (s) => s.status,
        'status',
        FloodReportStatus.loading,
      ),
      isA<FloodReportState>()
          .having((s) => s.status, 'status', FloodReportStatus.ready)
          .having((s) => s.reports.map((r) => r.id), 'ids', ['fresh']),
    ],
  );

  group('filter', () {
    Future<FloodReportCubit> loaded() async {
      final cubit = FloodReportCubit(repo, now: () => now)..start();
      repo.controller.add([fresh, other]);
      await Future<void>.delayed(Duration.zero);
      return cubit;
    }

    test('all shows every report', () async {
      final cubit = await loaded();
      expect(cubit.state.visibleReports.map((r) => r.id), ['fresh', 'other']);
    });

    test('mine shows only the current user\'s reports', () async {
      final cubit = await loaded()
        ..setFilter(ReportFilter.mine);
      expect(cubit.state.visibleReports.map((r) => r.id), ['fresh']);
    });

    test('hidden shows nothing but keeps the data', () async {
      final cubit = await loaded()
        ..setFilter(ReportFilter.hidden);
      expect(cubit.state.visibleReports, isEmpty);
      expect(cubit.state.reports, hasLength(2));
    });
  });

  blocTest<FloodReportCubit, FloodReportState>(
    'emits failure when the stream errors',
    build: () => FloodReportCubit(repo),
    act: (cubit) async {
      cubit.start();
      repo.controller.addError(Exception('offline'));
    },
    skip: 1,
    expect: () => [
      isA<FloodReportState>()
          .having((s) => s.status, 'status', FloodReportStatus.failure)
          .having((s) => s.errorMessage, 'message', contains('offline')),
    ],
  );

  test('submit returns null on success and the message on failure', () async {
    const r = NewFloodReport(latitude: 1, longitude: 2, depth: WaterDepth.knee);

    expect(await FloodReportCubit(repo).submit(r), isNull);
    expect(repo.submitted, [r]);

    final failing = FakeFloodReportRepository(submitError: Exception('RLS'));
    expect(await FloodReportCubit(failing).submit(r), contains('RLS'));
  });
}
