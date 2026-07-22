import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'cached_tile_provider.dart';

/// Pre-downloads OpenStreetMap tiles around a trip's stops into the same cache
/// the map reads from, so the trip's map works fully offline.
///
/// Intentionally conservative to respect the public OSM tile policy: it only
/// covers small neighbourhoods around each stop (not whole bounding boxes),
/// caps the total number of tiles, throttles requests, and sends a proper
/// User-Agent.
class OfflineMapService {
  static const _urlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const _headers = {
    'User-Agent': 'RahhalAI/1.0 (offline map download; trip planner)',
  };

  /// Zoom levels to cache — city overview through street level.
  static const _zooms = [12, 13, 14, 15];

  /// Hard ceiling so a trip can never trigger a huge download.
  static const _maxTiles = 600;

  /// (lng,lat) → slippy tile x/y at [z].
  static Point<int> _tileOf(double lat, double lng, int z) {
    final n = 1 << z; // 2^z
    final x = ((lng + 180.0) / 360.0 * n).floor();
    final latRad = lat * pi / 180.0;
    final y =
        ((1.0 - (log(tan(latRad) + 1.0 / cos(latRad)) / pi)) / 2.0 * n).floor();
    return Point(x.clamp(0, n - 1), y.clamp(0, n - 1));
  }

  static String _tileUrl(int z, int x, int y) => _urlTemplate
      .replaceFirst('{z}', '$z')
      .replaceFirst('{x}', '$x')
      .replaceFirst('{y}', '$y');

  /// The unique set of tiles to fetch: each stop's tile plus a small ring of
  /// neighbours at every zoom level, deduplicated and capped.
  static List<String> _tilesForStops(List<LatLng> stops) {
    final seen = <String>{};
    final urls = <String>[];
    for (final z in _zooms) {
      // Wider ring at closer zooms so the walkable area is covered.
      final ring = z >= 14 ? 2 : 1;
      for (final s in stops) {
        final t = _tileOf(s.latitude, s.longitude, z);
        for (var dx = -ring; dx <= ring; dx++) {
          for (var dy = -ring; dy <= ring; dy++) {
            final x = t.x + dx;
            final y = t.y + dy;
            if (x < 0 || y < 0) continue;
            final url = _tileUrl(z, x, y);
            if (seen.add(url)) urls.add(url);
            if (urls.length >= _maxTiles) return urls;
          }
        }
      }
    }
    return urls;
  }

  /// Downloads the trip's tiles. [onProgress] is called with (done, total).
  /// Returns the number successfully cached. Failures on individual tiles are
  /// swallowed so a few network hiccups don't abort the whole download.
  static Future<int> downloadForStops(
    List<LatLng> stops, {
    void Function(int done, int total)? onProgress,
  }) async {
    final valid = stops
        .where((s) => s.latitude.abs() > 0.001 && s.longitude.abs() > 0.001)
        .toList();
    if (valid.isEmpty) return 0;

    final urls = _tilesForStops(valid);
    final total = urls.length;
    var done = 0;
    var ok = 0;

    // Small concurrency to stay polite to the tile server.
    const batchSize = 4;
    for (var i = 0; i < urls.length; i += batchSize) {
      final batch = urls.skip(i).take(batchSize);
      await Future.wait(batch.map((url) async {
        try {
          await mapTileCacheManager.downloadFile(url, authHeaders: _headers);
          ok++;
        } catch (e) {
          debugPrint('OfflineMapService tile failed: $e');
        } finally {
          done++;
          onProgress?.call(done, total);
        }
      }));
      // Brief pause between batches — throttling.
      await Future.delayed(const Duration(milliseconds: 120));
    }
    return ok;
  }

  static int estimateTileCount(List<LatLng> stops) {
    final valid = stops
        .where((s) => s.latitude.abs() > 0.001 && s.longitude.abs() > 0.001)
        .toList();
    if (valid.isEmpty) return 0;
    return _tilesForStops(valid).length;
  }
}
