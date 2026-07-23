import 'package:get_it/get_it.dart';
import '../network/ai_service.dart';
import '../network/cloud_sync_service.dart';
import '../network/image_search_service.dart';
import '../network/weather_service.dart';
import '../../features/weather/data/weather_repository.dart';
import '../../features/currency/data/currency_service.dart';
import '../../features/nearby/data/nearby_service.dart';
import '../services/notification_service.dart';
import '../services/location_service.dart';
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

  // Cloud Sync Service
  sl.registerLazySingleton<CloudSyncService>(() => CloudSyncService());

  // Image Search Service
  sl.registerLazySingleton<ImageSearchService>(() => ImageSearchService());

  // Weather Service
  sl.registerLazySingleton<WeatherService>(() => WeatherService());

  // Notification Service
  sl.registerLazySingleton<NotificationService>(() => NotificationService());

  // Location Service
  sl.registerLazySingleton<LocationService>(() => LocationService());

  // ─── Repositories ─────────────────────────────────────────────────────────

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(),
  );

  sl.registerLazySingleton<DocumentRepository>(
    () => DocumentRepositoryImpl(dbHelper: sl<DatabaseHelper>()),
  );

  sl.registerLazySingleton<TripRepository>(
    () => TripRepositoryImpl(
      dbHelper: sl<DatabaseHelper>(),
      aiService: sl<AITravelService>(),
      syncService: sl<CloudSyncService>(),
    ),
  );

  sl.registerLazySingleton<ItineraryRepository>(
    () => ItineraryRepositoryImpl(dbHelper: sl<DatabaseHelper>()),
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
    () => BudgetRepositoryImpl(dbHelper: sl<DatabaseHelper>()),
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

  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(
      dbHelper: sl<DatabaseHelper>(),
      aiService: sl<AITravelService>(),
    ),
  );

  // ─── Cubits (factory — new instance per use) ──────────────────────────────

  sl.registerFactory<TripPlannerCubit>(
    () => TripPlannerCubit(tripRepository: sl<TripRepository>()),
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

  sl.registerFactory<AuthCubit>(
    () => AuthCubit(repository: sl<AuthRepository>()),
  );

  sl.registerFactory<DocumentCubit>(
    () => DocumentCubit(repository: sl<DocumentRepository>()),
  );

  sl.registerLazySingleton<FavoritesCubit>(
    () => FavoritesCubit(repository: sl<FavoritesRepository>()),
  );
}
