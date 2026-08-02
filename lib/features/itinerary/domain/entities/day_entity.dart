import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/utils/localized_prose.dart';

class DayEntity extends Equatable {
  final String id;
  final String tripId;
  final int dayNumber;
  final DateTime? date;
  final String? theme;

  /// English copy of [theme], filled in on demand — see [localizedProse].
  final String? themeEn;
  final String? summary;

  const DayEntity({
    required this.id,
    required this.tripId,
    required this.dayNumber,
    this.date,
    this.theme,
    this.themeEn,
    this.summary,
  });

  /// The day theme in the app's current language.
  String? displayTheme(BuildContext context) =>
      localizedProse(context, theme, themeEn);

  @override
  List<Object?> get props =>
      [id, tripId, dayNumber, date, theme, themeEn, summary];
}
