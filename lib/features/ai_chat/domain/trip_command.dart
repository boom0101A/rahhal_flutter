/// Recognises the handful of things a user can ask the assistant to *do* to
/// their itinerary, as opposed to ask about.
///
/// Parsing happens locally in Dart rather than by asking the model to emit a
/// command, for three reasons: it is deterministic (the same sentence always
/// means the same thing), it is testable, and it costs nothing against the
/// Groq token budget — which is already the app's tightest constraint.
///
/// Anything not confidently recognised returns null and is treated as an
/// ordinary question. Guessing here would mean deleting someone's day.
library;

enum TripCommandKind { deleteDay, deleteStop, markVisited, swapStop }

class TripCommand {
  final TripCommandKind kind;

  /// For [TripCommandKind.deleteDay].
  final int? dayNumber;

  /// Place name for stop-level commands.
  final String? target;

  const TripCommand({required this.kind, this.dayNumber, this.target});

  @override
  String toString() => 'TripCommand($kind, day=$dayNumber, target=$target)';
}

/// A real, nearby place found to replace a stop for [TripCommandKind.swapStop].
/// Populated during preview, once a candidate has actually been looked up —
/// never guessed or fabricated.
class SwapCandidate {
  final String name;
  final String nameEn;
  final String address;
  final String category;
  final double lat;
  final double lng;
  final String? placeId;

  const SwapCandidate({
    required this.name,
    required this.nameEn,
    required this.address,
    required this.category,
    required this.lat,
    required this.lng,
    this.placeId,
  });
}

/// Returns a command when the text unambiguously asks for one, else null.
TripCommand? parseTripCommand(String input) {
  final text = _normalize(input);
  if (text.isEmpty) return null;

  final isReplace = _hasAny(text, _replaceVerbs);
  final isDelete = _hasAny(text, _deleteVerbs);
  final isVisited = _hasAny(text, _visitedVerbs);

  // "swap X" / "بدّل المطعم الفلاني" — checked first so a replace verb never
  // gets misread as a delete.
  if (isReplace) {
    final target = _extractTarget(text, _replaceVerbs);
    if (target != null) {
      return TripCommand(kind: TripCommandKind.swapStop, target: target);
    }
    return null;
  }

  // "delete day 3" / "احذف اليوم الثالث"
  if (isDelete && _hasAny(text, _dayWords)) {
    final day = _extractNumber(text);
    if (day != null && day > 0) {
      return TripCommand(kind: TripCommandKind.deleteDay, dayNumber: day);
    }
    // "delete the day" with no number is ambiguous — refuse rather than pick.
    return null;
  }

  if (isDelete) {
    final target = _extractTarget(text, _deleteVerbs);
    if (target != null) {
      return TripCommand(kind: TripCommandKind.deleteStop, target: target);
    }
    return null;
  }

  if (isVisited) {
    final target = _extractTarget(text, _visitedVerbs);
    if (target != null) {
      return TripCommand(kind: TripCommandKind.markVisited, target: target);
    }
    return null;
  }

  return null;
}

// ─── internals ──────────────────────────────────────────────────────────────

String _normalize(String s) {
  var t = s.trim().toLowerCase();
  t = t.replaceAll(RegExp('[ً-ْـ]'), ''); // Arabic diacritics + tatweel
  t = t.replaceAll(RegExp('[أإآٱ]'), 'ا');
  t = t.replaceAll('ة', 'ه');
  t = t.replaceAll('ى', 'ي');
  // Arabic-Indic digits → Latin, so "٣" and "3" behave identically.
  const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
  for (var i = 0; i < arabicDigits.length; i++) {
    t = t.replaceAll(arabicDigits[i], '$i');
  }
  return t.replaceAll(RegExp(r'\s+'), ' ').trim();
}

const _replaceVerbs = ['بدل', 'استبدل', 'غير لي', 'replace', 'swap'];
const _deleteVerbs = ['احذف', 'حذف', 'الغي', 'الغاء', 'شيل', 'ازل', 'remove', 'delete', 'cancel'];
const _visitedVerbs = ['زرت', 'زرته', 'زرنا', 'تم زياره', 'علم', 'visited', 'mark visited', 'been to'];
const _dayWords = ['اليوم', 'يوم', 'day'];

bool _hasAny(String text, List<String> needles) =>
    needles.any((n) => text.contains(n));

/// Digits, Arabic ordinals, or English number words.
int? _extractNumber(String text) {
  final digit = RegExp(r'\d+').firstMatch(text);
  if (digit != null) return int.tryParse(digit.group(0)!);

  const ordinals = {
    'الاول': 1, 'اول': 1, 'first': 1,
    'الثاني': 2, 'ثاني': 2, 'second': 2,
    'الثالث': 3, 'ثالث': 3, 'third': 3,
    'الرابع': 4, 'رابع': 4, 'fourth': 4,
    'الخامس': 5, 'خامس': 5, 'fifth': 5,
    'السادس': 6, 'سادس': 6, 'sixth': 6,
    'السابع': 7, 'سابع': 7, 'seventh': 7,
    'الثامن': 8, 'ثامن': 8, 'eighth': 8,
    'التاسع': 9, 'تاسع': 9, 'ninth': 9,
    'العاشر': 10, 'عاشر': 10, 'tenth': 10,
  };
  for (final e in ordinals.entries) {
    if (text.contains(e.key)) return e.value;
  }
  return null;
}

/// Everything after the verb is taken as the place name, with filler words
/// stripped. Returns null when nothing meaningful is left.
String? _extractTarget(String text, List<String> verbs) {
  var rest = text;
  for (final verb in verbs) {
    final i = rest.indexOf(verb);
    if (i >= 0) {
      rest = rest.substring(i + verb.length);
      break;
    }
  }
  for (final filler in const [
    'محطه', 'محطة', 'زياره', 'زيارة', 'مكان', 'الي', 'من', 'في',
    'the', 'stop', 'place', 'visit', 'to', 'as', 'a',
  ]) {
    rest = rest.replaceAll(RegExp('(^| )$filler( |\$)'), ' ');
  }
  rest = rest.trim();
  // A one-character leftover is noise, not a place name.
  return rest.length < 2 ? null : rest;
}
