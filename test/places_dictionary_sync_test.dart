import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the contract between the destination picker and the backend.
///
/// `_pickSuggestion` writes the place's ARABIC name into the destination field,
/// and that is what gets POSTed to /api/generate-trip. The server resolves it
/// through its zero-cost `AR_CITY_DICTIONARY`; anything it can't find there
/// falls through to a Google Places lookup — and that free tier is only 100
/// searches/day for the entire app, which is exactly what left trips with
/// every stop deleted once before. So: every searchable foreign place must
/// also be a key in the server dictionary.
void main() {
  const countryLabels = {
    'تركيا', 'إيران', 'الأردن', 'السعودية', 'الإمارات', 'الكويت',
    'قطر', 'البحرين', 'عُمان', 'سوريا', 'لبنان', 'مصر', 'فلسطين', 'تونس',
  };

  late String dart;
  late String serverJs;

  setUpAll(() {
    dart = File('lib/core/data/iraq_places.dart').readAsStringSync();
    serverJs = File('server.js').readAsStringSync();
  });

  List<({String ar, String en, String gov})> parseEntries() {
    const str = "(?:'((?:[^'\\\\]|\\\\.)*)'|\"((?:[^\"\\\\]|\\\\.)*)\")";
    final re = RegExp(
      "IraqPlace\\(\\s*ar:\\s*$str"
      "\\s*,\\s*en:\\s*$str"
      "\\s*,\\s*governorate:\\s*'([^']*)'",
    );
    return re.allMatches(dart).map((m) {
      final ar = (m.group(1) ?? m.group(2)!).replaceAll(r"\'", "'");
      final en = (m.group(3) ?? m.group(4)!).replaceAll(r"\'", "'");
      return (ar: ar, en: en, gov: m.group(5)!);
    }).toList();
  }

  test('the dataset parses and is substantial', () {
    final entries = parseEntries();
    expect(entries.length, greaterThan(400),
        reason: 'Iraq plus the neighbouring countries');
  });

  test('no duplicate Arabic keys — a duplicate silently shadows the other', () {
    final seen = <String>{};
    final dupes = <String>[];
    for (final e in parseEntries()) {
      if (!seen.add(e.ar)) dupes.add(e.ar);
    }
    expect(dupes, isEmpty, reason: 'duplicated: ${dupes.join(", ")}');
  });

  test('every foreign place is resolvable from the server dictionary for free',
      () {
    final foreign =
        parseEntries().where((e) => countryLabels.contains(e.gov)).toList();
    expect(foreign.length, greaterThan(300),
        reason: 'sanity: the neighbour dataset is actually loaded');

    final missing = foreign
        .where((e) => !serverJs.contains("'${e.ar}':"))
        .map((e) => '${e.ar} (${e.en})')
        .toList();

    expect(missing, isEmpty,
        reason: 'These are searchable in the app but absent from server.js\'s '
            'AR_CITY_DICTIONARY, so each one would spend Google Places quota '
            'on every trip:\n  ${missing.join("\n  ")}');
  });
}
