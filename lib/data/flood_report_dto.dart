import '../domain/flood_report.dart';

/// Row shape of `public.flood_reports`.
abstract final class FloodReportDto {
  static const _depthCodes = {
    WaterDepth.none: 'none',
    WaterDepth.ankle: 'ankle',
    WaterDepth.knee: 'knee',
    WaterDepth.waist: 'waist',
    WaterDepth.aboveWaist: 'above_waist',
  };

  static FloodReport fromRow(Map<String, dynamic> row) {
    final code = row['water_depth'] as String;
    return FloodReport(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      latitude: (row['latitude'] as num).toDouble(),
      longitude: (row['longitude'] as num).toDouble(),
      depth: _depthCodes.entries
          .firstWhere(
            (e) => e.value == code,
            orElse: () => throw FormatException('Unknown water_depth: $code'),
          )
          .key,
      note: row['note'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  static Map<String, dynamic> toInsert(NewFloodReport report) => {
    'latitude': report.latitude,
    'longitude': report.longitude,
    'water_depth': _depthCodes[report.depth],
    if (report.note case final note? when note.trim().isNotEmpty)
      'note': note.trim(),
  };
}
