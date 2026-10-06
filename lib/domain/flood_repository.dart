import 'flood_station.dart';

abstract interface class FloodRepository {
  Future<List<FloodStation>> getStations();
}
