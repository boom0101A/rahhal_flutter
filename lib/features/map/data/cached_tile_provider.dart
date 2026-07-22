import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_map/flutter_map.dart';

/// Shared cache for map tiles. Using one named cache (rather than the global
/// default) keeps tiles separate from image caches and lets us prefetch into
/// exactly the store the map reads from.
final CacheManager mapTileCacheManager = CacheManager(
  Config(
    'rahhal_map_tiles',
    stalePeriod: const Duration(days: 30),
    maxNrOfCacheObjects: 3000,
  ),
);

/// A [TileProvider] that serves map tiles through [flutter_cache_manager], so
/// every tile the user views is written to disk and re-served from there — the
/// map then keeps working over already-seen areas with no connection. Combined
/// with [OfflineMapService] prefetch, a whole trip's map can be made available
/// offline.
class CachedTileProvider extends TileProvider {
  CachedTileProvider({super.headers});

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return CachedNetworkImageProvider(
      getTileUrl(coordinates, options),
      headers: headers,
      cacheManager: mapTileCacheManager,
    );
  }
}
