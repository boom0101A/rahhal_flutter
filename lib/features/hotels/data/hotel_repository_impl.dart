import 'package:dartz/dartz.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/failures.dart';
import '../domain/entities/hotel_entity.dart';
import '../domain/repositories/hotel_repository.dart';

class HotelRepositoryImpl implements HotelRepository {
  final DatabaseHelper _dbHelper;

  HotelRepositoryImpl({required DatabaseHelper dbHelper}) : _dbHelper = dbHelper;

  @override
  Future<Either<Failure, List<HotelEntity>>> getHotelsForTrip(
      String tripId) async {
    try {
      final rows = await _dbHelper.query(
        'hotels',
        where: 'trip_id = ?',
        whereArgs: [tripId],
        orderBy: 'rating DESC',
      );
      return Right(rows.map(_fromMap).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  HotelEntity _fromMap(Map<String, dynamic> m) => HotelEntity(
        id: m['id'] as String,
        tripId: m['trip_id'] as String,
        name: m['name'] as String,
        nameEn: m['name_en'] as String?,
        hotelType: m['hotel_type'] as String?,
        rating: (m['rating'] as num? ?? 0).toDouble(),
        pricePerNight: (m['price_per_night'] as num? ?? 0).toDouble(),
        address: m['address'] as String?,
        latitude: (m['latitude'] as num? ?? 0).toDouble(),
        longitude: (m['longitude'] as num? ?? 0).toDouble(),
        phone: m['phone'] as String?,
        imageUrl: m['image_url'] as String?,
        aiDescription: m['ai_description'] as String?,
        bookingUrl: m['booking_url'] as String?,
        placeId: m['place_id'] as String?,
        coordsVerified: (m['coords_verified'] as int? ?? 0) == 1,
      );
}
