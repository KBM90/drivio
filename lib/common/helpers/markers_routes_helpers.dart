import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MarkersRoutesHelpers {
  Future<Marker> createGifMarker(
    LatLng position,
    String gifFilePath, {
    double width = 50,
    double height = 50,
  }) async {
    final byteData = await rootBundle.load(gifFilePath);
    final gifBytes = byteData.buffer.asUint8List();

    return Marker(
      point: position,
      width: width,
      height: height,
      child: Image.memory(gifBytes, width: width, height: height),
    );
  }
}
