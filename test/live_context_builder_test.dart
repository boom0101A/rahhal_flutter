import 'package:flutter_test/flutter_test.dart';
import 'package:rahhal_flutter/features/ai_chat/domain/live_context_builder.dart';
import 'package:rahhal_flutter/core/network/weather_service.dart';
import 'package:rahhal_flutter/features/nearby/data/nearby_service.dart';

void main() {
  group('buildLiveContextSummary', () {
    test('returns an empty string when every data source is missing', () {
      final result = buildLiveContextSummary(lang: 'ar');
      expect(result, isEmpty);
    });

    test('a missing weather does not drop the nearby-places section', () {
      final result = buildLiveContextSummary(
        lang: 'ar',
        weather: null,
        nearbyPlaces: const [
          NearbyPlace(
            id: 'p1',
            name: 'مطعم الرشيد',
            nameEn: 'Al Rasheed',
            lat: 33.3,
            lng: 44.4,
            type: 'restaurant',
            distanceMeters: 200,
          ),
        ],
      );
      expect(result, contains('مطعم الرشيد'));
    });

    test('a missing nearby-places list does not drop the weather section', () {
      final result = buildLiveContextSummary(
        lang: 'en',
        weather: const WeatherData(
          temp: 30,
          feelsLike: 33,
          description: 'clear sky',
          icon: '01d',
          humidity: 20,
          windSpeed: 5,
          cityName: 'Baghdad',
        ),
      );
      expect(result, contains('Baghdad'));
      expect(result, contains('30'));
    });

    test('no day matches today: the open-stops section is simply absent', () {
      final result = buildLiveContextSummary(
        lang: 'ar',
        openStopsClosingTimes: const {},
        weather: const WeatherData(
          temp: 25,
          feelsLike: 25,
          description: 'sunny',
          icon: '01d',
          humidity: 10,
          windSpeed: 2,
          cityName: 'Erbil',
        ),
      );
      expect(result, isNot(contains('تغلق')));
    });

    test('formats all three sections together in Arabic', () {
      final result = buildLiveContextSummary(
        lang: 'ar',
        weather: const WeatherData(
          temp: 28,
          feelsLike: 30,
          description: 'صافي',
          icon: '01d',
          humidity: 15,
          windSpeed: 3,
          cityName: 'بغداد',
        ),
        nearbyPlaces: const [
          NearbyPlace(
            id: 'p1',
            name: 'حديقة الزوراء',
            nameEn: 'Zawra Park',
            lat: 33.3,
            lng: 44.4,
            type: 'park',
            distanceMeters: 400,
          ),
        ],
        openStopsClosingTimes: {
          'متحف بغداد': DateTime(2026, 8, 16, 17, 0),
        },
      );

      expect(result, contains('بغداد'));
      expect(result, contains('حديقة الزوراء'));
      expect(result, contains('متحف بغداد'));
      expect(result, contains('5:00 م'));
    });

    test('respects the maxLength cap', () {
      final longName = 'م' * 3000;
      final result = buildLiveContextSummary(
        lang: 'ar',
        openStopsClosingTimes: {longName: DateTime(2026, 8, 16, 20, 0)},
        maxLength: 200,
      );
      expect(result.length, lessThanOrEqualTo(200));
    });
  });
}
