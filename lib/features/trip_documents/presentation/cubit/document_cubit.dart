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
    if (isClosed) return;
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
    if (isClosed) return;
    result.fold(
      (failure) => _emitActionError(failure.message),
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
    if (isClosed) return;
    result.fold(
      (failure) => _emitActionError(failure.message),
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
    if (isClosed) return;
    result.fold(
      (failure) => _emitActionError(failure.message),
      (_) {
        final updatedDocs = current.documents.where((d) => d.id != docId).toList();
        emit(DocumentsLoaded(documents: updatedDocs, isActionLoading: false));
      },
    );
  }

  /// Keeps whatever's already on screen instead of replacing it with a
  /// full-screen error when add/update/delete fails — mirrors
  /// BudgetCubit._emitActionError. Only a failure during the initial
  /// loadDocuments() (nothing loaded yet to preserve) falls back to
  /// DocumentsError. Reads `state` fresh, not a captured `current` — by the
  /// time a fold callback runs, state has already moved to the
  /// isActionLoading:true snapshot taken at the start of the action.
  void _emitActionError(String message) {
    final current = state;
    emit(current is DocumentsLoaded
        ? current.withError(message)
        : DocumentsError(message));
  }

  /// Called by the UI right after it shows the action-error snackbar, so a
  /// later failure with the same message still triggers a fresh notice.
  void clearActionError() {
    final current = state;
    if (current is DocumentsLoaded && current.actionError != null) {
      emit(current.clearError());
    }
  }
}
