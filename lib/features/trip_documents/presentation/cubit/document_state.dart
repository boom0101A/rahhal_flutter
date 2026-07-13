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

  const DocumentsLoaded({
    required this.documents,
    this.isActionLoading = false,
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

  @override
  List<Object?> get props => [documents, isActionLoading];
}

class DocumentsError extends DocumentsState {
  final String message;

  const DocumentsError(this.message);

  @override
  List<Object?> get props => [message];
}
