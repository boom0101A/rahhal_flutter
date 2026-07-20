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
import 'page_transitions.dart';
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

      // ── Bottom-tab shell ─────────────────────────────────────────────────
      // StatefulShellRoute.indexedStack keeps each tab's own state (scroll
      // position, in-progress forms) alive via an IndexedStack, and switches
      // between them instantly — the same feel as WhatsApp/Instagram tabs —
      // instead of the previous plain ShellRoute, which rebuilt the
      // destination from scratch on every tap and animated the switch like
      // a stack push (wrong direction cues for sibling tabs).
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationLayout(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const SavedTripsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/plan',
                name: 'plan',
                builder: (context, state) => const TripInputScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                name: 'favorites',
                builder: (context, state) => const FavoritesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── Settings ─────────────────────────────────────────────────────────
      // Deliberately outside the shell: a full-screen destination with no
      // bottom nav bar, pushed on the root navigator from Profile/Home.
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) =>
            slideUpPage(state: state, child: const SettingsScreen()),
      ),

      // ── Generating Screen ─────────────────────────────────────────────────
      GoRoute(
        path: '/plan/generating',
        name: 'generating',
        pageBuilder: (context, state) {
          final params = state.extra as Map<String, dynamic>? ?? {};
          return slideUpPage(state: state, child: GeneratingScreen(params: params));
        },
      ),

      // ── Trip Dashboard (Tabbed) ───────────────────────────────────────────
      GoRoute(
        path: '/trip/:tripId',
        name: 'trip',
        pageBuilder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          final trip = state.extra as TripEntity?;
          return slideUpPage(
            state: state,
            child: TripDashboardScreen(tripId: tripId, trip: trip),
          );
        },
        routes: [
          // ── Map Full Screen ─────────────────────────────────────────────
          GoRoute(
            path: 'map',
            name: 'tripMap',
            pageBuilder: (context, state) {
              final tripId = state.pathParameters['tripId']!;
              return slideUpPage(state: state, child: MapFullScreen(tripId: tripId));
            },
          ),

          // ── Stop Detail ─────────────────────────────────────────────────
          GoRoute(
            path: 'stop/:stopId',
            name: 'stopDetail',
            pageBuilder: (context, state) {
              final stopId = state.pathParameters['stopId']!;
              return slideUpModalPage(
                state: state,
                child: StopDetailScreen(stopId: stopId),
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
              return slideUpModalPage(
                state: state,
                child: ChatScreen(tripId: tripId, trip: trip),
              );
            },
          ),

          // ── Documents ───────────────────────────────────────────────────
          GoRoute(
            path: 'documents',
            name: 'tripDocuments',
            pageBuilder: (context, state) {
              final tripId = state.pathParameters['tripId']!;
              return slideUpModalPage(
                state: state,
                child: DocumentsScreen(tripId: tripId),
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
