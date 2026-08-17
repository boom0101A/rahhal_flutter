import 'package:flutter_test/flutter_test.dart';
import 'package:rahhal_flutter/features/hotels/domain/entities/hotel_entity.dart';
import 'package:rahhal_flutter/features/restaurants/domain/entities/restaurant_entity.dart';
import 'package:rahhal_flutter/features/trip_planner/domain/entities/stop_entity.dart';

/// Regression test for a silent "the translation ran but nothing changed" bug.
///
/// These entities are Equatable. Their `props` lists left the `*En` fields out,
/// so an entity that had just gained its English text compared EQUAL to its
/// pre-translation self — and a Cubit's `emit()` of an equal state is dropped
/// as a no-op. The database held the English text while the UI kept rendering
/// Arabic, with nothing anywhere reporting a problem.
void main() {
  test('a hotel differing only in its English fields is not equal', () {
    const arabicOnly = HotelEntity(
      id: 'h1', tripId: 't1', name: 'فندق', hotelType: 'فندق',
      rating: 4, pricePerNight: 100, address: 'شارع',
      latitude: 1, longitude: 1, aiDescription: 'وصف',
    );
    final translated = HotelEntity(
      id: arabicOnly.id, tripId: arabicOnly.tripId, name: arabicOnly.name,
      hotelType: arabicOnly.hotelType, hotelTypeEn: 'Hotel',
      rating: arabicOnly.rating, pricePerNight: arabicOnly.pricePerNight,
      address: arabicOnly.address, addressEn: 'Street',
      latitude: arabicOnly.latitude, longitude: arabicOnly.longitude,
      aiDescription: arabicOnly.aiDescription, aiDescriptionEn: 'Description',
    );

    expect(translated, isNot(equals(arabicOnly)));
  });

  test('a restaurant differing only in its English fields is not equal', () {
    const arabicOnly = RestaurantEntity(
      id: 'r1', tripId: 't1', name: 'مطعم', cuisineType: 'عراقي',
      halalCertified: true, rating: 4, pricePerPerson: 20, priceTier: 'mid',
      address: 'شارع', latitude: 1, longitude: 1, openingHours: 'الاثنين',
      aiDescription: 'وصف', isRecommended: false,
    );
    final translated = RestaurantEntity(
      id: arabicOnly.id, tripId: arabicOnly.tripId, name: arabicOnly.name,
      cuisineType: arabicOnly.cuisineType, cuisineTypeEn: 'Iraqi',
      halalCertified: arabicOnly.halalCertified, rating: arabicOnly.rating,
      pricePerPerson: arabicOnly.pricePerPerson, priceTier: arabicOnly.priceTier,
      address: arabicOnly.address, addressEn: 'Street',
      latitude: arabicOnly.latitude, longitude: arabicOnly.longitude,
      openingHours: arabicOnly.openingHours, openingHoursEn: 'Monday',
      aiDescription: arabicOnly.aiDescription, aiDescriptionEn: 'Description',
      isRecommended: arabicOnly.isRecommended,
    );

    expect(translated, isNot(equals(arabicOnly)));
  });

  test('a stop differing only in its English fields is not equal', () {
    const arabicOnly = StopEntity(
      id: 's1', dayId: 'd1', tripId: 't1', orderIndex: 0, name: 'محطة',
      category: 'museum', timeOfDay: 'morning', durationMinutes: 60,
      latitude: 1, longitude: 1, address: 'شارع', costUsd: 0,
      aiTip: 'نصيحة', bookingRequired: false,
    );
    final translated = StopEntity(
      id: arabicOnly.id, dayId: arabicOnly.dayId, tripId: arabicOnly.tripId,
      orderIndex: arabicOnly.orderIndex, name: arabicOnly.name,
      nameEn: 'Stop', category: arabicOnly.category,
      timeOfDay: arabicOnly.timeOfDay,
      durationMinutes: arabicOnly.durationMinutes,
      latitude: arabicOnly.latitude, longitude: arabicOnly.longitude,
      address: arabicOnly.address, addressEn: 'Street',
      costUsd: arabicOnly.costUsd, aiTip: arabicOnly.aiTip, aiTipEn: 'Tip',
      bookingRequired: arabicOnly.bookingRequired,
    );

    expect(translated, isNot(equals(arabicOnly)));
  });

  test('identical entities still compare equal', () {
    const a = StopEntity(
      id: 's1', dayId: 'd1', tripId: 't1', orderIndex: 0, name: 'محطة',
      category: 'museum', timeOfDay: 'morning', durationMinutes: 60,
      latitude: 1, longitude: 1, costUsd: 0, bookingRequired: false,
    );
    const b = StopEntity(
      id: 's1', dayId: 'd1', tripId: 't1', orderIndex: 0, name: 'محطة',
      category: 'museum', timeOfDay: 'morning', durationMinutes: 60,
      latitude: 1, longitude: 1, costUsd: 0, bookingRequired: false,
    );

    expect(a, equals(b));
  });
}
