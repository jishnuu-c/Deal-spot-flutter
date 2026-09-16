import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import 'api_client.dart';
import 'storage_service.dart';

class AuditLogState {
  final List<AuditLog> logs;
  final List<RecentActivity> recentActivities;
  final AuditLogFilter filter;
  final int totalElements;
  final int totalPages;
  final int currentPage;
  final bool isLoading;
  final bool isLoadingRecent;
  final String? errorMessage;

  const AuditLogState({
    this.logs = const [],
    this.recentActivities = const [],
    this.filter = const AuditLogFilter(),
    this.totalElements = 0,
    this.totalPages = 0,
    this.currentPage = 0,
    this.isLoading = false,
    this.isLoadingRecent = false,
    this.errorMessage,
  });

  AuditLogState copyWith({
    List<AuditLog>? logs,
    List<RecentActivity>? recentActivities,
    AuditLogFilter? filter,
    int? totalElements,
    int? totalPages,
    int? currentPage,
    bool? isLoading,
    bool? isLoadingRecent,
    String? errorMessage,
  }) {
    return AuditLogState(
      logs: logs ?? this.logs,
      recentActivities: recentActivities ?? this.recentActivities,
      filter: filter ?? this.filter,
      totalElements: totalElements ?? this.totalElements,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      isLoadingRecent: isLoadingRecent ?? this.isLoadingRecent,
      errorMessage: errorMessage,
    );
  }
}

class AuditLogNotifier extends StateNotifier<AuditLogState> {
  final ApiClient _apiClient;

  AuditLogNotifier(this._apiClient) : super(const AuditLogState());

  // Matches Angular getPagedLogs()
  Future<void> fetchPagedLogs({AuditLogFilter? filter}) async {
    final currentFilter = filter ?? state.filter;
    state = state.copyWith(isLoading: true, filter: currentFilter, errorMessage: null);

    try {
      final response = await _apiClient.get(
        '/admin/audit-logs',
        queryParameters: currentFilter.toQueryParams(),
      );

      if (response.statusCode == 200 && response.data != null) {
        dynamic data = response.data;
        if (data is Map && data.containsKey('data') && (data['data'] is Map || data['data'] is List)) {
          data = data['data'];
        }

        if (data is Map) {
          final pageData = AuditLogPage.fromJson(data);
          state = state.copyWith(
            logs: pageData.content,
            totalElements: pageData.totalElements,
            totalPages: pageData.totalPages,
            currentPage: pageData.number,
            isLoading: false,
          );
          return;
        } else if (data is List) {
          final list = data
              .whereType<Map>()
              .map((e) => AuditLog.fromJson(e))
              .toList();
          state = state.copyWith(
            logs: list,
            totalElements: list.length,
            totalPages: 1,
            currentPage: 0,
            isLoading: false,
          );
          return;
        }
      }
      state = state.copyWith(isLoading: false);
    } catch (e, stack) {
      debugPrint('Error fetching audit logs: $e\n$stack');
      String errMsg = 'Failed to load audit logs: $e';
      if (e is DioException) {
        if (e.response?.data != null) {
          final resData = e.response!.data;
          if (resData is Map && resData.containsKey('message')) {
            errMsg = '${resData['message']} (${e.response?.statusCode})';
          } else if (resData is String && resData.isNotEmpty) {
            errMsg = '$resData (${e.response?.statusCode})';
          }
        }
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: errMsg,
      );
    }
  }

  // Matches Angular getRecentActivities()
  Future<List<RecentActivity>> fetchRecentActivities() async {
    state = state.copyWith(isLoadingRecent: true);
    try {
      final response = await _apiClient.get('/admin/audit-logs/recent');
      if (response.statusCode == 200 && response.data != null) {
        dynamic data = response.data;
        if (data is Map && data.containsKey('data') && data['data'] is List) {
          data = data['data'];
        }
        if (data is List) {
          final list = data
              .whereType<Map>()
              .map((e) => RecentActivity.fromJson(e))
              .toList();
          state = state.copyWith(recentActivities: list, isLoadingRecent: false);
          return list;
        }
      }
    } catch (e) {
      debugPrint('Error fetching recent activities: $e');
    }
    state = state.copyWith(isLoadingRecent: false);
    return state.recentActivities;
  }

  // Matches Angular getLogsByEntity()
  Future<List<AuditLog>> fetchLogsByEntity(String entityType, int entityId) async {
    try {
      final response = await _apiClient.get('/admin/audit-logs/entity/$entityType/$entityId');
      if (response.statusCode == 200 && response.data != null) {
        dynamic data = response.data;
        if (data is Map && data.containsKey('data') && data['data'] is List) {
          data = data['data'];
        }
        if (data is List) {
          return data
              .whereType<Map>()
              .map((e) => AuditLog.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching logs by entity: $e');
    }
    return [];
  }

  // Matches Angular getLogsByUser()
  Future<List<AuditLog>> fetchLogsByUser(int userId) async {
    try {
      final response = await _apiClient.get('/admin/audit-logs/user/$userId');
      if (response.statusCode == 200 && response.data != null) {
        dynamic data = response.data;
        if (data is Map && data.containsKey('data') && data['data'] is List) {
          data = data['data'];
        }
        if (data is List) {
          return data
              .whereType<Map>()
              .map((e) => AuditLog.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching logs by user: $e');
    }
    return [];
  }

  void updateFilter(AuditLogFilter newFilter) {
    state = state.copyWith(filter: newFilter);
    fetchPagedLogs(filter: newFilter);
  }

  void changePage(int newPage) {
    if (newPage >= 0 && (state.totalPages == 0 || newPage < state.totalPages)) {
      final updated = state.filter.copyWith(page: newPage);
      state = state.copyWith(filter: updated);
      fetchPagedLogs(filter: updated);
    }
  }

  void logAction(
    String entityType,
    int entityId,
    String action,
    int performedBy,
    String? ipAddress,
    Map<String, dynamic>? payload,
  ) {
    final newId = state.logs.isEmpty
        ? 1
        : state.logs.map((log) => log.id).reduce((a, b) => a > b ? a : b) + 1;
    final log = AuditLog(
      id: newId,
      entityType: entityType,
      entityId: entityId,
      action: action,
      performedById: performedBy,
      ipAddress: ipAddress,
      parsedPayload: payload,
      createdAt: DateTime.now().toIso8601String(),
    );
    state = state.copyWith(logs: [log, ...state.logs]);
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ApiClient(storage);
});

final auditLogRepositoryProvider =
    StateNotifierProvider<AuditLogNotifier, AuditLogState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuditLogNotifier(apiClient);
});

