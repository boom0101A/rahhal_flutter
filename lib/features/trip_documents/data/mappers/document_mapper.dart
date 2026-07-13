import '../../domain/entities/document_entity.dart';

class DocumentMapper {
  static DocumentEntity fromMap(Map<String, dynamic> m) => DocumentEntity(
        id: m['id'] as String,
        tripId: m['trip_id'] as String,
        docType: m['doc_type'] as String,
        title: m['title'] as String,
        filePath: m['file_path'] as String?,
        fileUrl: m['file_url'] as String?,
        notes: m['notes'] as String?,
        expiryDate: m['expiry_date'] != null
            ? DateTime.tryParse(m['expiry_date'] as String)
            : null,
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  static Map<String, dynamic> toMap(DocumentEntity doc) => {
        'id': doc.id,
        'trip_id': doc.tripId,
        'doc_type': doc.docType,
        'title': doc.title,
        'file_path': doc.filePath,
        'file_url': doc.fileUrl,
        'notes': doc.notes,
        'expiry_date': doc.expiryDate?.toIso8601String(),
        'created_at': doc.createdAt.toIso8601String(),
      };
}
