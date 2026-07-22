import 'dart:math';

/// A rough distance + travel-time estimate between two consecutive stops.
/// Deliberately simple and offline: a straight-line (haversine) distance with
/// a detour factor, and speed assumptions for walking vs driving. It's a
/// planning hint ("~15 min walk"), not turn-by-turn navigation.
class TravelEstimate {
  /// Straight-line distance in kilometres.
  final double distanceKm;

  /// Whether walking is the assumed mode (short hops) vs driving.
  final bool isWalking;

  /// Estimated minutes for the assumed mode.
  final int minutes;

  const TravelEstimate({
    required this.distanceKm,
    required this.isWalking,
    required this.minutes,
  });

  /// Real streets are longer than a straight line; a 1.3x factor approximates
  /// typical city routing without needing a directions API.
  static const double _detourFactor = 1.3;
  static const double _walkKmh = 4.8; // average walking pace
  static const double _driveKmh = 28.0; // average urban driving with stops
  static const double _walkThresholdKm = 1.5; // walk under this, drive over

  static const double _earthRadiusKm = 6371;

  static double _haversine(
      double lat1, double lng1, double lat2, double lng2) {
    double toRad(double d) => d * pi / 180;
    final dLat = toRad(lat2 - lat1);
    final dLng = toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(toRad(lat1)) * cos(toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return _earthRadiusKm * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  /// Returns null when either coordinate is missing/invalid, or the two points
  /// are effectively the same spot (nothing meaningful to show).
  static TravelEstimate? between({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    final valid = fromLat.abs() > 0.001 &&
        fromLng.abs() > 0.001 &&
        toLat.abs() > 0.001 &&
        toLng.abs() > 0.001;
    if (!valid) return null;

    final straight = _haversine(fromLat, fromLng, toLat, toLng);
    final routed = straight * _detourFactor;
    if (routed < 0.05) return null; // < 50 m — same place

    final isWalking = routed <= _walkThresholdKm;
    final speed = isWalking ? _walkKmh : _driveKmh;
    final minutes = max(1, (routed / speed * 60).round());

    return TravelEstimate(
      distanceKm: routed,
      isWalking: isWalking,
      minutes: minutes,
    );
  }

  /// e.g. "0.4 km" or "3.2 km".
  String get distanceLabel => distanceKm < 1
      ? '${(distanceKm * 1000).round()} m'
      : '${distanceKm.toStringAsFixed(1)} km';
}
