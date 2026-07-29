import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rahhal_flutter/features/trip_planner/presentation/screens/trip_input_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    // The form is long enough to need scrolling at the default 800x600 test
    // surface, which would leave the travel-style chips and the budget-cap
    // field unmounted (off the initial viewport). A tall surface fits the
    // whole scroll view in one frame, so every widget below is reachable
    // without simulating drag gestures for each of them.
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
        home: TripInputScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('rejects generation with an empty destination', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('خطط رحلتي بالذكاء الاصطناعي'));
    await tester.pump(); // show the SnackBar

    expect(find.text('الرجاء إدخال اسم الوجهة'), findsOneWidget);
  });

  testWidgets('rejects generation with no travel style selected',
      (tester) async {
    await pumpScreen(tester);

    // Deselect the two travel styles that are pre-selected by default
    // (culture, food) so the style set becomes empty.
    await tester.tap(find.text('ثقافة'));
    await tester.pump();
    await tester.tap(find.text('طعام'));
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'بغداد');
    await tester.tap(find.text('خطط رحلتي بالذكاء الاصطناعي'));
    await tester.pump();

    expect(find.text('الرجاء اختيار نمط سفر واحد على الأقل'), findsOneWidget);
  });

  testWidgets('rejects an invalid total budget cap', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField).first, 'بغداد');
    // The budget cap field is the only other TextField on this screen.
    await tester.enterText(find.byType(TextField).last, '-5');
    await tester.tap(find.text('خطط رحلتي بالذكاء الاصطناعي'));
    await tester.pump();

    expect(find.text('الرجاء إدخال مبلغ صحيح أكبر من صفر'), findsOneWidget);
  });
}
