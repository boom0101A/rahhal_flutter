/// Offline search index for Iraqi destinations: every governorate, its cities
/// and districts, plus the country's best-known heritage and tourist sites.
///
/// This is deliberately LOCAL data, not a Places Autocomplete call: search stays
/// instant, works with no connection, and costs nothing against the Google
/// Places quota (which can't be raised, since Google Cloud billing isn't
/// available in Iraq).
///
/// [en] is what gets sent to the trip planner — it matches the server's
/// AR_CITY_DICTIONARY, so a picked suggestion always resolves to the right city.
library;

enum IraqPlaceKind { governorate, city, landmark }

class IraqPlace {
  /// Arabic name shown to the user.
  final String ar;

  /// Canonical English name sent to the planner.
  final String en;

  /// Governorate this belongs to (Arabic), shown as the subtitle.
  final String governorate;

  final IraqPlaceKind kind;

  /// Extra spellings people actually type (colloquial or alternate forms).
  final List<String> aliases;

  const IraqPlace({
    required this.ar,
    required this.en,
    required this.governorate,
    required this.kind,
    this.aliases = const [],
  });
}

/// Normalizes Arabic for forgiving matching: strips diacritics and tatweel,
/// unifies alef/ya/ta-marbuta variants, and drops the "ال" article — so
/// "الحلّة", "الحله" and "حلة" all match each other.
String normalizeArabic(String input) {
  var s = input.trim().toLowerCase();
  s = s.replaceAll(RegExp('[ً-ْـ]'), ''); // diacritics + tatweel
  s = s.replaceAll(RegExp('[أإآٱ]'), 'ا');
  s = s.replaceAll('ة', 'ه');
  s = s.replaceAll('ى', 'ي');
  s = s.replaceAll('ؤ', 'و');
  s = s.replaceAll('ئ', 'ي');
  s = s.replaceAll(RegExp(r'[^\w؀-ۿ]+'), ' ');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (s.startsWith('ال') && s.length > 4) s = s.substring(2);
  return s;
}

/// Ranked search across the index. Exact match first, then prefix, then
/// substring — so typing "كرب" surfaces كربلاء before a partial elsewhere.
List<IraqPlace> searchIraqPlaces(String query, {int limit = 12}) {
  final q = normalizeArabic(query);
  if (q.isEmpty) return const [];

  final scored = <({IraqPlace place, int score})>[];
  for (final p in iraqPlaces) {
    final candidates = <String>[
      normalizeArabic(p.ar),
      p.en.toLowerCase(),
      ...p.aliases.map(normalizeArabic),
    ];

    int best = -1;
    for (final c in candidates) {
      if (c == q) {
        best = 100;
        break;
      }
      if (c.startsWith(q)) {
        best = best < 70 ? 70 : best;
      } else if (c.contains(q)) {
        best = best < 40 ? 40 : best;
      }
    }
    if (best < 0) continue;

    // Governorates outrank districts at equal relevance; landmarks come last.
    final kindBonus = switch (p.kind) {
      IraqPlaceKind.governorate => 6,
      IraqPlaceKind.city => 3,
      IraqPlaceKind.landmark => 0,
    };
    scored.add((place: p, score: best + kindBonus));
  }

  scored.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    return a.place.ar.length.compareTo(b.place.ar.length); // shorter = closer
  });

  // Collapse duplicates that resolve to the same destination (e.g. "بصرة" and
  // "البصرة" both → Basra) so the list doesn't repeat itself.
  final seen = <String>{};
  final out = <IraqPlace>[];
  for (final s in scored) {
    if (seen.add(s.place.en.toLowerCase())) out.add(s.place);
    if (out.length >= limit) break;
  }
  return out;
}

const List<IraqPlace> iraqPlaces = [
  // ─── Baghdad ──────────────────────────────────────────────────────────────
  IraqPlace(ar: 'بغداد', en: 'Baghdad', governorate: 'بغداد', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'الكاظمية', en: 'Kadhimiya, Baghdad', governorate: 'بغداد', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الأعظمية', en: 'Adhamiyah, Baghdad', governorate: 'بغداد', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'أبو غريب', en: 'Abu Ghraib', governorate: 'بغداد', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'المحمودية', en: 'Al-Mahmudiyah', governorate: 'بغداد', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'المدائن', en: "Al-Mada'in", governorate: 'بغداد', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'التاجي', en: 'Al-Taji', governorate: 'بغداد', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'شارع المتنبي', en: 'Al-Mutanabbi Street, Baghdad', governorate: 'بغداد', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'المتحف العراقي', en: 'Iraq Museum, Baghdad', governorate: 'بغداد', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'القشلة', en: 'Al-Qishla, Baghdad', governorate: 'بغداد', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'المدرسة المستنصرية', en: 'Al-Mustansiriya School, Baghdad', governorate: 'بغداد', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'طاق كسرى', en: 'Taq Kasra (Ctesiphon)', governorate: 'بغداد', kind: IraqPlaceKind.landmark, aliases: ['ايوان كسرى', 'قطيسفون']),
  IraqPlace(ar: 'جزيرة بغداد السياحية', en: 'Baghdad Island', governorate: 'بغداد', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'حديقة الزوراء', en: 'Zawraa Park, Baghdad', governorate: 'بغداد', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'نصب الحرية', en: 'Freedom Monument, Baghdad', governorate: 'بغداد', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'نصب الشهيد', en: 'Al-Shaheed Monument, Baghdad', governorate: 'بغداد', kind: IraqPlaceKind.landmark),

  // ─── Basra ────────────────────────────────────────────────────────────────
  IraqPlace(ar: 'البصرة', en: 'Basra', governorate: 'البصرة', kind: IraqPlaceKind.governorate, aliases: ['بصرة']),
  IraqPlace(ar: 'الفاو', en: 'Al-Faw', governorate: 'البصرة', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الزبير', en: 'Al-Zubair', governorate: 'البصرة', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'القرنة', en: 'Al-Qurna', governorate: 'البصرة', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'أبو الخصيب', en: 'Abu Al-Khaseeb', governorate: 'البصرة', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'أم قصر', en: 'Umm Qasr', governorate: 'البصرة', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'شط العرب', en: 'Shatt Al-Arab, Basra', governorate: 'البصرة', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'كورنيش البصرة', en: 'Basra Corniche', governorate: 'البصرة', kind: IraqPlaceKind.landmark),

  // ─── Nineveh ──────────────────────────────────────────────────────────────
  IraqPlace(ar: 'نينوى', en: 'Mosul (Nineveh)', governorate: 'نينوى', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'الموصل', en: 'Mosul', governorate: 'نينوى', kind: IraqPlaceKind.city, aliases: ['موصل']),
  IraqPlace(ar: 'تلعفر', en: 'Tal Afar', governorate: 'نينوى', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'سنجار', en: 'Sinjar', governorate: 'نينوى', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'بعشيقة', en: 'Bashiqa', governorate: 'نينوى', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الحمدانية', en: 'Al-Hamdaniya (Qaraqosh)', governorate: 'نينوى', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'قرقوش', en: 'Qaraqosh', governorate: 'نينوى', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الشيخان', en: 'Al-Shikhan', governorate: 'نينوى', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'لالش', en: 'Lalish, Nineveh', governorate: 'نينوى', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'الحضر', en: 'Hatra', governorate: 'نينوى', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'نمرود', en: 'Nimrud', governorate: 'نينوى', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'الجامع النوري', en: 'Al-Nuri Mosque, Mosul', governorate: 'نينوى', kind: IraqPlaceKind.landmark, aliases: ['الحدباء']),

  // ─── Erbil ────────────────────────────────────────────────────────────────
  IraqPlace(ar: 'أربيل', en: 'Erbil', governorate: 'أربيل', kind: IraqPlaceKind.governorate, aliases: ['اربيل', 'هولير']),
  IraqPlace(ar: 'شقلاوة', en: 'Shaqlawa', governorate: 'أربيل', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'سوران', en: 'Soran', governorate: 'أربيل', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'كويسنجق', en: 'Koya', governorate: 'أربيل', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'راوندوز', en: 'Rawanduz', governorate: 'أربيل', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'عنكاوة', en: 'Ainkawa, Erbil', governorate: 'أربيل', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'جومان', en: 'Choman', governorate: 'أربيل', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'قلعة أربيل', en: 'Erbil Citadel', governorate: 'أربيل', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'شلال بيخال', en: 'Bekhal Waterfall', governorate: 'أربيل', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'جبل كورك', en: 'Korek Mountain', governorate: 'أربيل', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'كردستان', en: 'Erbil (Kurdistan)', governorate: 'إقليم كردستان', kind: IraqPlaceKind.governorate, aliases: ['إقليم كردستان']),

  // ─── Kirkuk ───────────────────────────────────────────────────────────────
  IraqPlace(ar: 'كركوك', en: 'Kirkuk', governorate: 'كركوك', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'الحويجة', en: 'Al-Hawija', governorate: 'كركوك', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'داقوق', en: 'Daquq', governorate: 'كركوك', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'دبس', en: 'Dibis', governorate: 'كركوك', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'قلعة كركوك', en: 'Kirkuk Citadel', governorate: 'كركوك', kind: IraqPlaceKind.landmark),

  // ─── Najaf ────────────────────────────────────────────────────────────────
  IraqPlace(ar: 'النجف', en: 'Najaf', governorate: 'النجف', kind: IraqPlaceKind.governorate, aliases: ['نجف']),
  IraqPlace(ar: 'الكوفة', en: 'Kufa', governorate: 'النجف', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'المشخاب', en: 'Al-Mishkhab', governorate: 'النجف', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'المناذرة', en: 'Al-Manathira', governorate: 'النجف', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'بحر النجف', en: 'Najaf Sea', governorate: 'النجف', kind: IraqPlaceKind.landmark),

  // ─── Karbala ──────────────────────────────────────────────────────────────
  IraqPlace(ar: 'كربلاء', en: 'Karbala', governorate: 'كربلاء', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'عين التمر', en: 'Ain Al-Tamur', governorate: 'كربلاء', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الهندية', en: 'Al-Hindiya', governorate: 'كربلاء', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'طويريج', en: 'Twairij', governorate: 'كربلاء', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'قصر الأخيضر', en: 'Al-Ukhaidir Fortress', governorate: 'كربلاء', kind: IraqPlaceKind.landmark),

  // ─── Babil ────────────────────────────────────────────────────────────────
  IraqPlace(ar: 'بابل', en: 'Babylon (Hillah)', governorate: 'بابل', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'الحلة', en: 'Hillah', governorate: 'بابل', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'المسيب', en: 'Al-Musayyib', governorate: 'بابل', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'المحاويل', en: 'Al-Mahawil', governorate: 'بابل', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الهاشمية', en: 'Al-Hashimiyah', governorate: 'بابل', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'برج بابل', en: 'Babylon Ruins', governorate: 'بابل', kind: IraqPlaceKind.landmark, aliases: ['اثار بابل', 'مدينة بابل الاثرية']),

  // ─── Anbar ────────────────────────────────────────────────────────────────
  IraqPlace(ar: 'الأنبار', en: 'Ramadi (Anbar)', governorate: 'الأنبار', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'الرمادي', en: 'Ramadi', governorate: 'الأنبار', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الفلوجة', en: 'Fallujah', governorate: 'الأنبار', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'هيت', en: 'Hit', governorate: 'الأنبار', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'حديثة', en: 'Haditha', governorate: 'الأنبار', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'القائم', en: 'Al-Qaim', governorate: 'الأنبار', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'عنة', en: 'Anah', governorate: 'الأنبار', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'راوة', en: 'Rawa', governorate: 'الأنبار', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الرطبة', en: 'Rutba', governorate: 'الأنبار', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الحبانية', en: 'Habbaniyah', governorate: 'الأنبار', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'بحيرة الحبانية', en: 'Lake Habbaniyah', governorate: 'الأنبار', kind: IraqPlaceKind.landmark),

  // ─── Dhi Qar ──────────────────────────────────────────────────────────────
  IraqPlace(ar: 'ذي قار', en: 'Nasiriyah (Dhi Qar)', governorate: 'ذي قار', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'الناصرية', en: 'Nasiriyah', governorate: 'ذي قار', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الرفاعي', en: 'Al-Rifai', governorate: 'ذي قار', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'سوق الشيوخ', en: 'Suq Al-Shuyukh', governorate: 'ذي قار', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الجبايش', en: 'Al-Chibayish', governorate: 'ذي قار', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الشطرة', en: 'Al-Shatrah', governorate: 'ذي قار', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'أور', en: 'Ur', governorate: 'ذي قار', kind: IraqPlaceKind.landmark, aliases: ['زقورة اور']),
  IraqPlace(ar: 'الأهوار', en: 'Mesopotamian Marshes', governorate: 'ذي قار', kind: IraqPlaceKind.landmark, aliases: ['اهوار العراق']),

  // ─── Maysan ───────────────────────────────────────────────────────────────
  IraqPlace(ar: 'ميسان', en: 'Amarah (Maysan)', governorate: 'ميسان', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'العمارة', en: 'Amarah', governorate: 'ميسان', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'علي الغربي', en: 'Ali Al-Gharbi', governorate: 'ميسان', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'المجر الكبير', en: 'Al-Majar Al-Kabir', governorate: 'ميسان', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'قلعة صالح', en: 'Qalat Saleh', governorate: 'ميسان', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الكحلاء', en: 'Al-Kahla', governorate: 'ميسان', kind: IraqPlaceKind.city),

  // ─── Qadisiyyah ───────────────────────────────────────────────────────────
  IraqPlace(ar: 'القادسية', en: 'Diwaniyah (Al-Qadisiyyah)', governorate: 'القادسية', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'الديوانية', en: 'Diwaniyah', governorate: 'القادسية', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'عفك', en: 'Afak', governorate: 'القادسية', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الحمزة', en: 'Al-Hamza', governorate: 'القادسية', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الشامية', en: 'Al-Shamiya', governorate: 'القادسية', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'نفر', en: 'Nippur', governorate: 'القادسية', kind: IraqPlaceKind.landmark),

  // ─── Wasit ────────────────────────────────────────────────────────────────
  IraqPlace(ar: 'واسط', en: 'Kut (Wasit)', governorate: 'واسط', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'الكوت', en: 'Kut', governorate: 'واسط', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'العزيزية', en: 'Al-Aziziyah', governorate: 'واسط', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الصويرة', en: 'Al-Suwaira', governorate: 'واسط', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الحي', en: 'Al-Hai', governorate: 'واسط', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'بدرة', en: 'Badra', governorate: 'واسط', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'النعمانية', en: 'Al-Numaniyah', governorate: 'واسط', kind: IraqPlaceKind.city),

  // ─── Muthanna ─────────────────────────────────────────────────────────────
  IraqPlace(ar: 'المثنى', en: 'Samawah (Al-Muthanna)', governorate: 'المثنى', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'السماوة', en: 'Samawah', governorate: 'المثنى', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الرميثة', en: 'Al-Rumaitha', governorate: 'المثنى', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الخضر', en: 'Al-Khidr', governorate: 'المثنى', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الوركاء', en: 'Uruk (Warka)', governorate: 'المثنى', kind: IraqPlaceKind.landmark, aliases: ['اوروك']),

  // ─── Diyala ───────────────────────────────────────────────────────────────
  IraqPlace(ar: 'ديالى', en: 'Baqubah (Diyala)', governorate: 'ديالى', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'بعقوبة', en: 'Baqubah', governorate: 'ديالى', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'خانقين', en: 'Khanaqin', governorate: 'ديالى', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'المقدادية', en: 'Al-Muqdadiyah', governorate: 'ديالى', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'بلدروز', en: 'Baladruz', governorate: 'ديالى', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'جلولاء', en: 'Jalawla', governorate: 'ديالى', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'كفري', en: 'Kifri', governorate: 'ديالى', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'مندلي', en: 'Mandali', governorate: 'ديالى', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'بحيرة حمرين', en: 'Hamrin Lake', governorate: 'ديالى', kind: IraqPlaceKind.landmark),

  // ─── Salah al-Din ─────────────────────────────────────────────────────────
  IraqPlace(ar: 'صلاح الدين', en: 'Tikrit (Salah al-Din)', governorate: 'صلاح الدين', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'تكريت', en: 'Tikrit', governorate: 'صلاح الدين', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'سامراء', en: 'Samarra', governorate: 'صلاح الدين', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'بلد', en: 'Balad', governorate: 'صلاح الدين', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'بيجي', en: 'Baiji', governorate: 'صلاح الدين', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الدجيل', en: 'Al-Dujail', governorate: 'صلاح الدين', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'طوز خورماتو', en: 'Tuz Khurmatu', governorate: 'صلاح الدين', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الشرقاط', en: 'Al-Shirqat', governorate: 'صلاح الدين', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الدور', en: 'Al-Dour', governorate: 'صلاح الدين', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الملوية', en: 'Malwiya Minaret, Samarra', governorate: 'صلاح الدين', kind: IraqPlaceKind.landmark, aliases: ['منارة الملوية']),
  IraqPlace(ar: 'آشور', en: 'Ashur (Qalat Sherqat)', governorate: 'صلاح الدين', kind: IraqPlaceKind.landmark),

  // ─── Duhok ────────────────────────────────────────────────────────────────
  IraqPlace(ar: 'دهوك', en: 'Duhok', governorate: 'دهوك', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'زاخو', en: 'Zakho', governorate: 'دهوك', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'العمادية', en: 'Amadiya', governorate: 'دهوك', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'سيميل', en: 'Sumel', governorate: 'دهوك', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'عقرة', en: 'Akre', governorate: 'دهوك', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'بردرش', en: 'Bardarash', governorate: 'دهوك', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'جسر زاخو', en: 'Delal Bridge, Zakho', governorate: 'دهوك', kind: IraqPlaceKind.landmark, aliases: ['جسر دلال']),
  IraqPlace(ar: 'سد دهوك', en: 'Duhok Dam', governorate: 'دهوك', kind: IraqPlaceKind.landmark),

  // ─── Sulaymaniyah ─────────────────────────────────────────────────────────
  IraqPlace(ar: 'السليمانية', en: 'Sulaymaniyah', governorate: 'السليمانية', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'رانية', en: 'Ranya', governorate: 'السليمانية', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'جمجمال', en: 'Chamchamal', governorate: 'السليمانية', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'كلار', en: 'Kalar', governorate: 'السليمانية', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'دربنديخان', en: 'Darbandikhan', governorate: 'السليمانية', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'دوكان', en: 'Dukan', governorate: 'السليمانية', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'بنجوين', en: 'Penjwin', governorate: 'السليمانية', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'بحيرة دوكان', en: 'Lake Dukan', governorate: 'السليمانية', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'أحمد آوا', en: 'Ahmed Awa', governorate: 'السليمانية', kind: IraqPlaceKind.landmark),

  // ─── Halabja ──────────────────────────────────────────────────────────────
  IraqPlace(ar: 'حلبجة', en: 'Halabja', governorate: 'حلبجة', kind: IraqPlaceKind.governorate),

  // ══ Beyond Iraq ═══════════════════════════════════════════════════════════
  // The destinations Iraqi travellers actually go to. `governorate` carries the
  // country name here, which is what the suggestion subtitle should read.

  // ─── Gulf ─────────────────────────────────────────────────────────────────
  IraqPlace(ar: 'مكة', en: 'Mecca', governorate: 'السعودية', kind: IraqPlaceKind.governorate, aliases: ['مكه', 'مكة المكرمة']),
  IraqPlace(ar: 'المدينة المنورة', en: 'Madinah', governorate: 'السعودية', kind: IraqPlaceKind.governorate, aliases: ['المدينه']),
  IraqPlace(ar: 'الرياض', en: 'Riyadh', governorate: 'السعودية', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'جدة', en: 'Jeddah', governorate: 'السعودية', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الدمام', en: 'Dammam', governorate: 'السعودية', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الطائف', en: 'Taif', governorate: 'السعودية', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'أبها', en: 'Abha', governorate: 'السعودية', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'العلا', en: 'AlUla', governorate: 'السعودية', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'دبي', en: 'Dubai', governorate: 'الإمارات', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'أبوظبي', en: 'Abu Dhabi', governorate: 'الإمارات', kind: IraqPlaceKind.governorate, aliases: ['ابو ظبي']),
  IraqPlace(ar: 'الشارقة', en: 'Sharjah', governorate: 'الإمارات', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'رأس الخيمة', en: 'Ras Al Khaimah', governorate: 'الإمارات', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الكويت', en: 'Kuwait City', governorate: 'الكويت', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'الدوحة', en: 'Doha', governorate: 'قطر', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'المنامة', en: 'Manama', governorate: 'البحرين', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'مسقط', en: 'Muscat', governorate: 'عُمان', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'صلالة', en: 'Salalah', governorate: 'عُمان', kind: IraqPlaceKind.city),

  // ─── Levant ───────────────────────────────────────────────────────────────
  IraqPlace(ar: 'دمشق', en: 'Damascus', governorate: 'سوريا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'حلب', en: 'Aleppo', governorate: 'سوريا', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'اللاذقية', en: 'Latakia', governorate: 'سوريا', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'حمص', en: 'Homs', governorate: 'سوريا', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'طرطوس', en: 'Tartus', governorate: 'سوريا', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'تدمر', en: 'Palmyra', governorate: 'سوريا', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'السيدة زينب', en: 'Sayyidah Zaynab, Damascus', governorate: 'سوريا', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'بيروت', en: 'Beirut', governorate: 'لبنان', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'طرابلس لبنان', en: 'Tripoli, Lebanon', governorate: 'لبنان', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'بعلبك', en: 'Baalbek', governorate: 'لبنان', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'جبيل', en: 'Byblos', governorate: 'لبنان', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'عمان', en: 'Amman', governorate: 'الأردن', kind: IraqPlaceKind.governorate, aliases: ['عمّان']),
  IraqPlace(ar: 'العقبة', en: 'Aqaba', governorate: 'الأردن', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'البتراء', en: 'Petra', governorate: 'الأردن', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'جرش', en: 'Jerash', governorate: 'الأردن', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'البحر الميت', en: 'Dead Sea', governorate: 'الأردن', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'القدس', en: 'Jerusalem', governorate: 'فلسطين', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'المسجد الأقصى', en: 'Al-Aqsa Mosque, Jerusalem', governorate: 'فلسطين', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'بيت لحم', en: 'Bethlehem', governorate: 'فلسطين', kind: IraqPlaceKind.city),

  // ─── Egypt & North Africa ─────────────────────────────────────────────────
  IraqPlace(ar: 'القاهرة', en: 'Cairo', governorate: 'مصر', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'الإسكندرية', en: 'Alexandria', governorate: 'مصر', kind: IraqPlaceKind.city, aliases: ['اسكندرية']),
  IraqPlace(ar: 'الأقصر', en: 'Luxor', governorate: 'مصر', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'أسوان', en: 'Aswan', governorate: 'مصر', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'شرم الشيخ', en: 'Sharm El Sheikh', governorate: 'مصر', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الغردقة', en: 'Hurghada', governorate: 'مصر', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الأهرامات', en: 'Pyramids of Giza', governorate: 'مصر', kind: IraqPlaceKind.landmark, aliases: ['اهرامات الجيزة', 'الجيزة']),
  IraqPlace(ar: 'مراكش', en: 'Marrakech', governorate: 'المغرب', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'الدار البيضاء', en: 'Casablanca', governorate: 'المغرب', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'فاس', en: 'Fez', governorate: 'المغرب', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'طنجة', en: 'Tangier', governorate: 'المغرب', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'تونس', en: 'Tunis', governorate: 'تونس', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'الجزائر', en: 'Algiers', governorate: 'الجزائر', kind: IraqPlaceKind.governorate),

  // ─── Türkiye & Iran ───────────────────────────────────────────────────────
  IraqPlace(ar: 'إسطنبول', en: 'Istanbul', governorate: 'تركيا', kind: IraqPlaceKind.governorate, aliases: ['استنبول', 'اسطنبول']),
  IraqPlace(ar: 'أنقرة', en: 'Ankara', governorate: 'تركيا', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'طرابزون', en: 'Trabzon', governorate: 'تركيا', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'أنطاليا', en: 'Antalya', governorate: 'تركيا', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'بورصة', en: 'Bursa', governorate: 'تركيا', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'إزمير', en: 'Izmir', governorate: 'تركيا', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'يلوا', en: 'Yalova', governorate: 'تركيا', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'صبنجة', en: 'Sapanca', governorate: 'تركيا', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'كابادوكيا', en: 'Cappadocia', governorate: 'تركيا', kind: IraqPlaceKind.landmark, aliases: ['كبادوكيا']),
  IraqPlace(ar: 'آيا صوفيا', en: 'Hagia Sophia, Istanbul', governorate: 'تركيا', kind: IraqPlaceKind.landmark, aliases: ['ايا صوفيا']),
  IraqPlace(ar: 'مشهد', en: 'Mashhad', governorate: 'إيران', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'طهران', en: 'Tehran', governorate: 'إيران', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'قم', en: 'Qom', governorate: 'إيران', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'شيراز', en: 'Shiraz', governorate: 'إيران', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'أصفهان', en: 'Isfahan', governorate: 'إيران', kind: IraqPlaceKind.city, aliases: ['اصفهان']),

  // ═══════════════════════════════════════════════════════════════════════════
  // Neighbouring countries — provinces, their main cities, and the landmarks
  // people actually search for. Every Arabic name below MUST also exist in
  // server.js's AR_CITY_DICTIONARY: `_pickSuggestion` puts `ar` in the input
  // box, and a name the server can't resolve from that zero-cost dictionary
  // falls through to a Google Places lookup — and the Places free tier is only
  // 100 searches/day. test/places_dictionary_sync_test.dart enforces the pair.
  // ═══════════════════════════════════════════════════════════════════════════

  // ─── Türkiye — provinces ───────────────────────────────────────────────────
  IraqPlace(ar: 'غازي عنتاب', en: 'Gaziantep', governorate: 'تركيا', kind: IraqPlaceKind.governorate, aliases: ['عنتاب']),
  IraqPlace(ar: 'شانلي أورفا', en: 'Sanliurfa', governorate: 'تركيا', kind: IraqPlaceKind.governorate, aliases: ['اورفا', 'الرها']),
  IraqPlace(ar: 'ماردين', en: 'Mardin', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'ديار بكر', en: 'Diyarbakir', governorate: 'تركيا', kind: IraqPlaceKind.governorate, aliases: ['ديياربكر']),
  IraqPlace(ar: 'وان', en: 'Van', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'قونيا', en: 'Konya', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'قيصري', en: 'Kayseri', governorate: 'تركيا', kind: IraqPlaceKind.governorate, aliases: ['كايسيري']),
  IraqPlace(ar: 'نوشهر', en: 'Nevsehir', governorate: 'تركيا', kind: IraqPlaceKind.governorate, aliases: ['نيفشهير']),
  IraqPlace(ar: 'مرسين', en: 'Mersin', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'أضنة', en: 'Adana', governorate: 'تركيا', kind: IraqPlaceKind.governorate, aliases: ['اضنة', 'أدنة']),
  IraqPlace(ar: 'هطاي', en: 'Hatay', governorate: 'تركيا', kind: IraqPlaceKind.governorate, aliases: ['انطاكيا', 'أنطاكية']),
  IraqPlace(ar: 'موغلا', en: 'Mugla', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'دنيزلي', en: 'Denizli', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'سقاريا', en: 'Sakarya', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'كوجالي', en: 'Kocaeli', governorate: 'تركيا', kind: IraqPlaceKind.governorate, aliases: ['ازميت']),
  IraqPlace(ar: 'ريزا', en: 'Rize', governorate: 'تركيا', kind: IraqPlaceKind.governorate, aliases: ['ريزه']),
  IraqPlace(ar: 'سامسون', en: 'Samsun', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'أرضروم', en: 'Erzurum', governorate: 'تركيا', kind: IraqPlaceKind.governorate, aliases: ['ارضروم']),
  IraqPlace(ar: 'ملاطية', en: 'Malatya', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'باتمان', en: 'Batman', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'شرناق', en: 'Sirnak', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'هكاري', en: 'Hakkari', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'بولو', en: 'Bolu', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'إسكي شهر', en: 'Eskisehir', governorate: 'تركيا', kind: IraqPlaceKind.governorate, aliases: ['اسكي شهر']),
  IraqPlace(ar: 'باليكسير', en: 'Balikesir', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'آيدن', en: 'Aydin', governorate: 'تركيا', kind: IraqPlaceKind.governorate, aliases: ['ايدن']),
  IraqPlace(ar: 'تشاناكالي', en: 'Canakkale', governorate: 'تركيا', kind: IraqPlaceKind.governorate, aliases: ['جناق قلعة']),
  IraqPlace(ar: 'أدرنة', en: 'Edirne', governorate: 'تركيا', kind: IraqPlaceKind.governorate, aliases: ['ادرنة']),
  IraqPlace(ar: 'سيواس', en: 'Sivas', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'إلازيغ', en: 'Elazig', governorate: 'تركيا', kind: IraqPlaceKind.governorate, aliases: ['الازيغ']),
  IraqPlace(ar: 'أوردو', en: 'Ordu', governorate: 'تركيا', kind: IraqPlaceKind.governorate, aliases: ['اوردو']),
  IraqPlace(ar: 'غيرسون', en: 'Giresun', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'أرتفين', en: 'Artvin', governorate: 'تركيا', kind: IraqPlaceKind.governorate, aliases: ['ارتفين']),
  IraqPlace(ar: 'قارص', en: 'Kars', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'آغري', en: 'Agri', governorate: 'تركيا', kind: IraqPlaceKind.governorate, aliases: ['اغري']),
  IraqPlace(ar: 'إسبارطة', en: 'Isparta', governorate: 'تركيا', kind: IraqPlaceKind.governorate, aliases: ['اسبارطة']),
  IraqPlace(ar: 'أفيون', en: 'Afyonkarahisar', governorate: 'تركيا', kind: IraqPlaceKind.governorate, aliases: ['افيون']),
  IraqPlace(ar: 'كوتاهيا', en: 'Kutahya', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'مانيسا', en: 'Manisa', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'كهرمان مرعش', en: 'Kahramanmaras', governorate: 'تركيا', kind: IraqPlaceKind.governorate, aliases: ['مرعش']),
  IraqPlace(ar: 'تكيرداغ', en: 'Tekirdag', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'زونغولداك', en: 'Zonguldak', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'أماسيا', en: 'Amasya', governorate: 'تركيا', kind: IraqPlaceKind.governorate, aliases: ['اماسيا']),
  IraqPlace(ar: 'توكات', en: 'Tokat', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'تشوروم', en: 'Corum', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'كاستامونو', en: 'Kastamonu', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'سينوب', en: 'Sinop', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'يوزغات', en: 'Yozgat', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'كير شهير', en: 'Kirsehir', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'أكسراي', en: 'Aksaray', governorate: 'تركيا', kind: IraqPlaceKind.governorate, aliases: ['اكسراي']),
  IraqPlace(ar: 'نيغدة', en: 'Nigde', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'كارامان', en: 'Karaman', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'بوردور', en: 'Burdur', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'أوشاك', en: 'Usak', governorate: 'تركيا', kind: IraqPlaceKind.governorate, aliases: ['اوشاك']),
  IraqPlace(ar: 'بيلجيك', en: 'Bilecik', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'بارتين', en: 'Bartin', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'كارابوك', en: 'Karabuk', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'دوزجة', en: 'Duzce', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'عثمانية', en: 'Osmaniye', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'كلس', en: 'Kilis', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'أديامان', en: 'Adiyaman', governorate: 'تركيا', kind: IraqPlaceKind.governorate, aliases: ['اديامان']),
  IraqPlace(ar: 'سعرت', en: 'Siirt', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'بتليس', en: 'Bitlis', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'موش', en: 'Mus', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'بينغول', en: 'Bingol', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'تونجلي', en: 'Tunceli', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'أرزنجان', en: 'Erzincan', governorate: 'تركيا', kind: IraqPlaceKind.governorate, aliases: ['ارزنجان']),
  IraqPlace(ar: 'بايبورت', en: 'Bayburt', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'غوموشهانة', en: 'Gumushane', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'إغدير', en: 'Igdir', governorate: 'تركيا', kind: IraqPlaceKind.governorate, aliases: ['اغدير']),
  IraqPlace(ar: 'أردهان', en: 'Ardahan', governorate: 'تركيا', kind: IraqPlaceKind.governorate, aliases: ['اردهان']),
  IraqPlace(ar: 'قرقلاريلي', en: 'Kirklareli', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'تشانكيري', en: 'Cankiri', governorate: 'تركيا', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'كيريك قلعة', en: 'Kirikkale', governorate: 'تركيا', kind: IraqPlaceKind.governorate),

  // ─── Türkiye — resort towns & landmarks ────────────────────────────────────
  IraqPlace(ar: 'بودروم', en: 'Bodrum', governorate: 'تركيا', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'فتحية', en: 'Fethiye', governorate: 'تركيا', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'مرمريس', en: 'Marmaris', governorate: 'تركيا', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'كوشاداسي', en: 'Kusadasi', governorate: 'تركيا', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'ألانيا', en: 'Alanya', governorate: 'تركيا', kind: IraqPlaceKind.city, aliases: ['الانيا']),
  IraqPlace(ar: 'سيدا', en: 'Side', governorate: 'تركيا', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'كيمر', en: 'Kemer', governorate: 'تركيا', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'بيليك', en: 'Belek', governorate: 'تركيا', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'كاش', en: 'Kas', governorate: 'تركيا', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'ديديم', en: 'Didim', governorate: 'تركيا', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'تشيشمة', en: 'Cesme', governorate: 'تركيا', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'شيلة', en: 'Sile', governorate: 'تركيا', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'باموكالي', en: 'Pamukkale', governorate: 'تركيا', kind: IraqPlaceKind.landmark, aliases: ['باموق كالي']),
  IraqPlace(ar: 'أوزنجول', en: 'Uzungol', governorate: 'تركيا', kind: IraqPlaceKind.landmark, aliases: ['اوزنجول']),
  IraqPlace(ar: 'أبانت', en: 'Abant', governorate: 'تركيا', kind: IraqPlaceKind.landmark, aliases: ['ابانت']),
  IraqPlace(ar: 'أولودنيز', en: 'Oludeniz', governorate: 'تركيا', kind: IraqPlaceKind.landmark, aliases: ['اولودنيز']),
  IraqPlace(ar: 'غوريمة', en: 'Goreme', governorate: 'تركيا', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'السلطان أحمد', en: 'Sultanahmet, Istanbul', governorate: 'تركيا', kind: IraqPlaceKind.landmark, aliases: ['سلطان احمد']),
  IraqPlace(ar: 'تقسيم', en: 'Taksim, Istanbul', governorate: 'تركيا', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'برج غلطة', en: 'Galata Tower, Istanbul', governorate: 'تركيا', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'المسجد الأزرق', en: 'Blue Mosque, Istanbul', governorate: 'تركيا', kind: IraqPlaceKind.landmark, aliases: ['الجامع الازرق']),
  IraqPlace(ar: 'قصر توبكابي', en: 'Topkapi Palace, Istanbul', governorate: 'تركيا', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'مضيق البوسفور', en: 'Bosphorus, Istanbul', governorate: 'تركيا', kind: IraqPlaceKind.landmark, aliases: ['البوسفور']),
  IraqPlace(ar: 'جزر الأميرات', en: "Princes' Islands, Istanbul", governorate: 'تركيا', kind: IraqPlaceKind.landmark, aliases: ['جزر الاميرات']),
  IraqPlace(ar: 'تشامليجا', en: 'Camlica, Istanbul', governorate: 'تركيا', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'برج الفتاة', en: "Maiden's Tower, Istanbul", governorate: 'تركيا', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'قصر دولمة بهجة', en: 'Dolmabahce Palace, Istanbul', governorate: 'تركيا', kind: IraqPlaceKind.landmark, aliases: ['دولمة بهجة']),
  IraqPlace(ar: 'أفسس', en: 'Ephesus', governorate: 'تركيا', kind: IraqPlaceKind.landmark, aliases: ['افسس']),
  IraqPlace(ar: 'جبل نمرود', en: 'Mount Nemrut', governorate: 'تركيا', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'دير سوميلا', en: 'Sumela Monastery', governorate: 'تركيا', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'أولوداغ', en: 'Uludag', governorate: 'تركيا', kind: IraqPlaceKind.landmark, aliases: ['اولوداغ']),

  // ─── Iran — provinces & main cities ────────────────────────────────────────
  IraqPlace(ar: 'تبريز', en: 'Tabriz', governorate: 'إيران', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'أرومية', en: 'Urmia', governorate: 'إيران', kind: IraqPlaceKind.governorate, aliases: ['اورمية']),
  IraqPlace(ar: 'أردبيل', en: 'Ardabil', governorate: 'إيران', kind: IraqPlaceKind.governorate, aliases: ['اردبيل']),
  IraqPlace(ar: 'كرج', en: 'Karaj', governorate: 'إيران', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'الأهواز', en: 'Ahvaz', governorate: 'إيران', kind: IraqPlaceKind.governorate, aliases: ['الاهواز', 'اهواز']),
  IraqPlace(ar: 'كرمانشاه', en: 'Kermanshah', governorate: 'إيران', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'إيلام', en: 'Ilam', governorate: 'إيران', kind: IraqPlaceKind.governorate, aliases: ['ايلام']),
  IraqPlace(ar: 'همدان', en: 'Hamadan', governorate: 'إيران', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'سنندج', en: 'Sanandaj', governorate: 'إيران', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'رشت', en: 'Rasht', governorate: 'إيران', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'ساري', en: 'Sari', governorate: 'إيران', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'غورغان', en: 'Gorgan', governorate: 'إيران', kind: IraqPlaceKind.governorate, aliases: ['كركان']),
  IraqPlace(ar: 'سمنان', en: 'Semnan', governorate: 'إيران', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'يزد', en: 'Yazd', governorate: 'إيران', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'كرمان', en: 'Kerman', governorate: 'إيران', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'بندر عباس', en: 'Bandar Abbas', governorate: 'إيران', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'زاهدان', en: 'Zahedan', governorate: 'إيران', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'بيرجند', en: 'Birjand', governorate: 'إيران', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'بجنورد', en: 'Bojnord', governorate: 'إيران', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'أراك', en: 'Arak', governorate: 'إيران', kind: IraqPlaceKind.governorate, aliases: ['اراك']),
  IraqPlace(ar: 'قزوين', en: 'Qazvin', governorate: 'إيران', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'زنجان', en: 'Zanjan', governorate: 'إيران', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'خرم آباد', en: 'Khorramabad', governorate: 'إيران', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'شهر كرد', en: 'Shahrekord', governorate: 'إيران', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'ياسوج', en: 'Yasuj', governorate: 'إيران', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'بوشهر', en: 'Bushehr', governorate: 'إيران', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'عبادان', en: 'Abadan', governorate: 'إيران', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'المحمرة', en: 'Khorramshahr', governorate: 'إيران', kind: IraqPlaceKind.city, aliases: ['خرمشهر']),
  IraqPlace(ar: 'دزفول', en: 'Dezful', governorate: 'إيران', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'جزيرة كيش', en: 'Kish Island', governorate: 'إيران', kind: IraqPlaceKind.city, aliases: ['كيش']),
  IraqPlace(ar: 'قشم', en: 'Qeshm', governorate: 'إيران', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'رامسر', en: 'Ramsar', governorate: 'إيران', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'چالوس', en: 'Chalus', governorate: 'إيران', kind: IraqPlaceKind.city, aliases: ['چالوس', 'شالوس']),
  IraqPlace(ar: 'برسبوليس', en: 'Persepolis', governorate: 'إيران', kind: IraqPlaceKind.landmark, aliases: ['تخت جمشيد']),
  IraqPlace(ar: 'ماسوله', en: 'Masuleh', governorate: 'إيران', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'كندوان', en: 'Kandovan', governorate: 'إيران', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'ساحة نقش جهان', en: 'Naqsh-e Jahan Square, Isfahan', governorate: 'إيران', kind: IraqPlaceKind.landmark, aliases: ['نقش جهان']),
  IraqPlace(ar: 'حرم الإمام الرضا', en: 'Imam Reza Shrine, Mashhad', governorate: 'إيران', kind: IraqPlaceKind.landmark, aliases: ['حرم الامام الرضا']),
  IraqPlace(ar: 'برج ميلاد', en: 'Milad Tower, Tehran', governorate: 'إيران', kind: IraqPlaceKind.landmark),

  // ─── Jordan — all 12 governorates + landmarks ──────────────────────────────
  IraqPlace(ar: 'إربد', en: 'Irbid', governorate: 'الأردن', kind: IraqPlaceKind.governorate, aliases: ['اربد']),
  IraqPlace(ar: 'الزرقاء', en: 'Zarqa', governorate: 'الأردن', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'البلقاء', en: 'Balqa', governorate: 'الأردن', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'السلط', en: 'As-Salt', governorate: 'الأردن', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'مادبا', en: 'Madaba', governorate: 'الأردن', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'الكرك', en: 'Karak', governorate: 'الأردن', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'الطفيلة', en: 'Tafilah', governorate: 'الأردن', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'معان', en: "Ma'an", governorate: 'الأردن', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'عجلون', en: 'Ajloun', governorate: 'الأردن', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'المفرق', en: 'Mafraq', governorate: 'الأردن', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'وادي رم', en: 'Wadi Rum', governorate: 'الأردن', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'قلعة عجلون', en: 'Ajloun Castle', governorate: 'الأردن', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'جبل نيبو', en: 'Mount Nebo', governorate: 'الأردن', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'أم قيس', en: 'Umm Qais', governorate: 'الأردن', kind: IraqPlaceKind.landmark, aliases: ['ام قيس']),
  IraqPlace(ar: 'محمية ضانا', en: 'Dana Reserve', governorate: 'الأردن', kind: IraqPlaceKind.landmark, aliases: ['ضانا']),

  // ─── Saudi Arabia — all 13 regions + main cities ───────────────────────────
  IraqPlace(ar: 'المنطقة الشرقية', en: 'Eastern Province', governorate: 'السعودية', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'تبوك', en: 'Tabuk', governorate: 'السعودية', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'حائل', en: 'Hail', governorate: 'السعودية', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'عرعر', en: 'Arar', governorate: 'السعودية', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'جازان', en: 'Jazan', governorate: 'السعودية', kind: IraqPlaceKind.governorate, aliases: ['جيزان']),
  IraqPlace(ar: 'نجران', en: 'Najran', governorate: 'السعودية', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'الباحة', en: 'Al Bahah', governorate: 'السعودية', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'سكاكا', en: 'Sakaka', governorate: 'السعودية', kind: IraqPlaceKind.governorate, aliases: ['الجوف']),
  IraqPlace(ar: 'بريدة', en: 'Buraidah', governorate: 'السعودية', kind: IraqPlaceKind.governorate, aliases: ['القصيم']),
  IraqPlace(ar: 'الخبر', en: 'Khobar', governorate: 'السعودية', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الظهران', en: 'Dhahran', governorate: 'السعودية', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الجبيل', en: 'Jubail', governorate: 'السعودية', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'ينبع', en: 'Yanbu', governorate: 'السعودية', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'حفر الباطن', en: 'Hafar Al-Batin', governorate: 'السعودية', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الأحساء', en: 'Al-Ahsa', governorate: 'السعودية', kind: IraqPlaceKind.city, aliases: ['الاحساء', 'الهفوف']),
  IraqPlace(ar: 'القطيف', en: 'Qatif', governorate: 'السعودية', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'عنيزة', en: 'Unaizah', governorate: 'السعودية', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'خميس مشيط', en: 'Khamis Mushait', governorate: 'السعودية', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الخرج', en: 'Al-Kharj', governorate: 'السعودية', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الدرعية', en: 'Diriyah', governorate: 'السعودية', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'أملج', en: 'Umluj', governorate: 'السعودية', kind: IraqPlaceKind.city, aliases: ['املج']),
  IraqPlace(ar: 'نيوم', en: 'NEOM', governorate: 'السعودية', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'جزر فرسان', en: 'Farasan Islands', governorate: 'السعودية', kind: IraqPlaceKind.landmark, aliases: ['فرسان']),
  IraqPlace(ar: 'رجال ألمع', en: 'Rijal Almaa', governorate: 'السعودية', kind: IraqPlaceKind.landmark, aliases: ['رجال الماع']),
  IraqPlace(ar: 'حافة العالم', en: 'Edge of the World, Riyadh', governorate: 'السعودية', kind: IraqPlaceKind.landmark),

  // ─── United Arab Emirates — all 7 emirates ─────────────────────────────────
  IraqPlace(ar: 'عجمان', en: 'Ajman', governorate: 'الإمارات', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'أم القيوين', en: 'Umm Al Quwain', governorate: 'الإمارات', kind: IraqPlaceKind.governorate, aliases: ['ام القيوين']),
  IraqPlace(ar: 'الفجيرة', en: 'Fujairah', governorate: 'الإمارات', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'العين', en: 'Al Ain', governorate: 'الإمارات', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'خورفكان', en: 'Khor Fakkan', governorate: 'الإمارات', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'حتا', en: 'Hatta', governorate: 'الإمارات', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'دبا', en: 'Dibba', governorate: 'الإمارات', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'ليوا', en: 'Liwa Oasis', governorate: 'الإمارات', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'برج خليفة', en: 'Burj Khalifa, Dubai', governorate: 'الإمارات', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'جامع الشيخ زايد', en: 'Sheikh Zayed Grand Mosque, Abu Dhabi', governorate: 'الإمارات', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'نخلة جميرا', en: 'Palm Jumeirah, Dubai', governorate: 'الإمارات', kind: IraqPlaceKind.landmark, aliases: ['النخلة']),
  IraqPlace(ar: 'دبي مول', en: 'Dubai Mall', governorate: 'الإمارات', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'لوفر أبوظبي', en: 'Louvre Abu Dhabi', governorate: 'الإمارات', kind: IraqPlaceKind.landmark, aliases: ['لوفر ابوظبي']),
  IraqPlace(ar: 'عالم فيراري', en: 'Ferrari World, Abu Dhabi', governorate: 'الإمارات', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'القرية العالمية', en: 'Global Village, Dubai', governorate: 'الإمارات', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'برواز دبي', en: 'Dubai Frame', governorate: 'الإمارات', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'متحف المستقبل', en: 'Museum of the Future, Dubai', governorate: 'الإمارات', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'جبل جيس', en: 'Jebel Jais', governorate: 'الإمارات', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'جزيرة ياس', en: 'Yas Island, Abu Dhabi', governorate: 'الإمارات', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'السعديات', en: 'Saadiyat Island, Abu Dhabi', governorate: 'الإمارات', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'مرسى دبي', en: 'Dubai Marina', governorate: 'الإمارات', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'جميرا', en: 'Jumeirah, Dubai', governorate: 'الإمارات', kind: IraqPlaceKind.landmark),

  // ─── Kuwait — all 6 governorates ───────────────────────────────────────────
  IraqPlace(ar: 'حولي', en: 'Hawalli', governorate: 'الكويت', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'الفروانية', en: 'Farwaniya', governorate: 'الكويت', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'مبارك الكبير', en: 'Mubarak Al-Kabeer', governorate: 'الكويت', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'الأحمدي', en: 'Ahmadi', governorate: 'الكويت', kind: IraqPlaceKind.governorate, aliases: ['الاحمدي']),
  IraqPlace(ar: 'الجهراء', en: 'Jahra', governorate: 'الكويت', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'السالمية', en: 'Salmiya', governorate: 'الكويت', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الفحيحيل', en: 'Fahaheel', governorate: 'الكويت', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'جزيرة فيلكا', en: 'Failaka Island', governorate: 'الكويت', kind: IraqPlaceKind.landmark, aliases: ['فيلكا']),
  IraqPlace(ar: 'أبراج الكويت', en: 'Kuwait Towers', governorate: 'الكويت', kind: IraqPlaceKind.landmark, aliases: ['ابراج الكويت']),
  IraqPlace(ar: 'الأفنيوز', en: 'The Avenues, Kuwait', governorate: 'الكويت', kind: IraqPlaceKind.landmark, aliases: ['الافنيوز']),

  // ─── Qatar — municipalities & landmarks ────────────────────────────────────
  IraqPlace(ar: 'الريان', en: 'Al Rayyan', governorate: 'قطر', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'الوكرة', en: 'Al Wakrah', governorate: 'قطر', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'الخور', en: 'Al Khor', governorate: 'قطر', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'أم صلال', en: 'Umm Salal', governorate: 'قطر', kind: IraqPlaceKind.governorate, aliases: ['ام صلال']),
  IraqPlace(ar: 'الظعاين', en: 'Al Daayen', governorate: 'قطر', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'الشحانية', en: 'Al Shahaniya', governorate: 'قطر', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'مسيعيد', en: 'Mesaieed', governorate: 'قطر', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'دخان', en: 'Dukhan', governorate: 'قطر', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'لوسيل', en: 'Lusail', governorate: 'قطر', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'سوق واقف', en: 'Souq Waqif, Doha', governorate: 'قطر', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'اللؤلؤة', en: 'The Pearl, Doha', governorate: 'قطر', kind: IraqPlaceKind.landmark, aliases: ['اللؤلؤه']),
  IraqPlace(ar: 'كتارا', en: 'Katara, Doha', governorate: 'قطر', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'متحف الفن الإسلامي', en: 'Museum of Islamic Art, Doha', governorate: 'قطر', kind: IraqPlaceKind.landmark, aliases: ['متحف الفن الاسلامي']),
  IraqPlace(ar: 'خور العديد', en: 'Khor Al Adaid', governorate: 'قطر', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'قلعة الزبارة', en: 'Al Zubarah Fort', governorate: 'قطر', kind: IraqPlaceKind.landmark, aliases: ['الزبارة']),

  // ─── Bahrain — all 4 governorates ──────────────────────────────────────────
  IraqPlace(ar: 'المحرق', en: 'Muharraq', governorate: 'البحرين', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'المحافظة الشمالية', en: 'Northern Governorate, Bahrain', governorate: 'البحرين', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'المحافظة الجنوبية', en: 'Southern Governorate, Bahrain', governorate: 'البحرين', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'الرفاع', en: 'Riffa', governorate: 'البحرين', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'مدينة عيسى', en: 'Isa Town', governorate: 'البحرين', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'مدينة حمد', en: 'Hamad Town', governorate: 'البحرين', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'سترة', en: 'Sitra', governorate: 'البحرين', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'البديع', en: 'Budaiya', governorate: 'البحرين', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'الجفير', en: 'Juffair', governorate: 'البحرين', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'السيف', en: 'Seef, Manama', governorate: 'البحرين', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'أمواج', en: 'Amwaj Islands', governorate: 'البحرين', kind: IraqPlaceKind.landmark, aliases: ['امواج']),
  IraqPlace(ar: 'درة البحرين', en: 'Durrat Al Bahrain', governorate: 'البحرين', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'قلعة البحرين', en: 'Qal\'at al-Bahrain', governorate: 'البحرين', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'شجرة الحياة', en: 'Tree of Life, Bahrain', governorate: 'البحرين', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'مسجد الفاتح', en: 'Al Fateh Grand Mosque, Manama', governorate: 'البحرين', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'حلبة البحرين', en: 'Bahrain International Circuit', governorate: 'البحرين', kind: IraqPlaceKind.landmark),

  // ─── Oman — all 11 governorates ────────────────────────────────────────────
  IraqPlace(ar: 'ظفار', en: 'Dhofar', governorate: 'عُمان', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'مسندم', en: 'Musandam', governorate: 'عُمان', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'خصب', en: 'Khasab', governorate: 'عُمان', kind: IraqPlaceKind.city),
  IraqPlace(ar: 'صحار', en: 'Sohar', governorate: 'عُمان', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'الرستاق', en: 'Rustaq', governorate: 'عُمان', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'نزوى', en: 'Nizwa', governorate: 'عُمان', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'إبراء', en: 'Ibra', governorate: 'عُمان', kind: IraqPlaceKind.governorate, aliases: ['ابراء']),
  IraqPlace(ar: 'صور', en: 'Sur', governorate: 'عُمان', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'عبري', en: 'Ibri', governorate: 'عُمان', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'البريمي', en: 'Al Buraimi', governorate: 'عُمان', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'هيما', en: 'Haima', governorate: 'عُمان', kind: IraqPlaceKind.governorate),
  IraqPlace(ar: 'الجبل الأخضر', en: 'Jebel Akhdar', governorate: 'عُمان', kind: IraqPlaceKind.landmark, aliases: ['الجبل الاخضر']),
  IraqPlace(ar: 'جبل شمس', en: 'Jebel Shams', governorate: 'عُمان', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'وادي شاب', en: 'Wadi Shab', governorate: 'عُمان', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'رمال وهيبة', en: 'Wahiba Sands', governorate: 'عُمان', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'هوية نجم', en: 'Bimmah Sinkhole', governorate: 'عُمان', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'جامع السلطان قابوس', en: 'Sultan Qaboos Grand Mosque, Muscat', governorate: 'عُمان', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'سوق مطرح', en: 'Mutrah Souq, Muscat', governorate: 'عُمان', kind: IraqPlaceKind.landmark, aliases: ['مطرح']),
  IraqPlace(ar: 'قلعة نزوى', en: 'Nizwa Fort', governorate: 'عُمان', kind: IraqPlaceKind.landmark),
  IraqPlace(ar: 'قلعة بهلاء', en: 'Bahla Fort', governorate: 'عُمان', kind: IraqPlaceKind.landmark, aliases: ['بهلاء']),
  IraqPlace(ar: 'جزيرة مصيرة', en: 'Masirah Island', governorate: 'عُمان', kind: IraqPlaceKind.landmark, aliases: ['مصيرة']),
];
