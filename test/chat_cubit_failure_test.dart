import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rahhal_flutter/core/errors/failures.dart';
import 'package:rahhal_flutter/features/ai_chat/domain/entities/chat_message_entity.dart';
import 'package:rahhal_flutter/features/ai_chat/domain/repositories/chat_repository.dart';
import 'package:rahhal_flutter/features/ai_chat/presentation/cubit/chat_cubit.dart';

/// Regression tests for two ChatCubit bugs:
/// 1. initChat's failure branch emitted the exact same `const ChatState()`
///    as a brand-new, genuinely-empty chat — a failed history load was
///    indistinguishable from "no messages yet".
/// 2. sendMessage's failure branch dropped the user's typed text on the
///    floor entirely — nothing restored it anywhere.
class _MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late _MockChatRepository repo;
  late ChatCubit cubit;

  setUp(() {
    repo = _MockChatRepository();
    cubit = ChatCubit(repository: repo);
  });

  group('initChat', () {
    test('a failed history load carries errorMessage, unlike a genuinely empty chat',
        () async {
      when(() => repo.getMessages('t1'))
          .thenAnswer((_) async => const Left(DatabaseFailure('locked')));

      await cubit.initChat(tripId: 't1', destination: 'Baghdad', tripSummary: '');

      expect(cubit.state.messages, isEmpty);
      expect(cubit.state.errorMessage, 'locked',
          reason: 'a failed load must be distinguishable from an empty chat, '
              'which leaves errorMessage null');
    });

    test('a genuinely empty chat has no errorMessage', () async {
      when(() => repo.getMessages('t1')).thenAnswer((_) async => const Right([]));

      await cubit.initChat(tripId: 't1', destination: 'Baghdad', tripSummary: '');

      expect(cubit.state.messages, isEmpty);
      expect(cubit.state.errorMessage, isNull);
    });
  });

  group('sendMessage', () {
    test('a failed send restores the typed text via failedMessageText', () async {
      when(() => repo.getMessages('t1')).thenAnswer((_) async => const Right([]));
      await cubit.initChat(tripId: 't1', destination: 'Baghdad', tripSummary: '');

      when(() => repo.sendMessage(
            tripId: any(named: 'tripId'),
            destination: any(named: 'destination'),
            tripSummary: any(named: 'tripSummary'),
            userMessage: any(named: 'userMessage'),
            history: any(named: 'history'),
          )).thenAnswer((_) async => const Left(NetworkFailure('offline')));

      await cubit.sendMessage('  Where should I eat?  ');

      expect(cubit.state.errorMessage, 'offline');
      expect(cubit.state.failedMessageText, 'Where should I eat?',
          reason: 'the trimmed text the user typed must survive the failure '
              'so the UI can put it back in the input field');
      expect(cubit.state.messages, isEmpty,
          reason: 'the optimistic temp message must be rolled back too');
    });

    test('clearError wipes errorMessage and failedMessageText but keeps messages',
        () async {
      when(() => repo.getMessages('t1')).thenAnswer((_) async => const Right([]));
      await cubit.initChat(tripId: 't1', destination: 'Baghdad', tripSummary: '');
      when(() => repo.sendMessage(
            tripId: any(named: 'tripId'),
            destination: any(named: 'destination'),
            tripSummary: any(named: 'tripSummary'),
            userMessage: any(named: 'userMessage'),
            history: any(named: 'history'),
          )).thenAnswer((_) async => const Left(NetworkFailure('offline')));
      await cubit.sendMessage('hi');

      cubit.clearError();

      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.failedMessageText, isNull);
    });

    test('a successful send leaves errorMessage and failedMessageText null',
        () async {
      when(() => repo.getMessages('t1')).thenAnswer((_) async => const Right([]));
      await cubit.initChat(tripId: 't1', destination: 'Baghdad', tripSummary: '');
      when(() => repo.sendMessage(
            tripId: any(named: 'tripId'),
            destination: any(named: 'destination'),
            tripSummary: any(named: 'tripSummary'),
            userMessage: any(named: 'userMessage'),
            history: any(named: 'history'),
          )).thenAnswer((_) async => Right(ChatMessageEntity(
                id: 'a1',
                tripId: 't1',
                role: 'assistant',
                content: 'Try Al-Rasheed street.',
                timestamp: DateTime(2026, 1, 1),
              )));

      await cubit.sendMessage('hi');

      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.failedMessageText, isNull);
      expect(cubit.state.messages, hasLength(2));
    });
  });
}
