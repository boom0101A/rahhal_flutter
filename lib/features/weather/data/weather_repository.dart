import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/config/app_config.dart';
import '../domain/entities/weather_entity.dart';


class WeatherRepository {
  final Dio _dio;

  WeatherRepository({Dio? dio}) : _dio = dio ?? Dio();

  static const _cachePrefix = 'weather_';
  static const _cacheTsPrefix = 'weather_ts_';
  static const _cacheDurationHours = 3;

  /// Fetch weather forecast for given coordinates.
  /// [lang] should be 'ar' or 'en' based on app locale.
  Future<WeatherForecast?> getForecast({
    required double lat,
    required double lon,
    String lang = 'en',
  }) async {
    final cacheKey = '$_cachePrefix${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}_$lang';
    final tsKey = '$_cacheTsPrefix${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}_$lang';

    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString(cacheKey);
    final cachedTs = prefs.getInt(tsKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiry = _cacheDurationHours * 3600 * 1000;

    if (cachedJson != null && (now - cachedTs) < expiry) {
      try {
        return WeatherForecast.fromJson(
          jsonDecode(cachedJson) as Map<String, dynamic>,
        );
      } catch (_) {}
    }

    try {
      final res = await _dio.get(
        '${AppConfig.proxyBaseUrl}/api/weather',
        queryParameters: {'lat': lat, 'lon': lon, 'lang': lang},
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );
      final forecast = WeatherForecast.fromJson(
        res.data as Map<String, dynamic>,
      );
      // Cache it
      await prefs.setString(cacheKey, jsonEncode(res.data));
      await prefs.setInt(tsKey, now);
      return forecast;
    } catch (_) {
      // Return stale cache if offline
      if (cachedJson != null) {
        try {
          return WeatherForecast.fromJson(
            jsonDecode(cachedJson) as Map<String, dynamic>,
          );
        } catch (_) {}
      }
      return null;
    }
  }
}
