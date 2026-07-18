import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../main.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/trip_planner/presentation/screens/saved_trips_screen.dart';
import '../../features/trip_planner/presentation/screens/trip_input_screen.dart';
import '../../features/trip_planner/presentation/screens/generating_screen.dart';
import '../../features/trip_planner/presentation/screens/trip_dashboard_screen.dart';
import '../../features/map/presentation/screens/map_full_screen.dart';
import '../../features/ai_chat/presentation/screens/chat_screen.dart';
import '../../features/auth/presentation/screens/settings_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/itinerary/presentation/screens/stop_detail_screen.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/trip_documents/presentation/screens/documents_screen.dart';
import '../../features/trip_planner/domain/entities/trip_entity.dart';
import '../../shared/widgets/main_navigation_layout.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import 'auth_notifier.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../di/injection.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final _authNotifier = AuthNotifier();

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: Listenable.merge([_authNotifier, appLocale]),
    redirect: (context, state) {
      final isAuthenticated = sl<AuthRepository>().isAuthenticated;
      final publicRoutes = ['/', '/onboarding', '/auth'];
      final isGoingToPublicRoute = publicRoutes.contains(state.uri.path);

      if (!isAuthenticated && !isGoingToPublicRoute) {
        return '/auth';
      }
      if (isAuthenticated && state.uri.path == '/auth') {
        return '/home';
      }
      return null;
    },
    routes: [
      // ── Splash ───────────────────────────────────────────────────────────
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Onboarding ───────────────────────────────────────────────────────
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ── Auth ─────────────────────────────────────────────────────────────
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) {
          final isLogin = state.uri.queryParameters['mode'] != 'register';
          return AuthScreen(isLogin: isLogin);
        },
      ),

      ShellRoute(
        builder: (context, state, child) {
          return MainNavigationLayout(child: child);
        },
        routes: [
          // ── Home (Saved Trips) ────────────────────────────────────────────────
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const SavedTripsScreen(),
          ),

          // ── Plan Trip (Input Wizard) ──────────────────────────────────────────
          GoRoute(
            path: '/plan',
            name: 'plan',
            builder: (context, state) => const TripInputScreen(),
          ),

          // ── Settings ─────────────────────────────────────────────────────────
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),

          // ── Profile ──────────────────────────────────────────────────────────
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),

          // ── Favorites ────────────────────────────────────────────────────────
          GoRoute(
            path: '/favorites',
            name: 'favorites',
            builder: (context, state) => const FavoritesScreen(),
          ),
        ],
      ),

      // ── Generating Screen ─────────────────────────────────────────────────
      GoRoute(
        path: '/plan/generating',
        name: 'generating',
        builder: (context, state) {
          final params = state.extra as Map<String, dynamic>? ?? {};
          return GeneratingScreen(params: params);
        },
      ),

      // ── Trip Dashboard (Tabbed) ───────────────────────────────────────────
      GoRoute(
        path: '/trip/:tripId',
        name: 'trip',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          final trip = state.extra as TripEntity?;
          return TripDashboardScreen(tripId: tripId, trip: trip);
        },
        routes: [
          // ── Map Full Screen ─────────────────────────────────────────────
          GoRoute(
            path: 'map',
            name: 'tripMap',
            builder: (context, state) {
              final tripId = state.pathParameters['tripId']!;
              return MapFullScreen(tripId: tripId);
            },
          ),

          // ── Stop Detail ─────────────────────────────────────────────────
          GoRoute(
            path: 'stop/:stopId',
            name: 'stopDetail',
            pageBuilder: (context, state) {
              final stopId = state.pathParameters['stopId']!;
              return CustomTransitionPage(
                child: StopDetailScreen(stopId: stopId),
                transitionsBuilder: (context, animation, secondary, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                        parent: animation, curve: Curves.easeOutCubic)),
                    child: child,
                  );
                },
              );
            },
          ),

          // ── AI Chat ─────────────────────────────────────────────────────
          GoRoute(
            path: 'chat',
            name: 'chat',
            pageBuilder: (context, state) {
              final tripId = state.pathParameters['tripId']!;
              final trip = state.extra as TripEntity?;
              return CustomTransitionPage(
                child: ChatScreen(tripId: tripId, trip: trip),
                transitionsBuilder: (context, animation, secondary, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                        parent: animation, curve: Curves.easeOutCubic)),
                    child: child,
                  );
                },
              );
            },
          ),

          // ── Documents ───────────────────────────────────────────────────
          GoRoute(
            path: 'documents',
            name: 'tripDocuments',
            pageBuilder: (context, state) {
              final tripId = state.pathParameters['tripId']!;
              return CustomTransitionPage(
                child: DocumentsScreen(tripId: tripId),
                transitionsBuilder: (context, animation, secondary, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                        parent: animation, curve: Curves.easeOutCubic)),
                    child: child,
                  );
                },
              );
            },
          ),
        ],
      ),

    ],

    // Error page
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: AppColors.adaptiveBgPrimary(context),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🗺️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              AppStrings.of(context).errorPageNotFound,
              style: TextStyle(
                color: AppColors.adaptiveTextPrimary(context),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: Text(AppStrings.of(context).backToHome),
            ),
          ],
        ),
      ),
    ),
  );
}
