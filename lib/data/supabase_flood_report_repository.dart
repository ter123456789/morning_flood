import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/flood_report.dart';
import '../domain/flood_report_repository.dart';
import 'flood_report_dto.dart';

class SupabaseFloodReportRepository implements FloodReportRepository {
  SupabaseFloodReportRepository(this._client);

  static const _table = 'flood_reports';

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Stream<List<FloodReport>> watchRecent(Duration window) async* {
    await _ensureSignedIn();
    final since = DateTime.now().toUtc().subtract(window).toIso8601String();
    yield* _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .gte('created_at', since)
        .order('created_at')
        .limit(500)
        .map((rows) => rows.map(FloodReportDto.fromRow).toList());
  }

  @override
  Future<void> submit(NewFloodReport report) async {
    await _ensureSignedIn();
    await _client.from(_table).insert(FloodReportDto.toInsert(report));
  }

  // Reports need an owner for RLS; anonymous sign-in avoids a signup flow.
  Future<void> _ensureSignedIn() async {
    if (_client.auth.currentSession == null) {
      await _client.auth.signInAnonymously();
    }
  }
}
