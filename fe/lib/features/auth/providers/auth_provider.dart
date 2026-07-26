import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/sync/sync_service.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;

  UserProfile({required this.id, required this.name, required this.email});

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final String? errorMessage;
  final UserProfile? user;

  AuthState({
    this.isLoggedIn = false,
    this.isLoading = false,
    this.errorMessage,
    this.user,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    String? errorMessage,
    UserProfile? user,
    bool clearError = false,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  final _api = ApiClient();

  @override
  AuthState build() {
    // Try to restore session on startup
    _checkSession();
    return AuthState();
  }

  Future<void> _checkSession() async {
    final hasToken = await _api.hasToken();
    if (!hasToken) return;

    state = state.copyWith(isLoading: true);

    try {
      final response = await _api.get(ApiEndpoints.me);
      if (response.success && response.data != null) {
        final user = UserProfile.fromJson(response.data);

        // Auto sync if not synced (in case previous sync failed due to invalid IDs)
        try {
          final storage = ref.read(localStorageServiceProvider);
          if (!storage.isCloudSynced()) {
            await ref.read(syncServiceProvider).initialMerge();
          }
        } catch (_) {}

        state = AuthState(isLoggedIn: true, isLoading: false, user: user);
      } else {
        // Token invalid/expired, clean up
        await _api.deleteToken();
        state = AuthState(isLoggedIn: false, isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _api.post(
        ApiEndpoints.login,
        body: {'email': email, 'password': password},
        withAuth: false,
      );

      if (response.success && response.data != null) {
        final token = response.data['token'] as String;
        await _api.saveToken(token);

        final userData = response.data['user'] as Map<String, dynamic>;
        final user = UserProfile.fromJson(userData);

        // Trigger initial merge if available BEFORE setting state to isLoggedIn=true
        try {
          await ref.read(syncServiceProvider).initialMerge();
        } catch (_) {}

        state = AuthState(isLoggedIn: true, isLoading: false, user: user);

        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.error ?? 'Email atau kata sandi salah',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal terhubung ke server. Periksa koneksi internet Anda.',
      );
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _api.post(
        ApiEndpoints.register,
        body: {'name': name, 'email': email, 'password': password},
        withAuth: false,
      );

      if (response.success) {
        // Auto-login after register
        return await login(email, password);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.error ?? 'Gagal mendaftar. Coba lagi.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal terhubung ke server. Periksa koneksi internet Anda.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _api.deleteToken();
    state = AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
