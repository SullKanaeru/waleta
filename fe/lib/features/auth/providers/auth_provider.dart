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

  AuthState({this.isLoggedIn = false, this.isLoading = false, this.errorMessage, this.user});

  AuthState copyWith({bool? isLoggedIn, bool? isLoading, String? errorMessage, UserProfile? user, bool clearError = false}) {
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

    final response = await _api.get(ApiEndpoints.me);
    if (response.success && response.data != null) {
      final user = UserProfile.fromJson(response.data);
      state = AuthState(isLoggedIn: true, user: user);
    } else {
      // Token invalid/expired, clean up
      await _api.deleteToken();
      state = AuthState();
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

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

      state = AuthState(isLoggedIn: true, user: user);

      // Trigger The Great Data Merge if local data has not been synced yet
      try {
        await ref.read(syncServiceProvider).initialMerge();
      } catch (_) {}

      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: response.error ?? 'Email atau kata sandi salah',
      );
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

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
  }

  Future<void> logout() async {
    await _api.deleteToken();
    state = AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
