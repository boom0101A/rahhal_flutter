import 'package:dartz/dartz.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/failures.dart';
import '../domain/entities/packing_item_entity.dart';
import '../domain/repositories/packing_repository.dart';
import 'mappers/packing_item_mapper.dart';

class PackingRepositoryImpl implements PackingRepository {
  final DatabaseHelper _dbHelper;

  PackingRepositoryImpl({required DatabaseHelper dbHelper})
      : _dbHelper = dbHelper;

  @override
  Future<Either<Failure, List<PackingItemEntity>>> getPackingItems(
      String tripId) async {
    try {
      final rows = await _dbHelper.query(
        'packing_items',
        where: 'trip_id = ?',
        whereArgs: [tripId],
      );
      return Right(rows.map(PackingItemMapper.fromMap).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addPackingItem(PackingItemEntity item) async {
    try {
      await _dbHelper.insert('packing_items', PackingItemMapper.toMap(item));
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updatePackingItem(
      PackingItemEntity item) async {
    try {
      await _dbHelper.update(
        'packing_items',
        PackingItemMapper.toMap(item),
        where: 'id = ?',
        whereArgs: [item.id],
      );
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePackingItem(String itemId) async {
    try {
      await _dbHelper.delete(
        'packing_items',
        where: 'id = ?',
        whereArgs: [itemId],
      );
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
