import 'waterway.dart';

abstract interface class WaterwayRepository {
  Future<List<Waterway>> getWaterways();
}
