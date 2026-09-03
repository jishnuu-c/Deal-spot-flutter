import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import 'api_client.dart';
import 'store_repository.dart';

class PartnerRequestState {
  final List<PartnerRequest> requests;
  final bool isLoading;
  final String? errorMessage;

  const PartnerRequestState({
    required this.requests,
    this.isLoading = false,
    this.errorMessage,
  });

  PartnerRequestState copyWith({
    List<PartnerRequest>? requests,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PartnerRequestState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class PartnerRequestNotifier extends StateNotifier<PartnerRequestState> {
  final Ref _ref;
  final ApiClient _apiClient;

  PartnerRequestNotifier(this._ref, this._apiClient)
      : super(const PartnerRequestState(requests: [], isLoading: true)) {
    fetchRequests();
  }

  Future<void> fetchRequests({PartnerRequestStatus? status}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      String path = '/admin/partner-requests';
      if (status != null) {
        path += '?status=${status.name}';
      }
      final response = await _apiClient.get(path);
      if (response.statusCode == 200 && response.data != null) {
        final rawList = response.data as List;
        final list = rawList
            .map((e) => PartnerRequest.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(requests: list, isLoading: false);
        return;
      }
    } catch (e) {
      debugPrint('Error loading partner requests: $e');
    }
    state = state.copyWith(isLoading: false);
  }

  List<PartnerRequest> getRequests({PartnerRequestStatus? status}) {
    if (status == null) return state.requests;
    return state.requests.where((r) => r.status == status).toList();
  }

  Future<bool> submitApplication(PartnerRequest req) async {
    try {
      final response = await _apiClient.post(
        '/partner-requests/apply',
        data: req.toJson(),
      );
      if (response.statusCode == 200 && response.data != null) {
        final created = PartnerRequest.fromJson(response.data as Map<String, dynamic>);
        state = state.copyWith(requests: [created, ...state.requests]);
        return true;
      }
    } catch (e) {
      debugPrint('Error submitting partner request: $e');
    }

    final newId = state.requests.isEmpty ? 1 : state.requests.map((r) => r.id).reduce((a, b) => a > b ? a : b) + 1;
    final newReq = req.copyWith(
      id: newId,
      status: PartnerRequestStatus.PENDING,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(requests: [newReq, ...state.requests]);
    return true;
  }

  Future<PartnerRequest?> approveRequest(int id) async {
    try {
      final response = await _apiClient.post('/admin/partner-requests/$id/approve');
      PartnerRequest? approvedItem;
      if (response.statusCode == 200 && response.data != null) {
        approvedItem = PartnerRequest.fromJson(response.data as Map<String, dynamic>);
      }

      // Refresh stores list since a new store was provisioned
      _ref.read(storeRepositoryProvider.notifier).fetchStores();

      final list = [...state.requests];
      final idx = list.indexWhere((r) => r.id == id);
      if (idx != -1) {
        list[idx] = approvedItem ?? list[idx].copyWith(
          status: PartnerRequestStatus.APPROVED,
          reviewedAt: DateTime.now(),
        );
        state = state.copyWith(requests: list);
        return list[idx];
      }
      return approvedItem;
    } catch (e) {
      debugPrint('Error approving partner request: $e');
      // Fallback local update if offline
      final list = [...state.requests];
      final idx = list.indexWhere((r) => r.id == id);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(
          status: PartnerRequestStatus.APPROVED,
          reviewedAt: DateTime.now(),
        );
        state = state.copyWith(requests: list);
        return list[idx];
      }
      return null;
    }
  }

  Future<bool> rejectRequest(int id, String reason) async {
    try {
      await _apiClient.post(
        '/admin/partner-requests/$id/reject',
        data: {'reason': reason},
      );
    } catch (e) {
      debugPrint('Error rejecting partner request: $e');
    }

    final list = [...state.requests];
    final idx = list.indexWhere((r) => r.id == id);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(
        status: PartnerRequestStatus.REJECTED,
        rejectionReason: reason,
        reviewedAt: DateTime.now(),
      );
      state = state.copyWith(requests: list);
      return true;
    }
    return false;
  }
}

final partnerRequestRepositoryProvider =
    StateNotifierProvider<PartnerRequestNotifier, PartnerRequestState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PartnerRequestNotifier(ref, apiClient);
});
