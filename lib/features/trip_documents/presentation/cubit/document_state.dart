import 'package:equatable/equatable.dart';
import '../../domain/entities/document_entity.dart';

abstract class DocumentsState extends Equatable {
  const DocumentsState();

  @override
  List<Object?> get props => [];
}

class DocumentsInitial extends DocumentsState {}

class DocumentsLoading extends DocumentsState {}

class DocumentsLoaded extends DocumentsState {
  final List<DocumentEntity> documents;
  final bool isActionLoading;

  /// Set when add/update/delete fails while the list is already on screen —
  /// a transient notice, not a reason to replace the loaded view with a
  /// full-screen error (that used to wipe every document the user could see
  /// over one failed action).
  final String? actionError;

  const DocumentsLoaded({
    required this.documents,
    this.isActionLoading = false,
    this.actionError,
  });

  DocumentsLoaded copyWith({
    List<DocumentEntity>? documents,
    bool? isActionLoading,
  }) {
    return DocumentsLoaded(
      documents: documents ?? this.documents,
      isActionLoading: isActionLoading ?? this.isActionLoading,
    );
  }

  DocumentsLoaded withError(String message) => DocumentsLoaded(
        documents: documents,
        isActionLoading: false,
        actionError: message,
      );

  DocumentsLoaded clearError() => DocumentsLoaded(
        documents: documents,
        isActionLoading: isActionLoading,
      );

  @override
  List<Object?> get props => [documents, isActionLoading, actionError];
}

class DocumentsError extends DocumentsState {
  final String message;

  const DocumentsError(this.message);

  @override
  List<Object?> get props => [message];
}
