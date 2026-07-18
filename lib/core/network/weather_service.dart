import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import 'dio_client.dart';

class WeatherData {
  final int temp;
  final int feelsLike;
  final String description;
  final String icon;
  final int humidity;
  final double windSpeed;
  final String cityName;
  final bool isMock;

  const WeatherData({
    required this.temp,
    required this.feelsLike,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.cityName,
    this.isMock = false,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) => WeatherData(
        temp: json['temp'] as int? ?? 0,
        feelsLike: json['feelsLike'] as int? ?? 0,
        description: json['description'] as String? ?? '',
        icon: json['icon'] as String? ?? '01d',
        humidity: json['humidity'] as int? ?? 0,
        windSpeed: (json['windSpeed'] as num? ?? 0).toDouble(),
        cityName: json['cityName'] as String? ?? '',
        isMock: json['isMock'] as bool? ?? false,
      );

  // يُحوّل كود الأيقونة لـ emoji مناسب
  String get emoji {
    if (icon.startsWith('01')) return '☀️';
    if (icon.startsWith('02')) return '🌤️';
    if (icon.startsWith('03') || icon.startsWith('04')) return '☁️';
    if (icon.startsWith('09') || icon.startsWith('10')) return '🌧️';
    if (icon.startsWith('11')) return '⛈️';
    if (icon.startsWith('13')) return '❄️';
    if (icon.startsWith('50')) return '🌫️';
    return '🌡️';
  }
}

class WeatherService {
  final Dio _dio = DioClient.general;

  Future<WeatherData> getWeather(String city, {String? countryCode}) async {
    try {
      final response = await _dio.get(
        '${AppConfig.proxyBaseUrl}/api/weather',
        queryParameters: {
          'city': city,
          if (countryCode != null) 'countryCode': countryCode,
        },
      );
      if (response.data != null && response.data is Map<String, dynamic>) {
        return WeatherData.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('WeatherService: $e');
    }

    // Client-side fallback if server fails or is unreachable
    return WeatherData(
      temp: 24,
      feelsLike: 22,
      description: 'مشمس',
      icon: '01d',
      humidity: 45,
      windSpeed: 3.2,
      cityName: city,
      isMock: true,
    );
  }
}
