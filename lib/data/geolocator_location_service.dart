import 'package:geolocator/geolocator.dart';

import '../domain/location_service.dart';

class GeolocatorLocationService implements LocationService {
  @override
  Future<({double latitude, double longitude})> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException('กรุณาเปิด Location Service');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationException('ไม่ได้รับอนุญาตให้เข้าถึงตำแหน่ง');
    }

    final pos = await Geolocator.getCurrentPosition();
    return (latitude: pos.latitude, longitude: pos.longitude);
  }
}
