import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import 'storage_service.dart';
import 'api_client.dart';

class AuthState {
  final User? currentUser;
  final AdminUser? currentAdmin;
  final String? errorMessage;
  final bool isLoading;

  const AuthState({
    this.currentUser,
    this.currentAdmin,
    this.errorMessage,
    this.isLoading = false,
  });

  bool get isLoggedIn => currentUser != null;
  bool get isAdminLoggedIn => currentAdmin != null;
  String? get error => errorMessage;

  AuthState copyWith({
    User? currentUser,
    AdminUser? currentAdmin,
    String? errorMessage,
    bool? isLoading,
    bool clearUser = false,
    bool clearAdmin = false,
  }) {
    return AuthState(
      currentUser: clearUser ? null : (currentUser ?? this.currentUser),
      currentAdmin: clearAdmin ? null : (currentAdmin ?? this.currentAdmin),
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final StorageService _storageService;
  final ApiClient _apiClient;

  AuthNotifier(this._storageService, this._apiClient) : super(const AuthState()) {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    state = state.copyWith(isLoading: true);
    final userJson = await _storageService.getUser();
    final adminJson = await _storageService.getAdminUser();

    User? restoredUser;
    AdminUser? restoredAdmin;

    if (userJson != null) {
      try {
        restoredUser = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      } catch (_) {}
    }

    if (adminJson != null) {
      try {
        restoredAdmin = AdminUser.fromJson(jsonDecode(adminJson) as Map<String, dynamic>);
      } catch (_) {}
    }

    state = AuthState(
      currentUser: restoredUser,
      currentAdmin: restoredAdmin,
      isLoading: false,
    );
  }

  // Customer Login
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _apiClient.post(
        '/auth/user/login',
        data: {'email': email.trim(), 'password': password},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final token = data['token'] as String? ?? '';
        final user = User(
          id: (data['id'] as num?)?.toInt() ?? 101,
          cityId: (data['cityId'] as num?)?.toInt() ?? 1,
          fullName: data['fullName'] as String? ?? email.split('@').first,
          email: data['email'] as String? ?? email,
          phone: data['phone'] as String? ?? '',
          preferredLang: 'en',
          emailVerified: 1,
          phoneVerified: 1,
          isActive: 1,
        );

        await _storageService.saveToken(token);
        await _storageService.saveUser(jsonEncode(user.toJson()));

        state = state.copyWith(
          isLoading: false,
          currentUser: user,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Login failed: Invalid credentials',
        );
        return false;
      }
    } catch (e) {
      // Fallback for offline testing or friendly error message
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().contains('401')
            ? 'Invalid email or password'
            : 'Unable to connect to server. Please check your network.',
      );
      return false;
    }
  }

  // Customer Register
  Future<bool> register(String fullName, String email, String phone, int cityId, {String password = 'Password@123'}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _apiClient.post(
        '/auth/user/register',
        data: {
          'fullName': fullName.trim(),
          'email': email.trim(),
          'phone': phone.trim(),
          'cityId': cityId,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final token = data['token'] as String? ?? '';
        final user = User(
          id: (data['id'] as num?)?.toInt() ?? 201,
          cityId: cityId,
          fullName: data['fullName'] as String? ?? fullName,
          email: data['email'] as String? ?? email,
          phone: phone,
          preferredLang: 'en',
          emailVerified: 1,
          phoneVerified: 0,
          isActive: 1,
        );

        await _storageService.saveToken(token);
        await _storageService.saveUser(jsonEncode(user.toJson()));

        state = state.copyWith(
          isLoading: false,
          currentUser: user,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Registration failed.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Registration failed. Server may be unreachable.',
      );
      return false;
    }
  }

  // Admin Login
  Future<bool> adminLogin(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _apiClient.post(
        '/auth/admin/login',
        data: {'email': email.trim(), 'password': password},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final token = data['token'] as String? ?? '';
        final role = data['role'] as String? ?? 'superadmin';

        final admin = AdminUser(
          id: (data['id'] as num?)?.toInt() ?? 1,
          fullName: data['fullName'] as String? ?? 'System Administrator',
          email: data['email'] as String? ?? email,
          role: role,
          isActive: 1,
          lastLoginAt: DateTime.now().toIso8601String(),
        );

        final user = User(
          id: admin.id,
          fullName: admin.fullName,
          email: admin.email,
          preferredLang: 'en',
          emailVerified: 1,
          phoneVerified: 1,
          isActive: 1,
        );

        await _storageService.saveAdminToken(token);
        await _storageService.saveAdminUser(jsonEncode(admin.toJson()));
        await _storageService.saveToken(token);
        await _storageService.saveUser(jsonEncode(user.toJson()));

        state = state.copyWith(
          isLoading: false,
          currentAdmin: admin,
          currentUser: user,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Admin login failed.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Admin login failed. Invalid credentials or server offline.',
      );
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _storageService.clearAuthData();
    state = const AuthState(); // Reset state
  }

  // Update Profile
  Future<void> updateProfile(User user) async {
    await _storageService.saveUser(jsonEncode(user.toJson()));
    state = state.copyWith(currentUser: user);
  }
}

// Providers
final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(storage, apiClient);
});
