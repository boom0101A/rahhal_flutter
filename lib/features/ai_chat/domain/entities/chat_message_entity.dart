import 'package:equatable/equatable.dart';

class ChatMessageEntity extends Equatable {
  final String id;
  final String tripId;
  final String role; // user | assistant
  final String content;
  final DateTime timestamp;
  final String messageType; // text | suggestion | action

  const ChatMessageEntity({
    required this.id,
    required this.tripId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.messageType = 'text',
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  ChatMessageEntity copyWith({
    String? id,
    String? tripId,
    String? role,
    String? content,
    DateTime? timestamp,
    String? messageType,
  }) {
    return ChatMessageEntity(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      messageType: messageType ?? this.messageType,
    );
  }

  @override
  List<Object?> get props =>
      [id, tripId, role, content, timestamp, messageType];
}
