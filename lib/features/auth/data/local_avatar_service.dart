import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A locally-stored profile picture.
///
/// There's no Firebase Storage in this project, so a picked photo can't be
/// uploaded to a URL Firebase Auth's `updatePhotoURL` would accept. Storing it
/// as a plain file on-device sidesteps that entirely: no new dependency (which
/// would need a full native rebuild and break Shorebird's OTA patching — a
/// picked-photo feature isn't worth losing that for), and the picture still
/// shows correctly, it just doesn't sync to other devices.
///
/// Display priority everywhere the avatar is shown: local file > Google's
/// `photoUrl` > initials.
class LocalAvatarService {
  static const _pathKey = 'local_avatar_path';

  /// Bumped on every successful change so [UserAvatar] instances elsewhere on
  /// screen (Profile header, Settings) refresh without needing a shared state
  /// management setup for something this small.
  static final ValueNotifier<int> version = ValueNotifier(0);

  final ImagePicker _picker;

  LocalAvatarService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  /// The saved avatar file, or null if none was ever set or it's gone missing
  /// from disk (e.g. cache was cleared).
  Future<File?> currentAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_pathKey);
    if (path == null) return null;
    final file = File(path);
    return await file.exists() ? file : null;
  }

  /// Opens the picker, copies the chosen image into app-private storage, and
  /// remembers its path. Returns null if the user cancelled.
  Future<File?> pickAndSave(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 640,
        maxHeight: 640,
        imageQuality: 85,
      );
      if (picked == null) return null;

      final dir = await getApplicationDocumentsDirectory();
      final destPath = '${dir.path}/profile_avatar.jpg';

      // Delete-then-copy rather than overwrite in place: some platforms cache
      // a FileImage by path, so reusing the exact path with new bytes can
      // still show the old picture until the app restarts. A stale old file
      // wastes a few KB at worst; a fresh path forces a real cache miss.
      final oldFile = File(destPath);
      if (await oldFile.exists()) await oldFile.delete();

      final saved = await File(picked.path).copy(destPath);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pathKey, saved.path);
      version.value++;
      return saved;
    } catch (e) {
      debugPrint('[LocalAvatar] pickAndSave failed: $e');
      return null;
    }
  }

  /// Removes the local photo so the avatar falls back to the Google photo (or
  /// initials).
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_pathKey);
    if (path != null) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (e) {
        debugPrint('[LocalAvatar] clear failed: $e');
      }
    }
    await prefs.remove(_pathKey);
    version.value++;
  }
}
