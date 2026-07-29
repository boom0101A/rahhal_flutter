import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rahhal_flutter/core/di/injection.dart';
import 'package:rahhal_flutter/features/auth/presentation/screens/splash_screen.dart';

void main() {
  testWidgets(
    'Splash screen renders, then redirects to onboarding on first launch',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await setupDependencies();

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
          GoRoute(
            path: '/onboarding',
            builder: (_, __) => const Scaffold(body: Text('onboarding-reached')),
          ),
          GoRoute(
            path: '/auth',
            builder: (_, __) => const Scaffold(body: Text('auth-reached')),
          ),
          GoRoute(
            path: '/home',
            builder: (_, __) => const Scaffold(body: Text('home-reached')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      // The real splash screen must actually build without throwing.
      expect(find.text('✈️'), findsWidgets);

      // SplashScreen waits 1.5s then reads prefs/auth state and navigates.
      // With no stored 'has_seen_onboarding', it must land on onboarding.
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      expect(find.text('onboarding-reached'), findsOneWidget);
    },
  );
}
