// lib/common/widgets/cached_tile_layer.dart
import 'package:drivio_app/common/constants/map_constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

class CachedTileLayer extends TileLayer {
  static const ColorFilter losSantosSanAndreas = ColorFilter.matrix([
    1.4, 0, 0, 0, 20, // Boost red warmth
    0, 1.2, 0, 0, 10, // Boost green
    0, 0, 0.9, 0, -10, // Reduce blue (warmer)
    0, 0, 0, 1, 0,
  ]);

  CachedTileLayer({
    super.key,
    String storeName = 'mapStore',
    BrowseLoadingStrategy loadingStrategy =
        BrowseLoadingStrategy.cacheFirst, // ✅ Changed
    Duration cachedValidDuration = const Duration(days: 30),
  }) : super(
         urlTemplate: MapConstants.tileLayerUrl,

         userAgentPackageName: MapConstants.userAgentPackageName,
         subdomains: ['a', 'b', 'c'],
         //keepBuffer: 2,//Loads 2 extra tiles on each side
         tileProvider: FMTCTileProvider(
           stores: {
             storeName: null, // ✅ Use the parameter, not hardcoded
           },
           loadingStrategy: loadingStrategy, // ✅ Use the parameter
           cachedValidDuration: cachedValidDuration,
           recordHitsAndMisses: true,
         ),
         tileBuilder: (context, widget, tile) {
           // Apply color filter for GTA look
           return ColorFiltered(
             colorFilter: losSantosSanAndreas,
             child: widget,
           );
         },
         maxZoom: 19,
       );
}
