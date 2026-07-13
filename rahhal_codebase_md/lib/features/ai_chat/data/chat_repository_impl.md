# ملف كود Dart: lib\features\ai_chat\data\chat_repository_impl.dart

```dart
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/ai_service.dart';
import '../domain/entities/chat_message_entity.dart';
import '../domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final DatabaseHelper _dbHelper;
  final AITravelService _aiService;
  final _uuid = const Uuid();

  ChatRepositoryImpl({
    required DatabaseHelper dbHelper,
    required AITravelService aiService,
  })  : _dbHelper = dbHelper,
        _aiService = aiService;

  @override
  Future<Either<Failure, List<ChatMessageEntity>>> getMessages(
      String tripId) async {
    try {
      final rows = await _dbHelper.query(
        'chat_messages',
        where: 'trip_id = ?',
        whereArgs: [tripId],
        orderBy: 'timestamp ASC',
      );
      return Right(rows.map(_fromMap).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChatMessageEntity>> sendMessage({
    required String tripId,
    required String destination,
    required String tripSummary,
    required String userMessage,
    required List<ChatMessageEntity> history,
  }) async {
    try {
      // Save user message to DB
      final userMsg = ChatMessageEntity(
        id: _uuid.v4(),
        tripId: tripId,
        role: 'user',
        content: userMessage,
        timestamp: DateTime.now(),
      );
      await _saveToDb(userMsg);

      // Build conversation history for API
      final apiHistory = history
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      // Call AI
      final responseText = await _aiService.chatWithAssistant(
        destination: destination,
        tripSummary: tripSummary,
        conversationHistory: apiHistory,
        userMessage: userMessage,
      );

      // Save assistant message
      final assistantMsg = ChatMessageEntity(
        id: _uuid.v4(),
        tripId: tripId,
        role: 'assistant',
        content: responseText,
        timestamp: DateTime.now(),
      );
      await _saveToDb(assistantMsg);

      return Right(assistantMsg);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AIException catch (e) {
      return Left(AIFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearHistory(String tripId) async {
    try {
      await _dbHelper.delete(
          'chat_messages', where: 'trip_id = ?', whereArgs: [tripId]);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveMessage(
      ChatMessageEntity message) async {
    try {
      await _saveToDb(message);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  Future<void> _saveToDb(ChatMessageEntity m) async {
    await _dbHelper.insert('chat_messages', {
      'id': m.id,
      'trip_id': m.tripId,
      'role': m.role,
      'content': m.content,
      'timestamp': m.timestamp.toIso8601String(),
      'message_type': m.messageType,
    });
  }

  ChatMessageEntity _fromMap(Map<String, dynamic> m) => ChatMessageEntity(
        id: m['id'] as String,
        tripId: m['trip_id'] as String,
        role: m['role'] as String,
        content: m['content'] as String,
        timestamp: DateTime.parse(m['timestamp'] as String),
        messageType: m['message_type'] as String? ?? 'text',
      );
}

```
