import 'package:flutter_test/flutter_test.dart';
import 'package:rahhal_flutter/core/data/iraq_places.dart';

/// Covers the English side of the destination picker.
///
/// The suggestion list showed `ar` and the Arabic governorate no matter what
/// language the app was in, so an English user got an Arabic list sitting above
/// translated city chips. And while English queries did match, the query was
/// normalised and the English candidate was not — so punctuation in a name
/// ("Al-Hillah", "Al-Mada'in") made it unreachable by the natural spelling.
///
/// Note what is deliberately NOT tested here: what gets written into the field.
/// That stays the Arabic name, because the server resolves an Arabic name
/// through its dictionary and attaches the governorate's real centre
/// coordinates, which its out-of-governorate stop filter depends on.
String? firstEn(String q) {
  final r = searchIraqPlaces(q);
  return r.isEmpty ? null : r.first.en;
}

void main() {
  group('English queries with punctuation', () {
    // Punctuation normalises to a space on both sides now, so typing a plain
    // space where the name has a hyphen, apostrophe, bracket or comma matches.
    // (Typing no separator at all — "maan" for "Ma'an" — still doesn't, and
    // isn't claimed to.)
    test('an apostrophe can be typed as a space', () {
      expect(firstEn('mada in'), "Al-Mada'in");
      expect(firstEn('ma an'), "Ma'an");
    });

    test('a hyphen can be typed as a space', () {
      expect(firstEn('al mahmudiyah'), 'Al-Mahmudiyah');
    });

    test('brackets and commas can be dropped', () {
      expect(firstEn('taq kasra ctesiphon'), 'Taq Kasra (Ctesiphon)');
      expect(firstEn('kadhimiya baghdad'), 'Kadhimiya, Baghdad');
    });

    test('plain English queries still work', () {
      // Guards the pre-existing behaviour the extra candidate could disturb.
      expect(firstEn('basra'), 'Basra');
      expect(firstEn('mosul'), 'Mosul');
    });

    test('Arabic queries are unaffected', () {
      expect(firstEn('حله'), 'Hillah');
      expect(firstEn('اربيل'), 'Erbil');
    });
  });

  group('governorateEn', () {
    test('resolves an Iraqi governorate to its English name', () {
      expect(governorateEn('بغداد'), 'Baghdad');
      expect(governorateEn('البصرة'), 'Basra');
    });

    test('returns null for a foreign country label', () {
      // Foreign entries store a country name where a governorate would be, and
      // no IraqPlace row exists for it. The caller drops that half of the
      // subtitle rather than inventing a translation.
      expect(governorateEn('تركيا'), isNull);
      expect(governorateEn('لا يوجد'), isNull);
    });

    test('every Iraqi place resolves, so no subtitle silently loses its half',
        () {
      final iraqi = iraqPlaces.where((p) =>
          iraqPlaces.any((g) => g.ar == p.governorate && g.kind == IraqPlaceKind.governorate));
      expect(iraqi, isNotEmpty);
      for (final p in iraqi) {
        expect(governorateEn(p.governorate), isNotNull,
            reason: '${p.en} has governorate "${p.governorate}"');
      }
    });
  });
}
