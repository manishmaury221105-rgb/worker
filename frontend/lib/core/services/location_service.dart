import 'dart:math';

class LocationData {
  final double latitude;
  final double longitude;
  final String address;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class LocationService {
  // Simulates or retrieves reliable GPS worksite coordinates with jitter
  static Future<LocationData> getCurrentLocation() async {
    // Standard worksite locations for realistic simulation
    final locations = [
      LocationData(
        latitude: 28.4595 + (Random().nextDouble() * 0.002 - 0.001),
        longitude: 77.0266 + (Random().nextDouble() * 0.002 - 0.001),
        address: 'Site Alpha, Sector 29, Cyber City, Gurugram',
      ),
      LocationData(
        latitude: 28.5355 + (Random().nextDouble() * 0.002 - 0.001),
        longitude: 77.3910 + (Random().nextDouble() * 0.002 - 0.001),
        address: 'Logistics Hub 4, Sector 62, Noida',
      ),
      LocationData(
        latitude: 28.6139 + (Random().nextDouble() * 0.002 - 0.001),
        longitude: 77.2090 + (Random().nextDouble() * 0.002 - 0.001),
        address: 'Central Zone Project Site, New Delhi',
      ),
    ];

    // Simulate GPS acquisition delay
    await Future.delayed(const Duration(milliseconds: 600));

    return locations[Random().nextInt(locations.length)];
  }
}
