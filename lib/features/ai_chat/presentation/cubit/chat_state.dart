part of 'chat_cubit.dart';

class ChatState extends Equatable {
  final List<ChatMessageEntity> messages;
  final bool isTyping;
  final String? errorMessage;

  const ChatState({
    this.messages = const [],
    this.isTyping = false,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [messages, isTyping, errorMessage];
}
