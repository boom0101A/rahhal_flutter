import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/document_entity.dart';

abstract class DocumentRepository {
  Future<Either<Failure, List<DocumentEntity>>> getDocuments(String tripId);
  Future<Either<Failure, void>> addDocument(DocumentEntity doc);
  Future<Either<Failure, void>> updateDocument(DocumentEntity doc);
  Future<Either<Failure, void>> deleteDocument(String docId);
}
