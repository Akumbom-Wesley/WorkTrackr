import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';
import '../../shared/models/auth_model.dart';
import 'package:dio/dio.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final LoggedInUser? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    LoggedInUser? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState());

  Future<void> login({
    required String erpNextEmployeeId,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final authResponse = await _repository.login(
        erpNextEmployeeId: erpNextEmployeeId,
        password: password,
      );

      await _repository.saveTokens(authResponse);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: LoggedInUser(
          userId: authResponse.userId,
          employeeId: authResponse.employeeId,
          erpnextEmployeeId: authResponse.erpnextEmployeeId,
          fullName: authResponse.fullName,
          role: authResponse.role,
          accessToken: authResponse.access,
          refreshToken: authResponse.refresh,
        ),
        errorMessage: null,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _mapDioError(e),
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'An unexpected error occurred.',
      );
    }
  }

  Future<void> checkStoredSession() async {
    final user = await _repository.getStoredUser();
    if (user != null) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> logout() async {
    await _repository.clearTokens();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  String _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please try again.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection.';
    }
    final statusCode = e.response?.statusCode;
    if (statusCode == 401) return 'Invalid Employee ID or password.';
    if (statusCode == 400) return 'Please fill in all fields.';
    if (statusCode == 500) return 'Server error. Please try again later.';
    return 'Something went wrong. Please try again.';
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(authRepositoryProvider)),
);
