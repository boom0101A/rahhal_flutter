# ملف كود Dart: lib\features\auth\domain\entities\user_entity.dart

```dart
import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final bool isAnonymous;

  const UserEntity({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
    this.isAnonymous = false,
  });

  String get initials {
    if (displayName != null && displayName!.isNotEmpty) {
      final parts = displayName!.split(' ');
      if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
      return displayName![0];
    }
    if (email != null && email!.isNotEmpty) return email![0].toUpperCase();
    return '؟';
  }

  @override
  List<Object?> get props => [uid, displayName, email, photoUrl, isAnonymous];
}

```
