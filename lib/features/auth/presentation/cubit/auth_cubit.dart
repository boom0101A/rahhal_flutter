import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/cloud_sync_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;

  AuthCubit({required AuthRepository repository})
      : _repository = repository,
        super(const AuthInitial());

  Future<void> _restoreCloudData(String uid) async {
    try {
      await sl<CloudSyncService>().restoreTripsFromCloud(uid);
    } catch (e) {
      debugPrint('AuthCubit: Failed to restore cloud data: $e');
    }
  }

  Future<void> signInAnonymously() async {
    emit(const AuthLoading());
    final result = await _repository.signInAnonymously();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) {
        emit(AuthAuthenticated(user));
        _restoreCloudData(user.uid);
      },
    );
  }

  Future<void> signInWithGoogle() async {
    emit(const AuthLoading());
    final result = await _repository.signInWithGoogle();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) {
        emit(AuthAuthenticated(user));
        _restoreCloudData(user.uid);
      },
    );
  }

  Future<void> signInWithEmail(String email, String password) async {
    emit(const AuthLoading());
    final result = await _repository.signInWithEmail(email, password);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) {
        emit(AuthAuthenticated(user));
        _restoreCloudData(user.uid);
      },
    );
  }

  Future<void> register(
      String email, String password, String displayName) async {
    emit(const AuthLoading());
    final result = await _repository.registerWithEmail(
        email, password, displayName);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) {
        emit(AuthAuthenticated(user));
        // A new user has no cloud data yet, but for consistency we can call it
        // or just rely on local state. It's harmless.
        _restoreCloudData(user.uid);
      },
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
      _restoreCloudData(user.uid);
    } else {
      emit(const AuthInitial());
    }
  }
}
