import '../../domain/flood_report.dart';

enum ReportFilter { all, mine, hidden }

enum FloodReportStatus { loading, ready, failure }

class FloodReportState {
  const FloodReportState({
    this.status = FloodReportStatus.loading,
    this.reports = const [],
    this.filter = ReportFilter.all,
    this.currentUserId,
    this.errorMessage,
  });

  final FloodReportStatus status;
  final List<FloodReport> reports;
  final ReportFilter filter;
  final String? currentUserId;
  final String? errorMessage;

  /// Reports to draw on the map after applying the user's [filter].
  List<FloodReport> get visibleReports => switch (filter) {
    ReportFilter.all => reports,
    ReportFilter.mine =>
      reports.where((r) => r.userId == currentUserId).toList(),
    ReportFilter.hidden => const [],
  };

  FloodReportState copyWith({
    FloodReportStatus? status,
    List<FloodReport>? reports,
    ReportFilter? filter,
    String? currentUserId,
    String? errorMessage,
  }) => FloodReportState(
    status: status ?? this.status,
    reports: reports ?? this.reports,
    filter: filter ?? this.filter,
    currentUserId: currentUserId ?? this.currentUserId,
    errorMessage: errorMessage,
  );
}
