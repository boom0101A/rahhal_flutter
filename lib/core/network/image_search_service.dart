import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dio_client.dart';

class ImageSearchService {
  final Dio _dio;
  // ✅ Route through proxy server — server holds Unsplash/Pexels keys
  ImageSearchService() : _dio = DioClient.anthropic;

  /// Searches for a high-quality landscape image matching [query].
  /// Routes THROUGH the proxy server so API keys stay server-side only.
  Future<String?> searchPhoto(String query) async {
    if (query.trim().isEmpty) return null;
    try {
      final response = await _dio.get(
        '/api/photos',
        queryParameters: {'query': query},
        options: Options(
          receiveTimeout: const Duration(seconds: 6),
          sendTimeout: const Duration(seconds: 4),
        ),
      );
      final url = response.data['url'] as String?;
      if (url != null && url.isNotEmpty) return url;
      // No match: return null so the UI shows its own placeholder tile. This
      // used to fall back to picsum.photos, which serves a RANDOM photo — a
      // cat or a mountain would appear captioned as a restaurant in Basra.
      return null;
    } catch (e) {
      debugPrint('[ImageSearch] Failed: $e');
      return null;
    }
  }
}
