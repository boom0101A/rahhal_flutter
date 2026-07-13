import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import '../../../../core/constants/app_strings.dart';

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
  final String currency;
  final String timezone;
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
    this.currency = 'USD',
    this.timezone = 'UTC',
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
      currency: currency ?? this.currency,
      timezone: timezone ?? this.timezone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  String get displayImageUrl {
    if (heroImageUrl != null && heroImageUrl!.trim().isNotEmpty) {
      return heroImageUrl!;
    }
    final seed = (destination + id).hashCode.abs() % 1000;
    return 'https://picsum.photos/seed/$seed/800/600';
  }

  String displayDestination(BuildContext context) {
    final lang = AppStrings.of(context).languageCode;
    if (lang == 'en' && destinationEn != null && destinationEn!.isNotEmpty) {
      return destinationEn!;
    }
    return destination;
  }

  @override
  List<Object?> get props => [
        id, userId, destination, countryCode, startDate, endDate,
        durationDays, budgetTier, budgetTotal, travelStyles, travelersCount,
        status, heroImageUrl, aiSummary, currency, timezone, createdAt, updatedAt,
      ];
}
