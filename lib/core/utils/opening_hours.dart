/// Parses the free-text opening hours Google Places returns
/// (`regularOpeningHours.weekdayDescriptions`, joined with " • ") well enough
/// to answer one question: what time does this place close on a given date?
///
/// Free text is inherently fragile, so every ambiguity resolves to **null**.
/// A missing notification is invisible; a wrong "closes in an hour" alert that
/// makes someone abandon their evening is not.
library;

/// Closing time for [date], or null when it can't be determined confidently.
///
/// Handles the shapes Places actually emits, e.g.
///   "Monday: 9:00 AM – 11:00 PM"
///   "Tuesday: 9:00 AM – 12:00 AM"   (past midnight → next day)
///   "Wednesday: Open 24 hours"      → null (never closes)
///   "Thursday: Closed"              → null (nothing to warn about)
DateTime? closingTimeFor(String? weekdayDescriptions, DateTime date) {
  if (weekdayDescriptions == null || weekdayDescriptions.trim().isEmpty) {
    return null;
  }

  final dayName = _weekdayNames[date.weekday];
  if (dayName == null) return null;

  // Find this weekday's entry among the " • "-joined segments.
  final segments = weekdayDescriptions.split('•');
  String? line;
  for (final s in segments) {
    if (s.toLowerCase().contains(dayName)) {
      line = s.trim();
      break;
    }
  }
  if (line == null) return null;

  final lower = line.toLowerCase();
  // Explicit non-answers: nothing to warn about either way.
  if (lower.contains('closed')) return null;
  if (lower.contains('24 hours') || lower.contains('open 24')) return null;

  // Take the LAST time on the line — that's the closing one. Ranges use an
  // en dash, hyphen or "to" depending on the locale, so rather than splitting
  // on a separator we just read every time token and keep the final one.
  final matches = _timePattern.allMatches(line).toList();
  if (matches.length < 2) return null; // need an open AND a close time

  final close = matches.last;
  final open = matches.first;

  final closeMinutes = _toMinutes(close);
  final openMinutes = _toMinutes(open);
  if (closeMinutes == null || openMinutes == null) return null;

  // A close time at or before the open time means it runs past midnight
  // (e.g. 9:00 AM – 12:00 AM), so it belongs to the following day.
  final crossesMidnight = closeMinutes <= openMinutes;
  final base = crossesMidnight ? date.add(const Duration(days: 1)) : date;

  return DateTime(
    base.year,
    base.month,
    base.day,
    closeMinutes ~/ 60,
    closeMinutes % 60,
  );
}

/// "9:00 AM", "11 PM", "23:00" — hour, optional minutes, optional meridiem.
final RegExp _timePattern = RegExp(
  r'(\d{1,2})(?::(\d{2}))?\s*([APap][Mm])?',
);

/// Minutes since midnight, or null when the token isn't a valid clock time.
int? _toMinutes(RegExpMatch m) {
  final rawHour = int.tryParse(m.group(1) ?? '');
  if (rawHour == null) return null;
  final minute = int.tryParse(m.group(2) ?? '0') ?? 0;
  if (minute > 59) return null;

  final meridiem = m.group(3)?.toLowerCase();
  int hour = rawHour;
  if (meridiem != null) {
    if (rawHour < 1 || rawHour > 12) return null; // 13 PM isn't a time
    if (meridiem == 'pm' && rawHour != 12) hour = rawHour + 12;
    if (meridiem == 'am' && rawHour == 12) hour = 0;
  } else if (rawHour > 23) {
    return null;
  }
  return hour * 60 + minute;
}

const Map<int, String> _weekdayNames = {
  DateTime.monday: 'monday',
  DateTime.tuesday: 'tuesday',
  DateTime.wednesday: 'wednesday',
  DateTime.thursday: 'thursday',
  DateTime.friday: 'friday',
  DateTime.saturday: 'saturday',
  DateTime.sunday: 'sunday',
};
