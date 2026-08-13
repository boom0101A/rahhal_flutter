import 'package:firebase_analytics/firebase_analytics.dart';

/// Thin wrapper around [FirebaseAnalytics] with named methods for every event
/// this app logs, so event names/params live in one place instead of being
/// sprinkled ad hoc across cubits and widgets. Injected via DI like
/// [NotificationService]/[LocationService] rather than called as a static, so
/// it stays mockable in tests.
class AnalyticsService {
  final FirebaseAnalytics _analytics;

  AnalyticsService([FirebaseAnalytics? analytics])
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  FirebaseAnalytics get analytics => _analytics;

  Future<void> logSignUp({required String method}) =>
      _analytics.logSignUp(signUpMethod: method);

  Future<void> logLogin({required String method}) =>
      _analytics.logLogin(loginMethod: method);

  Future<void> logAuthFailure({required String method, required String reason}) =>
      _analytics.logEvent(
        name: 'auth_failure',
        parameters: {'method': method, 'reason': reason},
      );

  Future<void> logTripGenerationStart({
    required String destination,
    required int durationDays,
    required String budgetTier,
  }) =>
      _analytics.logEvent(
        name: 'trip_generation_start',
        parameters: {
          'destination': destination,
          'duration_days': durationDays,
          'budget_tier': budgetTier,
        },
      );

  Future<void> logTripGenerationSuccess({
    required String destination,
    required int durationDays,
  }) =>
      _analytics.logEvent(
        name: 'trip_generation_success',
        parameters: {'destination': destination, 'duration_days': durationDays},
      );

  Future<void> logTripGenerationFailure({
    required String destination,
    required String reason,
  }) =>
      _analytics.logEvent(
        name: 'trip_generation_failure',
        parameters: {'destination': destination, 'reason': reason},
      );

  Future<void> logFavoriteToggle({
    required String itemType,
    required String itemId,
    required bool isFavorited,
  }) =>
      _analytics.logEvent(
        name: 'favorite_toggle',
        parameters: {
          'item_type': itemType,
          'item_id': itemId,
          'is_favorited': isFavorited,
        },
      );

  Future<void> logTripShare({required String tripId}) => _analytics.logEvent(
        name: 'trip_share',
        parameters: {'trip_id': tripId},
      );

  Future<void> logDetailView({required String itemType, required String itemId}) =>
      _analytics.logEvent(
        name: 'detail_view',
        parameters: {'item_type': itemType, 'item_id': itemId},
      );
}
