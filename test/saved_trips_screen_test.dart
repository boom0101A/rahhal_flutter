import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rahhal_flutter/core/di/injection.dart';
import 'package:rahhal_flutter/core/errors/failures.dart';
import 'package:rahhal_flutter/features/trip_planner/domain/entities/trip_entity.dart';
import 'package:rahhal_flutter/features/trip_planner/domain/repositories/trip_repository.dart';
import 'package:rahhal_flutter/features/trip_planner/presentation/cubit/saved_trips_cubit.dart';
import 'package:rahhal_flutter/features/trip_planner/presentation/screens/saved_trips_screen.dart';

class _MockTripRepository extends Mock implements TripRepository {}

TripEntity _trip({
  required String id,
  required String destination,
  DateTime? startDate,
  int durationDays = 3,
}) {
  // The screen derives its "ongoing / upcoming / completed" grouping from
  // DateTime.now() at render time (see _effectiveStatus in
  // saved_trips_screen.dart), so fixtures must be relative to "now" too —
  // a fixed calendar date here would silently go stale and break this test
  // the moment it's run on a different day.
  final now = DateTime.now();
  return TripEntity(
    id: id,
    destination: destination,
    startDate: startDate,
    endDate: startDate?.add(Duration(days: durationDays - 1)),
    durationDays: durationDays,
    budgetTier: 'mid',
    budgetTotal: 300,
    travelStyles: const ['culture'],
    travelersCount: 2,
    status: 'planned',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late _MockTripRepository repository;

  setUp(() {
    repository = _MockTripRepository();
    // SavedTripsScreen builds its own SavedTripsCubit via sl<SavedTripsCubit>()
    // rather than reading one from an ancestor BlocProvider, so the mock has
    // to be registered in the same GetIt instance the screen resolves from.
    sl.registerFactory<SavedTripsCubit>(
      () => SavedTripsCubit(repository: repository),
    );
  });

  tearDown(() {
    sl.reset();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    // A tall surface keeps every section (Ongoing/Upcoming/Completed) mounted
    // in one frame instead of requiring scroll gestures to reach each one.
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar', 'AE'),
        supportedLocales: [Locale('ar', 'AE'), Locale('en', 'US')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: SavedTripsScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('groups trips into Ongoing / Upcoming / Completed sections',
      (tester) async {
    final today = DateTime.now();
    final ongoingTrip = _trip(
      id: 'ongoing',
      destination: 'بغداد',
      startDate: today.subtract(const Duration(days: 1)),
      durationDays: 4,
    ); // started yesterday, 4-day trip → still ongoing today
    final upcomingTrip = _trip(
      id: 'upcoming',
      destination: 'أربيل',
      startDate: today.add(const Duration(days: 30)),
    );
    final completedTrip = _trip(
      id: 'completed',
      destination: 'البصرة',
      startDate: today.subtract(const Duration(days: 200)),
      durationDays: 2,
    );

    when(() => repository.getAllTrips()).thenAnswer(
      (_) async => Right([ongoingTrip, upcomingTrip, completedTrip]),
    );

    await pumpScreen(tester);

    expect(find.text('جارية الآن'), findsOneWidget);
    expect(find.text('القادمة'), findsOneWidget);
    expect(find.text('المنتهية'), findsOneWidget);
    expect(find.text('بغداد'), findsOneWidget);
    expect(find.text('أربيل'), findsOneWidget);
    expect(find.text('البصرة'), findsOneWidget);
  });

  testWidgets('search field filters the visible trip list', (tester) async {
    final baghdad = _trip(id: '1', destination: 'بغداد');
    final erbil = _trip(id: '2', destination: 'أربيل');

    when(() => repository.getAllTrips()).thenAnswer(
      (_) async => Right([baghdad, erbil]),
    );

    await pumpScreen(tester);

    expect(find.text('بغداد'), findsOneWidget);
    expect(find.text('أربيل'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'أربيل');
    await tester.pumpAndSettle();

    expect(find.text('بغداد'), findsNothing);
    // findsWidgets, not findsOneWidget: the search field itself now also
    // contains the typed text "أربيل", in addition to the trip card.
    expect(find.text('أربيل'), findsWidgets);
  });

  testWidgets('shows the empty state when there are no trips at all',
      (tester) async {
    when(() => repository.getAllTrips()).thenAnswer((_) async => const Right([]));

    await pumpScreen(tester);

    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('shows an error view when loading trips fails', (tester) async {
    when(() => repository.getAllTrips())
        .thenAnswer((_) async => Left(DatabaseFailure('boom')));

    await pumpScreen(tester);

    expect(find.text('boom'), findsOneWidget);
  });
}
