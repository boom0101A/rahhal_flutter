import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class MapLauncherService {
  /// Opens the location in Google Maps with search query & coordinates
  static Future<bool> openInGoogleMaps({
    required String placeName,
    String? city,
    double? lat,
    double? lon,
  }) async {
    try {
      final query = [
        placeName.trim(),
        if (city != null && city.trim().isNotEmpty) city.trim(),
      ].join(', ');

      final String googleMapsUrl;
      if (lat != null && lon != null && lat != 0.0 && lon != 0.0) {
        googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lon';
      } else {
        googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}';
      }

      final Uri uri = Uri.parse(googleMapsUrl);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback browser navigation
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Error launching Google Maps: $e');
      return false;
    }
  }

  /// Opens Uber app/web with pickup set to current location and dropoff to destination
  static Future<bool> openUberRide({
    required String placeName,
    String? city,
    double? lat,
    double? lon,
  }) async {
    try {
      final destinationName = [
        placeName.trim(),
        if (city != null && city.trim().isNotEmpty) city.trim(),
      ].join(', ');

      final String uberUrl;
      if (lat != null && lon != null && lat != 0.0 && lon != 0.0) {
        uberUrl =
            'https://m.uber.com/ul/?action=setPickup&pickup=my_location&dropoff[latitude]=$lat&dropoff[longitude]=$lon&dropoff[formatted_address]=${Uri.encodeComponent(destinationName)}';
      } else {
        uberUrl =
            'https://m.uber.com/ul/?action=setPickup&pickup=my_location&dropoff[formatted_address]=${Uri.encodeComponent(destinationName)}';
      }

      final Uri uri = Uri.parse(uberUrl);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching Uber: $e');
      return false;
    }
  }

  /// Opens Careem or web navigation link
  static Future<bool> openCareemRide({
    required String placeName,
    String? city,
  }) async {
    try {
      final destinationName = [
        placeName.trim(),
        if (city != null && city.trim().isNotEmpty) city.trim(),
      ].join(', ');

      final Uri uri = Uri.parse(
          'https://www.careem.com/ride?destination=${Uri.encodeComponent(destinationName)}');
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching Careem: $e');
      return false;
    }
  }
}
