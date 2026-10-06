import 'flood_report.dart';

abstract interface class FloodReportRepository {
  /// Id of the signed-in user, or null before the first sign-in.
  String? get currentUserId;

  /// Reports created within [window], updated live as users submit more.
  Stream<List<FloodReport>> watchRecent(Duration window);

  Future<void> submit(NewFloodReport report);
}
