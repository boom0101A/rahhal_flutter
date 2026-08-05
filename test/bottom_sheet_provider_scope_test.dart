import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression test for "saving a document does nothing".
///
/// This is the bottom-sheet variant of the trap already covered by
/// [provider_scope_regression_test.dart]. DocumentsScreen creates its
/// BlocProvider inside `build()` — which is fine for the screen body — but the
/// "add document" sheet is opened with `showModalBottomSheet`, and that pushes
/// a **new route** whose subtree is rooted in the Navigator's Overlay. The
/// Overlay sits *above* the provider, so nothing inside the sheet can look the
/// cubit up. `StatefulBuilder` made it invisible by shadowing the enclosing
/// `context` with its own parameter, so the code read like it was using the
/// screen's context when it wasn't.
///
/// Result: `context.read<DocumentCubit>()` threw, `Navigator.pop` on the next
/// line never ran, and the sheet just sat there with the document unsaved.
class _DocsCubit extends Cubit<int> {
  _DocsCubit() : super(0);
  void addDocument() => emit(state + 1);
}

/// The old shape: read from inside the sheet.
class _BrokenScreen extends StatelessWidget {
  const _BrokenScreen({required this.errors});
  final List<Object> errors;

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        // Note the shadowing: this `context` is the sheet's, not the screen's.
        builder: (context, setSheetState) => TextButton(
          onPressed: () {
            try {
              context.read<_DocsCubit>().addDocument();
              Navigator.pop(ctx);
            } catch (e) {
              errors.add(e);
            }
          },
          child: const Text('save'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _DocsCubit(),
      child: Builder(
        builder: (context) => TextButton(
          onPressed: () => _openSheet(context),
          child: const Text('open'),
        ),
      ),
    );
  }
}

/// The fixed shape: capture the cubit before opening the sheet, matching
/// `itinerary_tab.dart`.
class _FixedScreen extends StatelessWidget {
  const _FixedScreen({required this.errors, required this.onCubit});
  final List<Object> errors;
  final void Function(_DocsCubit) onCubit;

  void _openSheet(BuildContext context) {
    final cubit = context.read<_DocsCubit>();
    onCubit(cubit);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => TextButton(
          onPressed: () {
            try {
              cubit.addDocument();
              Navigator.pop(ctx);
            } catch (e) {
              errors.add(e);
            }
          },
          child: const Text('save'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _DocsCubit(),
      child: Builder(
        builder: (context) => TextButton(
          onPressed: () => _openSheet(context),
          child: const Text('open'),
        ),
      ),
    );
  }
}

void main() {
  testWidgets(
      'BROKEN shape: reading the cubit from inside a modal bottom sheet throws, '
      'so the document is never saved and the sheet never closes',
      (tester) async {
    final errors = <Object>[];
    await tester.pumpWidget(MaterialApp(home: _BrokenScreen(errors: errors)));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('save'));
    await tester.pumpAndSettle();

    expect(errors, hasLength(1),
        reason: 'the sheet lives in the Navigator Overlay, above the provider');
    expect(errors.single.toString(), contains('Could not find the correct Provider'));
    expect(find.text('save'), findsOneWidget,
        reason: 'Navigator.pop is on the line after the throw, so the sheet '
            'stays open — exactly the symptom the user would see');
  });

  testWidgets('FIXED shape: capturing the cubit first saves and closes the sheet',
      (tester) async {
    final errors = <Object>[];
    _DocsCubit? captured;
    await tester.pumpWidget(MaterialApp(
      home: _FixedScreen(errors: errors, onCubit: (c) => captured = c),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('save'));
    await tester.pumpAndSettle();

    expect(errors, isEmpty, reason: 'no provider lookup happens inside the sheet');
    expect(captured!.state, 1, reason: 'addDocument actually reached the cubit');
    expect(find.text('save'), findsNothing, reason: 'the sheet closed');
  });
}
