import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Singleton SQLite database helper.
/// All table creation and migration logic lives here.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  // ─── Init ─────────────────────────────────────────────────────────────────

  static const int _dbVersion = 7;
  static const String _dbName = 'rahhal_ai.db';

  static final Map<int, List<String>> _migrations = {
    2: [
      _createUsersTable,
      _createFavoritesTable,
      _createExpensesTable,
      _createDocumentsTable,
      ..._createIndexesV2,
    ],
    3: [
      'ALTER TABLE restaurants ADD COLUMN name_en TEXT;',
      'ALTER TABLE trips ADD COLUMN destination_en TEXT;',
      'ALTER TABLE trips ADD COLUMN is_mock_data INTEGER NOT NULL DEFAULT 0;',
      'ALTER TABLE stops ADD COLUMN image_url TEXT;',
    ],
    4: [
      'ALTER TABLE stops ADD COLUMN coords_verified INTEGER DEFAULT 0;',
      'ALTER TABLE stops ADD COLUMN place_id TEXT;',
    ],
    // Restaurants now come from Google Places, so they carry a place_id we can
    // deep-link with and a verified flag mirroring the one on stops.
    5: [
      'ALTER TABLE restaurants ADD COLUMN place_id TEXT;',
      'ALTER TABLE restaurants ADD COLUMN coords_verified INTEGER DEFAULT 0;',
    ],
    // Per-stop "visited" flag powers the day-progress tracker.
    6: [
      'ALTER TABLE stops ADD COLUMN is_visited INTEGER DEFAULT 0;',
    ],
    // Real hotels, sourced from Google Places / OSM, shown in a dedicated tab.
    7: [
      _createHotelsTable,
      'CREATE INDEX IF NOT EXISTS idx_hotels_trip_id ON hotels(trip_id)',
    ],
  };

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.transaction((txn) async {
      // Version 1 Tables
      await txn.execute(_createTripsTable);
      await txn.execute(_createDaysTable);
      await txn.execute(_createStopsTable);
      await txn.execute(_createRestaurantsTable);
      await txn.execute(_createHotelsTable);
      await txn.execute(_createBudgetItemsTable);
      await txn.execute(_createChatMessagesTable);

      // Version 2 Tables
      await txn.execute(_createUsersTable);
      await txn.execute(_createFavoritesTable);
      await txn.execute(_createExpensesTable);
      await txn.execute(_createDocumentsTable);

      // Indexes
      for (final indexQuery in [..._createIndexes, ..._createIndexesV2]) {
        await txn.execute(indexQuery);
      }
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('[DB] Upgrading database from v$oldVersion to v$newVersion');

    await db.transaction((txn) async {
      for (int v = oldVersion + 1; v <= newVersion; v++) {
        final statements = _migrations[v];
        if (statements != null) {
          for (final stmt in statements) {
            try {
              await txn.execute(stmt);
              debugPrint('[DB] Applied migration v$v: $stmt');
            } catch (e) {
              final msg = e.toString().toLowerCase();
              final isBenign = msg.contains('duplicate column') ||
                  msg.contains('already exists');
              if (!isBenign) {
                debugPrint('[DB] Migration v$v FAILED: $stmt — $e');
                rethrow;
              }
              debugPrint('[DB] Migration v$v statement skipped (already applied): $e');
            }
          }
        }
      }
    });
  }

  // ─── Table schemas ─────────────────────────────────────────────────────────

  static const String _createTripsTable = '''
    CREATE TABLE IF NOT EXISTS trips (
      id              TEXT PRIMARY KEY,
      user_id         TEXT,
      destination     TEXT NOT NULL,
      destination_en  TEXT,
      country_code    TEXT,
      start_date      TEXT,
      end_date        TEXT,
      duration_days   INTEGER NOT NULL DEFAULT 1,
      budget_tier     TEXT NOT NULL DEFAULT 'mid',
      budget_total    REAL DEFAULT 0,
      travel_styles   TEXT DEFAULT '[]',
      travelers_count INTEGER DEFAULT 1,
      status          TEXT NOT NULL DEFAULT 'planned',
      hero_image_url  TEXT,
      ai_summary      TEXT,
      travel_tips     TEXT DEFAULT '[]',
      best_time_to_visit TEXT,
      currency        TEXT DEFAULT 'USD',
      timezone        TEXT DEFAULT 'UTC',
      created_at      TEXT NOT NULL,
      updated_at      TEXT NOT NULL,
      synced_at       TEXT,
      is_mock_data    INTEGER NOT NULL DEFAULT 0
    )
  ''';

  static const String _createDaysTable = '''
    CREATE TABLE IF NOT EXISTS days (
      id          TEXT PRIMARY KEY,
      trip_id     TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
      day_number  INTEGER NOT NULL,
      date        TEXT,
      theme       TEXT,
      summary     TEXT
    )
  ''';

  static const String _createStopsTable = '''
    CREATE TABLE IF NOT EXISTS stops (
      id                TEXT PRIMARY KEY,
      day_id            TEXT NOT NULL REFERENCES days(id) ON DELETE CASCADE,
      trip_id           TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
      order_index       INTEGER DEFAULT 0,
      name              TEXT NOT NULL,
      name_en           TEXT,
      category          TEXT DEFAULT 'other',
      time_of_day       TEXT DEFAULT 'morning',
      start_time        TEXT,
      duration_minutes  INTEGER DEFAULT 60,
      latitude          REAL,
      longitude         REAL,
      address           TEXT,
      cost_usd          REAL DEFAULT 0,
      ai_tip            TEXT,
      image_url         TEXT,
      booking_required  INTEGER DEFAULT 0,
      booking_url       TEXT,
      coords_verified   INTEGER DEFAULT 0,
      place_id          TEXT,
      is_visited        INTEGER DEFAULT 0
    )
  ''';

  static const String _createRestaurantsTable = '''
    CREATE TABLE IF NOT EXISTS restaurants (
      id                TEXT PRIMARY KEY,
      trip_id           TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
      day_id            TEXT REFERENCES days(id) ON DELETE SET NULL,
      name              TEXT NOT NULL,
      name_en           TEXT,
      cuisine_type      TEXT,
      halal_certified   INTEGER DEFAULT 0,
      rating            REAL DEFAULT 0,
      price_per_person  REAL DEFAULT 0,
      price_tier        TEXT DEFAULT 'mid',
      address           TEXT,
      latitude          REAL DEFAULT 0,
      longitude         REAL DEFAULT 0,
      opening_hours     TEXT,
      image_url         TEXT,
      ai_description    TEXT,
      is_recommended    INTEGER DEFAULT 0,
      place_id          TEXT,
      coords_verified   INTEGER DEFAULT 0
    )
  ''';

  static const String _createHotelsTable = '''
    CREATE TABLE IF NOT EXISTS hotels (
      id                TEXT PRIMARY KEY,
      trip_id           TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
      name              TEXT NOT NULL,
      name_en           TEXT,
      hotel_type        TEXT,
      rating            REAL DEFAULT 0,
      price_per_night   REAL DEFAULT 0,
      address           TEXT,
      latitude          REAL DEFAULT 0,
      longitude         REAL DEFAULT 0,
      phone             TEXT,
      image_url         TEXT,
      ai_description    TEXT,
      booking_url       TEXT,
      place_id          TEXT,
      coords_verified   INTEGER DEFAULT 0
    )
  ''';

  static const String _createBudgetItemsTable = '''
    CREATE TABLE IF NOT EXISTS budget_items (
      id            TEXT PRIMARY KEY,
      trip_id       TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
      day_id        TEXT REFERENCES days(id) ON DELETE SET NULL,
      category      TEXT NOT NULL,
      description   TEXT,
      amount_usd    REAL DEFAULT 0,
      is_estimated  INTEGER DEFAULT 1
    )
  ''';

  static const String _createChatMessagesTable = '''
    CREATE TABLE IF NOT EXISTS chat_messages (
      id            TEXT PRIMARY KEY,
      trip_id       TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
      role          TEXT NOT NULL,
      content       TEXT NOT NULL,
      timestamp     TEXT NOT NULL,
      message_type  TEXT DEFAULT 'text'
    )
  ''';

  static const String _createUsersTable = '''
    CREATE TABLE IF NOT EXISTS users (
      uid TEXT PRIMARY KEY,
      display_name TEXT,
      email TEXT,
      photo_url TEXT,
      preferred_language TEXT DEFAULT 'ar',
      preferred_currency TEXT DEFAULT 'USD',
      default_budget_tier TEXT DEFAULT 'mid',
      created_at TEXT NOT NULL,
      last_login_at TEXT
    )
  ''';

  static const String _createFavoritesTable = '''
    CREATE TABLE IF NOT EXISTS favorites (
      id TEXT PRIMARY KEY,
      user_id TEXT,
      item_type TEXT NOT NULL,
      item_ref_id TEXT,
      destination_name TEXT,
      notes TEXT,
      created_at TEXT NOT NULL
    )
  ''';

  static const String _createExpensesTable = '''
    CREATE TABLE IF NOT EXISTS actual_expenses (
      id TEXT PRIMARY KEY,
      trip_id TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
      day_id TEXT REFERENCES days(id) ON DELETE SET NULL,
      category TEXT NOT NULL,
      description TEXT,
      amount REAL NOT NULL,
      currency TEXT DEFAULT 'USD',
      receipt_image_path TEXT,
      spent_at TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
  ''';

  static const String _createDocumentsTable = '''
    CREATE TABLE IF NOT EXISTS trip_documents (
      id TEXT PRIMARY KEY,
      trip_id TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
      doc_type TEXT NOT NULL,
      title TEXT NOT NULL,
      file_path TEXT,
      file_url TEXT,
      notes TEXT,
      expiry_date TEXT,
      created_at TEXT NOT NULL
    )
  ''';

  static const List<String> _createIndexes = [
    'CREATE INDEX IF NOT EXISTS idx_days_trip_id ON days(trip_id)',
    'CREATE INDEX IF NOT EXISTS idx_stops_trip_id ON stops(trip_id)',
    'CREATE INDEX IF NOT EXISTS idx_stops_day_id ON stops(day_id)',
    'CREATE INDEX IF NOT EXISTS idx_restaurants_trip_id ON restaurants(trip_id)',
    'CREATE INDEX IF NOT EXISTS idx_hotels_trip_id ON hotels(trip_id)',
    'CREATE INDEX IF NOT EXISTS idx_budget_items_trip_id ON budget_items(trip_id)',
    'CREATE INDEX IF NOT EXISTS idx_chat_messages_trip_id ON chat_messages(trip_id)',
  ];

  static const List<String> _createIndexesV2 = [
    'CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON favorites(user_id)',
    'CREATE INDEX IF NOT EXISTS idx_expenses_trip_id ON actual_expenses(trip_id)',
    'CREATE INDEX IF NOT EXISTS idx_expenses_day_id ON actual_expenses(day_id)',
    'CREATE INDEX IF NOT EXISTS idx_documents_trip_id ON trip_documents(trip_id)',
    'CREATE INDEX IF NOT EXISTS idx_users_uid ON users(uid)',
  ];

  // ─── Helper CRUD ──────────────────────────────────────────────────────────

  Future<int> insert(String table, Map<String, dynamic> row) async {
    final db = await database;
    return db.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return db.query(table,
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
        limit: limit);
  }

  Future<int> update(
    String table,
    Map<String, dynamic> row, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await database;
    return db.update(table, row, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<Map<String, dynamic>?> queryOne(
    String table, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await database;
    final results = await db.query(table, where: where, whereArgs: whereArgs);
    return results.isNotEmpty ? results.first : null;
  }

  Future<T> executeInTransaction<T>(
      Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  /// Closes and resets the database (for testing).
  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
