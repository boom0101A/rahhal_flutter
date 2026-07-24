import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/dio_client.dart';

/// One place returned by the server's /api/nearby-places endpoint. The server
/// sources these from Google Places (current names, exact distances) and falls
/// back to OpenStreetMap only when Places is unavailable.
class NearbyPlace {
  final String id;
  final String name;
  final String nameEn;
  final double lat;
  final double lng;
  final String type; // attraction | historic | museum | restaurant | cafe | park | shopping | worship | viewpoint | other
  final int distanceMeters;
  final double rating;
  final String address;
  final String? placeId;

  const NearbyPlace({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.lat,
    required this.lng,
    required this.type,
    this.distanceMeters = 0,
    this.rating = 0,
    this.address = '',
    this.placeId,
  });

  bool get hasRating => rating > 0;

  /// A short, localized distance label: "230 م" / "1.2 كم".
  String distanceLabel(String lang) {
    if (distanceMeters <= 0) return '';
    if (distanceMeters < 1000) {
      return lang == 'en' ? '$distanceMeters m' : '$distanceMeters م';
    }
    final km = (distanceMeters / 1000).toStringAsFixed(1);
    return lang == 'en' ? '$km km' : '$km كم';
  }

  factory NearbyPlace.fromJson(Map<String, dynamic> json) => NearbyPlace(
        id: '${json['id']}',
        name: (json['name'] ?? '').toString(),
        nameEn: (json['name_en'] ?? '').toString(),
        lat: (json['lat'] as num?)?.toDouble() ?? 0,
        lng: (json['lng'] as num?)?.toDouble() ?? 0,
        type: (json['type'] ?? 'other').toString(),
        distanceMeters: (json['distance_m'] as num?)?.toInt() ?? 0,
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        address: (json['address'] ?? '').toString(),
        placeId: (json['place_id'] as String?),
      );
}

class NearbyResult {
  final List<NearbyPlace> places;
  final String source; // 'google' | 'osm'

  const NearbyResult({required this.places, required this.source});
}

class NearbyService {
  final Dio _dio;
  NearbyService({Dio? dio}) : _dio = dio ?? DioClient.general;

  /// Places around a GPS point, closest first. [radius] is metres (default
  /// 1500 — deliberately tight so results are genuinely "around me"). [lang]
  /// localizes the returned names to match the app's language.
  Future<NearbyResult> getNearby({
    required double lat,
    required double lng,
    int radius = 1500,
    String lang = 'ar',
  }) async {
    try {
      final res = await _dio.get(
        '${AppConfig.proxyBaseUrl}/api/nearby-places',
        queryParameters: {
          'lat': lat,
          'lng': lng,
          'radius': radius,
          'lang': lang,
        },
      );
      final list = (res.data?['places'] as List?) ?? const [];
      final source = (res.data?['source'] ?? 'osm').toString();
      final places = list
          .whereType<Map>()
          .map((e) => NearbyPlace.fromJson(e.cast<String, dynamic>()))
          .toList();
      return NearbyResult(places: places, source: source);
    } catch (e) {
      debugPrint('NearbyService.getNearby error: $e');
      rethrow;
    }
  }
}
