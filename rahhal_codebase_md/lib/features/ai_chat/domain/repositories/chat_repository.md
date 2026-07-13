# ملف كود Dart: lib\features\ai_chat\domain\repositories\chat_repository.dart

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/chat_message_entity.dart';

abstract class ChatRepository {
  Future<Either<Failure, List<ChatMessageEntity>>> getMessages(
      String tripId);
  Future<Either<Failure, ChatMessageEntity>> sendMessage({
    required String tripId,
    required String destination,
    required String tripSummary,
    required String userMessage,
    required List<ChatMessageEntity> history,
  });
  Future<Either<Failure, void>> clearHistory(String tripId);
  Future<Either<Failure, void>> saveMessage(ChatMessageEntity message);
}

```
