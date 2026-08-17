import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:rahhal_flutter/core/database/database_helper.dart';

/// Regression test for "English trip translation is permanently broken on
/// every fresh install."
///
/// `TripTranslationService` writes to nine `*_en` columns that were added by
/// migrations 14 and 15 — but a brand-new install never runs the migration
/// list at all (sqflite only calls `onUpgrade` when opening an EXISTING
/// database at a lower version; a fresh install goes straight through
/// `onCreate`). The `_create*Table` constants that `onCreate` uses had not
/// been kept in sync with those two migrations, so every column any
/// migration-14-or-15 user has was silently absent for anyone installing the
/// app for the first time — `db.update(..., {'ai_summary_en': ...})` throws
/// "no such column", caught by `ensureEnglish()`'s blanket catch, so the
/// English text just silently never appears, forever, with no error visible
/// anywhere.
///
/// This drives the REAL production code path — `DatabaseHelper.instance` via
/// the public `database` getter, exactly as the app does — rather than
/// re-implementing the schema separately, so it actually proves what ships.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('a brand-new database has every *_en column the translation service writes to',
      () async {
    // A fresh install has no existing file at all — delete first so onCreate
    // (not onUpgrade) is guaranteed to be the path exercised, matching a
    // real first launch.
    await DatabaseHelper.instance.close();
    final path = await databaseFactory.getDatabasesPath();
    await databaseFactory.deleteDatabase('$path/rahhal_ai.db');

    final db = await DatabaseHelper.instance.database;

    Future<List<String>> columnsOf(String table) async {
      final rows = await db.rawQuery('PRAGMA table_info($table)');
      return rows.map((r) => r['name'] as String).toList();
    }

    final tripsCols = await columnsOf('trips');
    final daysCols = await columnsOf('days');
    final stopsCols = await columnsOf('stops');
    final restaurantsCols = await columnsOf('restaurants');
    final hotelsCols = await columnsOf('hotels');

    // Every column TripTranslationService's _targets map (trip_translation_
    // service.dart) actually writes to — the exact set that was missing.
    expect(tripsCols, containsAll(['ai_summary_en', 'travel_tips_en', 'best_time_to_visit_en']));
    expect(daysCols, containsAll(['theme_en', 'summary_en']));
    expect(stopsCols, containsAll(['ai_tip_en', 'address_en']));
    expect(
        restaurantsCols,
        containsAll([
          'ai_description_en',
          'cuisine_type_en',
          // Added to _targets so a venue Places couldn't verify stops being
          // stuck with Arabic-Indic-digit hours forever.
          'opening_hours_en',
          'address_en',
        ]));
    expect(hotelsCols,
        containsAll(['ai_description_en', 'hotel_type_en', 'address_en']));

    // And a write to each actually succeeds — the failure mode wasn't just
    // "missing from a list," it was a thrown DatabaseException on first use.
    await db.insert('trips', {
      'id': 't1', 'destination': 'x', 'duration_days': 1,
      'budget_tier': 'mid', 'created_at': '', 'updated_at': '',
    });
    await db.update('trips', {'ai_summary_en': 'ok'}, where: 'id = ?', whereArgs: ['t1']);
    final row = await db.query('trips', where: 'id = ?', whereArgs: ['t1']);
    expect(row.single['ai_summary_en'], 'ok');

    await db.close();
  });
}
