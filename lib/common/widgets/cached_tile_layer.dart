// lib/common/widgets/cached_tile_layer.dart
import 'package:drivio_app/common/constants/map_constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

class CachedTileLayer extends TileLayer {
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

         maxZoom: 16,
       );
}
