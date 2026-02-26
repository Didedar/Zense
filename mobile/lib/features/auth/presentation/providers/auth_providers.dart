import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/datasources/auth_api_service.dart';
import '../../data/models/auth_models.dart';

// Auth API service provider
final authApiServiceProvider = Provider<AuthApiService>((ref) {
  final client = ref.watch(dioClientProvider);
  return AuthApiService(client);
});

// Auth state
enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final UserRead? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });

  AuthState copyWith({AuthStatus? status, UserRead? user, String? error}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApiService _authApi;
  final SecureStorage _secureStorage;

  AuthNotifier(this._authApi, this._secureStorage) : super(const AuthState());

  Future<void> checkSession() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final hasTokens = await _secureStorage.hasTokens();
      if (!hasTokens) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }
      final user = await _authApi.getMe();
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      await _secureStorage.clearTokens();
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final tokens = await _authApi.login(email: email, password: password);
      await _secureStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      final user = await _authApi.getMe();
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  Future<void> register(
      String email, String password, String displayName) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final tokens = await _authApi.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      await _secureStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      final user = await _authApi.getMe();
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    await _secureStorage.clearTokens();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authApi = ref.watch(authApiServiceProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final dioClient = ref.watch(dioClientProvider);

  final notifier = AuthNotifier(authApi, secureStorage);
  dioClient.onUnauthenticated = () {
    notifier.logout();
  };
  return notifier;
});
