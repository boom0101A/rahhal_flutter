# ملف كود Dart: lib\features\ai_chat\presentation\cubit\chat_cubit.dart

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/repositories/chat_repository.dart';

part 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _repository;

  ChatCubit({required ChatRepository repository})
      : _repository = repository,
        super(const ChatState());

  String? _tripId;
  String _destination = '';
  String _tripSummary = '';

  Future<void> initChat({
    required String tripId,
    required String destination,
    required String tripSummary,
  }) async {
    _tripId = tripId;
    _destination = destination;
    _tripSummary = tripSummary;

    final result = await _repository.getMessages(tripId);
    result.fold(
      (_) => emit(const ChatState()),
      (messages) => emit(ChatState(messages: messages)),
    );
  }

  Future<void> sendMessage(String text) async {
    if (_tripId == null || text.trim().isEmpty) return;

    // Add user message to UI immediately
    final userMsg = ChatMessageEntity(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      tripId: _tripId!,
      role: 'user',
      content: text.trim(),
      timestamp: DateTime.now(),
    );

    emit(ChatState(
      messages: [...state.messages, userMsg],
      isTyping: true,
    ));

    // Send to AI
    final result = await _repository.sendMessage(
      tripId: _tripId!,
      destination: _destination,
      tripSummary: _tripSummary,
      userMessage: text.trim(),
      history: state.messages.where((m) => m.id != userMsg.id).toList(),
    );

    result.fold(
      (failure) {
        // Remove temp message on error, keep rest
        final withoutTemp = state.messages
            .where((m) => m.id != userMsg.id)
            .toList();
        emit(ChatState(
          messages: withoutTemp,
          isTyping: false,
          errorMessage: failure.message,
        ));
      },
      (assistantMsg) {
        // Replace temp message with persisted one
        final updated = state.messages.map((m) {
          return m.id == userMsg.id
              ? ChatMessageEntity(
                  id: DateTime.now().toIso8601String(),
                  tripId: _tripId!,
                  role: 'user',
                  content: text.trim(),
                  timestamp: userMsg.timestamp,
                )
              : m;
        }).toList();
        emit(ChatState(
          messages: [...updated, assistantMsg],
          isTyping: false,
        ));
      },
    );
  }

  Future<void> clearHistory() async {
    if (_tripId == null) return;
    await _repository.clearHistory(_tripId!);
    emit(const ChatState());
  }
}

```
