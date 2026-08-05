import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../database/database_helper.dart';
import 'dio_client.dart';

/// Fills in the English copy of a trip's AI-written prose, on demand.
///
/// The trip model writes summaries, day themes, stop tips and restaurant/hotel
/// blurbs in Arabic only — names were the only thing with an English
/// counterpart. So switching the app to English used to leave all that text
/// Arabic: there was nothing to switch to.
///
/// Translating here rather than at generation time is deliberate:
///   * the trip prompt's output budget is already tight, and doubling every
///     prose field risks the truncated-JSON failures that budget exists to
///     avoid, and
///   * this also covers trips that already exist on the device, which a
///     generation-time change never could.
///
/// Results are written straight into the `*_en` columns, so the cost is paid
/// once per trip and every later language switch is instant and offline.
class TripTranslationService {
  final DatabaseHelper _dbHelper;
  final Dio _dio;

  TripTranslationService({DatabaseHelper? dbHelper, Dio? dio})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _dio = dio ?? DioClient.general;

  /// Trips already being translated, so a rebuild or a second screen opening
  /// the same trip can't fire a duplicate paid request.
  final Set<String> _inFlight = {};

  /// Which table/column each key prefix maps back to. The wire format is a
  /// flat `{k, t}` list so the server stays schema-agnostic.
  static const _targets = <String, ({String table, String column})>{
    'trip.summary': (table: 'trips', column: 'ai_summary_en'),
    'trip.best_time': (table: 'trips', column: 'best_time_to_visit_en'),
    'day.theme': (table: 'days', column: 'theme_en'),
    'day.summary': (table: 'days', column: 'summary_en'),
    'stop.tip': (table: 'stops', column: 'ai_tip_en'),
    'rest.desc': (table: 'restaurants', column: 'ai_description_en'),
    'rest.cuisine': (table: 'restaurants', column: 'cuisine_type_en'),
    'hotel.desc': (table: 'hotels', column: 'ai_description_en'),
    'hotel.type': (table: 'hotels', column: 'hotel_type_en'),
  };

  /// Ensures [tripId] has English prose, translating whatever is still missing.
  ///
  /// Safe to call on every trip open: it returns immediately once nothing is
  /// missing, and never throws — a failure just leaves the Arabic text in
  /// place, which is what the UI falls back to anyway.
  Future<bool> ensureEnglish(String tripId) async {
    if (_inFlight.contains(tripId)) return false;
    _inFlight.add(tripId);
    try {
      final items = await _collectUntranslated(tripId);
      if (items.isEmpty) return false;

      final translated = await _translate(items);
      if (translated.isEmpty) return false;

      await _persist(tripId, translated);
      debugPrint('[Translate] trip $tripId: ${translated.length}/${items.length} fields');
      return true;
    } catch (e) {
      debugPrint('[Translate] trip $tripId failed (keeping Arabic): $e');
      return false;
    } finally {
      _inFlight.remove(tripId);
    }
  }

  /// True when anything in this trip still lacks an English version — lets a
  /// caller decide whether it's worth showing a "translating…" hint.
  Future<bool> needsTranslation(String tripId) async =>
      (await _collectUntranslated(tripId)).isNotEmpty;

  // ── Gathering ─────────────────────────────────────────────────────────────

  /// Rows whose Arabic prose is present but whose English copy is not.
  /// `travel_tips` is handled as one unit (see the note in localizedProseList).
  Future<List<({String k, String t})>> _collectUntranslated(String tripId) async {
    final out = <({String k, String t})>[];

    String? nonEmpty(Object? v) {
      final s = v as String?;
      return (s != null && s.trim().isNotEmpty) ? s : null;
    }

    final trip = await _dbHelper.queryOne('trips', where: 'id = ?', whereArgs: [tripId]);
    if (trip != null) {
      final summary = nonEmpty(trip['ai_summary']);
      if (summary != null && nonEmpty(trip['ai_summary_en']) == null) {
        out.add((k: 'trip.summary|$tripId', t: summary));
      }
      final best = nonEmpty(trip['best_time_to_visit']);
      if (best != null && nonEmpty(trip['best_time_to_visit_en']) == null) {
        out.add((k: 'trip.best_time|$tripId', t: best));
      }
      // Tips are a JSON array; each element travels as its own item so the
      // model can't quietly merge them, and they're reassembled on the way in.
      final tipsEn = _decodeTips(trip['travel_tips_en'] as String?);
      if (tipsEn.isEmpty) {
        final tips = _decodeTips(trip['travel_tips'] as String?);
        for (var i = 0; i < tips.length; i++) {
          if (tips[i].trim().isEmpty) continue;
          out.add((k: 'trip.tip.$i|$tripId', t: tips[i]));
        }
      }
    }

    Future<void> gather(String table, String col, String colEn, String prefix) async {
      final rows = await _dbHelper.query(table, where: 'trip_id = ?', whereArgs: [tripId]);
      for (final r in rows) {
        final src = nonEmpty(r[col]);
        if (src == null || nonEmpty(r[colEn]) != null) continue;
        out.add((k: '$prefix|${r['id']}', t: src));
      }
    }

    await gather('days', 'theme', 'theme_en', 'day.theme');
    await gather('days', 'summary', 'summary_en', 'day.summary');
    await gather('stops', 'ai_tip', 'ai_tip_en', 'stop.tip');
    await gather('restaurants', 'ai_description', 'ai_description_en', 'rest.desc');
    await gather('hotels', 'ai_description', 'ai_description_en', 'hotel.desc');
    // The type chips ("مطعم" / "فندق"). The server fills these for free from
    // its English Places result, so this only picks up AI-invented entries and
    // trips generated before that was in place.
    await gather('restaurants', 'cuisine_type', 'cuisine_type_en', 'rest.cuisine');
    await gather('hotels', 'hotel_type', 'hotel_type_en', 'hotel.type');

    return out;
  }

  static List<String> _decodeTips(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.map((e) => e.toString()).toList();
    } catch (_) {
      // A malformed blob is treated as "no tips" rather than breaking the
      // whole translation pass.
    }
    return const [];
  }

  // ── Network ───────────────────────────────────────────────────────────────

  Future<Map<String, String>> _translate(List<({String k, String t})> items) async {
    final res = await _dio.post(
      '${AppConfig.proxyBaseUrl}/api/translate',
      data: {
        'targetLang': 'en',
        'items': items.map((e) => {'k': e.k, 't': e.t}).toList(),
      },
      options: Options(receiveTimeout: const Duration(seconds: 60)),
    );

    final list = (res.data is Map) ? (res.data['items'] as List?) : null;
    if (list == null) return const {};

    final out = <String, String>{};
    for (final entry in list) {
      if (entry is! Map) continue;
      final k = entry['k'];
      final t = entry['t'];
      if (k is String && t is String && t.trim().isNotEmpty) out[k] = t.trim();
    }
    return out;
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> _persist(String tripId, Map<String, String> translated) async {
    final tips = <int, String>{};

    for (final entry in translated.entries) {
      final sep = entry.key.lastIndexOf('|');
      if (sep <= 0) continue;
      final prefix = entry.key.substring(0, sep);
      final id = entry.key.substring(sep + 1);

      if (prefix.startsWith('trip.tip.')) {
        final idx = int.tryParse(prefix.substring('trip.tip.'.length));
        if (idx != null) tips[idx] = entry.value;
        continue;
      }

      final target = _targets[prefix];
      if (target == null) continue;
      await _dbHelper.update(
        target.table,
        {target.column: entry.value},
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    // Only store the tips list once every tip came back, so a partial result
    // can't leave a list that's shorter than the Arabic one — the UI swaps the
    // list wholesale, and a truncated English list would silently hide tips.
    if (tips.isNotEmpty) {
      final trip = await _dbHelper.queryOne('trips', where: 'id = ?', whereArgs: [tripId]);
      final original = _decodeTips(trip?['travel_tips'] as String?);
      if (tips.length == original.where((t) => t.trim().isNotEmpty).length) {
        final ordered = (tips.keys.toList()..sort()).map((i) => tips[i]!).toList();
        await _dbHelper.update(
          'trips',
          {'travel_tips_en': jsonEncode(ordered)},
          where: 'id = ?',
          whereArgs: [tripId],
        );
      }
    }
  }
}
