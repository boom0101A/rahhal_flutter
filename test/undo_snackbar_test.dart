import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers the reported "‏تم حذف الرحلة / تراجع‏ bar never goes away" bug.
///
/// A single SnackBar does expire on its own, so the real cause was queueing:
/// ScaffoldMessenger shows SnackBars strictly one after another, so deleting
/// N trips put N × 4s of bar on screen back-to-back with no gap — which is
/// indistinguishable from one that never closes. Clearing before showing
/// keeps exactly one alive.
///
/// Note on timing: `pumpAndSettle` only drains *animations*. The SnackBar's
/// display window is a plain Timer, so the clock has to be advanced with
/// explicit `pump(duration)` calls or the bar looks stuck in tests too.
const _undoWindow = Duration(seconds: 4);
const _animation = Duration(milliseconds: 500);

Widget _harness(void Function(BuildContext) onPressed) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => onPressed(context),
          child: const Text('delete'),
        ),
      ),
    ),
  );
}

void _showQueued(BuildContext context, String label) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(label), duration: _undoWindow),
  );
}

void _showClearingFirst(BuildContext context, String label) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(label), duration: _undoWindow));
}

/// Taps the button and lets the bar finish animating in.
Future<void> _delete(WidgetTester tester) async {
  await tester.tap(find.text('delete'));
  await tester.pump();
  await tester.pump(_animation);
}

void main() {
  testWidgets('a single undo bar closes on its own after the undo window',
      (tester) async {
    var n = 0;
    await tester.pumpWidget(_harness((c) => _showQueued(c, 'bar ${n++}')));

    await _delete(tester);
    expect(find.text('bar 0'), findsOneWidget);

    await tester.pump(_undoWindow);
    await tester.pump(_animation);
    expect(find.text('bar 0'), findsNothing,
        reason: 'a lone SnackBar expires by itself — so one stuck bar on '
            'screen is never just "the timer did not run"');
  });

  testWidgets(
      'BROKEN: three quick deletes keep a bar on screen for three full '
      'windows, because each waits its turn in the queue', (tester) async {
    var n = 0;
    await tester.pumpWidget(_harness((c) => _showQueued(c, 'bar ${n++}')));

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('delete'));
      await tester.pump();
    }
    await tester.pump(_animation);
    expect(find.text('bar 0'), findsOneWidget, reason: 'first of the queue');

    // The whole point: a full undo window has passed, yet the user is STILL
    // looking at a bar — the next one in the queue has taken over. That is
    // what reads as "the message never disappears".
    await tester.pump(_undoWindow);
    await tester.pump(_animation);
    expect(find.text('bar 0'), findsNothing, reason: 'the first one did expire');
    expect(find.textContaining('bar'), findsOneWidget,
        reason: 'but a queued replacement is already on screen in its place');
  });

  testWidgets(
      'FIXED: clearing first leaves only the newest bar, gone one window later',
      (tester) async {
    var n = 0;
    await tester
        .pumpWidget(_harness((c) => _showClearingFirst(c, 'bar ${n++}')));

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('delete'));
      await tester.pump();
    }
    await tester.pump(_animation);

    expect(find.text('bar 0'), findsNothing);
    expect(find.text('bar 1'), findsNothing);
    expect(find.text('bar 2'), findsOneWidget,
        reason: 'only the newest undo is meaningful, so only it survives');

    await tester.pump(_undoWindow);
    await tester.pump(_animation);
    expect(find.textContaining('bar'), findsNothing,
        reason: 'no queue left behind — the bar really is gone after one window');
  });
}
