import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rahhal_flutter/core/di/injection.dart';
import 'package:rahhal_flutter/features/ai_chat/domain/entities/chat_message_entity.dart';
import 'package:rahhal_flutter/features/ai_chat/domain/repositories/chat_repository.dart';
import 'package:rahhal_flutter/features/ai_chat/presentation/cubit/chat_cubit.dart';
import 'package:rahhal_flutter/features/ai_chat/presentation/screens/chat_screen.dart';
import 'package:rahhal_flutter/features/itinerary/domain/repositories/itinerary_repository.dart';
import 'package:rahhal_flutter/features/trip_planner/domain/entities/trip_entity.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

class _MockItineraryRepository extends Mock implements ItineraryRepository {}

class _FakeChatMessageEntity extends Fake implements ChatMessageEntity {}

void main() {
  late _MockChatRepository chatRepository;
  late _MockItineraryRepository itineraryRepository;

  final trip = TripEntity(
    id: 'trip-1',
    destination: 'بغداد',
    durationDays: 3,
    budgetTier: 'mid',
    budgetTotal: 300,
    travelStyles: const ['culture'],
    travelersCount: 2,
    status: 'planned',
    aiSummary: 'A short trip to Baghdad',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValue(_FakeChatMessageEntity());
  });

  setUp(() {
    chatRepository = _MockChatRepository();
    itineraryRepository = _MockItineraryRepository();

    when(() => chatRepository.getMessages(any()))
        .thenAnswer((_) async => const Right([]));
    when(() => itineraryRepository.getDaysForTrip(any()))
        .thenAnswer((_) async => const Right([]));

    sl.registerLazySingleton<ItineraryRepository>(() => itineraryRepository);
    sl.registerFactory<ChatCubit>(
      () => ChatCubit(repository: chatRepository),
    );
  });

  tearDown(() {
    sl.reset();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar', 'AE'),
        supportedLocales: const [Locale('ar', 'AE'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: ChatScreen(tripId: trip.id, trip: trip),
      ),
    );
    // Not pumpAndSettle: the header has a repeating (never-settling) pulse
    // animation, so a few bounded pumps are used instead to let the mocked
    // async calls (initChat's getMessages, the itinerary-context lookup)
    // resolve without waiting forever for that animation to finish.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('shows the welcome screen with quick-reply suggestions when there is no history',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text('أهلاً! أنا مساعد رحّال'), findsOneWidget);
    expect(find.text('الطقس سيئ اليوم — اقترح بديلاً داخلياً'), findsOneWidget);
  });

  testWidgets('sending a message shows it immediately and then shows the assistant reply',
      (tester) async {
    final reply = ChatMessageEntity(
      id: 'reply-1',
      tripId: trip.id,
      role: 'assistant',
      content: 'جرّب مطعم الزهاوي، مطبخ عراقي أصيل.',
      timestamp: DateTime.now(),
    );
    when(() => chatRepository.sendMessage(
          tripId: any(named: 'tripId'),
          destination: any(named: 'destination'),
          tripSummary: any(named: 'tripSummary'),
          userMessage: any(named: 'userMessage'),
          history: any(named: 'history'),
        )).thenAnswer((_) async => Right(reply));

    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'ما أفضل مطعم؟');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('ما أفضل مطعم؟'), findsOneWidget);
    expect(find.text('جرّب مطعم الزهاوي، مطبخ عراقي أصيل.'), findsOneWidget);
  });
}
