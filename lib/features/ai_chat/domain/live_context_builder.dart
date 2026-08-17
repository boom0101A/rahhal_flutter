/// Formats the compact "live data" block attached to every chat message —
/// current weather, real nearby places, and which of today's stops are still
/// open — so the assistant answers from real data instead of guessing.
///
/// Deliberately pure: fetching weather/location/nearby-places and computing
/// closing times all happen in chat_screen.dart. Kept separate so the
/// formatting/length-capping logic is testable without GPS, network, or a
/// database.
library;

import '../../../core/network/weather_service.dart';
import '../../nearby/data/nearby_service.dart';

/// Filters [closingTimes] (stop display name → closing time today) down to
/// the entries still open at [now]. Callers should re-run this at send time
/// rather than caching its result — unlike weather/nearby-places, "still
/// open" is inherently time-sensitive and would otherwise go stale over a
/// long chat session. Pure and free (no network), so recomputing per
/// message costs nothing.
Map<String, DateTime> stillOpenAt(
        Map<String, DateTime> closingTimes, DateTime now) =>
    Map.fromEntries(closingTimes.entries.where((e) => e.value.isAfter(now)));

/// [openStopsClosingTimes] maps a stop's display name to when it closes
/// today; only stops still open (closing time in the future) should be
/// passed in — the caller decides that using `closingTimeFor`, then
/// [stillOpenAt] to keep it fresh at send time.
String buildLiveContextSummary({
  required String lang,
  WeatherData? weather,
  List<NearbyPlace> nearbyPlaces = const [],
  Map<String, DateTime> openStopsClosingTimes = const {},
  int maxLength = 1500,
}) {
  final isArabic = lang != 'en';
  final lines = <String>[];

  if (weather != null) {
    lines.add(isArabic
        ? 'الطقس الآن في ${weather.cityName}: ${weather.temp}° (يبدو كأنه ${weather.feelsLike}°)، ${weather.description}.'
        : 'Current weather in ${weather.cityName}: ${weather.temp}° (feels like ${weather.feelsLike}°), ${weather.description}.');
  }

  if (openStopsClosingTimes.isNotEmpty) {
    final items = openStopsClosingTimes.entries
        .take(8)
        .map((e) => '${e.key} (${_formatClock(e.value, isArabic)})')
        .join('، ');
    lines.add(isArabic
        ? 'محطات من خطة اليوم لا تزال مفتوحة الآن، وتغلق عند: $items.'
        : "Today's planned stops still open now, closing at: $items.");
  }

  if (nearbyPlaces.isNotEmpty) {
    final items = nearbyPlaces
        .take(5)
        .map((p) => p.walkLabel(lang).isEmpty
            ? p.name
            : '${p.name} (${p.walkLabel(lang)})')
        .join('، ');
    lines.add(isArabic
        ? 'أماكن حقيقية قريبة من موقع المسافر الآن: $items.'
        : "Real places near the traveler's current location right now: $items.");
  }

  final result = lines.join('\n');
  return result.length > maxLength ? result.substring(0, maxLength) : result;
}

/// "10:30 م" / "10:30 PM" — kept locale-independent (no `intl` DateFormat)
/// so this never depends on locale data being initialized.
String _formatClock(DateTime t, bool isArabic) {
  final h24 = t.hour;
  final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
  final minute = t.minute.toString().padLeft(2, '0');
  final suffix = h24 < 12 ? (isArabic ? 'ص' : 'AM') : (isArabic ? 'م' : 'PM');
  return '$h12:$minute $suffix';
}
