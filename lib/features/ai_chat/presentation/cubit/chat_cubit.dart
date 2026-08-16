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
    if (isClosed) return;
    result.fold(
      // A failed load must not look identical to a brand-new chat with no
      // messages yet — carry the error so the UI can tell the user their
      // history didn't come back, instead of silently showing "welcome".
      (failure) => emit(ChatState(errorMessage: failure.message)),
      (messages) => emit(ChatState(messages: messages)),
    );
  }

  Future<void> sendMessage(String text, {String liveContext = ''}) async {
    if (_tripId == null || text.trim().isEmpty) return;
    final content = text.trim();

    // Add user message to UI immediately
    final userMsg = ChatMessageEntity(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      tripId: _tripId!,
      role: 'user',
      content: content,
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
      userMessage: content,
      history: state.messages.where((m) => m.id != userMsg.id).toList(),
      liveContext: liveContext,
    );

    if (isClosed) return;
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
          // What the user typed is otherwise gone — nothing else restores
          // it to the input field.
          failedMessageText: content,
        ));
      },
      (assistantMsg) {
        // Replace temp user message with final persisted state
        // The user message is ALREADY in DB from repository
        // Just update the temp ID to a stable one
        final updatedMessages = [...state.messages];
        final tempIndex = updatedMessages.indexWhere((m) => m.id == userMsg.id);
        if (tempIndex != -1) {
          // Keep the same content, just confirm it's "real" now
          updatedMessages[tempIndex] = userMsg.copyWith(
            id: 'confirmed_${userMsg.timestamp.millisecondsSinceEpoch}',
          );
        }
        emit(ChatState(
          messages: [...updatedMessages, assistantMsg],
          isTyping: false,
        ));
      },
    );
  }

  Future<void> clearHistory() async {
    if (_tripId == null) return;
    await _repository.clearHistory(_tripId!);
    if (isClosed) return;
    emit(const ChatState());
  }

  /// Called by the UI right after it's shown the error snackbar (and, if
  /// applicable, restored a failed message's text), so a later failure with
  /// the same message still triggers a fresh notice.
  void clearError() {
    if (state.errorMessage == null && state.failedMessageText == null) return;
    emit(ChatState(messages: state.messages, isTyping: state.isTyping));
  }
}
