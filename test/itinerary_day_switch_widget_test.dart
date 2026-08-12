import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rahhal_flutter/features/itinerary/domain/entities/day_entity.dart';
import 'package:rahhal_flutter/features/itinerary/domain/repositories/itinerary_repository.dart';
import 'package:rahhal_flutter/features/itinerary/presentation/cubit/itinerary_cubit.dart';
import 'package:rahhal_flutter/features/itinerary/presentation/widgets/itinerary_tab.dart';
import 'package:rahhal_flutter/shared/widgets/shimmer_loader.dart';

/// Widget-level regression test for the choppy day-switch transition.
/// Uses days with EMPTY stop lists deliberately — this isolates the actual
/// bug (the day-content crossfade) without needing FavoritesCubit/GoRouter/
/// network-image test scaffolding that real stop cards would pull in (none
/// of that exists in reusable form in this test suite today).
class _MockRepo extends Mock implements ItineraryRepository {}

void main() {
  late _MockRepo repo;
  late ItineraryCubit cubit;
  final day1 = const DayEntity(id: 'd1', tripId: 't1', dayNumber: 1, theme: 'يوم بغداد');
  final day2 = const DayEntity(id: 'd2', tripId: 't1', dayNumber: 2, theme: 'يوم أربيل');

  setUp(() {
    repo = _MockRepo();
    cubit = ItineraryCubit(repository: repo);
    when(() => repo.getDaysForTrip('t1')).thenAnswer((_) async => Right([day1, day2]));
    when(() => repo.getStopsForDay('d1')).thenAnswer((_) async => const Right([]));
    when(() => repo.getStopsForDay('d2')).thenAnswer((_) async => const Right([]));
  });

  Future<void> pumpTab(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
          body: BlocProvider<ItineraryCubit>.value(
            value: cubit,
            child: const ItineraryTab(tripId: 't1'),
          ),
        ),
      ),
    );
    await cubit.loadItinerary('t1');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('switching days never shows a shimmer flash, at any point in the transition',
      (tester) async {
    await pumpTab(tester);
    expect(find.text('يوم بغداد'), findsOneWidget);

    await tester.tap(find.text('اليوم 2'));
    // Sample across the whole transition instead of pumpAndSettle() —
    // ShimmerStopCard's Shimmer.fromColors runs an infinite
    // AnimationController, so any path that still shows it would hang
    // pumpAndSettle(). Explicit pumps also let us actually catch a
    // mid-transition shimmer flash if the fix regresses.
    for (final ms in [0, 50, 100, 150, 200, 300, 350]) {
      await tester.pump(Duration(milliseconds: ms));
      expect(find.byType(ShimmerStopCard), findsNothing,
          reason: 'a shimmer flash at ${ms}ms into the switch is exactly the '
              'jump-cut this fix removes');
    }
  });

  testWidgets('the old day\'s content is gone and the new day\'s is shown once settled',
      (tester) async {
    await pumpTab(tester);
    expect(find.text('يوم بغداد'), findsOneWidget);
    expect(find.text('يوم أربيل'), findsNothing);

    await tester.tap(find.text('اليوم 2'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('يوم بغداد'), findsNothing);
    expect(find.text('يوم أربيل'), findsOneWidget);
  });

  testWidgets('tapping the already-selected day chip does not refetch or transition',
      (tester) async {
    await pumpTab(tester);

    await tester.tap(find.text('اليوم 1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Initial load already called getStopsForDay('d1') once — tapping the
    // same, already-active day must not call it again.
    verify(() => repo.getStopsForDay('d1')).called(1);
    expect(find.text('يوم بغداد'), findsOneWidget);
  });

  testWidgets('a longer trip (4 days) transitions smoothly on every non-adjacent jump, '
      'not just day 1 ↔ day 2', (tester) async {
    final day3 = const DayEntity(id: 'd3', tripId: 't1', dayNumber: 3, theme: 'يوم البصرة');
    final day4 = const DayEntity(id: 'd4', tripId: 't1', dayNumber: 4, theme: 'يوم الموصل');
    when(() => repo.getDaysForTrip('t1'))
        .thenAnswer((_) async => Right([day1, day2, day3, day4]));
    when(() => repo.getStopsForDay('d3')).thenAnswer((_) async => const Right([]));
    when(() => repo.getStopsForDay('d4')).thenAnswer((_) async => const Right([]));

    await pumpTab(tester);
    expect(find.text('يوم بغداد'), findsOneWidget);

    // Day 1 → Day 4 (skips over 2 and 3 entirely).
    await tester.tap(find.text('اليوم 4'));
    for (final ms in [0, 50, 150, 300]) {
      await tester.pump(Duration(milliseconds: ms));
      expect(find.byType(ShimmerStopCard), findsNothing);
    }
    expect(find.text('يوم بغداد'), findsNothing);
    expect(find.text('يوم الموصل'), findsOneWidget);

    // Day 4 → Day 2 (backwards, non-adjacent).
    await tester.tap(find.text('اليوم 2'));
    for (final ms in [0, 50, 150, 300]) {
      await tester.pump(Duration(milliseconds: ms));
      expect(find.byType(ShimmerStopCard), findsNothing);
    }
    expect(find.text('يوم الموصل'), findsNothing);
    expect(find.text('يوم أربيل'), findsOneWidget);

    // Day 2 → Day 3 (adjacent, forward).
    await tester.tap(find.text('اليوم 3'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('يوم أربيل'), findsNothing);
    expect(find.text('يوم البصرة'), findsOneWidget);
  });
}
