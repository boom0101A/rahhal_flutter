import 'package:dartz/dartz.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/document_entity.dart';
import '../../domain/repositories/document_repository.dart';
import '../mappers/document_mapper.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final DatabaseHelper _dbHelper;

  DocumentRepositoryImpl({required DatabaseHelper dbHelper})
      : _dbHelper = dbHelper;

  @override
  Future<Either<Failure, List<DocumentEntity>>> getDocuments(
      String tripId) async {
    try {
      final rows = await _dbHelper.query(
        'trip_documents',
        where: 'trip_id = ?',
        whereArgs: [tripId],
        orderBy: 'created_at DESC',
      );
      return Right(rows.map(DocumentMapper.fromMap).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addDocument(DocumentEntity doc) async {
    try {
      await _dbHelper.insert('trip_documents', DocumentMapper.toMap(doc));
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateDocument(DocumentEntity doc) async {
    try {
      await _dbHelper.update(
        'trip_documents',
        DocumentMapper.toMap(doc),
        where: 'id = ?',
        whereArgs: [doc.id],
      );
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDocument(String docId) async {
    try {
      await _dbHelper.delete(
        'trip_documents',
        where: 'id = ?',
        whereArgs: [docId],
      );
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
