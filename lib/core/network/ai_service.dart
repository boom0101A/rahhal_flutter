import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dio_client.dart';
import '../config/app_config.dart';
import '../errors/exceptions.dart';

/// Response model for a complete AI-generated trip plan.
class TripPlanResponse {
  final String destination;
  final String? destinationEn;
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
  final bool isMockData;

  const TripPlanResponse({
    required this.destination,
    this.destinationEn,
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
    this.isMockData = false,
  });

  factory TripPlanResponse.fromJson(Map<String, dynamic> json) {
    return TripPlanResponse(
      destination: json['destination'] as String? ?? '',
      destinationEn: json['destination_en'] as String?,
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
  final String? imageSearchQuery;
  final String? placeId;
  final bool coordsVerified;

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
    this.imageSearchQuery,
    this.placeId,
    this.coordsVerified = false,
  });

  factory StopResponse.fromJson(Map<String, dynamic> json) {
    final String addressCandidate = json['google_address'] as String? ?? json['address'] as String? ?? '';
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
      address: addressCandidate,
      costUsd: (json['cost_usd'] as num? ?? 0).toDouble(),
      aiTip: json['ai_tip'] as String? ?? '',
      bookingRequired: json['booking_required'] as bool? ?? false,
      bookingUrl: json['booking_url'] as String?,
      imageSearchQuery: json['image_search_query'] as String?,
      placeId: json['place_id'] as String?,
      coordsVerified: json['coords_verified'] as bool? ?? false,
    );
  }
}

class RestaurantResponse {
  final String name;
  final String? nameEn;
  final String cuisineType;
  final bool halalCertified;
  final double rating;
  final double pricePerPersonUsd;
  final String address;
  final double latitude;
  final double longitude;
  final String aiDescription;
  final String? imageSearchQuery;

  const RestaurantResponse({
    required this.name,
    this.nameEn,
    required this.cuisineType,
    required this.halalCertified,
    required this.rating,
    required this.pricePerPersonUsd,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.aiDescription,
    this.imageSearchQuery,
  });

  factory RestaurantResponse.fromJson(Map<String, dynamic> json) {
    return RestaurantResponse(
      name: json['name'] as String? ?? '',
      nameEn: json['name_en'] as String?,
      cuisineType: json['cuisine_type'] as String? ?? '',
      halalCertified: json['halal_certified'] as bool? ?? false,
      rating: (json['rating'] as num? ?? 0).toDouble(),
      pricePerPersonUsd: (json['price_per_person_usd'] as num? ?? 0).toDouble(),
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num? ?? 0).toDouble(),
      longitude: (json['longitude'] as num? ?? 0).toDouble(),
      aiDescription: json['ai_description'] as String? ?? '',
      imageSearchQuery: json['image_search_query'] as String?,
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

  // ─── Error classifier ────────────────────────────────────────────────────────

  /// Converts any caught error into a user-friendly [AIException] message.
  AIException _classifyError(Object e) {
    if (e is DioException) {
      final inner = e.error;
      if (inner is AIException) return inner;
      if (inner is NetworkException) {
        return AIException(
          message: AppConfig.kServerMayNeedWarmup
              ? 'server-warmup-timeout'
              : 'network-exception',
        );
      }
      final code = e.response?.statusCode ?? 0;
      if (code == 401 || code == 403) {
        return AIException(message: 'invalid-api-key', statusCode: code);
      }
      if (code == 429) {
        return AIException(message: 'rate-limit', statusCode: code);
      }
      if (code >= 500) {
        return AIException(message: 'server-error-$code', statusCode: code);
      }
    }
    return AIException(message: e.toString());
  }

  // ─── Server Warmup ──────────────────────────────────────────────────────────

  /// Sends a lightweight GET /health to wake up the server if it's sleeping.
  /// Returns true if server is awake, false if it couldn't be reached.
  /// This is called BEFORE the actual trip generation to avoid timeout on the
  /// heavy AI endpoint.
  Future<bool> warmupServer() async {
    try {
      final response = await _dio.get(
        '/health',
        options: Options(
          // Give the server up to 90s to wake up from cold start
          receiveTimeout: const Duration(seconds: 90),
        ),
      );
      debugPrint('[AITravelService] Server warmup OK: ${response.statusCode}');
      return true;
    } catch (e) {
      debugPrint('[AITravelService] Server warmup failed: $e');
      return false;
    }
  }

  /// Checks /api/status to confirm the server is up AND has a valid AI key configured.
  /// Returns true only when ai_ready=true — meaning Claude or Gemini key is present.
  Future<bool> checkServerReady() async {
    try {
      final response = await _dio.get(
        '/api/status',
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      final data = response.data as Map<String, dynamic>;
      final aiReady = data['ai_ready'] as bool? ?? false;
      final engine = data['ai_engine'] as String? ?? 'none';
      debugPrint('[AITravelService] Server status: ai_ready=$aiReady, engine=$engine');
      if (!aiReady) {
        debugPrint('[AITravelService] Server up but no AI key configured!');
      }
      return aiReady;
    } catch (e) {
      debugPrint('[AITravelService] Server status check failed: $e');
      return false;
    }
  }

  // ─── Public API ─────────────────────────────────────────────────────────────

  /// Generates a complete trip plan using Claude AI.
  Future<TripPlanResponse> generateTripPlan({
    required String destination,
    required int durationDays,
    required String budgetTier,
    required List<String> travelStyles,
    required int travelersCount,
    DateTime? startDate,
    double? userLat,
    double? userLng,
    String? countryCode,
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
          'userLat': userLat,
          'userLng': userLng,
          'countryCode': countryCode,
        },
      );

      final jsonMap = response.data as Map<String, dynamic>;
      return TripPlanResponse.fromJson(jsonMap);
    } catch (e) {
      final classified = _classifyError(e);
      debugPrint('[AITravelService] generateTripPlan failed: ${classified.message}');

      // When mock fallback is enabled, use smart city data for ANY error.
      // This guarantees the app always works — even without a valid API key.
      // When a real Gemini key is configured later, real AI kicks in automatically.
      if (AppConfig.kUseMockFallback) {
        debugPrint('[AITravelService] Activating smart city fallback for: ${classified.message}');
        try {
          return _generateMockTripResponse(
              destination, durationDays, budgetTier, travelersCount);
        } catch (mockErr) {
          debugPrint('[AITravelService] Mock also failed: $mockErr');
          throw classified;
        }
      }

      throw classified;
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
      final classified = _classifyError(e);
      debugPrint('[AITravelService] chatWithAssistant failed: $classified');

      try {
        return _generateMockChatReply(destination, userMessage);
      } catch (_) {
        throw classified;
      }
    }
  }

  // ─── Destination-Aware City Knowledge Mock Database ──────────────────────────

  static const Map<String, _CityMockData> _cityDatabase = {
    // Turkey - إسطنبول
    'إسطنبول': _CityMockData(
      lat: 41.0082, lng: 28.9784, countryCode: 'TR', currency: 'TRY',
      landmarks: [
        _MockPlace('آيا صوفيا', 'Hagia Sophia', 41.0086, 28.9802, 'landmark'),
        _MockPlace('قصر توبقابي', 'Topkapi Palace', 41.0115, 28.9833, 'palace'),
        _MockPlace('المسجد الأزرق', 'Blue Mosque', 41.0054, 28.9768, 'mosque'),
        _MockPlace('البازار الكبير', 'Grand Bazaar', 41.0108, 28.9681, 'market'),
        _MockPlace('برج غلطة', 'Galata Tower', 41.0256, 28.9740, 'landmark'),
        _MockPlace('متحف إسطنبول للفنون الحديثة', 'Istanbul Modern Museum', 41.0280, 28.9814, 'museum'),
        _MockPlace('شارع الاستقلال', 'Istiklal Avenue', 41.0335, 28.9770, 'shopping'),
        _MockPlace('جسر البوسفور', 'Bosphorus Bridge', 41.0462, 29.0337, 'viewpoint'),
      ],
      restaurants: [
        _MockRestaurant('مطعم النار والبحر', 'Nar ve Deniz', 'مأكولات تركية أصيلة', 41.0220, 28.9756),
        _MockRestaurant('مطعم بوتيك الكباب', 'Kebapçı Boutique', 'كباب تركي', 41.0105, 28.9680),
        _MockRestaurant('مقهى بييرلوتي', 'Pierre Loti Café', 'مشروبات وحلويات', 41.0398, 28.9394),
      ],
    ),
    'istanbul': _CityMockData(
      lat: 41.0082, lng: 28.9784, countryCode: 'TR', currency: 'TRY',
      landmarks: [
        _MockPlace('آيا صوفيا', 'Hagia Sophia', 41.0086, 28.9802, 'landmark'),
        _MockPlace('قصر توبقابي', 'Topkapi Palace', 41.0115, 28.9833, 'palace'),
        _MockPlace('المسجد الأزرق', 'Blue Mosque', 41.0054, 28.9768, 'mosque'),
        _MockPlace('البازار الكبير', 'Grand Bazaar', 41.0108, 28.9681, 'market'),
        _MockPlace('برج غلطة', 'Galata Tower', 41.0256, 28.9740, 'landmark'),
        _MockPlace('متحف إسطنبول للفنون الحديثة', 'Istanbul Modern Museum', 41.0280, 28.9814, 'museum'),
        _MockPlace('شارع الاستقلال', 'Istiklal Avenue', 41.0335, 28.9770, 'shopping'),
        _MockPlace('جسر البوسفور', 'Bosphorus Bridge', 41.0462, 29.0337, 'viewpoint'),
      ],
      restaurants: [
        _MockRestaurant('مطعم النار والبحر', 'Nar ve Deniz', 'مأكولات تركية أصيلة', 41.0220, 28.9756),
        _MockRestaurant('مطعم بوتيك الكباب', 'Kebapçı Boutique', 'كباب تركي', 41.0105, 28.9680),
        _MockRestaurant('مقهى بييرلوتي', 'Pierre Loti Café', 'مشروبات وحلويات', 41.0398, 28.9394),
      ],
    ),

    // Egypt - القاهرة
    'القاهرة': _CityMockData(
      lat: 30.0444, lng: 31.2357, countryCode: 'EG', currency: 'EGP',
      landmarks: [
        _MockPlace('المتحف المصري بالتحرير', 'Egyptian Museum', 30.0478, 31.2336, 'museum'),
        _MockPlace('أهرامات الجيزة والأبو الهول', 'Giza Pyramids', 29.9792, 31.1342, 'landmark'),
        _MockPlace('قلعة صلاح الدين الأيوبي', 'Cairo Citadel', 30.0290, 31.2597, 'palace'),
        _MockPlace('خان الخليلي', 'Khan el-Khalili', 30.0477, 31.2627, 'market'),
        _MockPlace('جامع محمد علي', 'Mohamed Ali Mosque', 30.0285, 31.2599, 'mosque'),
        _MockPlace('متحف الحضارة المصرية', 'NMEC Museum', 30.0076, 31.2483, 'museum'),
        _MockPlace('برج القاهرة', 'Cairo Tower', 30.0459, 31.2243, 'viewpoint'),
      ],
      restaurants: [
        _MockRestaurant('كشري أبو طارق', 'Koshary Abou Tarek', 'مأكولات شعبية مصرية', 30.0501, 31.2384),
        _MockRestaurant('مطعم الفيشاوي', 'El Fishawy Cafe', 'قهوة ومأكولات شرقية', 30.0478, 31.2628),
        _MockRestaurant('مطعم صبحي كابر', 'Sobhy Kaber', 'مشويات ومقادم', 30.0768, 31.2461),
      ],
    ),
    'cairo': _CityMockData(
      lat: 30.0444, lng: 31.2357, countryCode: 'EG', currency: 'EGP',
      landmarks: [
        _MockPlace('المتحف المصري بالتحرير', 'Egyptian Museum', 30.0478, 31.2336, 'museum'),
        _MockPlace('أهرامات الجيزة والأبو الهول', 'Giza Pyramids', 29.9792, 31.1342, 'landmark'),
        _MockPlace('قلعة صلاح الدين الأيوبي', 'Cairo Citadel', 30.0290, 31.2597, 'palace'),
        _MockPlace('خان الخليلي', 'Khan el-Khalili', 30.0477, 31.2627, 'market'),
        _MockPlace('جامع محمد علي', 'Mohamed Ali Mosque', 30.0285, 31.2599, 'mosque'),
      ],
      restaurants: [
        _MockRestaurant('كشري أبو طارق', 'Koshary Abou Tarek', 'مأكولات شعبية مصرية', 30.0501, 31.2384),
      ],
    ),

    // UAE - دبي
    'دبي': _CityMockData(
      lat: 25.2048, lng: 55.2708, countryCode: 'AE', currency: 'AED',
      landmarks: [
        _MockPlace('برج خليفة', 'Burj Khalifa', 25.1972, 55.2744, 'landmark'),
        _MockPlace('دبي مول والنوافير', 'Dubai Mall & Fountains', 25.1978, 55.2796, 'shopping'),
        _MockPlace('الخور والتكسي البحري', 'Dubai Creek & Abra', 25.2632, 55.3076, 'viewpoint'),
        _MockPlace('سوق الذهب بالتوابل', 'Gold & Spice Souk', 25.2680, 55.3027, 'market'),
        _MockPlace('متحف المستقبل', 'Museum of the Future', 25.2197, 55.2828, 'museum'),
        _MockPlace('شاطئ جميرا', 'Jumeirah Beach', 25.2084, 55.2425, 'beach'),
        _MockPlace('برج العرب', 'Burj Al Arab', 25.1412, 55.1852, 'landmark'),
      ],
      restaurants: [
        _MockRestaurant('مطعم النافورة', 'Al Nafoorah', 'مطبخ لبناني فاخر', 25.2048, 55.2708),
        _MockRestaurant('مطعم أتموسفير', 'At.mosphere Burj Khalifa', 'مطبخ عالمي', 25.1972, 55.2744),
      ],
    ),
    'dubai': _CityMockData(
      lat: 25.2048, lng: 55.2708, countryCode: 'AE', currency: 'AED',
      landmarks: [
        _MockPlace('برج خليفة', 'Burj Khalifa', 25.1972, 55.2744, 'landmark'),
        _MockPlace('دبي مول والنوافير', 'Dubai Mall & Fountains', 25.1978, 55.2796, 'shopping'),
        _MockPlace('متحف المستقبل', 'Museum of the Future', 25.2197, 55.2828, 'museum'),
      ],
      restaurants: [
        _MockRestaurant('مطعم النافورة', 'Al Nafoorah', 'مطبخ لبناني فاخر', 25.2048, 55.2708),
      ],
    ),

    // France - باريس
    'باريس': _CityMockData(
      lat: 48.8566, lng: 2.3522, countryCode: 'FR', currency: 'EUR',
      landmarks: [
        _MockPlace('برج إيفل', 'Eiffel Tower', 48.8584, 2.2945, 'landmark'),
        _MockPlace('متحف اللوفر', 'Louvre Museum', 48.8606, 2.3376, 'museum'),
        _MockPlace('كاتدرائية نوتردام', 'Notre-Dame Cathedral', 48.8530, 2.3499, 'landmark'),
        _MockPlace('شارع الشانزيليزيه', 'Champs-Élysées', 48.8698, 2.3078, 'shopping'),
        _MockPlace('متحف أورسيه', "Musée d'Orsay", 48.8600, 2.3266, 'museum'),
        _MockPlace('قوس النصر', 'Arc de Triomphe', 48.8738, 2.2950, 'landmark'),
        _MockPlace('مونمارتر وكنيسة ساكريه كور', 'Montmartre & Sacré-Cœur', 48.8867, 2.3431, 'viewpoint'),
      ],
      restaurants: [
        _MockRestaurant('مطعم لو بروكوب', 'Le Procope', 'مطبخ فرنسي كلاسيكي', 48.8524, 2.3399),
        _MockRestaurant('مطعم بيسترو لو مارايس', 'Le Marais Bistro', 'بيسترو فرنسي', 48.8567, 2.3601),
      ],
    ),
    'paris': _CityMockData(
      lat: 48.8566, lng: 2.3522, countryCode: 'FR', currency: 'EUR',
      landmarks: [
        _MockPlace('برج إيفل', 'Eiffel Tower', 48.8584, 2.2945, 'landmark'),
        _MockPlace('متحف اللوفر', 'Louvre Museum', 48.8606, 2.3376, 'museum'),
        _MockPlace('قوس النصر', 'Arc de Triomphe', 48.8738, 2.2950, 'landmark'),
      ],
      restaurants: [
        _MockRestaurant('مطعم لو بروكوب', 'Le Procope', 'مطبخ فرنسي كلاسيكي', 48.8524, 2.3399),
      ],
    ),

    // Saudi Arabia - الرياض / جدة / مكة / المدينة
    'الرياض': _CityMockData(
      lat: 24.7136, lng: 46.6753, countryCode: 'SA', currency: 'SAR',
      landmarks: [
        _MockPlace('برج المملكة وجسر المشاهدة', 'Kingdom Centre Tower', 24.7115, 46.6744, 'viewpoint'),
        _MockPlace('حي الدرعية التاريخي', 'Historic Diriyah', 24.7340, 46.5772, 'landmark'),
        _MockPlace('قصر المربع والمتحف الوطني', 'National Museum & Murabba Palace', 24.6473, 46.7112, 'museum'),
        _MockPlace('بوليفارد رياض سيتي', 'Boulevard Riyadh City', 24.7667, 46.5983, 'shopping'),
      ],
      restaurants: [
        _MockRestaurant('مطعم القرية النجودية', 'Najd Village', 'مأكولات سعودية نجودية', 24.7088, 46.6800),
        _MockRestaurant('مطعم التمية والفرن', 'Al-Mamoora', 'مشويات ومقبلات', 24.7136, 46.6753),
      ],
    ),
    'جدة': _CityMockData(
      lat: 21.5433, lng: 39.1728, countryCode: 'SA', currency: 'SAR',
      landmarks: [
        _MockPlace('البلد التاريخية وباب مكة', 'Al-Balad Historical Center', 21.4858, 39.1866, 'landmark'),
        _MockPlace('كورنيش جدة الواجهة البحرية', 'Jeddah Corniche Waterfront', 21.5833, 39.1083, 'viewpoint'),
        _MockPlace('نافورة الملك فهد', 'King Fahd Fountain', 21.5161, 39.1481, 'landmark'),
        _MockPlace('مسجد الرحمة العائم', 'Al Rahma Floating Mosque', 21.6508, 39.1042, 'mosque'),
      ],
      restaurants: [
        _MockRestaurant('مطعم السدة للمظبي', 'Al Saddah Restaurant', 'مندي ومظبي أصيل', 21.5433, 39.1728),
        _MockRestaurant('مطعم البيك', 'Al Baik', 'وجبات سريعة ومأكولات بحرية', 21.5000, 39.1667),
      ],
    ),
  };

  TripPlanResponse _generateMockTripResponse(
    String destination,
    int durationDays,
    String budgetTier,
    int travelersCount,
  ) {
    // Look up destination in database (case-insensitive & partial match)
    final destLower = destination.toLowerCase().trim();
    _CityMockData? cityData;

    for (final entry in _cityDatabase.entries) {
      if (destLower.contains(entry.key.toLowerCase()) ||
          entry.key.toLowerCase().contains(destLower)) {
        cityData = entry.value;
        break;
      }
    }

    final double baseLat = cityData?.lat ?? 24.7136;
    final double baseLng = cityData?.lng ?? 46.6753;
    final String countryCode = cityData?.countryCode ?? 'SA';
    final String currency = cityData?.currency ?? 'SAR';
    final landmarks = cityData?.landmarks ?? [
      _MockPlace('المعلم التاريخي الشهير في $destination', 'Historic Landmark in $destination', baseLat + 0.005, baseLng + 0.005, 'landmark'),
      _MockPlace('المتحف المركزي بـ $destination', 'Central Museum of $destination', baseLat - 0.003, baseLng + 0.008, 'museum'),
      _MockPlace('السوق القديم والمنتزه', 'Old Souk & Park', baseLat + 0.008, baseLng - 0.004, 'market'),
      _MockPlace('المطل البانورامي', 'Panoramic Overlook', baseLat - 0.006, baseLng - 0.005, 'viewpoint'),
    ];
    final restaurants = cityData?.restaurants ?? [
      _MockRestaurant('مطعم الأصالة بـ $destination', 'Authentic Dining', 'مأكولات محلية', baseLat + 0.002, baseLng + 0.003),
      _MockRestaurant('كافيه ومقهى $destination', 'Café & Pastry', 'حلويات ومشروبات', baseLat - 0.004, baseLng + 0.006),
    ];

    final double costPerDay = switch (budgetTier) {
      'economy' => 60,
      'mid' => 150,
      'luxury' => 450,
      _ => 150,
    };
    final double budgetTotal = costPerDay * durationDays * travelersCount;

    // Build days — ensuring no landmark is repeated across days
    final List<DayPlanResponse> mockDays = [];
    int landmarkIndex = 0;

    for (int day = 1; day <= durationDays; day++) {
      final List<StopResponse> mockStops = [];

      // Morning Attraction (Unique per day)
      if (landmarkIndex < landmarks.length) {
        final place = landmarks[landmarkIndex++];
        mockStops.add(StopResponse(
          orderIndex: 0,
          name: place.nameAr,
          nameEn: place.nameEn,
          category: place.category,
          timeOfDay: 'morning',
          startTime: '09:30',
          durationMinutes: 120,
          latitude: place.lat,
          longitude: place.lng,
          address: '$destination - ${place.nameAr}',
          costUsd: budgetTier == 'economy' ? 0.0 : 15.0,
          aiTip: 'ينصح بالوصول مبكراً للاستمتاع بالجولة وتجنب أوقات الذروة.',
          bookingRequired: place.category == 'museum',
          imageSearchQuery: '${place.nameEn} $destination',
        ));
      }

      // Afternoon / Evening Attraction (Unique per day)
      if (landmarkIndex < landmarks.length) {
        final place = landmarks[landmarkIndex++];
        mockStops.add(StopResponse(
          orderIndex: 1,
          name: place.nameAr,
          nameEn: place.nameEn,
          category: place.category,
          timeOfDay: 'afternoon',
          startTime: '14:30',
          durationMinutes: 90,
          latitude: place.lat,
          longitude: place.lng,
          address: '$destination - ${place.nameAr}',
          costUsd: 0.0,
          aiTip: 'مكان رائع لالتقاط الصور التذكارية والاسترخاء.',
          bookingRequired: false,
          imageSearchQuery: '${place.nameEn} $destination',
        ));
      }

      // Recommended restaurant for this day
      final restaurant = restaurants.isNotEmpty
          ? restaurants[(day - 1) % restaurants.length]
          : null;

      mockDays.add(DayPlanResponse(
        dayNumber: day,
        theme: _dayTheme(day),
        dateOffset: day - 1,
        summary: mockStops.isNotEmpty
            ? 'جولة متميزة تشمل زيارة ${mockStops.map((s) => s.name).join(" و ")}.'
            : 'يوم استكشاف وثقافة حرة بوسط مدينة $destination.',
        stops: mockStops,
        recommendedRestaurant: restaurant != null
            ? RestaurantResponse(
                name: restaurant.nameAr,
                nameEn: restaurant.nameEn,
                cuisineType: restaurant.cuisineType,
                halalCertified: true,
                rating: 4.6 + (day % 4) * 0.1,
                pricePerPersonUsd: budgetTier == 'economy' ? 12.0 : 30.0,
                address: '$destination - ${restaurant.nameAr}',
                latitude: restaurant.lat,
                longitude: restaurant.lng,
                aiDescription: 'مطعم شهير وموصى به يقدم أشهى الوجبات في $destination.',
                imageSearchQuery: '${restaurant.cuisineType} restaurant $destination food',
              )
            : null,
      ));
    }

    final mockAllRestaurants = restaurants.map((r) => RestaurantResponse(
      name: r.nameAr,
      nameEn: r.nameEn,
      cuisineType: r.cuisineType,
      halalCertified: true,
      rating: 4.8,
      pricePerPersonUsd: 25.0,
      address: destination,
      latitude: r.lat,
      longitude: r.lng,
      aiDescription: 'تجربة طعام ممتازة بـ $destination.',
      imageSearchQuery: '${r.cuisineType} food',
    )).toList();

    return TripPlanResponse(
      destination: destination,
      countryCode: countryCode,
      aiSummary:
          'خطة سياحية مخصصة ومفصلة لزيارة مدينة $destination واكتشاف أشهر معالمها الثقافية والترفيهية.',
      budgetTotalUsd: budgetTotal,
      heroImageQuery: '$destination travel landmark view',
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
        'احرص على استخدام وسائل النقل الرسمية وتأكيد حجز الفنادق المباشر.',
        'يفضل الاحتفاظ بمبالغ نقدية بسيطة من العملة المحلية ($currency).',
        'تأكد من تنزيل الخرائط دون اتصال بالإنترنت أثناء التنقل.'
      ],
      bestTimeToVisit: 'الربيع والخريف (الطقس معتدل ومناسب للرحلات)',
      currency: currency,
      timezone: 'UTC+3',
      isMockData: true,
    );
  }

  String _dayTheme(int day) {
    const themes = [
      'يوم المعالم التاريخية والتراثية',
      'يوم الثقافة والمتاحف الكبرى',
      'يوم الطبيعة والاسترخاء البانورامي',
      'يوم التسوق والأسواق القديمة والحديثة',
      'يوم الترفيه والجولات السياحية البحرية',
      'يوم استكشاف المطاعم والنكهات المحلية',
      'يوم المغامرة والجولات المفتوحة',
    ];
    return themes[(day - 1) % themes.length];
  }

  String _generateMockChatReply(String destination, String userMessage) {
    return _contextAwareFallback(destination, userMessage);
  }

  String _contextAwareFallback(String destination, String userMessage) {
    final msg = userMessage.trim();

    // Food & Restaurants
    if (RegExp(r'مطعم|أكل|طعام|غداء|عشاء|فطور|وجبة|حلال|مأكولات|طبق|مشويات|كافيه|حلويات').hasMatch(msg)) {
      return 'بخصوص الطعام في $destination، أنصحك بالبحث عن المطاعم المحلية في المناطق السياحية الرئيسية للمدينة. تأكد من التحقق من تقييمات Google Maps والبحث عن علامة "حلال" إذا كان ذلك مهماً لك. تبويب المطاعم في رحلتك يحتوي على توصياتنا المخصصة.';
    }

    // Transit & Transport
    if (RegExp(r'مواصلات|تاكسي|مترو|حافلة|أوبر|كريم|سيارة|وصول|كيف أصل|تأجير|طيران').hasMatch(msg)) {
      return 'للتنقل في $destination، يُنصح باستخدام تطبيقات النقل الذكي مثل Uber أو Careem لراحة أكبر. يمكنك أيضاً استخدام زر "احجز رحلة" في كل محطة من محطات رحلتك للوصول المباشر.';
    }

    // Weather & Clothing
    if (RegExp(r'طقس|جو|درجة حرارة|مطر|ملابس|برد|حر|شمس|فصل').hasMatch(msg)) {
      return 'للاطلاع على الطقس الحالي في $destination، يُنصح بمراجعة تطبيق الطقس المحلي أو شريط الطقس بـ التطبيق. احمل معك طبقات من الملابس للتكيف مع تغيرات الطقس اليومية.';
    }

    // Budget, Prices, Currency
    if (RegExp(r'سعر|تكلفة|ميزانية|غالي|رخيص|دولار|عملة|صرف|فلوس|مبلغ').hasMatch(msg)) {
      return 'تبويب "الميزانية" في تطبيقك يحتوي على التكاليف التقريبية المفصّلة لرحلتك إلى $destination. للصرف، ابحث عن أقرب محطة صرافة أو استخدم بطاقة ائتمانية دولية في معظم الأماكن السياحية.';
    }

    // Booking & Tickets & Timings
    if (RegExp(r'حجز|تذكرة|موعد|متوفر|مغلق|مفتوح|ساعات|دوام|تأشيرة|فيزا').hasMatch(msg)) {
      return 'للحجز المسبق في $destination، زر الموقع الرسمي لكل معلم سياحي. معظم المتاحف والمعالم الكبرى تتيح الحجز أونلاين بأسعار مخفضة. تجد روابط الحجز داخل تفاصيل كل محطة في جدول رحلتك.';
    }

    // Shopping & Souvenirs
    if (RegExp(r'تسوق|سوق|بازار|مشتريات|هدايا|تذكارات|مول|متاجر').hasMatch(msg)) {
      return 'للتسوق في $destination، ابحث عن الأسواق الشعبية التقليدية للحصول على أفضل الأسعار وأصالة التجربة. المساومة مقبولة في الأسواق التقليدية لكن ليس في المتاجر الحديثة.';
    }

    // Safety & Etiquette & Emergency
    if (RegExp(r'أمان|آمن|محظور|عادات|ثقافة|احترام|قانون|طوارئ|إرشادات').hasMatch(msg)) {
      return 'عند زيارة $destination، احترم العادات والتقاليد المحلية. تأكد من مراجعة سفارة بلدك للاطلاع على أحدث التحذيرات السفرية. في حالة الطوارئ اتصل برقم الطوارئ المحلي.';
    }

    // Smart default
    return 'بخصوص سؤالك عن $destination: أنصحك بالبحث عن هذا الموضوع تحديداً على موقع TripAdvisor أو Lonely Planet للحصول على معلومات دقيقة ومحدّثة. هل تريد معرفة تفاصيل أخرى عن رحلتك؟';
  }

}

// ─── Data Classes for City Knowledge Base ─────────────────────────────────────

class _CityMockData {
  final double lat;
  final double lng;
  final String countryCode;
  final String currency;
  final List<_MockPlace> landmarks;
  final List<_MockRestaurant> restaurants;

  const _CityMockData({
    required this.lat,
    required this.lng,
    required this.countryCode,
    required this.currency,
    required this.landmarks,
    required this.restaurants,
  });
}

class _MockPlace {
  final String nameAr;
  final String nameEn;
  final double lat;
  final double lng;
  final String category;

  const _MockPlace(
    this.nameAr,
    this.nameEn,
    this.lat,
    this.lng,
    this.category,
  );
}

class _MockRestaurant {
  final String nameAr;
  final String nameEn;
  final String cuisineType;
  final double lat;
  final double lng;

  const _MockRestaurant(
    this.nameAr,
    this.nameEn,
    this.cuisineType,
    this.lat,
    this.lng,
  );
}
