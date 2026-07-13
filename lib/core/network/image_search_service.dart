import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import 'dio_client.dart';

class ImageSearchService {
  // استخدم general بدلاً من anthropic — لا يحتاج token header ولا AI error handling
  final Dio _dio = DioClient.general;

  /// Searches for a high-quality landscape image matching [query].
  /// Calls our Next.js backend proxy endpoint to keep the Unsplash access key secure.
  Future<String?> searchPhoto(String query) async {
    if (query.trim().isEmpty) return null;
    try {
      final response = await _dio.get(
        '${AppConfig.proxyBaseUrl}/api/photos',
        queryParameters: {'query': query},
      );
      
      if (response.data != null && response.data['url'] != null) {
        return response.data['url'] as String;
      }
      return null;
    } catch (e) {
      debugPrint('ImageSearchService: $e');
      return null; // فشل الصورة لا يجب أن يوقف الرحلة
    }
  }
}
