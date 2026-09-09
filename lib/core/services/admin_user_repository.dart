import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import 'api_client.dart';
import 'auth_repository.dart';

class AdminUserState {
  final List<AdminUser> admins;
  final bool isLoading;
  final String? errorMessage;

  const AdminUserState({
    required this.admins,
    this.isLoading = false,
    this.errorMessage,
  });

  AdminUserState copyWith({
    List<AdminUser>? admins,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AdminUserState(
      admins: admins ?? this.admins,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AdminUserNotifier extends StateNotifier<AdminUserState> {
  final Ref _ref;
  final ApiClient _apiClient;

  AdminUserNotifier(this._ref, this._apiClient)
      : super(const AdminUserState(admins: [], isLoading: false));

  Future<void> fetchAdmins() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _apiClient.get('/admin/users/fetch-all');
      if (response.statusCode == 200 && response.data != null) {
        dynamic raw = response.data;
        if (raw is String) {
          raw = jsonDecode(raw);
        }
        List rawList = [];
        if (raw is List) {
          rawList = raw;
        } else if (raw is Map && raw['data'] is List) {
          rawList = raw['data'] as List;
        } else if (raw is Map && raw['content'] is List) {
          rawList = raw['content'] as List;
        }

        final list = <AdminUser>[];
        for (final item in rawList) {
          try {
            if (item is Map<String, dynamic>) {
              list.add(AdminUser.fromJson(item));
            } else if (item is Map) {
              list.add(AdminUser.fromJson(Map<String, dynamic>.from(item)));
            }
          } catch (_) {}
        }

        state = state.copyWith(admins: list, isLoading: false, clearError: true);
        return;
      }
    } catch (e) {
      final errStr = e.toString();
      String cleanError;
      if (errStr.contains('401')) {
        cleanError = '401_UNAUTHORIZED';
      } else if (errStr.contains('Connection refused') ||
          errStr.contains('SocketException') ||
          errStr.contains('Network is unreachable') ||
          errStr.contains('connectTimeout')) {
        cleanError = 'SERVER_UNREACHABLE';
      } else {
        cleanError = errStr;
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: cleanError,
      );
      return;
    }

    state = state.copyWith(isLoading: false);
  }

  Future<AdminUser> createAdmin({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await _apiClient.post(
      '/admin/users/create',
      data: {
        'fullName': fullName.trim(),
        'email': email.trim(),
        'password': password,
        'role': role,
      },
    );

    if (response.statusCode == 200 && response.data != null) {
      final newAdmin = AdminUser.fromJson(response.data as Map<String, dynamic>);
      state = state.copyWith(
        admins: [...state.admins.where((a) => a.id != newAdmin.id), newAdmin],
      );
      return newAdmin;
    } else {
      throw Exception('Failed to create admin user');
    }
  }

  Future<AdminUser> toggleAdminStatus(int id) async {
    final response = await _apiClient.put('/admin/users/toggle/$id');
    if (response.statusCode == 200 && response.data != null) {
      final updated = AdminUser.fromJson(response.data as Map<String, dynamic>);
      state = state.copyWith(
        admins: state.admins.map((a) => a.id == updated.id ? updated : a).toList(),
      );
      return updated;
    } else {
      // Fallback local toggle if response is empty
      final current = state.admins.firstWhere((a) => a.id == id);
      final toggled = current.copyWith(isActive: current.isActive == 1 ? 0 : 1);
      state = state.copyWith(
        admins: state.admins.map((a) => a.id == id ? toggled : a).toList(),
      );
      return toggled;
    }
  }

  Future<void> deleteAdmin(int id) async {
    final response = await _apiClient.delete('/admin/users/delete/$id');
    if (response.statusCode == 200) {
      state = state.copyWith(
        admins: state.admins.where((a) => a.id != id).toList(),
      );
    } else {
      throw Exception('Failed to delete admin user');
    }
  }
}

final adminUserRepositoryProvider =
    StateNotifierProvider<AdminUserNotifier, AdminUserState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AdminUserNotifier(ref, apiClient);
});
