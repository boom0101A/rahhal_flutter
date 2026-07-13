import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/document_entity.dart';
import '../../domain/repositories/document_repository.dart';
import 'document_state.dart';

class DocumentCubit extends Cubit<DocumentsState> {
  final DocumentRepository _repository;

  DocumentCubit({required DocumentRepository repository})
      : _repository = repository,
        super(DocumentsInitial());

  Future<void> loadDocuments(String tripId) async {
    emit(DocumentsLoading());
    final result = await _repository.getDocuments(tripId);
    result.fold(
      (failure) => emit(DocumentsError(failure.message)),
      (docs) => emit(DocumentsLoaded(documents: docs)),
    );
  }

  Future<void> addDocument(DocumentEntity doc) async {
    final current = state;
    List<DocumentEntity> currentDocs = [];
    if (current is DocumentsLoaded) {
      currentDocs = current.documents;
      emit(current.copyWith(isActionLoading: true));
    } else {
      emit(DocumentsLoading());
    }

    final result = await _repository.addDocument(doc);
    result.fold(
      (failure) => emit(DocumentsError(failure.message)),
      (_) {
        final updatedDocs = [doc, ...currentDocs];
        emit(DocumentsLoaded(documents: updatedDocs, isActionLoading: false));
      },
    );
  }

  Future<void> updateDocument(DocumentEntity doc) async {
    final current = state;
    if (current is! DocumentsLoaded) return;

    emit(current.copyWith(isActionLoading: true));

    final result = await _repository.updateDocument(doc);
    result.fold(
      (failure) => emit(DocumentsError(failure.message)),
      (_) {
        final updatedDocs = current.documents.map((d) => d.id == doc.id ? doc : d).toList();
        emit(DocumentsLoaded(documents: updatedDocs, isActionLoading: false));
      },
    );
  }

  Future<void> deleteDocument(String tripId, String docId) async {
    final current = state;
    if (current is! DocumentsLoaded) return;

    emit(current.copyWith(isActionLoading: true));

    final result = await _repository.deleteDocument(docId);
    result.fold(
      (failure) => emit(DocumentsError(failure.message)),
      (_) {
        final updatedDocs = current.documents.where((d) => d.id != docId).toList();
        emit(DocumentsLoaded(documents: updatedDocs, isActionLoading: false));
      },
    );
  }
}
