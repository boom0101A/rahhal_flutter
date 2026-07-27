import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:latlong2/latlong.dart';
import '../database/database_helper.dart';
import '../di/injection.dart';
import '../../features/currency/data/currency_service.dart';
import '../../features/map/data/offline_map_service.dart';

/// Result of preparing a trip for offline use.
class OfflinePrepResult {
  final int tilesCached;
  final int imagesCached;
  final int imagesFailed;

  const OfflinePrepResult({
    required this.tilesCached,
    required this.imagesCached,
    required this.imagesFailed,
  });

  /// True when everything the trip needs is now on the device.
  bool get isComplete => imagesFailed == 0;
}

/// Downloads everything a trip needs to work with no connection: map tiles,
/// every photo it shows, and the exchange rates its prices are converted with.
///
/// Trip text (days, stops, restaurants, hotels, budget) is already in SQLite
/// from the moment the trip is created, so it needs nothing here.
///
/// Runs only when the user asks: pre-caching a whole trip can pull tens of
/// megabytes, which is not something to spend on someone's mobile data
/// uninvited.
class OfflinePrepService {
  final DatabaseHelper _dbHelper;

  OfflinePrepService({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// [onProgress] reports 0.0–1.0 across the whole job (tiles + images).
  Future<OfflinePrepResult> prepareTrip({
    required String tripId,
    required List<LatLng> stopCoordinates,
    String? countryCode,
    void Function(double progress)? onProgress,
  }) async {
    final imageUrls = await _tripImageUrls(tripId);

    // Weight the two phases by their real item counts so the bar moves evenly.
    final tileTotal = stopCoordinates.isEmpty
        ? 0
        : OfflineMapService.estimateTileCount(stopCoordinates);
    final grandTotal = tileTotal + imageUrls.length;
    var done = 0;

    void report() {
      if (onProgress != null && grandTotal > 0) {
        onProgress((done / grandTotal).clamp(0.0, 1.0));
      }
    }

    // 1. Map tiles.
    var tilesCached = 0;
    if (stopCoordinates.isNotEmpty) {
      tilesCached = await OfflineMapService.downloadForStops(
        stopCoordinates,
        onProgress: (tileDone, _) {
          done = tileDone;
          report();
        },
      );
      // Keep the running total honest even if fewer tiles were needed.
      done = tileTotal;
      report();
    }

    // 2. Photos — the same DefaultCacheManager CachedNetworkImage reads from,
    //    so a cached file is picked up transparently when offline.
    final cache = DefaultCacheManager();
    var imagesCached = 0;
    var imagesFailed = 0;
    const batchSize = 4; // gentle on mobile connections
    for (var i = 0; i < imageUrls.length; i += batchSize) {
      final batch = imageUrls.skip(i).take(batchSize);
      await Future.wait(batch.map((url) async {
        try {
          await cache.downloadFile(url);
          imagesCached++;
        } catch (e) {
          imagesFailed++;
          debugPrint('[OfflinePrep] image failed: $e');
        } finally {
          done++;
          report();
        }
      }));
    }

    // 3. Exchange rates — cached in SharedPreferences and served even when
    //    stale, so budgets keep converting with no connection.
    await _warmCurrencyRates(countryCode);

    onProgress?.call(1.0);
    return OfflinePrepResult(
      tilesCached: tilesCached,
      imagesCached: imagesCached,
      imagesFailed: imagesFailed,
    );
  }

  /// Every photo URL the trip renders: stops, restaurants and hotels.
  Future<List<String>> _tripImageUrls(String tripId) async {
    final urls = <String>{};
    for (final table in ['stops', 'restaurants', 'hotels']) {
      try {
        final rows = await _dbHelper.query(
          table,
          where: 'trip_id = ?',
          whereArgs: [tripId],
        );
        for (final row in rows) {
          final url = (row['image_url'] as String?)?.trim();
          if (url != null && url.startsWith('http')) urls.add(url);
        }
      } catch (e) {
        // A table missing on an older schema must not abort the whole job.
        debugPrint('[OfflinePrep] skipping $table: $e');
      }
    }
    return urls.toList();
  }

  Future<void> _warmCurrencyRates(String? countryCode) async {
    final home = await CurrencyService.homeCurrency();
    final destination = CurrencyService.currencyForCountry(countryCode);
    final wanted = <String>{
      if (home != null) home,
      if (destination != null) destination,
    }..removeWhere((c) => c == 'USD');

    for (final code in wanted) {
      try {
        await sl<CurrencyService>().getRate(code);
      } catch (e) {
        debugPrint('[OfflinePrep] rate $code failed: $e');
      }
    }
  }
}
