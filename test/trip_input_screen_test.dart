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

  group('destination suggestions in English', () {
    Future<void> pumpEnglish(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('en', 'US'),
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

    testWidgets('the list reads in English, not Arabic', (tester) async {
      // The suggestion list used to render `ar` and the Arabic governorate
      // regardless of language, so an English user got an Arabic list sitting
      // above translated city chips.
      await pumpEnglish(tester);

      await tester.enterText(find.byType(TextField).first, 'karb');
      await tester.pumpAndSettle();

      expect(find.text('Karbala'), findsWidgets);
      expect(find.text('كربلاء'), findsNothing);
      // Subtitle: "<kind> · <governorate in English>".
      expect(
        find.textContaining('Governorate'),
        findsWidgets,
        reason: 'the kind label should be translated too',
      );
    });

    testWidgets('picking a suggestion still sends the Arabic name',
        (tester) async {
      // Load-bearing, not cosmetic: the server resolves an Arabic name through
      // its dictionary and attaches the governorate's real centre coordinates,
      // which its out-of-governorate stop filter measures against. An English
      // name takes a pass-through branch with no coordinates, so sending it
      // would silently disable that filter for every English-language user.
      await pumpEnglish(tester);

      await tester.enterText(find.byType(TextField).first, 'karb');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Karbala').first);
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.controller!.text, 'كربلاء');
    });
  });
}
