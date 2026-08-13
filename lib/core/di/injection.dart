import 'package:get_it/get_it.dart';
import '../network/ai_service.dart';
import '../network/cloud_sync_service.dart';
import '../network/issue_report_service.dart';
import '../network/trip_translation_service.dart';
import '../network/image_search_service.dart';
import '../network/weather_service.dart';
import '../../features/weather/data/weather_repository.dart';
import '../../features/currency/data/currency_service.dart';
import '../../features/nearby/data/nearby_service.dart';
import '../services/notification_service.dart';
import '../services/location_service.dart';
import '../services/analytics_service.dart';
import '../services/fcm_service.dart';
import '../services/data_export_service.dart';
import '../services/place_resolver_service.dart';
import '../services/location_share_service.dart';
import '../services/offline_prep_service.dart';
import '../services/storage_service.dart';
import '../../features/auth/data/profile_stats_service.dart';
import '../../features/auth/data/local_avatar_service.dart';
import '../services/trip_notification_scheduler.dart';
import '../../features/ai_chat/data/trip_command_executor.dart';
import '../database/database_helper.dart';
import '../../features/trip_planner/data/trip_repository_impl.dart';
import '../../features/trip_planner/domain/repositories/trip_repository.dart';
import '../../features/trip_planner/presentation/cubit/trip_planner_cubit.dart';
import '../../features/itinerary/data/itinerary_repository_impl.dart';
import '../../features/itinerary/domain/repositories/itinerary_repository.dart';
import '../../features/itinerary/presentation/cubit/itinerary_cubit.dart';
import '../../features/map/data/map_repository_impl.dart';
import '../../features/map/domain/repositories/map_repository.dart';
import '../../features/map/presentation/cubit/map_cubit.dart';
import '../../features/restaurants/data/restaurant_repository_impl.dart';
import '../../features/restaurants/domain/repositories/restaurant_repository.dart';
import '../../features/restaurants/presentation/cubit/restaurants_cubit.dart';
import '../../features/hotels/data/hotel_repository_impl.dart';
import '../../features/hotels/domain/repositories/hotel_repository.dart';
import '../../features/hotels/presentation/cubit/hotels_cubit.dart';
import '../../features/budget/data/budget_repository_impl.dart';
import '../../features/budget/domain/repositories/budget_repository.dart';
import '../../features/budget/presentation/cubit/budget_cubit.dart';
import '../../features/trip_planner/presentation/cubit/saved_trips_cubit.dart';
import '../../features/ai_chat/data/chat_repository_impl.dart';
import '../../features/ai_chat/domain/repositories/chat_repository.dart';
import '../../features/ai_chat/presentation/cubit/chat_cubit.dart';
import '../../features/auth/data/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/favorites/data/favorites_repository_impl.dart';
import '../../features/favorites/domain/repositories/favorites_repository.dart';
import '../../features/favorites/presentation/cubit/favorites_cubit.dart';
import '../../features/trip_documents/data/repositories/document_repository_impl.dart';
import '../../features/trip_documents/domain/repositories/document_repository.dart';
import '../../features/trip_documents/presentation/cubit/document_cubit.dart';

final GetIt sl = GetIt.instance;

Future<void> setupDependencies() async {
  // ─── Core ─────────────────────────────────────────────────────────────────

  // Database
  sl.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper.instance);

  // AI Service
  sl.registerLazySingleton<AITravelService>(() => AITravelService());

  // Issue Report Service ("this AI result is wrong")
  sl.registerLazySingleton<IssueReportService>(() => IssueReportService());

  // Data Export Service ("export my data")
  sl.registerLazySingleton<DataExportService>(() => DataExportService());

  // Cloud Sync Service
  sl.registerLazySingleton<CloudSyncService>(() => CloudSyncService());

  // Translates a trip's AI prose into English on demand (see the service
  // doc for why this is not done at generation time).
  sl.registerLazySingleton<TripTranslationService>(
    () => TripTranslationService(dbHelper: sl<DatabaseHelper>()),
  );

  // Image Search Service
  sl.registerLazySingleton<ImageSearchService>(() => ImageSearchService());

  // Weather Service
  sl.registerLazySingleton<WeatherService>(() => WeatherService());

  // Notification Service
  sl.registerLazySingleton<NotificationService>(() => NotificationService());

  // Location Service
  sl.registerLazySingleton<LocationService>(() => LocationService());

  // Analytics Service
  sl.registerLazySingleton<AnalyticsService>(() => AnalyticsService());

  // FCM Service (Android push)
  sl.registerLazySingleton<FcmService>(() => FcmService());

  // ─── Repositories ─────────────────────────────────────────────────────────

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      dbHelper: sl<DatabaseHelper>(),
      syncService: sl<CloudSyncService>(),
    ),
  );

  sl.registerLazySingleton<DocumentRepository>(
    () => DocumentRepositoryImpl(
      dbHelper: sl<DatabaseHelper>(),
      syncService: sl<CloudSyncService>(),
    ),
  );

  sl.registerLazySingleton<TripRepository>(
    () => TripRepositoryImpl(
      dbHelper: sl<DatabaseHelper>(),
      aiService: sl<AITravelService>(),
      syncService: sl<CloudSyncService>(),
    ),
  );

  sl.registerLazySingleton<ItineraryRepository>(
    () => ItineraryRepositoryImpl(
      dbHelper: sl<DatabaseHelper>(),
      syncService: sl<CloudSyncService>(),
    ),
  );

  sl.registerLazySingleton<MapRepository>(
    () => MapRepositoryImpl(dbHelper: sl<DatabaseHelper>()),
  );

  sl.registerLazySingleton<RestaurantRepository>(
    () => RestaurantRepositoryImpl(dbHelper: sl<DatabaseHelper>()),
  );

  sl.registerLazySingleton<HotelRepository>(
    () => HotelRepositoryImpl(dbHelper: sl<DatabaseHelper>()),
  );

  sl.registerLazySingleton<BudgetRepository>(
    () => BudgetRepositoryImpl(
      dbHelper: sl<DatabaseHelper>(),
      syncService: sl<CloudSyncService>(),
    ),
  );

  sl.registerLazySingleton<FavoritesRepository>(
    () => FavoritesRepositoryImpl(
      dbHelper: sl<DatabaseHelper>(),
      authRepository: sl<AuthRepository>(),
    ),
  );

  sl.registerLazySingleton<WeatherRepository>(() => WeatherRepository());

  sl.registerLazySingleton<CurrencyService>(() => CurrencyService());

  sl.registerLazySingleton<NearbyService>(() => NearbyService());

  sl.registerLazySingleton<PlaceResolverService>(() => PlaceResolverService());

  sl.registerLazySingleton<LocationShareService>(() => LocationShareService());

  sl.registerLazySingleton<OfflinePrepService>(
    () => OfflinePrepService(dbHelper: sl<DatabaseHelper>()),
  );

  sl.registerLazySingleton<TripNotificationScheduler>(
    () => TripNotificationScheduler(dbHelper: sl<DatabaseHelper>()),
  );

  sl.registerLazySingleton<StorageService>(() => StorageService());

  sl.registerLazySingleton<ProfileStatsService>(
    () => ProfileStatsService(dbHelper: sl<DatabaseHelper>()),
  );

  sl.registerLazySingleton<LocalAvatarService>(() => LocalAvatarService());

  sl.registerLazySingleton<TripCommandExecutor>(
    () => TripCommandExecutor(
      dbHelper: sl<DatabaseHelper>(),
      syncService: sl<CloudSyncService>(),
    ),
  );

  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(
      dbHelper: sl<DatabaseHelper>(),
      aiService: sl<AITravelService>(),
    ),
  );

  // ─── Cubits (factory — new instance per use) ──────────────────────────────

  sl.registerFactory<TripPlannerCubit>(
    () => TripPlannerCubit(
      tripRepository: sl<TripRepository>(),
      analytics: sl<AnalyticsService>(),
    ),
  );

  sl.registerFactory<ItineraryCubit>(
    () => ItineraryCubit(repository: sl<ItineraryRepository>()),
  );

  sl.registerFactory<MapCubit>(
    () => MapCubit(repository: sl<MapRepository>()),
  );

  sl.registerFactory<RestaurantsCubit>(
    () => RestaurantsCubit(repository: sl<RestaurantRepository>()),
  );

  sl.registerFactory<HotelsCubit>(
    () => HotelsCubit(repository: sl<HotelRepository>()),
  );

  sl.registerFactory<BudgetCubit>(
    () => BudgetCubit(repository: sl<BudgetRepository>()),
  );

  sl.registerFactory<SavedTripsCubit>(
    () => SavedTripsCubit(repository: sl<TripRepository>()),
  );

  sl.registerFactory<ChatCubit>(
    () => ChatCubit(repository: sl<ChatRepository>()),
  );

  // Singleton, not factory: like FavoritesCubit, this is provided exactly
  // once at the app root (main.dart) and is meant to be the single shared
  // source of truth for auth state across every screen.
  sl.registerLazySingleton<AuthCubit>(
    () => AuthCubit(
      repository: sl<AuthRepository>(),
      analytics: sl<AnalyticsService>(),
      fcm: sl<FcmService>(),
    ),
  );

  sl.registerFactory<DocumentCubit>(
    () => DocumentCubit(repository: sl<DocumentRepository>()),
  );

  sl.registerLazySingleton<FavoritesCubit>(
    () => FavoritesCubit(
      repository: sl<FavoritesRepository>(),
      analytics: sl<AnalyticsService>(),
    ),
  );
}
