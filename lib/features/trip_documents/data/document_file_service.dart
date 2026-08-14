import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/crash_reporter.dart';

/// Thrown by [DocumentFileService.pickAndSave] when the OS denied camera or
/// gallery access — distinct from the user simply cancelling the picker.
class DocumentImagePermissionDeniedException implements Exception {}

/// Storage for the photos attached to trip documents (passport, visa, tickets).
///
/// The screen used to persist `XFile.path` straight from the picker. That path
/// is in the OS cache directory, which the system is free to purge at any
/// time and which "clear cache" wipes outright — so a passport photo could
/// disappear on its own and leave a broken-image placeholder behind. Everything
/// here exists to make the bytes live somewhere the app owns.
///
/// Modelled on [LocalAvatarService], which already had this right. Two
/// deliberate differences: a fresh UUID name per pick instead of one fixed
/// filename (a trip has many documents), and a much larger size cap, because a
/// passport page has to stay readable where a 640px avatar doesn't.
///
/// Delete helpers are static so the repositories can call them without taking
/// a new constructor dependency.
///
/// When receipt photos land (`actual_expenses.receipt_image_path` is already in
/// the schema but nothing writes it yet), they should route through here too
/// rather than repeating the original mistake.
class DocumentFileService {
  static const _folder = 'trip_documents';
  static const _uuid = Uuid();

  final ImagePicker _picker;

  DocumentFileService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  /// Opens the picker and copies the chosen image into app-private storage.
  ///
  /// Returns the saved path, or null if the user cancelled; throws
  /// [DocumentImagePermissionDeniedException] if the OS denied access.
  Future<String?> pickAndSave(ImageSource source) async {
    final XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        // Big enough that the small print on a visa stays legible.
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 85,
      );
    } on PlatformException catch (e) {
      if (e.code == 'camera_access_denied' || e.code == 'photo_access_denied') {
        throw DocumentImagePermissionDeniedException();
      }
      debugPrint('[DocumentFile] pickImage failed: ${e.code} ${e.message}');
      return null;
    }
    if (picked == null) return null;

    try {
      final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/$_folder');
      if (!await dir.exists()) await dir.create(recursive: true);

      final dest = '${dir.path}/${_uuid.v4()}${extensionOf(picked.path)}';
      final saved = await File(picked.path).copy(dest);
      return saved.path;
    } catch (e) {
      debugPrint('[DocumentFile] pickAndSave failed: $e');
      return null;
    }
  }

  /// The extension to give the copy, taken from the picked file.
  ///
  /// Kept as a pure function so the fallback is testable without a device: a
  /// picker can hand back a path with no extension at all, and an image file
  /// with no suffix confuses both the OS and `Image.file`'s decoder.
  @visibleForTesting
  static String extensionOf(String sourcePath) {
    final slash = sourcePath.lastIndexOf(RegExp(r'[/\\]'));
    final name = slash >= 0 ? sourcePath.substring(slash + 1) : sourcePath;
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) return '.jpg';
    final ext = name.substring(dot);
    // A "." in the middle of a name isn't necessarily an extension; anything
    // implausibly long is treated as part of the name.
    return ext.length <= 6 ? ext.toLowerCase() : '.jpg';
  }

  /// Deletes one stored image. Silent on a path that's already gone — every
  /// caller is a cleanup path where failing loudly would be worse.
  static Future<void> deleteFile(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('[DocumentFile] delete failed for $path: $e');
    }
  }

  static Future<void> deleteFiles(Iterable<String?> paths) async {
    for (final p in paths) {
      await deleteFile(p);
    }
  }

  /// Wipes every stored document image — for account deletion.
  ///
  /// Scoped to the `trip_documents` subfolder on purpose: the app documents
  /// directory itself also holds `profile_avatar.jpg` and anything else future
  /// features put there.
  static Future<void> deleteAll() async {
    try {
      final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/$_folder');
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (e, st) {
      debugPrint('[DocumentFile] deleteAll failed: $e');
      reportNonFatal(e, st, reason: 'DocumentFileService.deleteAll failed');
    }
  }
}
