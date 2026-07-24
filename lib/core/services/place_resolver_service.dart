import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../network/dio_client.dart';

/// Resolves a place (name + its coordinates) to its EXACT Google Places id.
///
/// Why this exists: deep-linking to Google Maps with just a name produces a
/// search that lists similarly-named places in other governorates/countries.
/// With a place_id, Maps opens that one specific listing — the right branch,
/// in the right city, with its real name, photos and reviews.
///
/// The server only returns an id when the match is physically near the given
/// coordinates, so a namesake elsewhere is never returned.
class PlaceResolverService {
  final Dio _dio;
  PlaceResolverService({Dio? dio}) : _dio = dio ?? DioClient.general;

  /// In-memory cache so repeated taps on the same card don't re-hit the API.
  static final Map<String, String?> _cache = {};

  static String _key(String name, double lat, double lng) =>
      '${name.trim().toLowerCase()}|${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';

  /// Returns the resolved place id, or null when it can't be resolved
  /// confidently (caller should then fall back to a name+coordinate search).
  Future<String?> resolvePlaceId({
    required String name,
    required double lat,
    required double lng,
    String? city,
  }) async {
    if (name.trim().isEmpty || lat == 0 || lng == 0) return null;

    final key = _key(name, lat, lng);
    if (_cache.containsKey(key)) return _cache[key];

    try {
      final res = await _dio.get(
        '${AppConfig.proxyBaseUrl}/api/resolve-place',
        queryParameters: {
          'name': name.trim(),
          'lat': lat,
          'lng': lng,
          if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
        },
        options: Options(receiveTimeout: const Duration(seconds: 8)),
      );
      final id = res.data?['place_id'] as String?;
      _cache[key] = id;
      return id;
    } catch (e) {
      debugPrint('PlaceResolverService.resolvePlaceId error: $e');
      // Cache the miss briefly so a failing network doesn't stall every tap.
      _cache[key] = null;
      return null;
    }
  }
}
