// lib/application/auth_bloc.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:edi_translator/data/auth_api.dart';
import 'package:edi_translator/data/auth_model.dart';
import 'package:edi_translator/data/blockchain_api.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({
    required this.role,
    required this.username,
    required this.password,
  });
  final String role;
  final String username;
  final String password;
  @override
  List<Object?> get props => [role, username, password];
}

class AuthRegisterRequested extends AuthEvent {
  const AuthRegisterRequested({
    required this.studentId,
    required this.password,
    required this.university,
  });
  final String studentId;
  final String password;
  final String university;
  @override
  List<Object?> get props => [studentId, password, university];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.session);
  final UserSession session;
  @override
  List<Object?> get props => [session];
}

class AuthRegistered extends AuthState {
  const AuthRegistered(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthInitial()) {
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
  }

  Future<void> _onLogin(
      AuthLoginRequested e, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final session = await AuthApi.login(
        role: e.role,
        username: e.username,
        password: e.password,
      );
      emit(AuthAuthenticated(session));
    } on ApiException catch (ex) {
      emit(AuthError(ex.message));
    } catch (ex) {
      emit(AuthError(_networkMsg(ex)));
    }
  }

  Future<void> _onRegister(
      AuthRegisterRequested e, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final msg = await AuthApi.registerStudent(
        studentId: e.studentId,
        password: e.password,
        university: e.university,
      );
      emit(AuthRegistered(msg));
    } on ApiException catch (ex) {
      emit(AuthError(ex.message));
    } catch (ex) {
      emit(AuthError(_networkMsg(ex)));
    }
  }

  void _onLogout(AuthLogoutRequested e, Emitter<AuthState> emit) {
    emit(const AuthInitial());
  }

  String _networkMsg(Object ex) {
    final s = ex.toString();
    if (s.contains('SocketException') ||
        s.contains('Connection refused') ||
        s.contains('TimeoutException')) {
      return 'Cannot reach server.\nMake sure Flask is running on your PC.';
    }
    return s;
  }
}
