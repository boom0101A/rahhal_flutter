import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../di/injection.dart';
import 'place_resolver_service.dart';

class MapLauncherService {
  /// Opens the location in Google Maps, aiming to land on the actual PLACE CARD
  /// (name, photos, reviews, hours) rather than a bare coordinate pin.
  ///
  /// Resolution order, best → worst:
  ///   1. `place_id` present → the exact business listing (no ambiguity between
  ///      branches of a chain). Always preferred.
  ///   2. name + coordinates → a NAME search centered on the coordinates
  ///      (`/maps/search/<name>/@lat,lng,zoom`). Google resolves this to the
  ///      real listing at that spot instead of showing raw coordinates — this
  ///      is the fix for places we don't have a place_id for.
  ///   3. name only → a plain name search.
  ///   4. coordinates only → a coordinate pin (last resort — no card).
  static Future<bool> openInGoogleMaps({
    required String placeName,
    String? city,
    double? lat,
    double? lon,
    String? placeId,
  }) async {
    try {
      final name = placeName.trim();
      final hasName = name.isNotEmpty;
      final hasCoords = lat != null && lon != null && lat != 0.0 && lon != 0.0;

      // No stored place_id (AI-generated stops, OSM places, older saved trips)?
      // Resolve the EXACT listing from the name + its own coordinates first.
      // Without this, the name search below can surface similarly-named places
      // in other governorates/countries instead of this one.
      var resolvedPlaceId = placeId;
      if ((resolvedPlaceId == null || resolvedPlaceId.trim().isEmpty) &&
          hasName &&
          hasCoords) {
        try {
          resolvedPlaceId = await sl<PlaceResolverService>().resolvePlaceId(
            name: name,
            lat: lat,
            lng: lon,
            city: city,
          );
        } catch (e) {
          debugPrint('Place resolution skipped: $e');
        }
      }
      // Include the city/area only as extra disambiguation for the name search.
      final labelledQuery = [
        if (hasName) name,
        if (city != null && city.trim().isNotEmpty) city.trim(),
      ].join('، ');

      final String googleMapsUrl;
      if (resolvedPlaceId != null && resolvedPlaceId.trim().isNotEmpty) {
        // Exact listing. `query` is required by the Maps URL API; use the name
        // when we have it, otherwise the coordinates.
        final q = hasName ? name : (hasCoords ? '$lat,$lon' : name);
        googleMapsUrl =
            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(q)}'
            '&query_place_id=${Uri.encodeComponent(resolvedPlaceId.trim())}';
      } else if (hasName && hasCoords) {
        // Search by name, biased to the exact coordinates → opens the place
        // card, not a coordinate pin.
        googleMapsUrl =
            'https://www.google.com/maps/search/${Uri.encodeComponent(labelledQuery)}/@$lat,$lon,17z';
      } else if (hasName) {
        googleMapsUrl =
            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(labelledQuery)}';
      } else if (hasCoords) {
        googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lon';
      } else {
        return false;
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
