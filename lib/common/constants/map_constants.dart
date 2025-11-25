class MapConstants {
  static const String tileLayerUrl =
      "https://tile.openstreetmap.org/{z}/{x}/{y}.png";

  static const osrmBaseUrl = 'https://router.project-osrm.org/route/v1/driving';
  // ✅ Add user agent package name
  static const String userAgentPackageName = 'com.drivio.www.drivio';
  static const String cacheStoreName = 'mapStore'; // ✅ Add this
}
