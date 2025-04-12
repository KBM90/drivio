import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

Marker buildMarker(LatLng userLocation, Icon icon) =>
    Marker(point: userLocation, child: icon);
