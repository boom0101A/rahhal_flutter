import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rahhal_flutter/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:rahhal_flutter/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:rahhal_flutter/features/restaurants/domain/entities/restaurant_entity.dart';
import 'package:rahhal_flutter/features/restaurants/domain/repositories/restaurant_repository.dart';
import 'package:rahhal_flutter/features/restaurants/presentation/cubit/restaurants_cubit.dart';
import 'package:rahhal_flutter/features/restaurants/presentation/widgets/restaurants_tab.dart';

/// Regression test for the newly-added strict travel-style gating: when a
/// trip doesn't have the "food" style, the server now sends back zero
/// restaurants on purpose. Without this fix, an empty list rendered the
/// generic "no restaurants match this filter" message plus a full (useless)
/// filter-chip row and a "0 مطعم" count — looking like the app was broken
/// rather than reflecting the user's own choice.
class _MockRepo extends Mock implements RestaurantRepository {}
class _MockFavoritesRepo extends Mock implements FavoritesRepository {}

RestaurantEntity _restaurant(String id) => RestaurantEntity(
      id: id,
      tripId: 't1',
      name: 'r-$id',
      halalCertified: false,
      rating: 4.5,
      pricePerPerson: 10,
      priceTier: 'mid',
      latitude: 0,
      longitude: 0,
      isRecommended: false,
    );

void main() {
  late _MockRepo repo;
  late RestaurantsCubit cubit;
  late _MockFavoritesRepo favoritesRepo;
  late FavoritesCubit favoritesCubit;

  setUp(() {
    repo = _MockRepo();
    cubit = RestaurantsCubit(repository: repo);
    favoritesRepo = _MockFavoritesRepo();
    when(() => favoritesRepo.getFavorites()).thenAnswer((_) async => const Right([]));
    favoritesCubit = FavoritesCubit(repository: favoritesRepo);
  });

  Future<void> pumpTab(WidgetTester tester, {List<String>? travelStyles}) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar', 'AE'),
        supportedLocales: const [Locale('ar', 'AE'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<RestaurantsCubit>.value(value: cubit),
              // Each restaurant card reads FavoritesCubit for its heart icon
              // — not provided here, this widget tree would throw and the
              // card (including its name text) would never actually render.
              BlocProvider<FavoritesCubit>.value(value: favoritesCubit),
            ],
            child: RestaurantsTab(tripId: 't1', travelStyles: travelStyles),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('empty list + food not selected shows the style explanation, no filter row',
      (tester) async {
    when(() => repo.getRestaurantsForTrip('t1')).thenAnswer((_) async => const Right([]));
    await cubit.loadRestaurants('t1');

    await pumpTab(tester, travelStyles: ['culture', 'stay']);

    expect(find.text('لم تختر نمط "طعام" لهذه الرحلة، لذلك لم تُدرَج أي مطاعم فيها.'),
        findsOneWidget);
    expect(find.textContaining('مطعم'), findsNothing,
        reason: 'the "N مطعم" results count must not render over a '
            'permanently-empty, by-design list');
  });

  testWidgets('empty list + food selected shows the generic no-results message',
      (tester) async {
    when(() => repo.getRestaurantsForTrip('t1')).thenAnswer((_) async => const Right([]));
    await cubit.loadRestaurants('t1');

    await pumpTab(tester, travelStyles: ['food']);

    expect(find.text('لا توجد مطاعم بهذا الفلتر'), findsOneWidget,
        reason: 'food WAS selected, so an empty result is a real "nothing '
            'found", not a by-design exclusion');
  });

  testWidgets('a legacy trip (no travelStyles) with real restaurants still renders them',
      (tester) async {
    when(() => repo.getRestaurantsForTrip('t1'))
        .thenAnswer((_) async => Right([_restaurant('a'), _restaurant('b')]));
    await cubit.loadRestaurants('t1');

    await pumpTab(tester, travelStyles: null);
    // Lets each card's flutter_animate entrance (fadeIn/slideX, staggered
    // per index) actually finish and dispose its ticker, rather than leaving
    // a pending timer when the test tears down mid-animation.
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('لم تختر نمط "طعام" لهذه الرحلة، لذلك لم تُدرَج أي مطاعم فيها.'),
        findsNothing);
    expect(find.textContaining('مطعم'), findsWidgets);
  });
}
