import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/flood_repository.dart';
import 'flood_map_state.dart';

class FloodMapCubit extends Cubit<FloodMapState> {
  FloodMapCubit(this._repository) : super(const FloodMapInitial());

  final FloodRepository _repository;

  Future<void> load() async {
    emit(const FloodMapLoading());
    try {
      emit(FloodMapLoaded(await _repository.getStations()));
    } catch (e) {
      emit(FloodMapFailure(e.toString()));
    }
  }
}
