import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class UserLocationResult {
  final double latitude;
  final double longitude;
  final String cityName;
  final String countryName;
  final String? countryCode;

  const UserLocationResult({
    required this.latitude,
    required this.longitude,
    required this.cityName,
    required this.countryName,
    this.countryCode,
  });

  String get fullLocationDisplay {
    final validCity = cityName.trim();
    final validCountry = countryName.trim();

    if (validCity.isNotEmpty && validCity != 'الموقع الحالي' && validCountry.isNotEmpty) {
      return '$validCity، $validCountry';
    } else if (validCity.isNotEmpty && validCity != 'الموقع الحالي') {
      return validCity;
    } else if (validCountry.isNotEmpty) {
      return validCountry;
    }
    return 'الموقع الحالي';
  }
}

class LocationService {
  final Dio _dio = Dio();

  Future<UserLocationResult?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('LocationService: Location services are disabled.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('LocationService: Location permissions are denied.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('LocationService: Location permissions are permanently denied.');
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      String cityName = '';
      String countryName = '';
      String? countryCode;

      // 1. Try native geocoding plugin first
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          cityName = _firstNonEmpty([
            place.locality,
            place.subAdministrativeArea,
            place.administrativeArea,
            place.subLocality,
            place.name,
          ]);
          countryName = (place.country ?? '').trim();
          countryCode = place.isoCountryCode;
        }
      } catch (e) {
        debugPrint('Native reverse geocoding error: $e');
      }

      // 2. If city or country is empty, fallback to free BigDataCloud Reverse Geocoding API
      if (cityName.isEmpty || countryName.isEmpty) {
        final fallbackResult = await _fallbackApiGeocode(position.latitude, position.longitude);
        if (fallbackResult != null) {
          if (cityName.isEmpty) cityName = fallbackResult.cityName;
          if (countryName.isEmpty) countryName = fallbackResult.countryName;
          if (countryCode == null || countryCode.isEmpty) countryCode = fallbackResult.countryCode;
        }
      }

      if (cityName.isEmpty) cityName = 'الموقع الحالي';

      return UserLocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        cityName: cityName,
        countryName: countryName,
        countryCode: countryCode,
      );
    } catch (e) {
      debugPrint('LocationService getCurrentLocation error: $e');
      return null;
    }
  }

  String _firstNonEmpty(List<String?> items) {
    for (final item in items) {
      if (item != null && item.trim().isNotEmpty && item.trim() != 'الموقع الحالي') {
        return item.trim();
      }
    }
    return '';
  }

  Future<({String cityName, String countryName, String? countryCode})?> _fallbackApiGeocode(
      double lat, double lon) async {
    try {
      final response = await _dio.get(
        'https://api.bigdatacloud.net/data/reverse-geocode-client',
        queryParameters: {
          'latitude': lat,
          'longitude': lon,
          'localityLanguage': 'ar',
        },
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );

      if (response.data != null && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final city = (data['city'] as String?)?.trim() ??
            (data['locality'] as String?)?.trim() ??
            (data['principalSubdivision'] as String?)?.trim() ??
            '';
        final country = (data['countryName'] as String?)?.trim() ?? '';
        final code = (data['countryCode'] as String?)?.trim();

        return (cityName: city, countryName: country, countryCode: code);
      }
    } catch (e) {
      debugPrint('Fallback BigDataCloud geocoding failed: $e');
    }
    return null;
  }
}
