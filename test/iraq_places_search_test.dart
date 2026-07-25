import 'package:flutter_test/flutter_test.dart';
import 'package:rahhal_flutter/core/data/iraq_places.dart';

void main() {
  String? firstEn(String q) {
    final r = searchIraqPlaces(q);
    return r.isEmpty ? null : r.first.en;
  }

  test('exact Arabic governorate name', () {
    expect(firstEn('كركوك'), 'Kirkuk');
    expect(firstEn('بغداد'), 'Baghdad');
  });

  test('partial / prefix typing', () {
    expect(firstEn('كرب'), 'Karbala');
    expect(firstEn('سليم'), 'Sulaymaniyah');
  });

  test('tolerates missing ال and different spellings', () {
    expect(firstEn('حله'), 'Hillah'); // الحلة without ال, ة→ه
    expect(firstEn('بصره'), 'Basra');
    expect(firstEn('اربيل'), 'Erbil'); // أربيل without hamza
  });

  test('English queries work too', () {
    expect(firstEn('basra'), 'Basra');
    expect(firstEn('mosul'), 'Mosul');
  });

  test('landmarks and ancient sites are searchable', () {
    expect(firstEn('أور'), 'Ur');
    expect(firstEn('الملوية'), 'Malwiya Minaret, Samarra');
    expect(firstEn('قلعة اربيل'), 'Erbil Citadel');
    expect(firstEn('الاهوار'), 'Mesopotamian Marshes');
  });

  test('aliases resolve', () {
    expect(firstEn('هولير'), 'Erbil');
    expect(firstEn('اثار بابل'), 'Babylon Ruins');
  });

  test('governorates outrank districts at equal relevance', () {
    // "نينوى" is the governorate entry; must not be beaten by a district.
    expect(firstEn('نينوى'), 'Mosul (Nineveh)');
  });

  test('no duplicate destinations in results', () {
    final r = searchIraqPlaces('ا', limit: 20);
    final ens = r.map((p) => p.en.toLowerCase()).toList();
    expect(ens.toSet().length, ens.length);
  });

  test('empty query returns nothing', () {
    expect(searchIraqPlaces('   '), isEmpty);
  });
}
