import 'package:flutter/widgets.dart';

import '../constants/app_strings.dart';

/// Picks the right language for a piece of AI-written prose.
///
/// The model writes trip text (summaries, day themes, stop tips, restaurant and
/// hotel blurbs) in Arabic. `TripTranslationService` fills in an English copy
/// on demand, so both may exist — or, for a trip that hasn't been translated
/// yet or whose translation failed, only the Arabic one.
///
/// Falling back to [original] rather than showing nothing is deliberate: a
/// missing translation should read as "not translated yet", never as an empty
/// card.
String? localizedProse(BuildContext context, String? original, String? english) {
  if (AppStrings.of(context).languageCode == 'en' &&
      english != null &&
      english.trim().isNotEmpty) {
    return english;
  }
  return original;
}

/// List variant, for `travel_tips`. Falls back whole-list rather than
/// per-item: a half-Arabic, half-English list of tips reads worse than one
/// consistent language.
List<String> localizedProseList(
  BuildContext context,
  List<String> original,
  List<String> english,
) {
  if (AppStrings.of(context).languageCode == 'en' && english.isNotEmpty) {
    return english;
  }
  return original;
}
