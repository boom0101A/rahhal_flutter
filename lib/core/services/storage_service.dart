import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/map/data/cached_tile_provider.dart';

/// How much space the app's downloadable content is using, split so the user
/// can see what they'd actually be freeing.
class StorageUsage {
  /// Photos of stops, restaurants and hotels.
  final int imageBytes;

  /// Offline map tiles.
  final int mapTileBytes;

  const StorageUsage({required this.imageBytes, required this.mapTileBytes});

  int get totalBytes => imageBytes + mapTileBytes;

  static const empty = StorageUsage(imageBytes: 0, mapTileBytes: 0);
}

/// Measures and clears the caches the app fills up over time.
///
/// Deliberately scoped to *re-downloadable* content only: trips, days, stops,
/// budgets and documents live in SQLite and are never touched here, so
/// "clear cache" can never cost the user their itineraries.
class StorageService {
  /// Sums the on-disk size of the image and map-tile caches.
  Future<StorageUsage> usage() async {
    try {
      final root = await getTemporaryDirectory();
      // flutter_cache_manager keeps each cache in a folder named after its key.
      final images = await _dirSize(Directory('${root.path}/libCachedImageData'));
      final tiles = await _dirSize(Directory('${root.path}/rahhal_map_tiles'));
      return StorageUsage(imageBytes: images, mapTileBytes: tiles);
    } catch (e) {
      debugPrint('[Storage] usage failed: $e');
      return StorageUsage.empty;
    }
  }

  /// Empties both caches. Everything removed re-downloads on next use, so the
  /// only cost is bandwidth — never data.
  Future<void> clearCaches() async {
    try {
      await DefaultCacheManager().emptyCache();
    } catch (e) {
      debugPrint('[Storage] clearing image cache failed: $e');
    }
    try {
      await mapTileCacheManager.emptyCache();
    } catch (e) {
      debugPrint('[Storage] clearing tile cache failed: $e');
    }
  }

  Future<int> _dirSize(Directory dir) async {
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        try {
          total += await entity.length();
        } catch (_) {
          // A file deleted mid-scan shouldn't abort the whole measurement.
        }
      }
    }
    return total;
  }

  /// "12.4 MB" / "820 KB" — Latin digits, matching how sizes read elsewhere.
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 MB';
    const kb = 1024;
    const mb = kb * 1024;
    const gb = mb * 1024;
    if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(1)} GB';
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
    return '${(bytes / kb).round()} KB';
  }
}
