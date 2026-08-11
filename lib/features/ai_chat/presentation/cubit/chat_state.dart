part of 'chat_cubit.dart';

class ChatState extends Equatable {
  final List<ChatMessageEntity> messages;
  final bool isTyping;
  final String? errorMessage;

  /// Text of a message that just failed to send, so the UI can put it back
  /// in the input field instead of silently discarding what the user typed.
  final String? failedMessageText;

  const ChatState({
    this.messages = const [],
    this.isTyping = false,
    this.errorMessage,
    this.failedMessageText,
  });

  @override
  List<Object?> get props =>
      [messages, isTyping, errorMessage, failedMessageText];
}
