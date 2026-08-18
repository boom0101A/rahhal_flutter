import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:rahhal_flutter/core/constants/app_strings.dart';
import 'package:rahhal_flutter/core/services/map_launcher_service.dart';

/// Regression test for a silent-failure bug: five call sites across
/// `itinerary_tab.dart`, `stop_detail_screen.dart` and `nearby_screen.dart`
/// called `MapLauncherService.openInGoogleMaps`/`openUberRide` without ever
/// checking the returned `bool`. On a device with no Maps app and a `geo:`/
/// `https:` launch that genuinely fails, the tap did nothing — no error, no
/// retry, nothing — while the exact same failure already showed a
/// `mapsOpenFailed` snackbar in `hotels_tab.dart` and `restaurant_map_button
/// .dart`. All five sites were rewritten to follow that same pattern.
///
/// Rather than standing up the three real screens (each needs GoRouter,
/// FavoritesCubit and GetIt-registered repositories the rest of this suite
/// deliberately avoids pulling in for widget tests — see the comment in
/// itinerary_day_switch_widget_test.dart), this exercises the exact pattern
/// those five call sites now share: call the real [MapLauncherService]
/// (with url_launcher's platform channel faked) and assert the snackbar
/// behaviour the fix is responsible for.
class _FakeUrlLauncher extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  _FakeUrlLauncher({required this.succeeds});
  final bool succeeds;

  @override
  Future<bool> canLaunch(String url) async => succeeds;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async => succeeds;
}

/// Mirrors the exact onPressed pattern added to the five call sites.
class _MapButton extends StatelessWidget {
  const _MapButton({required this.action});
  final Future<bool> Function() action;

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final failureMessage = AppStrings.of(context).mapsOpenFailed;
    final launched = await action();
    if (!launched) {
      messenger.showSnackBar(SnackBar(content: Text(failureMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ElevatedButton(
        onPressed: () => _open(context),
        child: const Text('open'),
      ),
    );
  }
}

void main() {
  Future<void> pump(WidgetTester tester, Future<bool> Function() action) {
    return tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en', 'US'),
        supportedLocales: const [Locale('ar', 'AE'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: _MapButton(action: action),
      ),
    );
  }

  testWidgets(
      'a failed Google Maps launch now shows the "could not open Maps" snackbar',
      (tester) async {
    UrlLauncherPlatform.instance = _FakeUrlLauncher(succeeds: false);

    await pump(
      tester,
      () => MapLauncherService.openInGoogleMaps(
        placeName: 'Ur Ziggurat',
        placeId: 'ChIJtestPlace', // set so no PlaceResolverService lookup is needed
        lat: 30.9626,
        lon: 46.1033,
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump(); // start the async handler
    await tester.pump(); // let the snackbar animate in

    expect(find.text('Could not open Google Maps'), findsOneWidget,
        reason: 'a launch failure must not be silent — every other Maps '
            'button in the app already tells the user this');
  });

  testWidgets('a failed Uber launch also shows the failure snackbar',
      (tester) async {
    UrlLauncherPlatform.instance = _FakeUrlLauncher(succeeds: false);

    await pump(
      tester,
      () => MapLauncherService.openUberRide(
        placeName: 'Ur Ziggurat',
        lat: 30.9626,
        lon: 46.1033,
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Could not open Google Maps'), findsOneWidget);
  });

  testWidgets('a successful launch shows no failure snackbar', (tester) async {
    UrlLauncherPlatform.instance = _FakeUrlLauncher(succeeds: true);

    await pump(
      tester,
      () => MapLauncherService.openInGoogleMaps(
        placeName: 'Ur Ziggurat',
        placeId: 'ChIJtestPlace',
        lat: 30.9626,
        lon: 46.1033,
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Could not open Google Maps'), findsNothing,
        reason: 'a real success must not be second-guessed with an error');
  });
}
