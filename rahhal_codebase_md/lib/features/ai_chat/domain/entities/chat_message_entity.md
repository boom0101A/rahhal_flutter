# ملف كود Dart: lib\features\ai_chat\domain\entities\chat_message_entity.dart

```dart
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

  @override
  List<Object?> get props =>
      [id, tripId, role, content, timestamp, messageType];
}

```
