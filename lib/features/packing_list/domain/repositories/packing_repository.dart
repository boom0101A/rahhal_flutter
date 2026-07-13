import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/packing_item_entity.dart';

abstract class PackingRepository {
  Future<Either<Failure, List<PackingItemEntity>>> getPackingItems(String tripId);
  Future<Either<Failure, void>> addPackingItem(PackingItemEntity item);
  Future<Either<Failure, void>> updatePackingItem(PackingItemEntity item);
  Future<Either<Failure, void>> deletePackingItem(String itemId);
}
