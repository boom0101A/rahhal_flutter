# ملف كود Dart: lib\core\network\image_search_service.dart

```dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dio_client.dart';

class ImageSearchService {
  final Dio _dio = DioClient.anthropic; // Anthropic general-purpose client automatically handles the proxy base URL and token headers!

  /// Searches for a high-quality landscape image matching [query].
  /// Calls our Next.js backend proxy endpoint to keep the Unsplash access key secure.
  Future<String?> searchPhoto(String query) async {
    if (query.trim().isEmpty) return null;
    try {
      final response = await _dio.get(
        '/api/photos',
        queryParameters: {'query': query},
      );
      
      if (response.data != null && response.data['url'] != null) {
        return response.data['url'] as String;
      }
      return null;
    } catch (e) {
      debugPrint('ImageSearchService: Error searching photo for query "$query": $e');
      return null;
    }
  }
}

```
