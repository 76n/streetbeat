import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(const AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthUserSynced>(_onUserSynced);
    on<AuthSignInEmail>(_onSignInEmail);
    on<AuthSignInGoogle>(_onSignInGoogle);
    on<AuthSignUp>(_onSignUp);
    on<AuthSignOut>(_onSignOut);
  }

  final AuthRepository _repository;
  StreamSubscription<User?>? _authSub;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    await _authSub?.cancel();
    final current = _repository.currentUser;
    emit(
      current != null
          ? AuthAuthenticated(current)
          : const AuthUnauthenticated(),
    );
    _authSub = _repository.authStateChanges.listen((user) {
      if (!isClosed) {
        add(AuthUserSynced(user));
      }
    });
  }

  void _onUserSynced(AuthUserSynced event, Emitter<AuthState> emit) {
    final user = event.user;
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onSignInEmail(
    AuthSignInEmail event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _repository.signInWithEmailAndPassword(
        email: event.email.trim(),
        password: event.password,
      );
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapFirebaseAuthMessage(e)));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignInGoogle(
    AuthSignInGoogle event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _repository.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapFirebaseAuthMessage(e)));
    } on StateError catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignUp(AuthSignUp event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final credential = await _repository.createUserWithEmailAndPassword(
        email: event.email.trim(),
        password: event.password,
      );
      final user = credential.user;
      if (user == null) {
        emit(const AuthError('Could not create account.'));
        return;
      }
      try {
        await _repository.createUserDocument(
          uid: user.uid,
          name: event.name.trim(),
          email: event.email.trim(),
          activityType: event.activityType,
          weeklyGoalRuns: event.weeklyGoalRuns,
          raceGoal: event.raceGoal,
        );
      } catch (e) {
        await _repository.signOut();
        emit(AuthError('Could not save your profile: $e'));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_mapFirebaseAuthMessage(e)));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignOut(AuthSignOut event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      await _repository.signOut();
    } catch (e) {
      emit(AuthError(e.toString()));
      final user = _repository.currentUser;
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthUnauthenticated());
      }
    }
  }

  String _mapFirebaseAuthMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return e.message ?? e.code;
    }
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    return super.close();
  }
}
