import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rahhal_flutter/core/services/analytics_service.dart';
import 'package:rahhal_flutter/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:rahhal_flutter/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:rahhal_flutter/features/hotels/domain/entities/hotel_entity.dart';
import 'package:rahhal_flutter/features/hotels/domain/repositories/hotel_repository.dart';
import 'package:rahhal_flutter/features/hotels/presentation/cubit/hotels_cubit.dart';
import 'package:rahhal_flutter/features/hotels/presentation/widgets/hotels_tab.dart';

/// Regression test mirroring restaurants_tab_style_gate_test.dart, for the
/// "stay" style gating hotels the same way "food" gates restaurants.
class _MockRepo extends Mock implements HotelRepository {}
class _MockFavoritesRepo extends Mock implements FavoritesRepository {}
class _MockAnalyticsService extends Mock implements AnalyticsService {}

HotelEntity _hotel(String id) => HotelEntity(
      id: id,
      tripId: 't1',
      name: 'h-$id',
      rating: 4.2,
      pricePerNight: 80,
      latitude: 0,
      longitude: 0,
    );

void main() {
  late _MockRepo repo;
  late HotelsCubit cubit;
  late _MockFavoritesRepo favoritesRepo;
  late FavoritesCubit favoritesCubit;

  setUp(() {
    repo = _MockRepo();
    cubit = HotelsCubit(repository: repo);
    favoritesRepo = _MockFavoritesRepo();
    when(() => favoritesRepo.getFavorites()).thenAnswer((_) async => const Right([]));
    favoritesCubit = FavoritesCubit(repository: favoritesRepo, analytics: _MockAnalyticsService());
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
              BlocProvider<HotelsCubit>.value(value: cubit),
              // Each hotel card reads FavoritesCubit for its heart icon —
              // not provided here, the card (including its name text) would
              // never actually render.
              BlocProvider<FavoritesCubit>.value(value: favoritesCubit),
            ],
            child: HotelsTab(tripId: 't1', travelStyles: travelStyles),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('empty list + stay not selected shows the style explanation',
      (tester) async {
    when(() => repo.getHotelsForTrip('t1')).thenAnswer((_) async => const Right([]));
    await cubit.loadHotels('t1');

    await pumpTab(tester, travelStyles: ['culture', 'food']);

    expect(find.text('لم تختر نمط "إقامة" لهذه الرحلة، لذلك لم تُدرَج أي فنادق فيها.'),
        findsOneWidget);
  });

  testWidgets('empty list + stay selected shows the generic no-hotels message',
      (tester) async {
    when(() => repo.getHotelsForTrip('t1')).thenAnswer((_) async => const Right([]));
    await cubit.loadHotels('t1');

    await pumpTab(tester, travelStyles: ['stay']);

    expect(
        find.text(
            'لم تختر نمط "إقامة" لهذه الرحلة، لذلك لم تُدرَج أي فنادق فيها.'),
        findsNothing,
        reason: 'stay WAS selected, so an empty result must not blame the style');
  });

  testWidgets('a legacy trip (no travelStyles) with real hotels still renders them',
      (tester) async {
    when(() => repo.getHotelsForTrip('t1'))
        .thenAnswer((_) async => Right([_hotel('a'), _hotel('b')]));
    await cubit.loadHotels('t1');

    await pumpTab(tester, travelStyles: null);
    // Lets each card's flutter_animate entrance (fadeIn/slideX, staggered
    // per index) actually finish and dispose its ticker, rather than leaving
    // a pending timer when the test tears down mid-animation.
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('h-a'), findsOneWidget);
    expect(find.text('h-b'), findsOneWidget);
  });
}
