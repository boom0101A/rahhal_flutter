import 'package:flutter_test/flutter_test.dart';
import 'package:rahhal_flutter/core/network/cloud_sync_service.dart';
import 'package:rahhal_flutter/features/trip_documents/data/document_file_service.dart';

/// Regression test for "my favourites disappear every time I reopen the app".
///
/// Restoring a trip from the cloud re-inserts its row with
/// ConflictAlgorithm.replace, which SQLite implements as delete-then-insert.
/// `favorites.trip_id` cascades on delete, and favourites were in no part of
/// the sync payload — so every restore silently wiped them, and a restore runs
/// on every launch for a signed-in user.
///
/// The merge below is what survives that. It is a static function precisely so
/// the rule can be proven here without a database or Firebase.
void main() {
  Map<String, dynamic> fav(String id, {String? tripId, String? notes}) => {
        'id': id,
        'trip_id': tripId ?? 'trip-1',
        'item_type': 'stop',
        'item_ref_id': 'stop-$id',
        'notes': notes,
        'created_at': '2026-01-01T00:00:00.000',
      };

  List<String> idsOf(List<Map<String, dynamic>> rows) =>
      rows.map((r) => r['id'] as String).toList()..sort();

  group('mergeFavoritesForRestore', () {
    test('a cloud document written before favourites synced keeps all of them',
        () {
      // The legacy case, and the one that matters most: no `favorites` key at
      // all. Treating that as "the cloud says there are none" would delete
      // every favourite — the same bug, just moved.
      final merged = CloudSyncService.mergeFavoritesForRestore(
        [fav('a'), fav('b')],
        null,
        'trip-1',
      );
      expect(idsOf(merged), ['a', 'b']);
    });

    test('an empty cloud array also preserves local', () {
      final merged = CloudSyncService.mergeFavoritesForRestore(
        [fav('a')],
        const <dynamic>[],
        'trip-1',
      );
      expect(idsOf(merged), ['a']);
    });

    test('disjoint rows are unioned', () {
      final merged = CloudSyncService.mergeFavoritesForRestore(
        [fav('local')],
        [fav('cloud')],
        'trip-1',
      );
      expect(idsOf(merged), ['cloud', 'local']);
    });

    test('the cloud wins a collision on id', () {
      final merged = CloudSyncService.mergeFavoritesForRestore(
        [fav('a', notes: 'local note')],
        [fav('a', notes: 'cloud note')],
        'trip-1',
      );
      expect(merged, hasLength(1));
      expect(merged.single['notes'], 'cloud note');
    });

    test('a mismatched trip_id from the cloud is forced, not trusted', () {
      // A wrong trip_id fails the foreign key, and that abort takes down the
      // restore of the entire trip — not just this row.
      final merged = CloudSyncService.mergeFavoritesForRestore(
        const [],
        [fav('a', tripId: 'some-other-trip')],
        'trip-1',
      );
      expect(merged.single['trip_id'], 'trip-1');
    });

    test('malformed cloud entries are skipped rather than thrown on', () {
      final merged = CloudSyncService.mergeFavoritesForRestore(
        [fav('keep')],
        ['not a map', 42, null, {'no': 'id'}, {'id': ''}, fav('ok')],
        'trip-1',
      );
      expect(idsOf(merged), ['keep', 'ok']);
    });

    test('a local row is never dropped', () {
      // The deliberate trade: un-favouriting doesn't propagate across devices.
      // A stale heart is recoverable; a deleted row is not.
      final merged = CloudSyncService.mergeFavoritesForRestore(
        [fav('only-local')],
        [fav('only-cloud')],
        'trip-1',
      );
      expect(idsOf(merged), contains('only-local'));
    });
  });

  group('DocumentFileService.extensionOf', () {
    test('keeps a real extension, lowercased', () {
      expect(DocumentFileService.extensionOf('/cache/scan.PNG'), '.png');
      expect(DocumentFileService.extensionOf(r'C:\tmp\a.jpeg'), '.jpeg');
    });

    test('falls back to .jpg when there is nothing usable', () {
      // A picker can hand back a path with no extension, and an image file
      // with no suffix confuses the OS and the decoder alike.
      expect(DocumentFileService.extensionOf('/cache/image_1234'), '.jpg');
      expect(DocumentFileService.extensionOf('/cache/trailing.'), '.jpg');
      expect(DocumentFileService.extensionOf('.hidden'), '.jpg');
    });

    test('a dot inside the name is not treated as an extension', () {
      expect(
        DocumentFileService.extensionOf('/cache/scan.2026-08-06-backup'),
        '.jpg',
      );
    });
  });
}
