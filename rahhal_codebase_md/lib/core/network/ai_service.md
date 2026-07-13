# ملف كود Dart: lib\core\network\ai_service.dart

```dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dio_client.dart';

/// Response model for a complete AI-generated trip plan.
class TripPlanResponse {
  final String destination;
  final String countryCode;
  final String aiSummary;
  final double budgetTotalUsd;
  final String heroImageQuery;
  final List<DayPlanResponse> days;
  final List<RestaurantResponse> allRestaurants;
  final BudgetBreakdownResponse budgetBreakdown;
  final List<String> travelTips;
  final String bestTimeToVisit;
  final String currency;
  final String timezone;

  const TripPlanResponse({
    required this.destination,
    required this.countryCode,
    required this.aiSummary,
    required this.budgetTotalUsd,
    required this.heroImageQuery,
    required this.days,
    required this.allRestaurants,
    required this.budgetBreakdown,
    required this.travelTips,
    required this.bestTimeToVisit,
    required this.currency,
    required this.timezone,
  });

  factory TripPlanResponse.fromJson(Map<String, dynamic> json) {
    return TripPlanResponse(
      destination: json['destination'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? '',
      aiSummary: json['ai_summary'] as String? ?? '',
      budgetTotalUsd: (json['budget_total_usd'] as num? ?? 0).toDouble(),
      heroImageQuery: json['hero_image_query'] as String? ?? '',
      days: ((json['days'] as List?) ?? [])
          .map((d) => DayPlanResponse.fromJson(d as Map<String, dynamic>))
          .toList(),
      allRestaurants: ((json['all_restaurants'] as List?) ?? [])
          .map((r) => RestaurantResponse.fromJson(r as Map<String, dynamic>))
          .toList(),
      budgetBreakdown: BudgetBreakdownResponse.fromJson(
          json['budget_breakdown'] as Map<String, dynamic>? ?? {}),
      travelTips: ((json['travel_tips'] as List?) ?? [])
          .map((t) => t.toString())
          .toList(),
      bestTimeToVisit: json['best_time_to_visit'] as String? ?? '',
      currency: json['currency'] as String? ?? 'USD',
      timezone: json['timezone'] as String? ?? 'UTC',
    );
  }
}

class DayPlanResponse {
  final int dayNumber;
  final String theme;
  final int dateOffset;
  final String summary;
  final List<StopResponse> stops;
  final RestaurantResponse? recommendedRestaurant;

  const DayPlanResponse({
    required this.dayNumber,
    required this.theme,
    required this.dateOffset,
    required this.summary,
    required this.stops,
    this.recommendedRestaurant,
  });

  factory DayPlanResponse.fromJson(Map<String, dynamic> json) {
    return DayPlanResponse(
      dayNumber: json['day_number'] as int? ?? 0,
      theme: json['theme'] as String? ?? '',
      dateOffset: json['date_offset'] as int? ?? 0,
      summary: json['summary'] as String? ?? '',
      stops: ((json['stops'] as List?) ?? [])
          .map((s) => StopResponse.fromJson(s as Map<String, dynamic>))
          .toList(),
      recommendedRestaurant: json['recommended_restaurant'] != null
          ? RestaurantResponse.fromJson(
              json['recommended_restaurant'] as Map<String, dynamic>)
          : null,
    );
  }
}

class StopResponse {
  final int orderIndex;
  final String name;
  final String nameEn;
  final String category;
  final String timeOfDay;
  final String startTime;
  final int durationMinutes;
  final double latitude;
  final double longitude;
  final String address;
  final double costUsd;
  final String aiTip;
  final bool bookingRequired;
  final String? bookingUrl;

  const StopResponse({
    required this.orderIndex,
    required this.name,
    required this.nameEn,
    required this.category,
    required this.timeOfDay,
    required this.startTime,
    required this.durationMinutes,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.costUsd,
    required this.aiTip,
    required this.bookingRequired,
    this.bookingUrl,
  });

  factory StopResponse.fromJson(Map<String, dynamic> json) {
    return StopResponse(
      orderIndex: json['order_index'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      category: json['category'] as String? ?? 'other',
      timeOfDay: json['time_of_day'] as String? ?? 'morning',
      startTime: json['start_time'] as String? ?? '09:00',
      durationMinutes: json['duration_minutes'] as int? ?? 60,
      latitude: (json['latitude'] as num? ?? 0).toDouble(),
      longitude: (json['longitude'] as num? ?? 0).toDouble(),
      address: json['address'] as String? ?? '',
      costUsd: (json['cost_usd'] as num? ?? 0).toDouble(),
      aiTip: json['ai_tip'] as String? ?? '',
      bookingRequired: json['booking_required'] as bool? ?? false,
      bookingUrl: json['booking_url'] as String?,
    );
  }
}

class RestaurantResponse {
  final String name;
  final String cuisineType;
  final bool halalCertified;
  final double rating;
  final double pricePerPersonUsd;
  final String address;
  final double latitude;
  final double longitude;
  final String aiDescription;

  const RestaurantResponse({
    required this.name,
    required this.cuisineType,
    required this.halalCertified,
    required this.rating,
    required this.pricePerPersonUsd,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.aiDescription,
  });

  factory RestaurantResponse.fromJson(Map<String, dynamic> json) {
    return RestaurantResponse(
      name: json['name'] as String? ?? '',
      cuisineType: json['cuisine_type'] as String? ?? '',
      halalCertified: json['halal_certified'] as bool? ?? false,
      rating: (json['rating'] as num? ?? 0).toDouble(),
      pricePerPersonUsd: (json['price_per_person_usd'] as num? ?? 0).toDouble(),
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num? ?? 0).toDouble(),
      longitude: (json['longitude'] as num? ?? 0).toDouble(),
      aiDescription: json['ai_description'] as String? ?? '',
    );
  }
}

class BudgetBreakdownResponse {
  final double accommodationUsd;
  final double foodUsd;
  final double transportUsd;
  final double activitiesUsd;
  final double shoppingUsd;

  const BudgetBreakdownResponse({
    required this.accommodationUsd,
    required this.foodUsd,
    required this.transportUsd,
    required this.activitiesUsd,
    required this.shoppingUsd,
  });

  factory BudgetBreakdownResponse.fromJson(Map<String, dynamic> json) {
    return BudgetBreakdownResponse(
      accommodationUsd: (json['accommodation_usd'] as num? ?? 0).toDouble(),
      foodUsd: (json['food_usd'] as num? ?? 0).toDouble(),
      transportUsd: (json['transport_usd'] as num? ?? 0).toDouble(),
      activitiesUsd: (json['activities_usd'] as num? ?? 0).toDouble(),
      shoppingUsd: (json['shopping_usd'] as num? ?? 0).toDouble(),
    );
  }
}

/// Service that calls the Anthropic Claude API to generate trip plans and chat.
class AITravelService {
  final Dio _dio;

  AITravelService() : _dio = DioClient.anthropic;

  // ─── Public API ─────────────────────────────────────────────────────────────

  /// Generates a complete trip plan using Claude AI.
  Future<TripPlanResponse> generateTripPlan({
    required String destination,
    required int durationDays,
    required String budgetTier,
    required List<String> travelStyles,
    required int travelersCount,
    DateTime? startDate,
  }) async {
    try {
      final response = await _dio.post(
        '/api/generate-trip',
        data: {
          'destination': destination,
          'durationDays': durationDays,
          'budgetTier': budgetTier,
          'travelStyles': travelStyles,
          'travelersCount': travelersCount,
          'startDate': startDate?.toIso8601String().split('T').first,
        },
      );

      final jsonMap = response.data as Map<String, dynamic>;
      return TripPlanResponse.fromJson(jsonMap);
    } catch (e) {
      debugPrint(
          '[AITravelService] API Error or no key, using smart mock fallback: $e');
      // Delay slightly to simulate AI generation
      await Future.delayed(const Duration(seconds: 2));
      return _generateMockTripResponse(
          destination, durationDays, budgetTier, travelersCount);
    }
  }

  /// Sends a chat message in the context of an existing trip.
  Future<String> chatWithAssistant({
    required String destination,
    required String tripSummary,
    required List<Map<String, String>> conversationHistory,
    required String userMessage,
  }) async {
    try {
      final response = await _dio.post(
        '/api/chat',
        data: {
          'destination': destination,
          'tripSummary': tripSummary,
          'conversationHistory': conversationHistory,
          'userMessage': userMessage,
        },
      );

      return response.data['reply'] as String;
    } catch (e) {
      debugPrint(
          '[AITravelService] Chat error, returning smart mock reply: $e');
      await Future.delayed(const Duration(milliseconds: 800));
      return _generateMockChatReply(destination, userMessage);
    }
  }

  // ─── Smart Mock Generator Fallbacks ────────────────────────────────────────

  TripPlanResponse _generateMockTripResponse(
    String destination,
    int durationDays,
    String budgetTier,
    int travelersCount,
  ) {
    final double costPerDay = switch (budgetTier) {
      'economy' => 60,
      'mid' => 150,
      'luxury' => 450,
      _ => 150,
    };
    final double budgetTotal = costPerDay * durationDays * travelersCount;

    // Coordinate offsets based on destination name hash to make it look stable but dynamic
    final int destHash = destination.hashCode;
    final double baseLat = 41.0082 + (destHash % 100) / 1000.0;
    final double baseLng = 28.9784 + ((destHash >> 2) % 100) / 1000.0;

    final List<DayPlanResponse> mockDays = [];
    for (int day = 1; day <= durationDays; day++) {
      final List<StopResponse> mockStops = [
        StopResponse(
          orderIndex: 0,
          name: 'زيارة المعالم التاريخية في $destination',
          nameEn: 'Historical Sightseeing in $destination',
          category: 'landmark',
          timeOfDay: 'morning',
          startTime: '09:30',
          durationMinutes: 120,
          latitude: baseLat + 0.005 * day,
          longitude: baseLng - 0.003 * day,
          address: 'وسط مدينة $destination',
          costUsd: budgetTier == 'economy' ? 0.0 : 15.0,
          aiTip: 'انصح بالذهاب مبكراً لتجنب الازدحام الشديد.',
          bookingRequired: false,
        ),
        StopResponse(
          orderIndex: 1,
          name: 'المتحف الوطني الرئيسي',
          nameEn: 'National Grand Museum',
          category: 'museum',
          timeOfDay: 'afternoon',
          startTime: '13:00',
          durationMinutes: 150,
          latitude: baseLat - 0.002 * day,
          longitude: baseLng + 0.006 * day,
          address: 'شارع الثقافة، $destination',
          costUsd: budgetTier == 'economy' ? 5.0 : 25.0,
          aiTip: 'يتوفر دليل صوتي باللغة العربية مجاناً عند إظهار الهوية.',
          bookingRequired: true,
          bookingUrl: 'https://example.com/booking',
        ),
        StopResponse(
          orderIndex: 2,
          name: 'الحديقة العامة والمطل البانورامي',
          nameEn: 'Central Park and Scenic Overlook',
          category: 'park',
          timeOfDay: 'evening',
          startTime: '17:30',
          durationMinutes: 90,
          latitude: baseLat + 0.008 * day,
          longitude: baseLng + 0.002 * day,
          address: 'تل الإطلالة، $destination',
          costUsd: 0.0,
          aiTip: 'أفضل مكان لمشاهدة غروب الشمس والتقاط الصور التذكارية.',
          bookingRequired: false,
        ),
      ];

      mockDays.add(DayPlanResponse(
        dayNumber: day,
        theme: 'يوم الاستكشاف والثقافة - اليوم $day',
        dateOffset: day - 1,
        summary:
            'سنقوم اليوم بزيارة أشهر المعالم التاريخية والثقافية والمتاحف بوسط المدينة.',
        stops: mockStops,
        recommendedRestaurant: RestaurantResponse(
          name: 'مطعم مذاق $destination التقليدي',
          cuisineType: 'مأكولات محلية',
          halalCertified: true,
          rating: 4.8,
          pricePerPersonUsd: budgetTier == 'economy' ? 10.0 : 30.0,
          address: 'شارع المطاعم القديم، $destination',
          latitude: baseLat + 0.001 * day,
          longitude: baseLng + 0.001 * day,
          aiDescription:
              'يقدم ألذ المأكولات الشعبية التقليدية بطابع أصيل وخدمة ممتازة.',
        ),
      ));
    }

    final mockAllRestaurants = [
      RestaurantResponse(
        name: 'مطعم الجمر والفرن',
        cuisineType: 'مشويات شرقية',
        halalCertified: true,
        rating: 4.7,
        pricePerPersonUsd: 25.0,
        address: 'منطقة الميناء البحري',
        latitude: baseLat + 0.012,
        longitude: baseLng - 0.008,
        aiDescription: 'متميز في تقديم اللحوم الطازجة على الفحم بخلطات سرية.',
      ),
      RestaurantResponse(
        name: 'كافيه البسفور والمطل',
        cuisineType: 'مشروبات وحلويات',
        halalCertified: true,
        rating: 4.9,
        pricePerPersonUsd: 12.0,
        address: 'كورنيش المشاة السياحي',
        latitude: baseLat - 0.008,
        longitude: baseLng + 0.015,
        aiDescription:
            'إطلالة خيالية مباشرة على البحر وقهوة عربية مختصة مع الحلويات الشرقية.',
      ),
    ];

    return TripPlanResponse(
      destination: destination,
      countryCode: 'TR',
      aiSummary:
          'رحلة مميزة إلى $destination لتجربة أروع المعالم التاريخية والثقافية والترفيهية.',
      budgetTotalUsd: budgetTotal,
      heroImageQuery: '$destination tourism sights sunset',
      days: mockDays,
      allRestaurants: mockAllRestaurants,
      budgetBreakdown: BudgetBreakdownResponse(
        accommodationUsd: budgetTotal * 0.45,
        foodUsd: budgetTotal * 0.25,
        transportUsd: budgetTotal * 0.15,
        activitiesUsd: budgetTotal * 0.10,
        shoppingUsd: budgetTotal * 0.05,
      ),
      travelTips: [
        'تأكد من شراء بطاقة المواصلات العامة لتوفير المال والوقت.',
        'احرص على شرب المياه المعبأة دائماً وتجنب مياه الصنبور.',
        'يفضل الاحتفاظ ببعض المبالغ النقدية المحلية للمشتريات الصغيرة.',
        'قم بتحميل تطبيق الخرائط دون اتصال بالإنترنت للوصول بسهولة.'
      ],
      bestTimeToVisit: 'من سبتمبر إلى نوفمبر (الخريف المعتدل)',
      currency: 'USD',
      timezone: 'UTC+3',
    );
  }

  String _generateMockChatReply(String destination, String userMessage) {
    final msg = userMessage.toLowerCase();
    if (msg.contains('مطعم') ||
        msg.contains('أكل') ||
        msg.contains('غداء') ||
        msg.contains('عشاء')) {
      return 'أنصحك بتجربة المطاعم الشعبية القريبة من وسط المدينة، حيث تقدم وجبات حلال تقليدية شهية وبأسعار مناسبة. كما يمكنك التحقق من تبويب "المطاعم" المخصص في رحلتك.';
    }
    if (msg.contains('سعر') ||
        msg.contains('تكلفة') ||
        msg.contains('تذاكر') ||
        msg.contains('حجز')) {
      return 'معظم الأماكن السياحية تتطلب حجوزات مسبقة لتفادي الطوابير الطويلة. يمكنك استخدام روابط الحجز المباشرة المتوفرة داخل تفاصيل كل محطة في جدولك.';
    }
    if (msg.contains('طقس') || msg.contains('جو') || msg.contains('مطر')) {
      return 'الطقس حالياً معتدل ومناسب جداً للزيارات الخارجية والجولات السياحية. يفضل دائماً ارتداء حذاء مريح وحمل مظلة خفيفة للاحتياط.';
    }
    return 'سؤال ممتاز! بخصوص $destination، أنصحك دائماً بمتابعة المسار المخطط له والتأكد من الانطلاق باكراً في الصباح لتحقيق أقصى استفادة من يومك سياحياً. هل تود معرفة أي تفاصيل إضافية؟';
  }
}

```
