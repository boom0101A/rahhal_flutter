import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rahhal_flutter/core/di/injection.dart';
import 'package:rahhal_flutter/features/weather/data/weather_repository.dart';
import 'package:rahhal_flutter/features/weather/domain/entities/weather_entity.dart';
import 'package:rahhal_flutter/features/weather/presentation/widgets/weather_banner.dart';

/// Regression test for "WeatherBanner never refreshes when its coordinates
/// change". A multi-city trip's itinerary tab passes the SELECTED day's
/// first-stop coordinates with no Key on the widget, so switching days used
/// to reuse the same State object — initState() (and therefore the fetch)
/// only ever ran once, freezing the display on the first day's city/weather
/// for the rest of the session.
class _MockWeatherRepository extends Mock implements WeatherRepository {}

WeatherForecast _forecastFor(String city) => WeatherForecast(
      city: city,
      forecast: const [
        WeatherDay(
          date: '2026-08-12',
          tempMin: 20,
          tempMax: 30,
          description: 'sunny',
          icon: '01d',
          humidity: 40,
          windSpeed: 2.0,
        ),
      ],
      isMock: false,
    );

void main() {
  late _MockWeatherRepository repo;

  setUp(() {
    repo = _MockWeatherRepository();
    sl.registerLazySingleton<WeatherRepository>(() => repo);
  });

  tearDown(sl.reset);

  testWidgets('changing lat/lon refetches instead of keeping the first city',
      (tester) async {
    when(() => repo.getForecast(lat: 33.3, lon: 44.4, lang: 'en'))
        .thenAnswer((_) async => _forecastFor('Baghdad'));
    when(() => repo.getForecast(lat: 36.2, lon: 44.0, lang: 'en'))
        .thenAnswer((_) async => _forecastFor('Erbil'));

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: WeatherBanner(lat: 33.3, lon: 44.4, lang: 'en')),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Baghdad'), findsOneWidget);
    verify(() => repo.getForecast(lat: 33.3, lon: 44.4, lang: 'en')).called(1);

    // Simulate the user selecting a different day whose first stop is in a
    // different city — same widget tree position, new lat/lon, no Key.
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: WeatherBanner(lat: 36.2, lon: 44.0, lang: 'en')),
    ));
    await tester.pumpAndSettle();

    verify(() => repo.getForecast(lat: 36.2, lon: 44.0, lang: 'en')).called(1);
    expect(find.textContaining('Erbil'), findsOneWidget,
        reason: 'the banner must show the newly-selected day\'s city, not '
            'stay frozen on whichever day loaded first');
    expect(find.textContaining('Baghdad'), findsNothing);
  });

  testWidgets('an unrelated rebuild with the same coordinates does not refetch',
      (tester) async {
    when(() => repo.getForecast(lat: 33.3, lon: 44.4, lang: 'en'))
        .thenAnswer((_) async => _forecastFor('Baghdad'));

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: WeatherBanner(lat: 33.3, lon: 44.4, lang: 'en')),
    ));
    await tester.pumpAndSettle();

    // Same tree, same props — just a second build pass (pumpWidget always
    // triggers one), the same way an unrelated ancestor rebuild would.
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: WeatherBanner(lat: 33.3, lon: 44.4, lang: 'en')),
    ));
    await tester.pumpAndSettle();

    verify(() => repo.getForecast(lat: 33.3, lon: 44.4, lang: 'en')).called(1);
  });
}
