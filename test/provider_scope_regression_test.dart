import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression test for the "deleted trips come back after refresh" and
/// "the trash icon does nothing" bugs.
///
/// Both had one root cause: SavedTripsScreen created its BlocProvider *inside*
/// its own `build()`, then called `context.read<SavedTripsCubit>()` from
/// `State.context` (and from the `BuildContext` passed into `build`). Provider
/// lookup walks *up* the element tree, and the BlocProvider is a **descendant**
/// of that context — so every one of those reads threw
/// ProviderNotFoundException and the delete never reached the cubit.
///
/// The swipe path still *looked* like it worked because Dismissible removes the
/// card from the tree itself before the throw; the row was never deleted, so a
/// pull-to-refresh brought it straight back.
class _CounterCubit extends Cubit<int> {
  _CounterCubit() : super(0);
  void increment() => emit(state + 1);
}

/// Reproduces the old, broken shape.
class _BrokenScreen extends StatefulWidget {
  const _BrokenScreen();
  @override
  State<_BrokenScreen> createState() => _BrokenScreenState();
}

class _BrokenScreenState extends State<_BrokenScreen> {
  Object? readError;

  void doAction() {
    try {
      context.read<_CounterCubit>().increment();
    } catch (e) {
      readError = e;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Provider created INSIDE this State's build — so it is a descendant of
    // `State.context`, not an ancestor.
    return BlocProvider(
      create: (_) => _CounterCubit(),
      child: TextButton(onPressed: doAction, child: const Text('act')),
    );
  }
}

/// Reproduces the fixed shape: the cubit is owned by the State and handed to
/// BlocProvider.value, so callbacks use the instance directly and never depend
/// on where they sit in the element tree.
class _FixedScreen extends StatefulWidget {
  const _FixedScreen();
  @override
  State<_FixedScreen> createState() => _FixedScreenState();
}

class _FixedScreenState extends State<_FixedScreen> {
  late final _CounterCubit _cubit = _CounterCubit();
  Object? readError;

  void doAction() {
    try {
      _cubit.increment();
    } catch (e) {
      readError = e;
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: TextButton(onPressed: doAction, child: const Text('act')),
    );
  }
}

void main() {
  testWidgets(
      'BROKEN shape: reading a cubit provided inside the same build() throws, '
      'so the action silently never runs', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _BrokenScreen()));

    final state = tester.state<_BrokenScreenState>(find.byType(_BrokenScreen));
    state.doAction();

    expect(
      state.readError,
      isNotNull,
      reason: 'context.read() from State.context must fail when the provider '
          'is created inside that same State.build() — this is exactly why '
          'cubit.deleteTrip() was never called',
    );
    expect(
      state.readError.toString(),
      contains('Could not find the correct Provider'),
      reason: 'the framework itself names the cause: the BuildContext used '
          'does not include the provider, because the provider is below it',
    );
  });

  testWidgets('FIXED shape: the State owns the cubit, so the action runs',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _FixedScreen()));

    final state = tester.state<_FixedScreenState>(find.byType(_FixedScreen));
    state.doAction();
    state.doAction();

    expect(state.readError, isNull, reason: 'no provider lookup, nothing to fail');
    expect(state._cubit.state, 2, reason: 'both actions actually reached the cubit');
  });

  testWidgets('FIXED shape still exposes the cubit to descendant BlocBuilders',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _FixedScreen()));
    final state = tester.state<_FixedScreenState>(find.byType(_FixedScreen));

    // A descendant must still be able to look it up normally — BlocProvider
    // .value keeps the widget-tree contract intact.
    final descendantContext = tester.element(find.text('act'));
    expect(descendantContext.read<_CounterCubit>(), same(state._cubit));
  });
}
