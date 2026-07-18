import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dio_client.dart';

class ImageSearchService {
  final Dio _dio;
  ImageSearchService() : _dio = DioClient.anthropic; // Use the proxy Dio

  /// Searches for a high-quality landscape image matching [query].
  /// Route THROUGH the proxy server — server holds the keys
  Future<String?> searchPhoto(String query) async {
    if (query.trim().isEmpty) return null;
    try {
      final response = await _dio.get(
        '/api/photos',
        queryParameters: {'query': query},
      );
      return response.data['url'] as String?;
    } catch (e) {
      debugPrint('[ImageSearch] Failed: $e');
      // Deterministic Picsum fallback (no key needed)
      final seed = query.hashCode.abs() % 1000;
      return 'https://picsum.photos/seed/$seed/800/600';
    }
  }
}
