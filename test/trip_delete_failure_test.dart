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

/// Regression test for "I deleted a trip and it came back".
///
/// The screen hides the card and shows "Trip deleted" the instant the undo
/// window opens, then fires the real delete when the window closes. The cubit
/// discarded the failure branch (`(failure) => null`), so a delete that failed
/// left the user with a confirmation message, a hidden card, and a trip that
/// silently reappeared on the next load.
class _MockTripRepository extends Mock implements TripRepository {}

/// Matches the screen's own undo window and Material's animation allowance.
const _undoWindow = Duration(seconds: 4);
const _animation = Duration(milliseconds: 500);

TripEntity _trip(String id, String destination) {
  final now = DateTime.now();
  return TripEntity(
    id: id,
    destination: destination,
    startDate: now.add(const Duration(days: 30)),
    endDate: now.add(const Duration(days: 32)),
    durationDays: 3,
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
    // The screen resolves its own cubit through GetIt rather than an ancestor
    // provider, so the mock has to live in the same instance.
    sl.registerFactory<SavedTripsCubit>(
      () => SavedTripsCubit(repository: repository),
    );
  });

  tearDown(sl.reset);

  Future<void> pumpScreen(WidgetTester tester) async {
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

  /// Deletes via the card's trash button (both entry points funnel into the
  /// same confirm dialog and `_scheduleDelete`; the button is the one that
  /// doesn't depend on swipe direction under RTL), then lets the undo window
  /// expire so the real delete runs.
  ///
  /// `pumpAndSettle` is not enough on its own — it drains animations, not the
  /// undo Timer (see undo_snackbar_test.dart).
  Future<void> deleteAndWaitOutUndo(WidgetTester tester) async {
    await tester.tap(find.byTooltip('حذف').first);
    await tester.pumpAndSettle();
    // Confirm dialog: the destructive action shares its label with the tooltip,
    // so target the one inside the dialog.
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('حذف'),
    ));

    // Explicit pumps from here, NOT pumpAndSettle. The undo bar carries a
    // countdown animation that runs for the whole window, so settling would
    // silently skip past it — and then keep going far enough to expire the
    // error bar this test is looking for.
    await tester.pump();
    await tester.pump(_animation); // dialog dismissal
    await tester.pump(_undoWindow); // undo window closes, real delete fires
    await tester.pump(); // async repository result lands
    await tester.pump(_animation); // replacement SnackBar enters
  }

  testWidgets('a delete that fails says so and puts the card back',
      (tester) async {
    final trip = _trip('t1', 'بغداد');
    when(() => repository.getAllTrips()).thenAnswer((_) async => Right([trip]));
    when(() => repository.deleteTrip('t1'))
        .thenAnswer((_) async => const Left(DatabaseFailure('locked')));

    await pumpScreen(tester);
    expect(find.text('بغداد'), findsOneWidget);

    await deleteAndWaitOutUndo(tester);

    expect(
      find.text('تعذّر حذف الرحلة، حاول مرة أخرى'),
      findsOneWidget,
      reason: 'the user was told it was deleted; a silent failure is a lie',
    );
    expect(
      find.text('بغداد'),
      findsOneWidget,
      reason: 'the card was hidden optimistically and must come back, or the '
          'list is missing a trip the user still owns',
    );
  });

  testWidgets('the list is not blanked out by a failed delete', (tester) async {
    // SavedTripsDeleteFailed extends SavedTripsLoaded and carries the trips
    // precisely so every `state is SavedTripsLoaded` branch keeps rendering.
    final a = _trip('t1', 'بغداد');
    final b = _trip('t2', 'أربيل');
    when(() => repository.getAllTrips())
        .thenAnswer((_) async => Right([a, b]));
    when(() => repository.deleteTrip('t1'))
        .thenAnswer((_) async => const Left(DatabaseFailure('locked')));

    await pumpScreen(tester);
    await deleteAndWaitOutUndo(tester);

    expect(find.text('أربيل'), findsOneWidget,
        reason: 'the untouched trip must survive the failure');
  });

  testWidgets('a delete that succeeds still reloads and shows no error',
      (tester) async {
    final trip = _trip('t1', 'بغداد');
    var deleted = false;
    when(() => repository.getAllTrips()).thenAnswer(
      (_) async => Right(deleted ? <TripEntity>[] : [trip]),
    );
    when(() => repository.deleteTrip('t1')).thenAnswer((_) async {
      deleted = true;
      return const Right(null);
    });

    await pumpScreen(tester);
    await deleteAndWaitOutUndo(tester);

    expect(find.text('تعذّر حذف الرحلة، حاول مرة أخرى'), findsNothing);
    expect(find.text('بغداد'), findsNothing);
  });
}
