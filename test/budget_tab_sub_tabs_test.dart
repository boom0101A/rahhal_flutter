import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rahhal_flutter/features/budget/domain/entities/budget_item_entity.dart';
import 'package:rahhal_flutter/features/budget/domain/repositories/budget_repository.dart';
import 'package:rahhal_flutter/features/budget/presentation/cubit/budget_cubit.dart';
import 'package:rahhal_flutter/features/budget/presentation/widgets/budget_tab.dart';

/// Regression test for the Costs tab's segmented control in ENGLISH.
///
/// The three pills sit in equal-width `Expanded` thirds, and their labels had
/// no `maxLines`/`FittedBox`. "Budget Comparison" is long enough to wrap onto
/// a second line, which made its pill taller than the other two — the visual
/// inconsistency the user reported. The fix mirrors the dashboard's outer tab
/// bar: scale the text down instead of letting it wrap.
class _MockBudgetRepo extends Mock implements BudgetRepository {}

void main() {
  late _MockBudgetRepo repo;
  late BudgetCubit cubit;

  setUp(() {
    repo = _MockBudgetRepo();
    cubit = BudgetCubit(repository: repo);
    when(() => repo.getBudgetItems('t1')).thenAnswer((_) async => const Right([]));
    when(() => repo.getBudgetBreakdown('t1'))
        .thenAnswer((_) async => const Right(BudgetBreakdown()));
    when(() => repo.getExpenses('t1')).thenAnswer((_) async => const Right([]));
    when(() => repo.getTripDays('t1')).thenAnswer((_) async => const Right([]));
  });

  Future<void> pumpTab(WidgetTester tester) async {
    // A deliberately narrow-ish phone width: this is where an unconstrained
    // long English label wraps.
    tester.view.physicalSize = const Size(720, 1400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en', 'US'),
        supportedLocales: const [Locale('ar', 'AE'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: BlocProvider<BudgetCubit>.value(
            value: cubit,
            child: const BudgetTab(tripId: 't1'),
          ),
        ),
      ),
    );
    await cubit.loadBudget('t1');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  // "Budget Comparison" is also used as a heading INSIDE the comparison view,
  // so scope every lookup to the pills themselves.
  Finder pillLabel(String text) => find.descendant(
        of: find.byType(AnimatedContainer),
        matching: find.text(text),
      );

  testWidgets('the long English sub-tab label never wraps to a second line',
      (tester) async {
    await pumpTab(tester);

    final label = tester.widget<Text>(pillLabel('Budget Comparison'));
    expect(label.maxLines, 1,
        reason: 'wrapping is what made this pill taller than its neighbours');
  });

  testWidgets('all three sub-tab pills render at the same height', (tester) async {
    await pumpTab(tester);

    double pillHeight(String label) {
      final pill = find.ancestor(
        of: pillLabel(label),
        matching: find.byType(AnimatedContainer),
      );
      return tester.getSize(pill.first).height;
    }

    final comparison = pillHeight('Budget Comparison');
    expect(pillHeight('Actual Expense'), comparison);
    expect(pillHeight('Daily Plan'), comparison);
  });

  testWidgets('switching between all three sub-tabs never triggers a layout overflow',
      (tester) async {
    await pumpTab(tester);

    // An earlier attempt animated this with AnimatedSwitcher, which keeps the
    // outgoing view mounted and lays both out at once — that re-layout made a
    // row in the comparison view overflow by 241px. Cycling every transition
    // and asserting no exception is the guard against reintroducing it.
    for (final label in ['Daily Plan', 'Actual Expense', 'Budget Comparison']) {
      await tester.tap(pillLabel(label));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120)); // mid-animation
      expect(tester.takeException(), isNull,
          reason: 'laying out "$label" must not overflow');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: '"$label" must settle cleanly');
    }
  });
}
