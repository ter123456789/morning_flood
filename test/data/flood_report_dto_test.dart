import 'package:flutter_test/flutter_test.dart';
import 'package:worning_foold/data/flood_report_dto.dart';
import 'package:worning_foold/domain/flood_report.dart';

void main() {
  test('fromRow parses a Supabase row', () {
    final r = FloodReportDto.fromRow({
      'id': 'a1',
      'user_id': 'u1',
      'latitude': 13.7,
      'longitude': 100,
      'water_depth': 'above_waist',
      'note': 'ถนนปิด',
      'created_at': '2026-10-06T08:00:00+00:00',
    });

    expect(r.depth, WaterDepth.aboveWaist);
    expect(r.longitude, 100.0);
    expect(r.note, 'ถนนปิด');
    expect(r.createdAt, DateTime.utc(2026, 10, 6, 8));
  });

  test('fromRow rejects an unknown depth code', () {
    expect(
      () => FloodReportDto.fromRow({
        'id': 'a1',
        'user_id': 'u1',
        'latitude': 0,
        'longitude': 0,
        'water_depth': 'chest',
        'created_at': '2026-10-06T08:00:00Z',
      }),
      throwsFormatException,
    );
  });

  test('toInsert omits blank notes and server-owned fields', () {
    final row = FloodReportDto.toInsert(
      const NewFloodReport(
        latitude: 1,
        longitude: 2,
        depth: WaterDepth.ankle,
        note: '   ',
      ),
    );

    expect(row, {'latitude': 1.0, 'longitude': 2.0, 'water_depth': 'ankle'});
  });
}
