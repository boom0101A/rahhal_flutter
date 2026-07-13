import 'package:equatable/equatable.dart';

class DocumentEntity extends Equatable {
  final String id;
  final String tripId;
  final String docType; // passport, visa, ticket, booking, other
  final String title;
  final String? filePath;
  final String? fileUrl;
  final String? notes;
  final DateTime? expiryDate;
  final DateTime createdAt;

  const DocumentEntity({
    required this.id,
    required this.tripId,
    required this.docType,
    required this.title,
    this.filePath,
    this.fileUrl,
    this.notes,
    this.expiryDate,
    required this.createdAt,
  });

  DocumentEntity copyWith({
    String? id,
    String? tripId,
    String? docType,
    String? title,
    String? filePath,
    String? fileUrl,
    String? notes,
    DateTime? expiryDate,
    DateTime? createdAt,
  }) {
    return DocumentEntity(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      docType: docType ?? this.docType,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      fileUrl: fileUrl ?? this.fileUrl,
      notes: notes ?? this.notes,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tripId,
        docType,
        title,
        filePath,
        fileUrl,
        notes,
        expiryDate,
        createdAt,
      ];
}
