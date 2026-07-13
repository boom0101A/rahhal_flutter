# ملف كود Dart: lib\features\auth\presentation\cubit\auth_cubit.dart

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;

  AuthCubit({required AuthRepository repository})
      : _repository = repository,
        super(const AuthInitial());

  Future<void> signInAnonymously() async {
    emit(const AuthLoading());
    final result = await _repository.signInAnonymously();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> signInWithEmail(String email, String password) async {
    emit(const AuthLoading());
    final result = await _repository.signInWithEmail(email, password);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> register(
      String email, String password, String displayName) async {
    emit(const AuthLoading());
    final result = await _repository.registerWithEmail(
        email, password, displayName);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> signOut() async {
    await _repository.signOut();
    emit(const AuthInitial());
  }

  void checkCurrentUser() {
    final user = _repository.getCurrentUser();
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(const AuthInitial());
    }
  }
}

```
