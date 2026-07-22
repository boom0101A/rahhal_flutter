import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/dio_client.dart';

/// One place returned by the server's /api/nearby-places endpoint (backed by
/// OpenStreetMap / Overpass — free, no per-request key).
class NearbyPlace {
  final String id;
  final String name;
  final String nameEn;
  final double lat;
  final double lng;
  final String type; // attraction | museum | restaurant | park | viewpoint | other

  const NearbyPlace({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.lat,
    required this.lng,
    required this.type,
  });

  factory NearbyPlace.fromJson(Map<String, dynamic> json) => NearbyPlace(
        id: '${json['id']}',
        name: (json['name'] ?? '').toString(),
        nameEn: (json['name_en'] ?? '').toString(),
        lat: (json['lat'] as num?)?.toDouble() ?? 0,
        lng: (json['lng'] as num?)?.toDouble() ?? 0,
        type: (json['type'] ?? 'other').toString(),
      );
}

class NearbyService {
  final Dio _dio;
  NearbyService({Dio? dio}) : _dio = dio ?? DioClient.general;

  /// Places around a GPS point. [radius] is metres (server default 2000).
  Future<List<NearbyPlace>> getNearby({
    required double lat,
    required double lng,
    int radius = 2000,
  }) async {
    try {
      final res = await _dio.get(
        '${AppConfig.proxyBaseUrl}/api/nearby-places',
        queryParameters: {'lat': lat, 'lng': lng, 'radius': radius},
      );
      final list = (res.data?['places'] as List?) ?? const [];
      return list
          .whereType<Map>()
          .map((e) => NearbyPlace.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      debugPrint('NearbyService.getNearby error: $e');
      rethrow;
    }
  }
}
