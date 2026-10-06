import 'geo_point.dart';
import 'wind_sample.dart';

abstract interface class WindRepository {
  Future<List<WindSample>> getCurrentWind(List<GeoPoint> points);
}
