import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import '../di/injection.dart';
import 'location_service.dart';

/// Shares where the user is *right now* as a Google Maps link, through whatever
/// app they pick (WhatsApp, Telegram, SMS…).
///
/// Deliberately a one-shot share, not background tracking: it needs no
/// background-location permission, drains no battery, keeps the user in full
/// control of who sees their position, and — unlike continuous tracking — can
/// ship as an over-the-air Dart update.
class LocationShareService {
  /// Returns false when the position couldn't be determined (permission denied
  /// or location services off), so the caller can show a hint.
  Future<bool> shareCurrentLocation({required String message}) async {
    try {
      final pos = await sl<LocationService>().getQuickPosition();
      if (pos == null) return false;

      // `?q=lat,lng` renders a pin at the exact point in every Maps client and
      // opens in a browser for anyone without the app installed.
      final lat = pos.latitude.toStringAsFixed(6);
      final lng = pos.longitude.toStringAsFixed(6);
      final link = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

      await Share.share('$message\n$link', subject: message);
      return true;
    } catch (e) {
      debugPrint('LocationShareService.shareCurrentLocation error: $e');
      return false;
    }
  }
}
