import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/flood_report.dart';
import '../../domain/flood_report_repository.dart';
import 'flood_report_state.dart';

class FloodReportCubit extends Cubit<FloodReportState> {
  FloodReportCubit(
    this._repository, {
    this.window = const Duration(hours: 24),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(const FloodReportState());

  final FloodReportRepository _repository;
  final Duration window;
  final DateTime Function() _now;
  StreamSubscription<List<FloodReport>>? _subscription;

  void start() {
    _subscription?.cancel();
    emit(state.copyWith(status: FloodReportStatus.loading));
    _subscription = _repository.watchRecent(window).listen(
      (reports) {
        // The live stream keeps rows past the window, so trim them here.
        final cutoff = _now().subtract(window);
        emit(
          state.copyWith(
            status: FloodReportStatus.ready,
            reports: reports.where((r) => r.createdAt.isAfter(cutoff)).toList(),
            currentUserId: _repository.currentUserId,
          ),
        );
      },
      onError: (Object e) => emit(
        state.copyWith(
          status: FloodReportStatus.failure,
          errorMessage: e.toString(),
        ),
      ),
    );
  }

  void setFilter(ReportFilter filter) => emit(state.copyWith(filter: filter));

  /// Returns null on success, or an error message to show the user.
  Future<String?> submit(NewFloodReport report) async {
    try {
      await _repository.submit(report);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
