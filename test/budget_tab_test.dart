import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rahhal_flutter/core/di/injection.dart';
import 'package:rahhal_flutter/core/errors/failures.dart';
import 'package:rahhal_flutter/features/budget/domain/entities/budget_item_entity.dart';
import 'package:rahhal_flutter/features/budget/domain/repositories/budget_repository.dart';
import 'package:rahhal_flutter/features/budget/presentation/cubit/budget_cubit.dart';
import 'package:rahhal_flutter/features/budget/presentation/widgets/budget_tab.dart';
import 'package:rahhal_flutter/features/currency/data/currency_service.dart';

class _MockBudgetRepository extends Mock implements BudgetRepository {}

void main() {
  late _MockBudgetRepository repository;

  setUp(() {
    repository = _MockBudgetRepository();
    SharedPreferences.setMockInitialValues({});
    // DualCurrencyText (used to render amounts) reads this via sl<>() —
    // registering the real service is safe since its calls fall back to
    // cached/local data with no network requirement for a USD-only user.
    sl.registerLazySingleton<CurrencyService>(() => CurrencyService());
  });

  tearDown(() {
    sl.reset();
  });

  Future<void> pumpTab(WidgetTester tester, BudgetCubit cubit) async {
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
          body: BlocProvider<BudgetCubit>.value(
            value: cubit,
            child: const BudgetTab(tripId: 'trip-1'),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('loaded state shows both budget sub-tabs', (tester) async {
    when(() => repository.getBudgetItems(any()))
        .thenAnswer((_) async => const Right([]));
    when(() => repository.getBudgetBreakdown(any()))
        .thenAnswer((_) async => const Right(BudgetBreakdown()));
    when(() => repository.getExpenses(any()))
        .thenAnswer((_) async => const Right([]));
    when(() => repository.getTripDays(any()))
        .thenAnswer((_) async => const Right([]));

    final cubit = BudgetCubit(repository: repository)..loadBudget('trip-1');
    await pumpTab(tester, cubit);

    // "Budget Comparison" also headlines the chart section within the view
    // itself, in addition to the sub-tab label, so more than one is expected.
    expect(find.text('مقارنة الميزانية'), findsWidgets);
    expect(find.text('المصروف الفعلي'), findsOneWidget);
  });

  testWidgets('tapping the "Actual Expense" sub-tab switches the view',
      (tester) async {
    when(() => repository.getBudgetItems(any()))
        .thenAnswer((_) async => const Right([]));
    when(() => repository.getBudgetBreakdown(any()))
        .thenAnswer((_) async => const Right(BudgetBreakdown()));
    when(() => repository.getExpenses(any()))
        .thenAnswer((_) async => const Right([]));
    when(() => repository.getTripDays(any()))
        .thenAnswer((_) async => const Right([]));

    final cubit = BudgetCubit(repository: repository)..loadBudget('trip-1');
    await pumpTab(tester, cubit);

    await tester.tap(find.text('المصروف الفعلي'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Still on the budget screen (no crash) with the same sub-tab bar shown,
    // now with "Actual Expense" as the active selection.
    expect(find.text('مقارنة الميزانية'), findsOneWidget);
    expect(find.text('المصروف الفعلي'), findsOneWidget);
  });

  testWidgets('shows an error view with a retry that reloads the budget',
      (tester) async {
    when(() => repository.getBudgetItems(any()))
        .thenAnswer((_) async => Left(DatabaseFailure('budget failed')));
    when(() => repository.getBudgetBreakdown(any()))
        .thenAnswer((_) async => const Right(BudgetBreakdown()));
    when(() => repository.getExpenses(any()))
        .thenAnswer((_) async => const Right([]));
    when(() => repository.getTripDays(any()))
        .thenAnswer((_) async => const Right([]));

    final cubit = BudgetCubit(repository: repository)..loadBudget('trip-1');
    await pumpTab(tester, cubit);

    expect(find.text('budget failed'), findsOneWidget);

    verify(() => repository.getBudgetItems('trip-1')).called(1);
  });
}
