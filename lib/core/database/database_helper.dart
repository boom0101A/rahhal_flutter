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

  static const int _dbVersion = 12;
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
    // Restaurant phone number — powers the booking & contact section
    // (call / WhatsApp). Hotels already carry one.
    8: [
      'ALTER TABLE restaurants ADD COLUMN phone TEXT;',
    ],
    // English opening hours — the parseable copy behind "closes in an hour"
    // warnings (the displayed Arabic hours use Arabic-Indic digits).
    9: [
      'ALTER TABLE restaurants ADD COLUMN opening_hours_en TEXT;',
    ],
    // favorites had no trip_id/FK at all, so a deleted trip's stops/
    // restaurants/hotels cascaded away but any favorite pointing at them
    // stayed forever as a dead row. Add trip_id with CASCADE so it's cleaned
    // up automatically from now on, backfill it for existing favorites by
    // looking up the item they point at, and drop whatever's left NULL —
    // those already point at nothing and were already unrecoverable orphans.
    10: [
      'ALTER TABLE favorites ADD COLUMN trip_id TEXT REFERENCES trips(id) ON DELETE CASCADE;',
      "UPDATE favorites SET trip_id = (SELECT trip_id FROM stops WHERE stops.id = favorites.item_ref_id) WHERE item_type = 'stop';",
      "UPDATE favorites SET trip_id = (SELECT trip_id FROM restaurants WHERE restaurants.id = favorites.item_ref_id) WHERE item_type = 'restaurant';",
      "UPDATE favorites SET trip_id = (SELECT trip_id FROM hotels WHERE hotels.id = favorites.item_ref_id) WHERE item_type = 'hotel';",
      'DELETE FROM favorites WHERE trip_id IS NULL;',
      'CREATE INDEX IF NOT EXISTS idx_favorites_trip_id ON favorites(trip_id);',
    ],
    // budget_items.amount_usd had no NOT NULL, unlike the structurally
    // identical actual_expenses.amount — SQLite can't ALTER a column's
    // constraint in place, so rebuild the table (the standard SQLite
    // pattern for this). The leading DROP makes every statement here safe
    // to retry if the app is killed mid-migration — the whole thing runs in
    // one transaction anyway, so a crash rolls back to the pre-migration
    // state and simply retries from the top on next launch.
    11: [
      'DROP TABLE IF EXISTS budget_items_new;',
      '''
      CREATE TABLE budget_items_new (
        id            TEXT PRIMARY KEY,
        trip_id       TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
        day_id        TEXT REFERENCES days(id) ON DELETE SET NULL,
        category      TEXT NOT NULL,
        description   TEXT,
        amount_usd    REAL NOT NULL DEFAULT 0,
        is_estimated  INTEGER DEFAULT 1
      );
      ''',
      '''
      INSERT INTO budget_items_new (id, trip_id, day_id, category, description, amount_usd, is_estimated)
      SELECT id, trip_id, day_id, category, description, COALESCE(amount_usd, 0), is_estimated FROM budget_items;
      ''',
      'DROP TABLE budget_items;',
      'ALTER TABLE budget_items_new RENAME TO budget_items;',
      'CREATE INDEX IF NOT EXISTS idx_budget_items_trip_id ON budget_items(trip_id);',
    ],
    // Two indexes that were always missing (trips.user_id is now
    // load-bearing — every trip list query filters by it) plus CHECK
    // constraints on enum-like columns that are fully owned by this client
    // app (a fixed, stable value set defined in Dart, verified against
    // every write site before adding each one below).
    //
    // Deliberately NOT applied to stops.category: that enum is defined
    // server-side (server.js's AI prompt schema) and can be extended by a
    // Railway deploy alone, independent of and faster than a client
    // release — a CHECK here could start rejecting every stop insert for a
    // trip the moment the server ships a category this client hasn't
    // shipped a matching constraint for yet.
    //
    // Each INSERT normalizes any pre-existing out-of-range value to the
    // column's own default via CASE/WHEN instead of trusting existing data
    // to already satisfy the new CHECK — a legacy row that somehow doesn't
    // match must not abort the whole migration transaction.
    12: [
      'CREATE INDEX IF NOT EXISTS idx_trips_user_id ON trips(user_id);',
      'CREATE INDEX IF NOT EXISTS idx_restaurants_day_id ON restaurants(day_id);',

      // trips: status + budget_tier
      'DROP TABLE IF EXISTS trips_new;',
      '''
      CREATE TABLE trips_new (
        id              TEXT PRIMARY KEY,
        user_id         TEXT,
        destination     TEXT NOT NULL,
        destination_en  TEXT,
        country_code    TEXT,
        start_date      TEXT,
        end_date        TEXT,
        duration_days   INTEGER NOT NULL DEFAULT 1,
        budget_tier     TEXT NOT NULL DEFAULT 'mid' CHECK (budget_tier IN ('economy','mid','luxury')),
        budget_total    REAL DEFAULT 0,
        travel_styles   TEXT DEFAULT '[]',
        travelers_count INTEGER DEFAULT 1,
        status          TEXT NOT NULL DEFAULT 'planned' CHECK (status IN ('planned','active','completed')),
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
      );
      ''',
      '''
      INSERT INTO trips_new (id, user_id, destination, destination_en, country_code, start_date, end_date, duration_days, budget_tier, budget_total, travel_styles, travelers_count, status, hero_image_url, ai_summary, travel_tips, best_time_to_visit, currency, timezone, created_at, updated_at, synced_at, is_mock_data)
      SELECT id, user_id, destination, destination_en, country_code, start_date, end_date, duration_days,
        CASE WHEN budget_tier IN ('economy','mid','luxury') THEN budget_tier ELSE 'mid' END,
        budget_total, travel_styles, travelers_count,
        CASE WHEN status IN ('planned','active','completed') THEN status ELSE 'planned' END,
        hero_image_url, ai_summary, travel_tips, best_time_to_visit, currency, timezone, created_at, updated_at, synced_at, is_mock_data
      FROM trips;
      ''',
      'DROP TABLE trips;',
      'ALTER TABLE trips_new RENAME TO trips;',
      'CREATE INDEX IF NOT EXISTS idx_trips_user_id ON trips(user_id);',

      // restaurants: price_tier
      'DROP TABLE IF EXISTS restaurants_new;',
      '''
      CREATE TABLE restaurants_new (
        id                TEXT PRIMARY KEY,
        trip_id           TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
        day_id            TEXT REFERENCES days(id) ON DELETE SET NULL,
        name              TEXT NOT NULL,
        name_en           TEXT,
        cuisine_type      TEXT,
        halal_certified   INTEGER DEFAULT 0,
        rating            REAL DEFAULT 0,
        price_per_person  REAL DEFAULT 0,
        price_tier        TEXT DEFAULT 'mid' CHECK (price_tier IN ('budget','mid','luxury')),
        address           TEXT,
        latitude          REAL DEFAULT 0,
        longitude         REAL DEFAULT 0,
        opening_hours     TEXT,
        image_url         TEXT,
        ai_description    TEXT,
        is_recommended    INTEGER DEFAULT 0,
        place_id          TEXT,
        coords_verified   INTEGER DEFAULT 0,
        phone             TEXT,
        opening_hours_en  TEXT
      );
      ''',
      '''
      INSERT INTO restaurants_new (id, trip_id, day_id, name, name_en, cuisine_type, halal_certified, rating, price_per_person, price_tier, address, latitude, longitude, opening_hours, image_url, ai_description, is_recommended, place_id, coords_verified, phone, opening_hours_en)
      SELECT id, trip_id, day_id, name, name_en, cuisine_type, halal_certified, rating, price_per_person,
        CASE WHEN price_tier IN ('budget','mid','luxury') THEN price_tier ELSE 'mid' END,
        address, latitude, longitude, opening_hours, image_url, ai_description, is_recommended, place_id, coords_verified, phone, opening_hours_en
      FROM restaurants;
      ''',
      'DROP TABLE restaurants;',
      'ALTER TABLE restaurants_new RENAME TO restaurants;',
      'CREATE INDEX IF NOT EXISTS idx_restaurants_trip_id ON restaurants(trip_id);',
      'CREATE INDEX IF NOT EXISTS idx_restaurants_day_id ON restaurants(day_id);',

      // actual_expenses: category
      'DROP TABLE IF EXISTS actual_expenses_new;',
      '''
      CREATE TABLE actual_expenses_new (
        id TEXT PRIMARY KEY,
        trip_id TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
        day_id TEXT REFERENCES days(id) ON DELETE SET NULL,
        category TEXT NOT NULL CHECK (category IN ('accommodation','food','transport','activities','shopping','other')),
        description TEXT,
        amount REAL NOT NULL,
        currency TEXT DEFAULT 'USD',
        receipt_image_path TEXT,
        spent_at TEXT NOT NULL,
        created_at TEXT NOT NULL
      );
      ''',
      '''
      INSERT INTO actual_expenses_new (id, trip_id, day_id, category, description, amount, currency, receipt_image_path, spent_at, created_at)
      SELECT id, trip_id, day_id,
        CASE WHEN category IN ('accommodation','food','transport','activities','shopping','other') THEN category ELSE 'other' END,
        description, amount, currency, receipt_image_path, spent_at, created_at
      FROM actual_expenses;
      ''',
      'DROP TABLE actual_expenses;',
      'ALTER TABLE actual_expenses_new RENAME TO actual_expenses;',
      'CREATE INDEX IF NOT EXISTS idx_expenses_trip_id ON actual_expenses(trip_id);',
      'CREATE INDEX IF NOT EXISTS idx_expenses_day_id ON actual_expenses(day_id);',

      // budget_items: category (amount_usd NOT NULL already added in v11)
      'DROP TABLE IF EXISTS budget_items_new;',
      '''
      CREATE TABLE budget_items_new (
        id            TEXT PRIMARY KEY,
        trip_id       TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
        day_id        TEXT REFERENCES days(id) ON DELETE SET NULL,
        category      TEXT NOT NULL CHECK (category IN ('accommodation','food','transport','activities','shopping','other')),
        description   TEXT,
        amount_usd    REAL NOT NULL DEFAULT 0,
        is_estimated  INTEGER DEFAULT 1
      );
      ''',
      '''
      INSERT INTO budget_items_new (id, trip_id, day_id, category, description, amount_usd, is_estimated)
      SELECT id, trip_id, day_id,
        CASE WHEN category IN ('accommodation','food','transport','activities','shopping','other') THEN category ELSE 'other' END,
        description, amount_usd, is_estimated
      FROM budget_items;
      ''',
      'DROP TABLE budget_items;',
      'ALTER TABLE budget_items_new RENAME TO budget_items;',
      'CREATE INDEX IF NOT EXISTS idx_budget_items_trip_id ON budget_items(trip_id);',

      // favorites: item_type
      'DROP TABLE IF EXISTS favorites_new;',
      '''
      CREATE TABLE favorites_new (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        trip_id TEXT REFERENCES trips(id) ON DELETE CASCADE,
        item_type TEXT NOT NULL CHECK (item_type IN ('stop','restaurant','hotel')),
        item_ref_id TEXT,
        destination_name TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      );
      ''',
      '''
      INSERT INTO favorites_new (id, user_id, trip_id, item_type, item_ref_id, destination_name, notes, created_at)
      SELECT id, user_id, trip_id,
        CASE WHEN item_type IN ('stop','restaurant','hotel') THEN item_type ELSE 'stop' END,
        item_ref_id, destination_name, notes, created_at
      FROM favorites;
      ''',
      'DROP TABLE favorites;',
      'ALTER TABLE favorites_new RENAME TO favorites;',
      'CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON favorites(user_id);',
      'CREATE INDEX IF NOT EXISTS idx_favorites_trip_id ON favorites(trip_id);',

      // chat_messages: role + message_type
      'DROP TABLE IF EXISTS chat_messages_new;',
      '''
      CREATE TABLE chat_messages_new (
        id            TEXT PRIMARY KEY,
        trip_id       TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
        role          TEXT NOT NULL CHECK (role IN ('user','assistant')),
        content       TEXT NOT NULL,
        timestamp     TEXT NOT NULL,
        message_type  TEXT DEFAULT 'text' CHECK (message_type IN ('text','suggestion','action'))
      );
      ''',
      '''
      INSERT INTO chat_messages_new (id, trip_id, role, content, timestamp, message_type)
      SELECT id, trip_id,
        CASE WHEN role IN ('user','assistant') THEN role ELSE 'user' END,
        content, timestamp,
        CASE WHEN message_type IN ('text','suggestion','action') THEN message_type ELSE 'text' END
      FROM chat_messages;
      ''',
      'DROP TABLE chat_messages;',
      'ALTER TABLE chat_messages_new RENAME TO chat_messages;',
      'CREATE INDEX IF NOT EXISTS idx_chat_messages_trip_id ON chat_messages(trip_id);',

      // trip_documents: doc_type
      'DROP TABLE IF EXISTS trip_documents_new;',
      '''
      CREATE TABLE trip_documents_new (
        id TEXT PRIMARY KEY,
        trip_id TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
        doc_type TEXT NOT NULL CHECK (doc_type IN ('passport','visa','ticket','booking','other')),
        title TEXT NOT NULL,
        file_path TEXT,
        file_url TEXT,
        notes TEXT,
        expiry_date TEXT,
        created_at TEXT NOT NULL
      );
      ''',
      '''
      INSERT INTO trip_documents_new (id, trip_id, doc_type, title, file_path, file_url, notes, expiry_date, created_at)
      SELECT id, trip_id,
        CASE WHEN doc_type IN ('passport','visa','ticket','booking','other') THEN doc_type ELSE 'other' END,
        title, file_path, file_url, notes, expiry_date, created_at
      FROM trip_documents;
      ''',
      'DROP TABLE trip_documents;',
      'ALTER TABLE trip_documents_new RENAME TO trip_documents;',
      'CREATE INDEX IF NOT EXISTS idx_documents_trip_id ON trip_documents(trip_id);',
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
      budget_tier     TEXT NOT NULL DEFAULT 'mid' CHECK (budget_tier IN ('economy','mid','luxury')),
      budget_total    REAL DEFAULT 0,
      travel_styles   TEXT DEFAULT '[]',
      travelers_count INTEGER DEFAULT 1,
      status          TEXT NOT NULL DEFAULT 'planned' CHECK (status IN ('planned','active','completed')),
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
      price_tier        TEXT DEFAULT 'mid' CHECK (price_tier IN ('budget','mid','luxury')),
      address           TEXT,
      latitude          REAL DEFAULT 0,
      longitude         REAL DEFAULT 0,
      opening_hours     TEXT,
      image_url         TEXT,
      ai_description    TEXT,
      is_recommended    INTEGER DEFAULT 0,
      place_id          TEXT,
      coords_verified   INTEGER DEFAULT 0,
      phone             TEXT,
      opening_hours_en  TEXT
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
      category      TEXT NOT NULL CHECK (category IN ('accommodation','food','transport','activities','shopping','other')),
      description   TEXT,
      amount_usd    REAL NOT NULL DEFAULT 0,
      is_estimated  INTEGER DEFAULT 1
    )
  ''';

  static const String _createChatMessagesTable = '''
    CREATE TABLE IF NOT EXISTS chat_messages (
      id            TEXT PRIMARY KEY,
      trip_id       TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
      role          TEXT NOT NULL CHECK (role IN ('user','assistant')),
      content       TEXT NOT NULL,
      timestamp     TEXT NOT NULL,
      message_type  TEXT DEFAULT 'text' CHECK (message_type IN ('text','suggestion','action'))
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
      trip_id TEXT REFERENCES trips(id) ON DELETE CASCADE,
      item_type TEXT NOT NULL CHECK (item_type IN ('stop','restaurant','hotel')),
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
      category TEXT NOT NULL CHECK (category IN ('accommodation','food','transport','activities','shopping','other')),
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
      doc_type TEXT NOT NULL CHECK (doc_type IN ('passport','visa','ticket','booking','other')),
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
    'CREATE INDEX IF NOT EXISTS idx_restaurants_day_id ON restaurants(day_id)',
    'CREATE INDEX IF NOT EXISTS idx_hotels_trip_id ON hotels(trip_id)',
    'CREATE INDEX IF NOT EXISTS idx_budget_items_trip_id ON budget_items(trip_id)',
    'CREATE INDEX IF NOT EXISTS idx_chat_messages_trip_id ON chat_messages(trip_id)',
  ];

  static const List<String> _createIndexesV2 = [
    'CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON favorites(user_id)',
    'CREATE INDEX IF NOT EXISTS idx_favorites_trip_id ON favorites(trip_id)',
    'CREATE INDEX IF NOT EXISTS idx_trips_user_id ON trips(user_id)',
    'CREATE INDEX IF NOT EXISTS idx_expenses_trip_id ON actual_expenses(trip_id)',
    'CREATE INDEX IF NOT EXISTS idx_expenses_day_id ON actual_expenses(day_id)',
    'CREATE INDEX IF NOT EXISTS idx_documents_trip_id ON trip_documents(trip_id)',
    'CREATE INDEX IF NOT EXISTS idx_users_uid ON users(uid)',
  ];

  // ─── Helper CRUD ──────────────────────────────────────────────────────────

  /// Shared insert path for every table — `ConflictAlgorithm.replace` means
  /// inserting a row whose id already exists REPLACES it, which for a
  /// parent table (trips, days) first CASCADE-deletes all of that row's
  /// children before the replacement is written. This is silent and easy to
  /// trigger by accident (e.g. reusing an id instead of generating a fresh
  /// one). It's safe today only because every insert path in this app
  /// generates a brand-new UUID (see `Uuid().v4()` at every call site) —
  /// no code ever intentionally re-inserts an existing id to trigger this.
  /// If that ever changes, this default needs revisiting per call site.
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

  /// Wipes every user row from the device.
  ///
  /// Used only when an account is deleted: leaving trips behind would let cloud
  /// sync resurrect them on the next sign-in, contradicting the deletion the
  /// user just asked for. Runs in one transaction so a failure part-way can't
  /// leave a half-erased database.
  Future<void> clearAllData() async {
    const tables = [
      // Children first — even though foreign keys cascade, explicit order keeps
      // this correct regardless of the PRAGMA state.
      'stops',
      'restaurants',
      'hotels',
      'budget_items',
      'chat_messages',
      'actual_expenses',
      'trip_documents',
      'days',
      'trips',
      'favorites',
      'users',
    ];
    final db = await database;
    await db.transaction((txn) async {
      for (final table in tables) {
        try {
          await txn.delete(table);
        } catch (e) {
          // A table absent on an older schema must not abort the wipe.
          debugPrint('[DB] clearAllData: skipping $table — $e');
        }
      }
    });
  }

  /// Assigns every trip with no owner yet to [uid].
  ///
  /// Trips saved before per-account filtering existed were never stamped with
  /// a `user_id`, which let every account on a shared device see every trip.
  /// Called on every sign-in so those legacy rows are claimed by whoever
  /// actually owns this device's data — a no-op once no `NULL` rows remain,
  /// since every trip saved after that point already has a real `user_id`.
  Future<void> claimOrphanedTrips(String uid) async {
    final db = await database;
    await db.update(
      'trips',
      {'user_id': uid},
      where: 'user_id IS NULL',
    );
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
