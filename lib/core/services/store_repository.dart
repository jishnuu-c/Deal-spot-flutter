import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart' hide Category;
import '../../models/models.dart';
import 'api_client.dart';
import 'city_repository.dart';
import 'category_repository.dart';

class StoreState {
  final List<Store> stores;
  final List<StoreBranch> branches;
  final List<int> followedStoreIds; // Store IDs followed by the current user
  final bool isLoading;

  const StoreState({
    required this.stores,
    required this.branches,
    required this.followedStoreIds,
    this.isLoading = false,
  });

  StoreState copyWith({
    List<Store>? stores,
    List<StoreBranch>? branches,
    List<int>? followedStoreIds,
    bool? isLoading,
  }) {
    return StoreState(
      stores: stores ?? this.stores,
      branches: branches ?? this.branches,
      followedStoreIds: followedStoreIds ?? this.followedStoreIds,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class StoreNotifier extends StateNotifier<StoreState> {
  final Ref _ref;
  final ApiClient _apiClient;

  StoreNotifier(this._ref, this._apiClient)
      : super(const StoreState(
          stores: [],
          branches: [],
          followedStoreIds: [],
          isLoading: true,
        )) {
    fetchStores();
    fetchFollowedStores();
  }

  Future<void> fetchStores() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiClient.get('/stores/fetch-all-stores');
      if (response.statusCode == 200 && response.data != null) {
        final rawList = response.data as List;
        final list = rawList.map((e) => Store.fromJson(e as Map<String, dynamic>)).toList();
        state = state.copyWith(stores: list, isLoading: false);
        return;
      }
    } catch (_) {}
    state = state.copyWith(isLoading: false);
  }

  Future<void> fetchFollowedStores() async {
    try {
      final response = await _apiClient.get('/stores/my-followed');
      if (response.statusCode == 200 && response.data != null) {
        final rawList = response.data as List;
        final list = rawList.map((e) => (e['id'] as num).toInt()).toList();
        state = state.copyWith(followedStoreIds: list);
      }
    } catch (_) {}
  }

  List<Store> getStores({int? cityId, int? categoryId}) {
    var list = state.stores;
    if (cityId != null) {
      list = list.where((s) => s.cityId == cityId).toList();
    }
    if (categoryId != null) {
      list = list.where((s) => s.categoryId == categoryId).toList();
    }
    return list.map((s) => _populateStore(s)).toList();
  }

  List<Store> getStoresForSelectedCity(int? cityId) {
    return getStores(cityId: cityId);
  }

  Store _populateStore(Store s) {
    final cities = _ref.read(cityRepositoryProvider).cities;
    final categories = _ref.read(categoryRepositoryProvider);
    final branches = state.branches.where((b) => b.storeId == s.id).toList();

    return s.copyWith(
      city: s.city ?? cities.where((c) => c.id == s.cityId).firstOrNull,
      category: s.category ?? categories.where((c) => c.id == s.categoryId).firstOrNull,
      branchesCount: branches.length,
      isFollowed: state.followedStoreIds.contains(s.id),
    );
  }

  Store? getStoreById(int id) {
    try {
      final store = state.stores.firstWhere((s) => s.id == id);
      return _populateStore(store);
    } catch (_) {
      return null;
    }
  }

  List<StoreBranch> getBranchesForStore(int storeId) {
    final cities = _ref.read(cityRepositoryProvider).cities;
    return state.branches
        .where((b) => b.storeId == storeId)
        .map((b) => b.copyWith(
              city: b.city ?? cities.where((c) => c.id == b.cityId).firstOrNull,
            ))
        .toList();
  }

  // Follow Store Toggle
  Future<bool> toggleFollowStore(int storeId) async {
    final isCurrentlyFollowed = state.followedStoreIds.contains(storeId);
    final updatedList = List<int>.from(state.followedStoreIds);

    if (isCurrentlyFollowed) {
      updatedList.remove(storeId);
    } else {
      updatedList.add(storeId);
    }
    state = state.copyWith(followedStoreIds: updatedList);

    try {
      final response = await _apiClient.post('/stores/$storeId/follow-toggle');
      if (response.statusCode == 200 && response.data != null) {
        final isFollowing = response.data['isFollowing'] as bool? ?? !isCurrentlyFollowed;
        return isFollowing;
      }
    } catch (_) {}

    return !isCurrentlyFollowed;
  }

  bool isFollowing(int storeId) {
    return state.followedStoreIds.contains(storeId);
  }

  List<Store> getFollowedStores() {
    return state.stores
        .where((s) => state.followedStoreIds.contains(s.id))
        .map((s) => _populateStore(s))
        .toList();
  }

  // Admin CRUD - Stores with Multipart Form Uploads
  Future<bool> createStore({
    required String nameEn,
    required String nameAr,
    required int cityId,
    required int categoryId,
    String? descriptionEn,
    String? descriptionAr,
    String? crNumber,
    String? vatNumber,
    String? contactPhone,
    String? contactEmail,
    String? website,
    bool isVerified = false,
    bool isFeatured = false,
    bool isActive = true,
    bool createManagerAccount = false,
    String? managerName,
    String? managerEmail,
    String? managerPassword,
    XFile? logoFile,
  }) async {
    try {
      final payload = {
        'nameEn': nameEn,
        'nameAr': nameAr,
        'cityId': cityId,
        'categoryId': categoryId,
        'descriptionEn': descriptionEn ?? '',
        'descriptionAr': descriptionAr ?? '',
        'crNumber': crNumber ?? '',
        'vatNumber': vatNumber ?? '',
        'contactPhone': contactPhone ?? '',
        'contactEmail': contactEmail ?? '',
        'website': website ?? '',
        'verified': isVerified,
        'featured': isFeatured,
        'active': isActive,
        if (createManagerAccount) ...{
          'managerName': managerName ?? nameEn,
          'managerEmail': managerEmail ?? contactEmail ?? '',
          'managerPassword': managerPassword ?? 'Partner@123',
        },
      };

      MultipartFile? filePart;
      if (logoFile != null) {
        final bytes = await logoFile.readAsBytes();
        final ext = logoFile.name.split('.').last.toLowerCase();
        final contentType = ext == 'png'
            ? MediaType('image', 'png')
            : ext == 'webp'
                ? MediaType('image', 'webp')
                : ext == 'svg'
                    ? MediaType('image', 'svg+xml')
                    : MediaType('image', 'jpeg');
        filePart = MultipartFile.fromBytes(bytes, filename: logoFile.name, contentType: contentType);
      }

      final formData = FormData();
      formData.files.add(MapEntry(
        'body',
        MultipartFile.fromString(
          jsonEncode(payload),
          contentType: MediaType('application', 'json'),
        ),
      ));
      if (filePart != null) {
        formData.files.add(MapEntry('file', filePart));
      }

      final response = await _apiClient.post('/stores/create', data: formData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null && response.data is Map<String, dynamic>) {
          final created = Store.fromJson(response.data as Map<String, dynamic>);
          state = state.copyWith(stores: [created, ...state.stores]);
        } else {
          await fetchStores();
        }
        return true;
      }
    } catch (_) {}

    // Local fallback
    final newId = state.stores.isEmpty ? 1 : state.stores.map((s) => s.id).reduce((a, b) => a > b ? a : b) + 1;
    final newStore = Store(
      id: newId,
      cityId: cityId,
      categoryId: categoryId,
      nameEn: nameEn,
      nameAr: nameAr,
      logoUrl: '',
      descriptionEn: descriptionEn,
      descriptionAr: descriptionAr,
      crNumber: crNumber,
      vatNumber: vatNumber,
      contactPhone: contactPhone,
      contactEmail: contactEmail,
      website: website,
      isVerified: isVerified ? 1 : 0,
      isActive: isActive ? 1 : 0,
      featured: isFeatured,
    );
    state = state.copyWith(stores: [newStore, ...state.stores]);
    return true;
  }

  Future<bool> updateStore({
    required int id,
    required String nameEn,
    required String nameAr,
    required int cityId,
    required int categoryId,
    String? descriptionEn,
    String? descriptionAr,
    String? crNumber,
    String? vatNumber,
    String? contactPhone,
    String? contactEmail,
    String? website,
    bool isVerified = false,
    bool isFeatured = false,
    bool isActive = true,
    XFile? logoFile,
  }) async {
    try {
      final payload = {
        'nameEn': nameEn,
        'nameAr': nameAr,
        'cityId': cityId,
        'categoryId': categoryId,
        'descriptionEn': descriptionEn ?? '',
        'descriptionAr': descriptionAr ?? '',
        'crNumber': crNumber ?? '',
        'vatNumber': vatNumber ?? '',
        'contactPhone': contactPhone ?? '',
        'contactEmail': contactEmail ?? '',
        'website': website ?? '',
        'verified': isVerified,
        'featured': isFeatured,
        'active': isActive,
      };

      MultipartFile? filePart;
      if (logoFile != null) {
        final bytes = await logoFile.readAsBytes();
        final ext = logoFile.name.split('.').last.toLowerCase();
        final contentType = ext == 'png'
            ? MediaType('image', 'png')
            : ext == 'webp'
                ? MediaType('image', 'webp')
                : ext == 'svg'
                    ? MediaType('image', 'svg+xml')
                    : MediaType('image', 'jpeg');
        filePart = MultipartFile.fromBytes(bytes, filename: logoFile.name, contentType: contentType);
      }

      final formData = FormData();
      formData.files.add(MapEntry(
        'body',
        MultipartFile.fromString(
          jsonEncode(payload),
          contentType: MediaType('application', 'json'),
        ),
      ));
      if (filePart != null) {
        formData.files.add(MapEntry('file', filePart));
      }

      final response = await _apiClient.put('/stores/update-store/$id', data: formData);
      if (response.statusCode == 200 && response.data != null && response.data is Map<String, dynamic>) {
        final updated = Store.fromJson(response.data as Map<String, dynamic>);
        state = state.copyWith(
          stores: state.stores.map((s) => s.id == id ? updated : s).toList(),
        );
        return true;
      }
    } catch (_) {}

    // Local fallback
    state = state.copyWith(
      stores: state.stores.map((s) {
        if (s.id == id) {
          return s.copyWith(
            nameEn: nameEn,
            nameAr: nameAr,
            cityId: cityId,
            categoryId: categoryId,
            descriptionEn: descriptionEn,
            descriptionAr: descriptionAr,
            crNumber: crNumber,
            vatNumber: vatNumber,
            contactPhone: contactPhone,
            contactEmail: contactEmail,
            website: website,
            isVerified: isVerified ? 1 : 0,
            isActive: isActive ? 1 : 0,
            featured: isFeatured,
          );
        }
        return s;
      }).toList(),
    );
    return true;
  }

  Future<bool> toggleFeatured(int id) async {
    try {
      final response = await _apiClient.put('/stores/toggle-featured/$id', data: {});
      if (response.statusCode == 200 && response.data != null) {
        final updated = Store.fromJson(response.data as Map<String, dynamic>);
        state = state.copyWith(
          stores: state.stores.map((s) => s.id == id ? updated : s).toList(),
        );
        return updated.featured;
      }
    } catch (_) {}

    // Local fallback
    bool newFeatured = false;
    state = state.copyWith(
      stores: state.stores.map((s) {
        if (s.id == id) {
          newFeatured = !s.featured;
          return s.copyWith(featured: newFeatured);
        }
        return s;
      }).toList(),
    );
    return newFeatured;
  }

  Future<bool> deleteStore(int id) async {
    try {
      final response = await _apiClient.delete('/stores/delete-store/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        state = state.copyWith(
          stores: state.stores.where((s) => s.id != id).toList(),
          branches: state.branches.where((b) => b.storeId != id).toList(),
          followedStoreIds: state.followedStoreIds.where((fid) => fid != id).toList(),
        );
        return true;
      }
    } catch (_) {}

    state = state.copyWith(
      stores: state.stores.where((s) => s.id != id).toList(),
      branches: state.branches.where((b) => b.storeId != id).toList(),
      followedStoreIds: state.followedStoreIds.where((fid) => fid != id).toList(),
    );
    return true;
  }

  // Admin CRUD - Branches
  Future<void> fetchBranchesForStore(int storeId) async {
    try {
      final response = await _apiClient.get('/store-branches/store/$storeId/branches');
      if (response.statusCode == 200 && response.data != null) {
        final rawList = response.data as List;
        final list = rawList.map((e) => StoreBranch.fromJson(e as Map<String, dynamic>)).toList();
        final otherBranches = state.branches.where((b) => b.storeId != storeId).toList();
        state = state.copyWith(branches: [...otherBranches, ...list]);
      }
    } catch (_) {}
  }

  Future<bool> createBranch(
    int storeId,
    int cityId,
    String name,
    double lat,
    double lng,
    String open,
    String close,
    int isActive, [
    String? phone,
    String? address,
  ]) async {
    try {
      final payload = {
        'storeId': storeId,
        'cityId': cityId,
        'branchName': name,
        'latitude': lat,
        'longitude': lng,
        'openTime': open,
        'closeTime': close,
        'phone': phone ?? '',
        'addressEn': address ?? '',
        'addressAr': address ?? '',
        'twentyFourHours': open == '00:00:00' && close == '23:59:59',
        'active': isActive == 1,
      };

      final response = await _apiClient.post('/store-branches/store/add-branch', data: payload);
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        final created = StoreBranch.fromJson(response.data as Map<String, dynamic>);
        state = state.copyWith(branches: [created, ...state.branches]);
        return true;
      }
    } catch (_) {}

    // Fallback local addition
    final newId = state.branches.isEmpty ? 1 : state.branches.map((b) => b.id).reduce((a, b) => a > b ? a : b) + 1;
    final newBranch = StoreBranch(
      id: newId,
      storeId: storeId,
      cityId: cityId,
      branchName: name,
      latitude: lat,
      longitude: lng,
      openTime: open,
      closeTime: close,
      isActive: isActive,
      contactPhone: phone,
      addressLine: address,
    );
    state = state.copyWith(branches: [newBranch, ...state.branches]);
    return true;
  }

  Future<bool> updateBranch(
    int id,
    int cityId,
    String name,
    double lat,
    double lng,
    String open,
    String close,
    int isActive, [
    String? phone,
    String? address,
  ]) async {
    try {
      final payload = {
        'cityId': cityId,
        'branchName': name,
        'latitude': lat,
        'longitude': lng,
        'openTime': open,
        'closeTime': close,
        'phone': phone ?? '',
        'addressEn': address ?? '',
        'addressAr': address ?? '',
        'twentyFourHours': open == '00:00:00' && close == '23:59:59',
        'active': isActive == 1,
      };

      final response = await _apiClient.put('/store-branches/update/$id', data: payload);
      if (response.statusCode == 200 && response.data != null) {
        final updated = StoreBranch.fromJson(response.data as Map<String, dynamic>);
        state = state.copyWith(
          branches: state.branches.map((b) => b.id == id ? updated : b).toList(),
        );
        return true;
      }
    } catch (_) {}

    state = state.copyWith(
      branches: state.branches.map((b) {
        if (b.id == id) {
          return b.copyWith(
            cityId: cityId,
            branchName: name,
            latitude: lat,
            longitude: lng,
            openTime: open,
            closeTime: close,
            isActive: isActive,
            contactPhone: phone,
            addressLine: address,
          );
        }
        return b;
      }).toList(),
    );
    return true;
  }

  Future<bool> deleteBranch(int id) async {
    try {
      final response = await _apiClient.delete('/store-branches/delete/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        state = state.copyWith(
          branches: state.branches.where((b) => b.id != id).toList(),
        );
        return true;
      }
    } catch (_) {}

    state = state.copyWith(
      branches: state.branches.where((b) => b.id != id).toList(),
    );
    return true;
  }
}

final storeRepositoryProvider = StateNotifierProvider<StoreNotifier, StoreState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StoreNotifier(ref, apiClient);
});
