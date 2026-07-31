import 'dart:async';
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
    if (isClosed) return;
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) {
        emit(AuthAuthenticated(user));
        _repository.restoreCloudData(user.uid);
      },
    );
  }

  Future<void> signInWithGoogle() async {
    emit(const AuthLoading());
    final result = await _repository.signInWithGoogle();
    if (isClosed) return;
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) {
        emit(AuthAuthenticated(user));
        unawaited(_repository.restoreCloudData(user.uid));
      },
    );
  }

  Future<void> signInWithEmail(String email, String password) async {
    emit(const AuthLoading());
    final result = await _repository.signInWithEmail(email, password);
    if (isClosed) return;
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) {
        emit(AuthAuthenticated(user));
        _repository.restoreCloudData(user.uid);
      },
    );
  }

  Future<void> register(
      String email, String password, String displayName) async {
    emit(const AuthLoading());
    final result = await _repository.registerWithEmail(
        email, password, displayName);
    if (isClosed) return;
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) {
        emit(AuthAuthenticated(user));
        // A new user has no cloud data yet, but for consistency we can call it
        // or just rely on local state. It's harmless.
        _repository.restoreCloudData(user.uid);
      },
    );
  }

  Future<void> signOut() async {
    await _repository.signOut();
    if (isClosed) return;
    emit(const AuthInitial());
  }

  /// Updates the display name and refreshes state so every screen showing it
  /// (Profile, Settings, the chat header) re-renders with the new value.
  /// Returns null on success, or a message to show the user on failure.
  Future<String?> updateDisplayName(String name) async {
    final result = await _repository.updateDisplayName(name);
    if (isClosed) return null;
    return result.fold(
      (failure) => failure.message,
      (user) {
        emit(AuthAuthenticated(user));
        return null;
      },
    );
  }

  /// Deletes the account, its cloud data, and every trip stored on this device.
  ///
  /// Returns null on success, or an error code the UI can localize — notably
  /// `auth/requires-recent-login`, which means the user must sign in again
  /// before the deletion is permitted.
  Future<String?> deleteAccount() async {
    emit(const AuthLoading());
    final result = await _repository.deleteAccount();
    if (isClosed) return null;

    return result.fold(
      (failure) {
        // Keep the user signed in so they can re-authenticate and retry.
        final user = _repository.getCurrentUser();
        emit(user != null ? AuthAuthenticated(user) : const AuthInitial());
        return failure.message;
      },
      (_) async {
        // The cloud copy is gone; leaving local trips behind would resurrect
        // them on the next sign-in via cloud sync and contradict the deletion.
        await _repository.clearLocalData();
        if (isClosed) return null;
        emit(const AuthInitial());
        return null;
      },
    );
  }

  void checkCurrentUser() {
    final user = _repository.getCurrentUser();
    if (user != null) {
      emit(AuthAuthenticated(user));
      _repository.restoreCloudData(user.uid);
    } else {
      emit(const AuthInitial());
    }
  }
}
