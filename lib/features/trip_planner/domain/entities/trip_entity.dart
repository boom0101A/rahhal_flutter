import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/localized_prose.dart';

class TripEntity extends Equatable {
  final String id;
  final String? userId;
  final String destination;
  final String? destinationEn;
  final String? countryCode;
  final DateTime? startDate;
  final DateTime? endDate;
  final int durationDays;
  final String budgetTier;
  final double budgetTotal;
  final List<String> travelStyles;
  final int travelersCount;
  final String status; // planned | active | completed
  final String? heroImageUrl;
  final String? aiSummary;
  final List<String> travelTips;
  final String? bestTimeToVisit;

  /// English copies of the three prose fields above, filled in on demand
  /// by TripTranslationService — see [localizedProse].
  final String? aiSummaryEn;
  final List<String> travelTipsEn;
  final String? bestTimeToVisitEn;
  final String currency;
  final String timezone;
  final bool isMockData;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;

  const TripEntity({
    required this.id,
    this.userId,
    required this.destination,
    this.destinationEn,
    this.countryCode,
    this.startDate,
    this.endDate,
    required this.durationDays,
    required this.budgetTier,
    required this.budgetTotal,
    required this.travelStyles,
    required this.travelersCount,
    required this.status,
    this.heroImageUrl,
    this.aiSummary,
    this.travelTips = const [],
    this.bestTimeToVisit,
    this.aiSummaryEn,
    this.travelTipsEn = const [],
    this.bestTimeToVisitEn,
    this.currency = 'USD',
    this.timezone = 'UTC',
    this.isMockData = false,
    required this.createdAt,
    required this.updatedAt,
    this.syncedAt,
  });

  TripEntity copyWith({
    String? id,
    String? userId,
    String? destination,
    String? countryCode,
    DateTime? startDate,
    DateTime? endDate,
    int? durationDays,
    String? budgetTier,
    double? budgetTotal,
    List<String>? travelStyles,
    int? travelersCount,
    String? status,
    String? heroImageUrl,
    String? aiSummary,
    List<String>? travelTips,
    String? bestTimeToVisit,
    String? aiSummaryEn,
    List<String>? travelTipsEn,
    String? bestTimeToVisitEn,
    String? currency,
    String? timezone,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? syncedAt,
  }) {
    return TripEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      destination: destination ?? this.destination,
      countryCode: countryCode ?? this.countryCode,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      durationDays: durationDays ?? this.durationDays,
      budgetTier: budgetTier ?? this.budgetTier,
      budgetTotal: budgetTotal ?? this.budgetTotal,
      travelStyles: travelStyles ?? this.travelStyles,
      travelersCount: travelersCount ?? this.travelersCount,
      status: status ?? this.status,
      heroImageUrl: heroImageUrl ?? this.heroImageUrl,
      aiSummary: aiSummary ?? this.aiSummary,
      travelTips: travelTips ?? this.travelTips,
      bestTimeToVisit: bestTimeToVisit ?? this.bestTimeToVisit,
      aiSummaryEn: aiSummaryEn ?? this.aiSummaryEn,
      travelTipsEn: travelTipsEn ?? this.travelTipsEn,
      bestTimeToVisitEn: bestTimeToVisitEn ?? this.bestTimeToVisitEn,
      currency: currency ?? this.currency,
      timezone: timezone ?? this.timezone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  /// Empty when we have no real photo — see [RestaurantEntity.displayImageUrl].
  String get displayImageUrl => heroImageUrl?.trim() ?? '';

  String displayDestination(BuildContext context) {
    final lang = AppStrings.of(context).languageCode;
    if (lang == 'en' && destinationEn != null && destinationEn!.isNotEmpty) {
      return destinationEn!;
    }
    return destination;
  }

  /// The trip summary in the app's current language.
  String? displayAiSummary(BuildContext context) =>
      localizedProse(context, aiSummary, aiSummaryEn);

  /// The travel tips in the app's current language.
  List<String> displayTravelTips(BuildContext context) =>
      localizedProseList(context, travelTips, travelTipsEn);

  /// The best-time-to-visit note in the app's current language.
  String? displayBestTimeToVisit(BuildContext context) =>
      localizedProse(context, bestTimeToVisit, bestTimeToVisitEn);

  @override
  // The `*En` fields have to be here too, or a trip that just gained its
  // English prose compares EQUAL to its old self and the cubit's emit() is
  // dropped as a no-op — leaving Arabic on screen despite the database
  // already holding the English text.
  List<Object?> get props => [
        id, userId, destination, destinationEn, countryCode, startDate, endDate,
        durationDays, budgetTier, budgetTotal, travelStyles, travelersCount,
        status, heroImageUrl, aiSummary, aiSummaryEn, travelTipsEn,
        bestTimeToVisitEn, currency, timezone, createdAt, updatedAt,
      ];
}
