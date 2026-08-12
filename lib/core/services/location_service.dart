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
  // receiveTimeout alone (set per-call below) only bounds the wait for
  // response data — it does nothing for a hung DNS lookup or TCP connect on
  // a degraded network, which could block getCurrentLocation()/
  // reverseGeocode() indefinitely since neither call has an outer timeout.
  final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 8)));

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

      // 1. Try native geocoding plugin first (Mobile only — geocoding is unsupported on Web)
      if (!kIsWeb) {
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
      }

      // 2. For Web OR if geocoding gave no result, fallback to free BigDataCloud Reverse Geocoding API
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

  /// Fast, coordinates-only location for latency-sensitive screens (e.g.
  /// "what's around me"). Returns the LAST KNOWN position instantly when the OS
  /// has one cached, and only falls back to a fresh (but low-accuracy, short-
  /// timeout) fix otherwise. Crucially it does NOT block on reverse geocoding —
  /// callers that need a city label should call [reverseGeocode] separately in
  /// the background so results can render immediately.
  Future<({double latitude, double longitude})?> getQuickPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      // Last known is essentially instant when available.
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        return (latitude: last.latitude, longitude: last.longitude);
      }

      // No cached fix — get a fresh one, but keep it fast (low accuracy is
      // plenty for a ~1.5km "nearby" search and returns much sooner).
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 6),
        ),
      );
      return (latitude: pos.latitude, longitude: pos.longitude);
    } catch (e) {
      debugPrint('LocationService.getQuickPosition error: $e');
      return null;
    }
  }

  /// Best-effort human label ("City, Country") for a coordinate. Safe to call
  /// in the background after results already render.
  Future<String> reverseGeocode(double lat, double lon) async {
    String cityName = '';
    String countryName = '';
    if (!kIsWeb) {
      try {
        final placemarks = await placemarkFromCoordinates(lat, lon);
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
        }
      } catch (e) {
        debugPrint('reverseGeocode native error: $e');
      }
    }
    if (cityName.isEmpty || countryName.isEmpty) {
      final fb = await _fallbackApiGeocode(lat, lon);
      if (fb != null) {
        if (cityName.isEmpty) cityName = fb.cityName;
        if (countryName.isEmpty) countryName = fb.countryName;
      }
    }
    return UserLocationResult(
      latitude: lat,
      longitude: lon,
      cityName: cityName.isEmpty ? 'الموقع الحالي' : cityName,
      countryName: countryName,
    ).fullLocationDisplay;
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
