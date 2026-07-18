import 'dart:convert';
import '../../domain/entities/trip_entity.dart';

class TripMapper {
  static TripEntity fromMap(Map<String, dynamic> m) => TripEntity(
        id: m['id'] as String,
        userId: m['user_id'] as String?,
        destination: m['destination'] as String,
        destinationEn: m['destination_en'] as String?,
        countryCode: m['country_code'] as String?,
        startDate: m['start_date'] != null
            ? DateTime.tryParse(m['start_date'] as String)
            : null,
        endDate: m['end_date'] != null
            ? DateTime.tryParse(m['end_date'] as String)
            : null,
        durationDays: m['duration_days'] as int? ?? 1,
        budgetTier: m['budget_tier'] as String? ?? 'mid',
        budgetTotal: (m['budget_total'] as num? ?? 0).toDouble(),
        travelStyles: _decodeList(m['travel_styles'] as String?),
        travelersCount: m['travelers_count'] as int? ?? 1,
        status: m['status'] as String? ?? 'planned',
        heroImageUrl: m['hero_image_url'] as String?,
        aiSummary: m['ai_summary'] as String?,
        travelTips: _decodeList(m['travel_tips'] as String?),
        bestTimeToVisit: m['best_time_to_visit'] as String?,
        currency: m['currency'] as String? ?? 'USD',
        timezone: m['timezone'] as String? ?? 'UTC',
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
        syncedAt: m['synced_at'] != null
            ? DateTime.tryParse(m['synced_at'] as String)
            : null,
        isMockData: (m['is_mock_data'] as int? ?? 0) == 1,
      );

  static Map<String, dynamic> toMap(TripEntity t) => {
        'id': t.id,
        'user_id': t.userId,
        'destination': t.destination,
        'destination_en': t.destinationEn,
        'country_code': t.countryCode,
        'start_date': t.startDate?.toIso8601String(),
        'end_date': t.endDate?.toIso8601String(),
        'duration_days': t.durationDays,
        'budget_tier': t.budgetTier,
        'budget_total': t.budgetTotal,
        'travel_styles': jsonEncode(t.travelStyles),
        'travelers_count': t.travelersCount,
        'status': t.status,
        'hero_image_url': t.heroImageUrl,
        'ai_summary': t.aiSummary,
        'travel_tips': jsonEncode(t.travelTips),
        'best_time_to_visit': t.bestTimeToVisit,
        'currency': t.currency,
        'timezone': t.timezone,
        'created_at': t.createdAt.toIso8601String(),
        'updated_at': t.updatedAt.toIso8601String(),
        'synced_at': t.syncedAt?.toIso8601String(),
        'is_mock_data': t.isMockData ? 1 : 0,
      };

  static List<String> _decodeList(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      return (jsonDecode(json) as List).map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }
}
